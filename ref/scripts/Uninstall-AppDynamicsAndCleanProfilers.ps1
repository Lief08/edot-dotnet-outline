<#
.SYNOPSIS
	Fully uninstall AppDynamics .NET agent artifacts and clean profiler-related configuration.

.DESCRIPTION
	This script is intended for Windows Server 2012 R2+ where the AppDynamics .NET agent
	(typically v20.x or v21.x) has been installed using the standard installer, but the
	uninstall leaves behind profiler configuration that continues to load AppDynamics
	assemblies in IIS or other .NET processes.

	The script performs the following high-level actions:
	  1. Detect AppDynamics .NET-related services, installation paths, and uninstall entries.
	  2. Discover profiler-related environment variables and registry values, including
		 AppDynamics, OpenTelemetry, and other profiler configuration.
	  3. Persist a JSON backup of all discovered state for rollback/audit.
	  4. Optionally stop and remove AppDynamics services and invoke MSI uninstalls.
	  5. Remove or neutralize profiler-related configuration so .NET no longer loads
		 AppDynamics (or other legacy) profilers.

	IMPORTANT:
	  - Run as local Administrator.
	  - Expect to recycle IIS (and ideally schedule a reboot) after cleanup to ensure
		processes pick up updated environment and registry settings.

.PARAMETER BackupDir
	Directory to store JSON backups of all discovered state.

.PARAMETER SkipUninstall
	If specified, do not attempt to run AppDynamics uninstallers; only clean profiler
	configuration. Useful if the product has already been removed.

.PARAMETER WhatIf
	If specified, do discovery and write backup JSON but do not make destructive changes
	(no uninstall, no registry/env var modifications).

.EXAMPLE
	.\Uninstall-AppDynamicsAndCleanProfilers.ps1

.EXAMPLE
	.\Uninstall-AppDynamicsAndCleanProfilers.ps1 -WhatIf

.EXAMPLE
	.\Uninstall-AppDynamicsAndCleanProfilers.ps1 -SkipUninstall -BackupDir 'C:\EDOT-Migration\Backups'

#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[Parameter(Mandatory = $false)]
	[string]$BackupDir = 'C:\EDOT-Migration\Backups',

	[Parameter(Mandatory = $false)]
	[switch]$SkipUninstall,

	[Parameter(Mandatory = $false)]
	[switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
	param(
		[string]$Message,
		[ValidateSet('INFO','WARN','ERROR','DEBUG')]
		[string]$Level = 'INFO'
	)

	$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
	$color = switch ($Level) {
		'INFO'  { 'White' }
		'WARN'  { 'Yellow' }
		'ERROR' { 'Red' }
		'DEBUG' { 'Cyan' }
	}
	Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Administrator {
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
	Write-Log "This script must be run as Administrator." -Level ERROR
	throw "Administrator privileges are required."
}

if (-not (Test-Path $BackupDir)) {
	Write-Log "Creating backup directory at: $BackupDir" -Level INFO
	New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$hostname  = $env:COMPUTERNAME
$backupFile = Join-Path $BackupDir "cleanup_${hostname}_${timestamp}.json"

$backup = @{
	Hostname          = $hostname
	Timestamp         = (Get-Date).ToString('o')
	Parameters        = @{
		BackupDir    = $BackupDir
		SkipUninstall = [bool]$SkipUninstall
	}
	AppDynamics       = @{}
	SystemEnv         = @{}
	AppPoolEnv        = @{}
	RegistryProfilers = @{}
	RegistrySearch    = @{}
}

function Get-AppDynamicsInfo {
	$result = @{
		Services   = @()
		InstallDir = $null
		Uninstall  = @()
	}

	Write-Log "Detecting AppDynamics-related services..." -Level INFO

	$services = Get-Service | Where-Object {
		$_.Name -like '*AppDynamics*' -or
		$_.DisplayName -like '*AppDynamics*'
	}

	foreach ($svc in $services) {
		try {
			$svcWmi = Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction Stop
		} catch {
			$svcWmi = $null
		}

		$result.Services += @{
			Name        = $svc.Name
			DisplayName = $svc.DisplayName
			Status      = $svc.Status
			PathName    = if ($svcWmi) { $svcWmi.PathName } else { $null }
		}
	}

	if ($result.Services.Count -gt 0 -and $result.Services[0].PathName) {
		$path = $result.Services[0].PathName.Trim('"')
		$exe  = $path.Split('"')[0]
		$result.InstallDir = Split-Path (Split-Path $exe -Parent) -Parent
		Write-Log "Inferred AppDynamics install directory: $($result.InstallDir)" -Level INFO
	}

	Write-Log "Searching for AppDynamics uninstall entries..." -Level INFO

	$uninstKeys = @(
		'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
		'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
	)

	foreach ($key in $uninstKeys) {
		if (-not (Test-Path $key)) { continue }

		Get-ChildItem $key | ForEach-Object {
			try {
				$p = Get-ItemProperty $_.PsPath -ErrorAction Stop
			} catch { return }

			if ($p.DisplayName -and $p.DisplayName -like '*AppDynamics*NET*Agent*') {
				$result.Uninstall += @{
					KeyPath        = $_.PsPath
					DisplayName    = $p.DisplayName
					UninstallString = $p.UninstallString
				}
			}
		}
	}

	return $result
}

function Get-SystemProfilerEnv {
	Write-Log "Collecting system-level profiler and agent environment variables..." -Level INFO

	$machine = [Environment]::GetEnvironmentVariables('Machine')
	$keysOfInterest = @(
		'COR_ENABLE_PROFILING','COR_PROFILER','COR_PROFILER_PATH',
		'CORECLR_ENABLE_PROFILING','CORECLR_PROFILER','CORECLR_PROFILER_PATH'
	)

	$result = @{}
	foreach ($key in $machine.Keys) {
		if ($key -in $keysOfInterest -or
			$key -like 'APPDYNAMICS_*' -or
			$key -like 'OTEL_*') {

			$result[$key] = $machine[$key]
		}
	}
	return $result
}

function Get-AppPoolEnvVars {
	Write-Log "Collecting IIS app pool environment variables related to profilers..." -Level INFO

	$base = 'HKLM:\SYSTEM\CurrentControlSet\Services\WAS\Parameters\AppPoolEnvironmentVariables'
	$result = @{}

	if (-not (Test-Path $base)) { return $result }

	Get-ChildItem $base | ForEach-Object {
		$poolName = $_.PSChildName
		$values = Get-ItemProperty $_.PsPath
		$envForPool = @{}
		foreach ($prop in $values.PSObject.Properties) {
			if ($prop.Name -in 'PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') { continue }
			if ($prop.Name -like 'COR_*' -or
				$prop.Name -like 'CORECLR_*' -or
				$prop.Name -like 'APPDYNAMICS_*' -or
				$prop.Name -like 'OTEL_*') {
				$envForPool[$prop.Name] = $prop.Value
			}
		}
		if ($envForPool.Count -gt 0) {
			$result[$poolName] = $envForPool
		}
	}

	return $result
}

function Get-RegistryProfilerSettings {
	Write-Log "Collecting known .NET profiler registry settings..." -Level INFO

	$paths = @(
		'HKLM:\SOFTWARE\Microsoft\.NETFramework',
		'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework'
	)
	$keys = @('COR_ENABLE_PROFILING','COR_PROFILER','COR_PROFILER_PATH')

	$result = @{}
	foreach ($path in $paths) {
		if (-not (Test-Path $path)) { continue }
		$item = Get-ItemProperty $path
		$entry = @{}
		foreach ($k in $keys) {
			if ($item.PSObject.Properties.Name -contains $k) {
				$entry[$k] = $item.$k
			}
		}
		if ($entry.Count -gt 0) {
			$result[$path] = $entry
		}
	}
	return $result
}

function Search-RegistryForProfilers {
	Write-Log "Searching registry for profiler and AppDynamics-related values (broad scan)..." -Level INFO

	$hives = @(
		'HKLM:\SYSTEM',
		'HKLM:\SOFTWARE',
		'HKLM:\SOFTWARE\WOW6432Node'
	)

	$namePatterns = @(
		'COR_ENABLE_PROFILING','COR_PROFILER','COR_PROFILER_PATH',
		'CORECLR_ENABLE_PROFILING','CORECLR_PROFILER','CORECLR_PROFILER_PATH',
		'APPDYNAMICS*','OTEL*'
	)

	$results = @()

	foreach ($root in $hives) {
		if (-not (Test-Path $root)) { continue }

		try {
			Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
				$keyPath = $_.PsPath
				try {
					$props = Get-ItemProperty -Path $keyPath -ErrorAction Stop
				} catch {
					return
				}

				foreach ($prop in $props.PSObject.Properties) {
					if ($prop.Name -in 'PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') { continue }

					$matchesName = $false
					foreach ($pattern in $namePatterns) {
						if ($prop.Name -like $pattern) { $matchesName = $true; break }
					}

					if (-not $matchesName) { continue }

					$results += [PSCustomObject]@{
						Hive      = $root
						KeyPath   = $keyPath
						Name      = $prop.Name
						Value     = $prop.Value
					}
				}
			}
		} catch {
			Write-Log "Registry search under $root encountered errors (continuing): $_" -Level WARN
		}
	}

	return $results
}

function Save-Backup {
	param(
		[hashtable]$Data,
		[string]$Path
	)

	Write-Log "Writing backup JSON to: $Path" -Level INFO
	$Data | ConvertTo-Json -Depth 8 | Out-File -FilePath $Path -Encoding UTF8
}

function Invoke-AppDynamicsUninstall {
	param(
		[hashtable]$AppDInfo
	)

	if ($SkipUninstall) {
		Write-Log "SkipUninstall specified; not invoking AppDynamics uninstallers." -Level INFO
		return
	}

	if (-not $AppDInfo.Uninstall -or $AppDInfo.Uninstall.Count -eq 0) {
		Write-Log "No AppDynamics uninstall entries found in registry." -Level WARN
		return
	}

	foreach ($entry in $AppDInfo.Uninstall) {
		$cmd = $entry.UninstallString
		if (-not $cmd) { continue }

		Write-Log "Invoking AppDynamics uninstall: $($entry.DisplayName)" -Level INFO
		Write-Log "Uninstall command: $cmd" -Level DEBUG

		if ($WhatIf) {
			Write-Log "WhatIf: Skipping execution of uninstall command." -Level WARN
			continue
		}

		try {
			if ($cmd -match 'msiexec') {
				Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd /qn" -Wait -NoNewWindow
			} else {
				Start-Process -FilePath 'cmd.exe' -ArgumentList "/c `"$cmd`"" -Wait -NoNewWindow
			}
			Write-Log "Uninstall command completed for $($entry.DisplayName)" -Level INFO
		} catch {
			Write-Log "Uninstall command failed for $($entry.DisplayName): $_" -Level ERROR
		}
	}
}

function Stop-AndRemove-AppDynamicsServices {
	param(
		[hashtable]$AppDInfo
	)

	if (-not $AppDInfo.Services -or $AppDInfo.Services.Count -eq 0) {
		Write-Log "No AppDynamics services detected to stop/remove." -Level INFO
		return
	}

	foreach ($svc in $AppDInfo.Services) {
		$name = $svc.Name
		Write-Log "Processing service: $name" -Level INFO

		if (-not $WhatIf) {
			try {
				if ($svc.Status -eq 'Running') {
					Write-Log "Stopping service $name..." -Level INFO
					Stop-Service -Name $name -Force -ErrorAction Stop
				}
			} catch {
				Write-Log "Failed to stop service $name: $_" -Level WARN
			}

			try {
				Write-Log "Deleting service $name via sc.exe..." -Level INFO
				sc.exe delete $name | Out-Null
			} catch {
				Write-Log "Failed to delete service $name: $_" -Level WARN
			}
		} else {
			Write-Log "WhatIf: Would stop and delete service $name" -Level WARN
		}
	}
}

function Clear-SystemProfilerEnv {
	param(
		[hashtable]$EnvSnapshot
	)

	if ($EnvSnapshot.Count -eq 0) {
		Write-Log "No system-level profiler or agent env vars to clear." -Level INFO
		return
	}

	foreach ($key in $EnvSnapshot.Keys) {
		Write-Log "Removing system environment variable: $key" -Level INFO
		if (-not $WhatIf) {
			[Environment]::SetEnvironmentVariable($key, $null, 'Machine')
		} else {
			Write-Log "WhatIf: Skipping removal of $key" -Level WARN
		}
	}
}

function Clear-AppPoolEnv {
	param(
		[hashtable]$AppPoolEnvSnapshot
	)

	if ($AppPoolEnvSnapshot.Count -eq 0) {
		Write-Log "No app pool-level profiler or agent env vars to clear." -Level INFO
		return
	}

	$base = 'HKLM:\SYSTEM\CurrentControlSet\Services\WAS\Parameters\AppPoolEnvironmentVariables'

	foreach ($poolName in $AppPoolEnvSnapshot.Keys) {
		$poolKey = Join-Path $base $poolName
		if (-not (Test-Path $poolKey)) { continue }

		foreach ($varName in $AppPoolEnvSnapshot[$poolName].Keys) {
			Write-Log "Removing env var '$varName' from app pool '$poolName'" -Level INFO
			if (-not $WhatIf) {
				Remove-ItemProperty -Path $poolKey -Name $varName -ErrorAction SilentlyContinue
			} else {
				Write-Log "WhatIf: Skipping removal of $varName from $poolName" -Level WARN
			}
		}
	}
}

function Clear-RegistryProfilerSettings {
	param(
		[hashtable]$RegistrySnapshot
	)

	if ($RegistrySnapshot.Count -eq 0) {
		Write-Log "No known .NET profiler registry settings to clear." -Level INFO
		return
	}

	foreach ($path in $RegistrySnapshot.Keys) {
		foreach ($name in $RegistrySnapshot[$path].Keys) {
			Write-Log "Clearing registry value '$name' at '$path'" -Level INFO
			if (-not $WhatIf) {
				try {
					Remove-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
				} catch {
					Write-Log "Failed to clear $name at $path: $_" -Level WARN
				}
			} else {
				Write-Log "WhatIf: Skipping clearing of $name at $path" -Level WARN
			}
		}
	}
}

function Clear-RegistrySearchMatches {
	param(
		[System.Collections.IEnumerable]$Matches
	)

	if (-not $Matches -or $Matches.Count -eq 0) {
		Write-Log "Registry search found no additional profiler-related values to clear." -Level INFO
		return
	}

	foreach ($m in $Matches) {
		Write-Log "Clearing registry value '$($m.Name)' at '$($m.KeyPath)'" -Level INFO
		if (-not $WhatIf) {
			try {
				Remove-ItemProperty -Path $m.KeyPath -Name $m.Name -ErrorAction SilentlyContinue
			} catch {
				Write-Log "Failed to clear $($m.Name) at $($m.KeyPath): $_" -Level WARN
			}
		} else {
			Write-Log "WhatIf: Skipping clearing of $($m.Name) at $($m.KeyPath)" -Level WARN
		}
	}
}

Write-Log "Starting AppDynamics and profiler cleanup on host $hostname" -Level INFO

# 1. Discovery & backup
$appDInfo            = Get-AppDynamicsInfo
$systemEnvSnapshot   = Get-SystemProfilerEnv
$appPoolEnvSnapshot  = Get-AppPoolEnvVars
$regProfilerSnapshot = Get-RegistryProfilerSettings
$regSearchSnapshot   = Search-RegistryForProfilers

$backup.AppDynamics       = $appDInfo
$backup.SystemEnv         = $systemEnvSnapshot
$backup.AppPoolEnv        = $appPoolEnvSnapshot
$backup.RegistryProfilers = $regProfilerSnapshot
$backup.RegistrySearch    = $regSearchSnapshot

Save-Backup -Data $backup -Path $backupFile

if ($WhatIf) {
	Write-Log "WhatIf specified: discovery and backup complete, no changes applied." -Level WARN
	Write-Log "Review backup file at: $backupFile" -Level INFO
	return
}

Write-Log "Proceeding with uninstall and cleanup actions." -Level INFO

# 2. Attempt to uninstall AppDynamics and remove services
Stop-AndRemove-AppDynamicsServices -AppDInfo $appDInfo
Invoke-AppDynamicsUninstall -AppDInfo $appDInfo

# 3. Clear environment variables and registry-based profiler configuration
Clear-SystemProfilerEnv     -EnvSnapshot $systemEnvSnapshot
Clear-AppPoolEnv            -AppPoolEnvSnapshot $appPoolEnvSnapshot
Clear-RegistryProfilerSettings -RegistrySnapshot $regProfilerSnapshot
Clear-RegistrySearchMatches    -Matches $regSearchSnapshot

Write-Log "Cleanup actions complete. It is recommended to recycle IIS (iisreset) and schedule a reboot to ensure all processes pick up the updated configuration." -Level WARN
