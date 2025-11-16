# Required Technical Corrections

## 1. Update IIS Cmdlets for Server 2012
```powershell
# Replace this:
Get-IISSite
Get-IISAppPool

# With this:
Import-Module WebAdministration
Get-ChildItem IIS:\Sites
Get-ChildItem IIS:\AppPools
Get-Website
Get-WebApplication
```

## 2. Handle AppDynamics Automatic Mode
```powershell
function Get-IISApplicationsFromConfig {
    param($ConfigXml)
    
    # Check for automatic mode
    if ($ConfigXml.SelectSingleNode("//IIS/automatic")) {
        Write-Log "Automatic mode detected - enumerating all IIS sites" -Level WARN
        return $null  # Signal to enumerate IIS directly
    }
    
    # Parse manual applications
    return Parse-ManualApplications -ConfigXml $ConfigXml
}
```

## 3. Correct IIS-to-AppPool Mapping
```powershell
function Get-AppPoolForApplication {
    param(
        [string]$SiteName,
        [string]$AppPath
    )
    
    Import-Module WebAdministration
    
    if ($AppPath -eq "/") {
        # Root application uses site's app pool
        $site = Get-Website -Name $SiteName
        return $site.ApplicationPool
    } else {
        # Sub-application has its own app pool
        $app = Get-WebApplication -Site $SiteName | 
               Where-Object { $_.Path -eq $AppPath }
        return $app.ApplicationPool
    }
}
```

## 4. Define EAI Extraction Strategy
```powershell
function Get-EAICodeFromAppPool {
    param([string]$AppPoolName)
    
    # Strategy 1: Parse from app pool name
    if ($AppPoolName -match '^(\d{4,5})-') {
        return $Matches[1]
    }
    
    # Strategy 2: Look up from external mapping
    # (Implement based on actual environment)
    
    # Strategy 3: Prompt user for mapping
    Write-Log "Cannot determine EAI for app pool: $AppPoolName" -Level WARN
    return $null
}
```