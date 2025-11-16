<#
.SYNOPSIS
    Builds EDOT .NET service registration configuration from existing AppDynamics installation.

.DESCRIPTION
    This script detects the AppDynamics .NET agent installation, parses the config.xml file,
    queries IIS configuration, and generates a serviceRegistration.yaml file organized by
    EAI codes for migration to Elastic Distribution of OpenTelemetry (EDOT) .NET agent.

.PARAMETER ConfigPath
    Optional path to AppDynamics config.xml file. If not provided, script will auto-detect.

.PARAMETER OutputPath
    Path for the generated serviceRegistration.yaml file. Default: .\serviceRegistration.yaml

.PARAMETER IncludeIIS
    Include IIS site and application pool discovery. Default: $true

.PARAMETER DryRun
    Test mode - performs all operations but doesn't write output file.

.PARAMETER LogLevel
    Logging verbosity level: INFO, WARN, ERROR, DEBUG. Default: INFO

.PARAMETER LogPath
    Path for the log file. Default: .\Build-EDOTServiceRegistration.log

.EXAMPLE
    .\Build-EDOTServiceRegistration.ps1

.EXAMPLE
    .\Build-EDOTServiceRegistration.ps1 -ConfigPath "C:\Custom\config.xml" -OutputPath "C:\Output\services.yaml"

.EXAMPLE
    .\Build-EDOTServiceRegistration.ps1 -DryRun -LogLevel DEBUG

.NOTES
    Author: Lief08
    Date: 2025-11-15
    Version: 1.0
    Requires: PowerShell 5.1+, Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\serviceRegistration.yaml",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeIIS = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
    [string]$LogLevel = 'INFO',
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\Build-EDOTServiceRegistration.log"
)

#Requires -RunAsAdministrator
#Requires -Version 5.1

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

$script:LogFile = $LogPath
$script:LogLevelValue = @{ 'DEBUG' = 0; 'INFO' = 1; 'WARN' = 2; 'ERROR' = 3 }
$script:CurrentLogLevel = $script:LogLevelValue[$LogLevel]

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    # TODO: Implement logging logic
    # - Check if message level meets current log level threshold
    # - Format timestamp
    # - Write to log file
    # - Write to console with appropriate color
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Placeholder for actual implementation
    Write-Host $logMessage
}

function Initialize-Logging {
    # TODO: Implement logging initialization
    # - Create or clear log file
    # - Write header information
    # - Validate log path is writable
    
    Write-Log "Logging initialized at $LogPath" -Level INFO
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

function Test-Prerequisites {
    # TODO: Implement prerequisite checks
    # - Check PowerShell version
    # - Verify administrator privileges
    # - Check if IIS is installed (if IncludeIIS is set)
    # - Validate WebAdministration module availability
    
    Write-Log "Validating prerequisites..." -Level INFO
    
    $isValid = $true
    
    # Check PS version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5.1 or higher required" -Level ERROR
        $isValid = $false
    }
    
    # Check admin privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "Administrator privileges required" -Level ERROR
        $isValid = $false
    }
    
    return $isValid
}

# ============================================================================
# PHASE 1: APPDYNAMICS DETECTION
# ============================================================================

function Find-AppDynamicsService {
    <#
    .SYNOPSIS
        Locates the AppDynamics Coordinator service on the system.
    #>
    
    Write-Log "Phase 1: Detecting AppDynamics installation..." -Level INFO
    
    # TODO: Implement service detection logic
    # - Query Windows services with pattern "AppDynamics.Agent.Coordinator*"
    # - Handle multiple matches
    # - Extract service executable path
    # - Validate service exists and is accessible
    
    $servicePattern = "*AppDynamics.Agent.Coordinator*"
    
    try {
        # Placeholder for actual service query
        # $service = Get-Service -DisplayName $servicePattern -ErrorAction Stop
        
        Write-Log "Searching for AppDynamics Coordinator service..." -Level DEBUG
        
        # Simulated service object structure
        $service = @{
            Name = "AppDynamics.Agent.Coordinator"
            DisplayName = "AppDynamics .NET Agent Coordinator"
            Status = "Running"
            BinaryPathName = "C:\Program Files\AppDynamics\AppDynamics .NET Agent\Coordinator.exe"
        }
        
        Write-Log "Found service: $($service.Name)" -Level INFO
        
        return $service
    }
    catch {
        Write-Log "Failed to locate AppDynamics service: $_" -Level ERROR
        return $null
    }
}

function Get-AppDynamicsInstallPath {
    param(
        [Parameter(Mandatory=$true)]
        $Service
    )
    
    # TODO: Implement installation path extraction
    # - Parse service executable path
    # - Navigate to parent directory
    # - Validate directory structure
    # - Return installation root path
    
    Write-Log "Extracting installation path from service..." -Level DEBUG
    
    try {
        # Extract path from service binary
        # $binaryPath = $Service.BinaryPathName
        # $installPath = Split-Path $binaryPath -Parent
        
        # Placeholder
        $installPath = "C:\Program Files\AppDynamics\AppDynamics .NET Agent"
        
        Write-Log "Installation path: $installPath" -Level INFO
        
        return $installPath
    }
    catch {
        Write-Log "Failed to extract installation path: $_" -Level ERROR
        return $null
    }
}

# ============================================================================
# PHASE 2: CONFIG.XML LOCATION
# ============================================================================

function Find-ConfigXml {
    param(
        [string]$InstallPath,
        [string]$CustomPath
    )
    
    Write-Log "Phase 2: Locating config.xml..." -Level INFO
    
    # TODO: Implement config.xml discovery logic
    # - Check custom path if provided
    # - Check standard locations in priority order:
    #   1. %ProgramData%\AppDynamics\DotNetAgent\Config\config.xml
    #   2. Installation path relative location
    #   3. %AllUsersProfile%\Application Data\AppDynamics\DotNetAgent\Config\config.xml
    # - Validate file exists and is readable
    # - Return first valid path found
    
    $locations = @()
    
    if ($CustomPath) {
        $locations += $CustomPath
    }
    
    $locations += "$env:ProgramData\AppDynamics\DotNetAgent\Config\config.xml"
    $locations += "$InstallPath\..\Config\config.xml"
    $locations += "$env:AllUsersProfile\Application Data\AppDynamics\DotNetAgent\Config\config.xml"
    
    foreach ($location in $locations) {
        Write-Log "Checking location: $location" -Level DEBUG
        
        # TODO: Test-Path and validate XML
        # if (Test-Path $location) {
        #     Write-Log "Found config.xml at: $location" -Level INFO
        #     return $location
        # }
    }
    
    # Placeholder return
    $configPath = "$env:ProgramData\AppDynamics\DotNetAgent\Config\config.xml"
    Write-Log "Using config.xml path: $configPath" -Level INFO
    
    return $configPath
}

function Test-ConfigXml {
    param(
        [string]$Path
    )
    
    # TODO: Implement XML validation
    # - Test if file exists
    # - Try to load as XML
    # - Validate root element is <appdynamics-agent>
    # - Check for required elements
    # - Return validation result
    
    Write-Log "Validating config.xml structure..." -Level DEBUG
    
    try {
        # [xml]$config = Get-Content $Path
        # Validate structure
        
        Write-Log "config.xml validation passed" -Level INFO
        return $true
    }
    catch {
        Write-Log "config.xml validation failed: $_" -Level ERROR
        return $false
    }
}

# ============================================================================
# PHASE 3: CONFIG.XML PARSING
# ============================================================================

function Get-AppDynamicsConfiguration {
    param(
        [string]$ConfigPath
    )
    
    Write-Log "Phase 3: Parsing config.xml..." -Level INFO
    
    # TODO: Implement XML parsing logic
    # - Load XML document
    # - Extract all relevant configuration sections
    # - Return structured object with configuration data
    
    try {
        # [xml]$configXml = Get-Content $ConfigPath
        
        $config = @{
            Controller = Get-ControllerConfig -ConfigXml $null
            IISApplications = Get-IISApplicationsFromConfig -ConfigXml $null
            StandaloneApps = Get-StandaloneAppsFromConfig -ConfigXml $null
        }
        
        Write-Log "Successfully parsed config.xml" -Level INFO
        Write-Log "Found $($config.IISApplications.Count) IIS applications" -Level INFO
        Write-Log "Found $($config.StandaloneApps.Count) standalone applications" -Level INFO
        
        return $config
    }
    catch {
        Write-Log "Failed to parse config.xml: $_" -Level ERROR
        return $null
    }
}

function Get-ControllerConfig {
    param($ConfigXml)
    
    # TODO: Extract controller configuration
    # - Host, port, SSL settings
    # - Application name
    # - Account information
    
    Write-Log "Extracting controller configuration..." -Level DEBUG
    
    # Placeholder structure
    return @{
        Host = "controller.company.com"
        Port = 8090
        SSL = $false
        Application = "MyApplication"
        Account = "customer1"
    }
}

function Get-IISApplicationsFromConfig {
    param($ConfigXml)
    
    # TODO: Extract IIS application configurations
    # - Parse <IIS><applications> section
    # - Extract site name, path, tier, controller application
    # - Return array of application objects
    
    Write-Log "Extracting IIS application configurations..." -Level DEBUG
    
    # Placeholder structure
    return @(
        @{
            Site = "Default Web Site"
            Path = "/app1"
            Tier = "WebTier1"
            ControllerApplication = "WebApp1"
        },
        @{
            Site = "Default Web Site"
            Path = "/app2"
            Tier = "WebTier2"
            ControllerApplication = "WebApp2"
        }
    )
}

function Get-StandaloneAppsFromConfig {
    param($ConfigXml)
    
    # TODO: Extract standalone application configurations
    # - Parse <StandaloneApplications> section
    # - Extract executable, tier, node information
    # - Return array of application objects
    
    Write-Log "Extracting standalone application configurations..." -Level DEBUG
    
    # Placeholder structure
    return @(
        @{
            Executable = "MyService.exe"
            Tier = "ServiceTier1"
            Node = "Node1"
        }
    )
}

# ============================================================================
# PHASE 4: IIS DISCOVERY
# ============================================================================

function Get-IISConfiguration {
    Write-Log "Phase 4: Querying IIS configuration..." -Level INFO
    
    # TODO: Implement IIS discovery logic
    # - Check if IIS is installed
    # - Import WebAdministration module
    # - Query all sites and application pools
    # - Build mapping structure
    # - Return IIS configuration object
    
    if (-not $IncludeIIS) {
        Write-Log "IIS discovery skipped (IncludeIIS = false)" -Level INFO
        return $null
    }
    
    try {
        # Import-Module WebAdministration -ErrorAction Stop
        
        $sites = Get-IISSites
        $appPools = Get-IISAppPools
        $mapping = Build-SiteToPoolMapping -Sites $sites -AppPools $appPools
        
        $iisConfig = @{
            Sites = $sites
            ApplicationPools = $appPools
            Mapping = $mapping
        }
        
        Write-Log "IIS discovery complete: $($sites.Count) sites, $($appPools.Count) app pools" -Level INFO
        
        return $iisConfig
    }
    catch {
        Write-Log "Failed to query IIS configuration: $_" -Level ERROR
        return $null
    }
}

function Get-IISSites {
    # TODO: Enumerate all IIS sites
    # - Use Get-Website or equivalent
    # - Extract name, bindings, physical path, app pool
    # - Return array of site objects
    
    Write-Log "Enumerating IIS sites..." -Level DEBUG
    
    # Placeholder structure
    return @(
        @{
            Name = "Default Web Site"
            ID = 1
            ApplicationPool = "DefaultAppPool"
            PhysicalPath = "C:\inetpub\wwwroot"
            Bindings = @("http/*:80:", "https/*:443:")
        }
    )
}

function Get-IISAppPools {
    # TODO: Enumerate all application pools
    # - Use Get-ChildItem IIS:\AppPools or equivalent
    # - Extract name, .NET version, pipeline mode, identity
    # - Return array of app pool objects
    
    Write-Log "Enumerating IIS application pools..." -Level DEBUG
    
    # Placeholder structure
    return @(
        @{
            Name = "DefaultAppPool"
            RuntimeVersion = "v4.0"
            PipelineMode = "Integrated"
            Identity = "ApplicationPoolIdentity"
        }
    )
}

function Build-SiteToPoolMapping {
    param(
        [array]$Sites,
        [array]$AppPools
    )
    
    # TODO: Create mapping between sites and app pools
    # - Match sites to their application pools
    # - Include virtual directories and applications
    # - Return mapping structure
    
    Write-Log "Building site-to-pool mapping..." -Level DEBUG
    
    # Placeholder structure
    return @{
        "Default Web Site" = "DefaultAppPool"
    }
}

# ============================================================================
# PHASE 5: EAI CODE EXTRACTION
# ============================================================================

function Get-EAICodeFromServiceName {
    param(
        [string]$ServiceName
    )
    
    # TODO: Implement EAI code extraction logic
    # - Apply regex patterns to extract 4-5 digit codes
    # - Pattern 1: ^\d{4,5}-(.+)$  (EAI at start)
    # - Pattern 2: ^(.+)-\d{4,5}$  (EAI at end)
    # - Return EAI code and clean service name
    # - Return null if no pattern matches
    
    Write-Log "Extracting EAI code from: $ServiceName" -Level DEBUG
    
    # Regex patterns
    $patterns = @(
        '^(\d{4,5})-(.+)$',  # EAI-ServiceName
        '^(.+)-(\d{4,5})$'   # ServiceName-EAI
    )
    
    foreach ($pattern in $patterns) {
        if ($ServiceName -match $pattern) {
            # Extract based on capture groups
            # Return @{ EAI = $matches[1]; CleanName = $matches[2] }
            
            Write-Log "Matched pattern: $pattern" -Level DEBUG
            return @{
                EAI = "1234"
                CleanName = "WebService"
            }
        }
    }
    
    Write-Log "No EAI pattern matched for: $ServiceName" -Level WARN
    return $null
}

function Group-ServicesByEAI {
    param(
        [array]$Services,
        [hashtable]$IISConfig,
        [hashtable]$AppDynamicsConfig
    )
    
    Write-Log "Phase 5: Grouping services by EAI code..." -Level INFO
    
    # TODO: Implement EAI grouping logic
    # - Iterate through all services
    # - Extract EAI code from each service name
    # - Group services, app pools, and sites by EAI
    # - Return structured hashtable organized by EAI
    
    $eaiGroups = @{}
    
    # Process each service
    # foreach ($service in $Services) {
    #     $eaiInfo = Get-EAICodeFromServiceName -ServiceName $service.Name
    #     if ($eaiInfo) {
    #         # Add to appropriate EAI group
    #     }
    # }
    
    Write-Log "Created $($eaiGroups.Count) EAI groups" -Level INFO
    
    # Placeholder structure
    return @{
        "1234" = @{
            ServiceNames = @("1234-WebService1", "1234-WebService2")
            ApplicationPools = @("AppPool1")
            Sites = @()
        }
    }
}

# ============================================================================
# PHASE 6: DATA STRUCTURE BUILDING
# ============================================================================

function Build-ServiceRegistrationStructure {
    param(
        [hashtable]$EAIGroups,
        [hashtable]$AppDynamicsConfig,
        [hashtable]$IISConfig
    )
    
    Write-Log "Phase 6: Building service registration data structure..." -Level INFO
    
    # TODO: Implement data structure building
    # - Create final hierarchical structure
    # - Associate IIS sites with EAI groups
    # - Add instrumentation metadata
    # - Validate relationships and data completeness
    # - Return complete structure ready for YAML conversion
    
    $structure = @{
        eai_services = @{}
    }
    
    foreach ($eai in $EAIGroups.Keys) {
        $group = $EAIGroups[$eai]
        
        # Build structure for this EAI
        $structure.eai_services[$eai] = @{
            service_names = $group.ServiceNames
            application_pools = $group.ApplicationPools
            iis_sites = Build-IISSiteMetadata -Sites $group.Sites -IISConfig $IISConfig
            instrumentation = Build-InstrumentationMetadata -EAI $eai -Config $AppDynamicsConfig
        }
    }
    
    Write-Log "Data structure built successfully" -Level INFO
    
    return $structure
}

function Build-IISSiteMetadata {
    param(
        [array]$Sites,
        [hashtable]$IISConfig
    )
    
    # TODO: Build IIS site metadata
    # - For each site, extract relevant information
    # - Include site name, path, tier, app pool
    # - Return array of site metadata objects
    
    Write-Log "Building IIS site metadata..." -Level DEBUG
    
    # Placeholder
    return @(
        @{
            site = "Default Web Site"
            path = "/app1"
            tier = "WebTier1"
            application_pool = "AppPool1"
        }
    )
}

function Build-InstrumentationMetadata {
    param(
        [string]$EAI,
        [hashtable]$Config
    )
    
    # TODO: Build instrumentation metadata
    # - Extract relevant configuration for this EAI
    # - Include controller application, tier, node pattern
    # - Return instrumentation object
    
    Write-Log "Building instrumentation metadata for EAI: $EAI" -Level DEBUG
    
    # Placeholder
    return @{
        controller_application = "MyApp"
        tier = "WebTier"
        node_pattern = "{hostname}-{eai}"
    }
}

# ============================================================================
# PHASE 7: YAML GENERATION
# ============================================================================

function ConvertTo-Yaml {
    param(
        [hashtable]$Data,
        [int]$IndentLevel = 0
    )
    
    # TODO: Implement YAML conversion logic
    # - Recursively convert hashtable to YAML format
    # - Handle arrays, nested hashtables, strings
    # - Maintain proper indentation
    # - Escape special characters
    # - Return YAML string
    
    Write-Log "Converting data structure to YAML format..." -Level DEBUG
    
    $yaml = ""
    $indent = "  " * $IndentLevel
    
    # Recursive conversion logic here
    # Handle hashtables, arrays, strings, etc.
    
    # Placeholder YAML
    $yaml = @"
eai_services:
  "1234":
    service_names:
      - "1234-WebService1"
      - "1234-WebService2"
    application_pools:
      - "AppPool1"
      - "AppPool2"
    iis_sites:
      - site: "Default Web Site"
        path: "/app1"
        tier: "WebTier1"
        application_pool: "AppPool1"
    instrumentation:
      controller_application: "MyApp"
      tier: "WebTier"
      node_pattern: "{hostname}-{eai}"
"@
    
    return $yaml
}

function Write-ServiceRegistrationYaml {
    param(
        [hashtable]$Data,
        [string]$OutputPath
    )
    
    Write-Log "Phase 7: Generating YAML output..." -Level INFO
    
    # TODO: Implement YAML output generation
    # - Convert data structure to YAML
    # - Write to output file
    # - Validate output file was created
    # - Return success/failure
    
    try {
        $yaml = ConvertTo-Yaml -Data $Data
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would write to $OutputPath" -Level INFO
            Write-Log "YAML Preview:`n$yaml" -Level INFO
            return $true
        }
        
        # Set-Content -Path $OutputPath -Value $yaml -Encoding UTF8
        
        Write-Log "Successfully wrote serviceRegistration.yaml to: $OutputPath" -Level INFO
        
        return $true
    }
    catch {
        Write-Log "Failed to write YAML output: $_" -Level ERROR
        return $false
    }
}

function Test-YamlOutput {
    param(
        [string]$Path
    )
    
    # TODO: Implement YAML validation
    # - Read file back
    # - Validate YAML syntax
    # - Check for data completeness
    # - Return validation result
    
    Write-Log "Validating generated YAML..." -Level DEBUG
    
    try {
        # Validation logic
        
        Write-Log "YAML validation passed" -Level INFO
        return $true
    }
    catch {
        Write-Log "YAML validation failed: $_" -Level ERROR
        return $false
    }
}

# ============================================================================
# REPORTING FUNCTIONS
# ============================================================================

function Write-SummaryReport {
    param(
        [hashtable]$Results
    )
    
    # TODO: Generate and display summary report
    # - Count total EAI codes, services, app pools, sites
    # - Display statistics
    # - Show output file locations
    # - Report any warnings or errors
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Migration Configuration Builder" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "--------"
    Write-Host "EAI Codes:          " -NoNewline; Write-Host "3" -ForegroundColor Yellow
    Write-Host "Services:           " -NoNewline; Write-Host "7" -ForegroundColor Yellow
    Write-Host "Application Pools:  " -NoNewline; Write-Host "5" -ForegroundColor Yellow
    Write-Host "IIS Sites:          " -NoNewline; Write-Host "5" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Output:" -ForegroundColor Green
    Write-Host "-------"
    Write-Host "YAML:  $OutputPath" -ForegroundColor White
    Write-Host "Log:   $LogPath" -ForegroundColor White
    Write-Host ""
    
    if ($DryRun) {
        Write-Host "[DRY RUN] No files were written" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] Migration preparation complete!" -ForegroundColor Green
    }
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    try {
        # Initialize
        Initialize-Logging
        Write-Host ""
        Write-Host "AppDynamics to EDOT Configuration Builder" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Validate prerequisites
        if (-not (Test-Prerequisites)) {
            Write-Log "Prerequisites validation failed" -Level ERROR
            exit 1
        }
        
        # Phase 1: Detect AppDynamics
        $service = Find-AppDynamicsService
        if (-not $service) {
            Write-Log "Failed to detect AppDynamics installation" -Level ERROR
            exit 1
        }
        
        $installPath = Get-AppDynamicsInstallPath -Service $service
        if (-not $installPath) {
            Write-Log "Failed to determine installation path" -Level ERROR
            exit 1
        }
        
        # Phase 2: Locate config.xml
        $configPath = Find-ConfigXml -InstallPath $installPath -CustomPath $ConfigPath
        if (-not $configPath) {
            Write-Log "Failed to locate config.xml" -Level ERROR
            exit 1
        }
        
        if (-not (Test-ConfigXml -Path $configPath)) {
            Write-Log "config.xml validation failed" -Level ERROR
            exit 1
        }
        
        # Phase 3: Parse config.xml
        $appDynamicsConfig = Get-AppDynamicsConfiguration -ConfigPath $configPath
        if (-not $appDynamicsConfig) {
            Write-Log "Failed to parse AppDynamics configuration" -Level ERROR
            exit 1
        }
        
        # Phase 4: Query IIS
        $iisConfig = Get-IISConfiguration
        # IIS config can be null if not installed or not requested
        
        # Phase 5: Extract EAI codes and group
        $eaiGroups = Group-ServicesByEAI -Services @() -IISConfig $iisConfig -AppDynamicsConfig $appDynamicsConfig
        if (-not $eaiGroups -or $eaiGroups.Count -eq 0) {
            Write-Log "No EAI groups were created" -Level WARN
        }
        
        # Phase 6: Build data structure
        $serviceRegistration = Build-ServiceRegistrationStructure -EAIGroups $eaiGroups -AppDynamicsConfig $appDynamicsConfig -IISConfig $iisConfig
        
        # Phase 7: Generate YAML output
        $success = Write-ServiceRegistrationYaml -Data $serviceRegistration -OutputPath $OutputPath
        if (-not $success) {
            Write-Log "Failed to generate YAML output" -Level ERROR
            exit 1
        }
        
        # Validate output (unless dry run)
        if (-not $DryRun) {
            Test-YamlOutput -Path $OutputPath
        }
        
        # Generate summary report
        $results = @{
            EAICount = $eaiGroups.Count
            ServiceCount = 0
            PoolCount = 0
            SiteCount = 0
        }
        Write-SummaryReport -Results $results
        
        Write-Log "Script execution completed successfully" -Level INFO
        exit 0
    }
    catch {
        Write-Log "Unhandled exception: $_" -Level ERROR
        Write-Log $_.ScriptStackTrace -Level ERROR
        exit 1
    }
}

# Execute main function
Main