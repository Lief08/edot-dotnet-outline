<#
.SYNOPSIS
    Install and configure Elastic Distribution of OpenTelemetry (EDOT) Collector in Gateway Mode
    
.DESCRIPTION
    This script installs the EDOT Collector compatible with Elastic 8.19 and configures it
    in Gateway Mode for aggregating telemetry data from multiple APM services.
    
.PARAMETER ElasticEndpoint
    The Elasticsearch endpoint URL (e.g., https://your-cluster.elastic.co:443)
    
.PARAMETER ApiKey
    Elasticsearch API key for authentication
    
.PARAMETER CollectorPort
    Port for the OTLP receiver (default: 4317 for gRPC, 4318 for HTTP)
    
.PARAMETER InstallDir
    Installation directory (default: C:\Program Files\Elastic\EDOTCollector)
    
.EXAMPLE
    .\Install-EDOTCollector.ps1 -ElasticEndpoint "https://myhost.elastic.co:443" -ApiKey "your-api-key"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ElasticEndpoint,
    
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$false)]
    [int]$CollectorPort = 4317,
    
    [Parameter(Mandatory=$false)]
    [int]$CollectorHttpPort = 4318,
    
    [Parameter(Mandatory=$false)]
    [string]$InstallDir = 'C:\Program Files\Elastic\EDOTCollector',
    
    [Parameter(Mandatory=$false)]
    [string]$Version = '8.19.0'
)

#Requires -RunAsAdministrator

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Detect system architecture
$architecture = if ([Environment]::Is64BitOperatingSystem) { 'x86_64' } else { 'x86' }
Write-Log "Detected architecture: $architecture" -Level INFO

# Set the URL for the Elastic EDOT Collector package (compatible with Elastic 8.19)
$EDOTCollectorUrl = "https://artifacts.elastic.co/downloads/apm-server/apm-server-${Version}-windows-${architecture}.zip"
Write-Log "Download URL: $EDOTCollectorUrl" -Level INFO

# Download the Elastic EDOT Collector package
$zipFilePath = Join-Path $env:TEMP "edot-collector-${Version}.zip"
Write-Log "Downloading EDOT Collector..." -Level INFO

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $EDOTCollectorUrl -OutFile $zipFilePath -UseBasicParsing
    Write-Log "Download completed successfully" -Level SUCCESS
} catch {
    Write-Log "Failed to download EDOT Collector: $_" -Level ERROR
    throw
}

# Create installation directory
Write-Log "Creating installation directory: $InstallDir" -Level INFO
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Extract the downloaded ZIP file
Write-Log "Extracting the EDOT Collector..." -Level INFO
try {
    Expand-Archive -Path $zipFilePath -DestinationPath $InstallDir -Force
    
    # Move files from versioned subdirectory to install root
    $extractedDir = Get-ChildItem -Path $InstallDir -Directory | Select-Object -First 1
    if ($extractedDir) {
        Get-ChildItem -Path $extractedDir.FullName | Move-Item -Destination $InstallDir -Force
        Remove-Item -Path $extractedDir.FullName -Force -Recurse
    }
    
    Write-Log "Extraction completed successfully" -Level SUCCESS
} catch {
    Write-Log "Failed to extract EDOT Collector: $_" -Level ERROR
    throw
}

# Deploy Gateway Mode configuration from template
$configPath = Join-Path $InstallDir 'otel-collector-config.yaml'
$templateConfigPath = Join-Path $PSScriptRoot 'otel-collector-gateway-config.yaml'

Write-Log "Deploying Gateway Mode configuration..." -Level INFO

if (-not (Test-Path $templateConfigPath)) {
    Write-Log "Configuration template not found at: $templateConfigPath" -Level ERROR
    throw "Missing otel-collector-gateway-config.yaml template file"
}

try {
    # Create logs directory
    $logsDir = Join-Path $InstallDir 'logs'
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    
    # Read template configuration
    $configContent = Get-Content -Path $templateConfigPath -Raw
    
    # Replace placeholders with actual values
    $configContent = $configContent -replace '\{ELASTIC_ENDPOINT\}', $ElasticEndpoint
    $configContent = $configContent -replace '\{ELASTIC_API_KEY\}', $ApiKey
    $configContent = $configContent -replace '\{INSTALL_DIR\}', ($InstallDir -replace '\\', '/')
    
    # Also update port numbers if they differ from defaults
    if ($CollectorPort -ne 4317) {
        $configContent = $configContent -replace '0\.0\.0\.0:4317', "0.0.0.0:$CollectorPort"
    }
    if ($CollectorHttpPort -ne 4318) {
        $configContent = $configContent -replace '0\.0\.0\.0:4318', "0.0.0.0:$CollectorHttpPort"
    }
    
    # Write final configuration file
    $configContent | Out-File -FilePath $configPath -Encoding UTF8 -Force
    Write-Log "Configuration deployed successfully to: $configPath" -Level SUCCESS
} catch {
    Write-Log "Failed to deploy configuration: $_" -Level ERROR
    throw
}

# Install the EDOT Collector as a Windows service
$edotServiceName = 'ElasticEDOTCollector'
$edotServiceExecutable = Join-Path $InstallDir 'apm-server.exe'

Write-Log "Installing EDOT Collector as Windows service..." -Level INFO

# Check if the service exists and remove it if it does
if (Get-Service -Name $edotServiceName -ErrorAction SilentlyContinue) {
    Write-Log "Existing service found. Stopping and removing..." -Level WARN
    Stop-Service -Name $edotServiceName -Force
    Start-Sleep -Seconds 2
    sc.exe delete $edotServiceName | Out-Null
    Start-Sleep -Seconds 1
}

# Create the service with configuration
$serviceArgs = "--config `"$configPath`" --path.home `"$InstallDir`" --path.data `"$InstallDir\data`""
$serviceBinary = "`"$edotServiceExecutable`" $serviceArgs"

try {
    New-Service -Name $edotServiceName `
                -BinaryPathName $serviceBinary `
                -DisplayName 'Elastic EDOT Collector (Gateway Mode)' `
                -Description 'Elastic Distribution of OpenTelemetry Collector aggregating telemetry from multiple APM services' `
                -StartupType Automatic `
                -ErrorAction Stop
    
    Write-Log "Service created successfully" -Level SUCCESS
} catch {
    Write-Log "Failed to create service: $_" -Level ERROR
    throw
}

# Configure service recovery options
sc.exe failure $edotServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null

# Configure firewall rules
Write-Log "Configuring Windows Firewall rules..." -Level INFO
try {
    $firewallRules = @(
        @{Name="EDOT-Collector-OTLP-gRPC"; Port=$CollectorPort; Protocol="TCP"},
        @{Name="EDOT-Collector-OTLP-HTTP"; Port=$CollectorHttpPort; Protocol="TCP"},
        @{Name="EDOT-Collector-Health"; Port=13133; Protocol="TCP"}
    )
    
    foreach ($rule in $firewallRules) {
        $existingRule = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
        if ($existingRule) {
            Remove-NetFirewallRule -DisplayName $rule.Name
        }
        
        New-NetFirewallRule -DisplayName $rule.Name `
                           -Direction Inbound `
                           -Action Allow `
                           -Protocol $rule.Protocol `
                           -LocalPort $rule.Port `
                           -Profile Any `
                           -ErrorAction Stop | Out-Null
    }
    Write-Log "Firewall rules configured successfully" -Level SUCCESS
} catch {
    Write-Log "Warning: Failed to configure firewall rules: $_" -Level WARN
}

# Start the service
Write-Log "Starting EDOT Collector service..." -Level INFO
try {
    Start-Service -Name $edotServiceName -ErrorAction Stop
    Start-Sleep -Seconds 3
    
    $serviceStatus = Get-Service -Name $edotServiceName
    if ($serviceStatus.Status -eq 'Running') {
        Write-Log "Service started successfully" -Level SUCCESS
    } else {
        Write-Log "Service is not running. Status: $($serviceStatus.Status)" -Level WARN
    }
} catch {
    Write-Log "Failed to start service: $_" -Level ERROR
    throw
}

# Cleanup
Write-Log "Cleaning up temporary files..." -Level INFO
Remove-Item $zipFilePath -Force -ErrorAction SilentlyContinue

# Display configuration summary
Write-Log "" -Level INFO
Write-Log "=== EDOT Collector Installation Complete ===" -Level SUCCESS
Write-Log "Version: $Version" -Level INFO
Write-Log "Mode: Gateway (Multi-Service APM Aggregation)" -Level INFO
Write-Log "Installation Directory: $InstallDir" -Level INFO
Write-Log "Configuration File: $configPath" -Level INFO
Write-Log "Service Name: $edotServiceName" -Level INFO
Write-Log "" -Level INFO
Write-Log "Receiver Endpoints:" -Level INFO
Write-Log "  - OTLP gRPC: 0.0.0.0:$CollectorPort" -Level INFO
Write-Log "  - OTLP HTTP: 0.0.0.0:$CollectorHttpPort" -Level INFO
Write-Log "  - Health Check: http://localhost:13133/health" -Level INFO
Write-Log "  - Metrics: http://localhost:8888/metrics" -Level INFO
Write-Log "  - zpages: http://localhost:55679/debug/tracez" -Level INFO
Write-Log "" -Level INFO
Write-Log "Elastic Endpoint: $ElasticEndpoint" -Level INFO
Write-Log "" -Level INFO
Write-Log "To configure APM agents to send data to this collector:" -Level INFO
Write-Log "  Set OTEL_EXPORTER_OTLP_ENDPOINT=http://<collector-host>:$CollectorPort" -Level INFO
Write-Log "" -Level INFO
Write-Log "Log files location: $logsDir" -Level INFO
Write-Log "" -Level INFO