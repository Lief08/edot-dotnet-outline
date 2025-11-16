# AppDynamics to Elastic EDOT .NET Migration - Configuration Builder Script

## Project Overview
This project creates a PowerShell script to facilitate the migration from AppDynamics .NET agent to Elastic Distribution of OpenTelemetry (EDOT) .NET agent by:
1. Parsing existing AppDynamics configuration to identify instrumented IIS sites
2. Extracting EAI codes from AppDynamics application/tier names
3. Mapping IIS sites to their application pools
4. Generating a JSON service registry for EDOT zero-code instrumentation deployment

## Version History
- **v1.0** - 2025-11-16 02:17:06 UTC - Initial draft with YAML output
- **v2.0** - 2025-11-16 02:29:55 UTC - Updated to JSON output format
- **v3.0** - 2025-11-16 02:32:00 UTC - Requirements clarified with EAI structure, service definitions, and EDOT deployment approach

## Created By
Lief08

---

## REQUIREMENTS CLARIFIED ✅

### 1. EAI Code Structure ✅
**Definition**: Internal application inventory designation
- **Format**: 4 or 5 digit number
- **Location**: Prefixed to AppDynamics application name or OTEL service name
- **Delimiter**: Underscore `_` or hyphen `-`
- **Examples**: 
  - `1234-CustomerPortal`
  - `12345_PaymentAPI`
  - `9876-OrderService`
- **Entry Method**: Manually entered in every case
- **Purpose**: Track and identify applications in inventory system

### 2. Service Names (AppDynamics Tiers) ✅
**Definition**: AppDynamics tier name = EDOT/OTEL service name
- **Structure**: Logical layers of an application (e.g., web tier, API tier, database tier)
- **Relationship**: 
  - AppDynamics Tier → EDOT Service Name
  - AppDynamics Application → Application grouping
  - Tier is aligned to IIS site
  - Tier is affixed with AppDynamics application name
- **Analogy**:
  - **Containers**: Service = Image, Nodes = Replicas of that image
  - **IIS**: Service = Tier (logical layer), Nodes = Individual servers running that tier

### 3. JSON Output Purpose ✅
**Function**: Custom service registry/service map
- **Consumer**: Custom PowerShell script for EDOT deployment
- **Use Case**: Selective EDOT auto-instrumentation (NOT all pools at once)
- **Content**: Everything needed to:
  - Identify which IIS application pools to instrument
  - Configure naming for each pool
  - Apply appropriate EDOT settings per pool

### 4. EDOT Deployment Method ✅
**Approach**: Zero-code instrumentation in custom location
- **Global Configuration** (IIS service level in registry):
  - OTLP endpoint
  - Bearer token
  - Other shared settings
- **Per-Application Pool Configuration**:
  - Profiler enablement
  - Assembly loading
  - Service naming (from EAI + tier mapping)
  - Additional required properties
- **Isolation**: Registry-based configuration for isolation between pools

---

## Project Requirements

### Platform Requirements
- **Target OS**: Windows Server 2012 and newer
- **Script Language**: PowerShell (4.0+ minimum, 5.1+ recommended)
- **Output Format**: JSON (native PowerShell support)
- **Dependencies**: 
  - WebAdministration module (for IIS queries)
  - No external modules required
- **Permissions**: Administrator access required

### Functional Requirements

#### Phase 1: AppDynamics Service Detection
- Detect the AppDynamics Coordinator service
- Locate installation directory
- Validate installation

#### Phase 2: Configuration File Discovery
- Find `config.xml` at standard locations:
  - `%ProgramData%\AppDynamics\DotNetAgent\Config\config.xml` (primary)
  - `%AllUsersProfile%\Application Data\AppDynamics\DotNetAgent\Config\config.xml` (fallback)
- Validate XML structure

#### Phase 3: Configuration Data Extraction
Extract from AppDynamics config.xml:

**Critical Data**:
- **IIS Applications** (manual or automatic mode)
  - Site name
  - Application path
  - Tier name (this becomes EDOT service name)
  - Controller application name (contains EAI code prefix)
  
**Parse Structure**:
```xml
<application controller-application="1234-CustomerPortal" path="/api" site="Default Web Site">
  <tier name="API-Tier"/>
</application>
```

Extract:
- `controller-application` = "1234-CustomerPortal" → EAI = "1234", App = "CustomerPortal"
- `tier` = "API-Tier" → EDOT service name = "1234-API-Tier" or "1234_API-Tier"
- `site` + `path` → Map to IIS application pool

**Handle Both Modes**:
- **Automatic mode**: `<IIS><automatic /></IIS>` → Enumerate all IIS sites
- **Manual mode**: `<IIS><applications>...</applications></IIS>` → Parse listed applications

#### Phase 4: IIS Metadata Collection
Using WebAdministration module:

1. **For each IIS application in AppDynamics config**:
   ```powershell
   $site = Get-Website -Name $appDynamicsApp.Site
   $iisApp = Get-WebApplication -Site $appDynamicsApp.Site | 
             Where-Object { $_.Path -eq $appDynamicsApp.Path }
   $appPool = $iisApp.ApplicationPool
   ```

2. **Collect for each application pool**:
   - Application pool name
   - .NET CLR version
   - Pipeline mode (Integrated/Classic)
   - Identity
   - Physical path
   - Associated IIS site(s)

3. **Map**:
   ```
   AppDynamics Site + Path → IIS Application → Application Pool
   ```

#### Phase 5: EAI Code Extraction
**Algorithm**:
```powershell
function Get-EAICode {
    param([string]$AppDynamicsApplicationName)
    
    # Match 4-5 digit prefix with _ or - delimiter
    if ($AppDynamicsApplicationName -match '^(\d{4,5})[-_](.+)$') {
        return @{
            EAI = $Matches[1]
            AppName = $Matches[2]
        }
    }
    
    Write-Warning "No EAI code found in: $AppDynamicsApplicationName"
    return $null
}
```

**Build Service Name for EDOT**:
```powershell
# AppDynamics: controller-application="1234-CustomerPortal", tier="API-Tier"
# EDOT Service Name: "1234-API-Tier" or "1234_API-Tier"

$serviceName = "$($eaiCode)-$($tierName)"
```

#### Phase 6: JSON Service Registry Generation

**Structure**:
```json
{
  "service_registry": {
    "1234": {
      "application_name": "CustomerPortal",
      "eai_code": "1234",
      "appdynamics": {
        "controller_application": "1234-CustomerPortal",
        "controller_host": "appdcontroller.company.com",
        "controller_port": 8090,
        "ssl_enabled": false
      },
      "services": [
        {
          "service_name": "1234-API-Tier",
          "tier_name": "API-Tier",
          "iis_site": "Default Web Site",
          "application_path": "/api",
          "application_pool": "1234-CustomerPortal-API",
          "physical_path": "C:\\inetpub\\wwwroot\\api",
          "dotnet_version": "v4.0",
          "pipeline_mode": "Integrated",
          "edot_configuration": {
            "OTEL_SERVICE_NAME": "1234-API-Tier",
            "OTEL_RESOURCE_ATTRIBUTES": "deployment.environment=production,service.namespace=CustomerPortal,eai.code=1234",
            "profiler_enabled": true,
            "instrumentation_enabled": true
          }
        },
        {
          "service_name": "1234-Web-Tier",
          "tier_name": "Web-Tier",
          "iis_site": "CustomerPortal Site",
          "application_path": "/",
          "application_pool": "1234-CustomerPortal-Web",
          "physical_path": "C:\\inetpub\\CustomerPortal",
          "dotnet_version": "v4.0",
          "pipeline_mode": "Integrated",
          "edot_configuration": {
            "OTEL_SERVICE_NAME": "1234-Web-Tier",
            "OTEL_RESOURCE_ATTRIBUTES": "deployment.environment=production,service.namespace=CustomerPortal,eai.code=1234",
            "profiler_enabled": true,
            "instrumentation_enabled": true
          }
        }
      ]
    },
    "5678": {
      "application_name": "OrderService",
      "eai_code": "5678",
      "appdynamics": {
        "controller_application": "5678_OrderService",
        "controller_host": "appdcontroller.company.com",
        "controller_port": 8090,
        "ssl_enabled": false
      },
      "services": [
        {
          "service_name": "5678_OrderAPI",
          "tier_name": "OrderAPI",
          "iis_site": "Default Web Site",
          "application_path": "/orders",
          "application_pool": "OrderServicePool",
          "physical_path": "C:\\inetpub\\wwwroot\\orders",
          "dotnet_version": "v4.0",
          "pipeline_mode": "Integrated",
          "edot_configuration": {
            "OTEL_SERVICE_NAME": "5678_OrderAPI",
            "OTEL_RESOURCE_ATTRIBUTES": "deployment.environment=production,service.namespace=OrderService,eai.code=5678",
            "profiler_enabled": true,
            "instrumentation_enabled": true
          }
        }
      ]
    }
  },
  "metadata": {
    "generated_date": "2025-11-16T02:29:55Z",
    "script_version": "3.0",
    "server_hostname": "WEBSERVER01",
    "appdynamics_controller": "appdcontroller.company.com:8090",
    "config_source": "C:\\ProgramData\\AppDynamics\\DotNetAgent\\Config\\config.xml",
    "total_eai_codes": 2,
    "total_services": 3,
    "total_application_pools": 3
  }
}
```

**Key Design Decisions**:
1. **Group by EAI Code** - Primary organizational unit
2. **Services Array** - Each tier/service under its EAI
3. **Include Both AppD and EDOT Config** - For reference and migration
4. **Application Pool Mapping** - Direct mapping for instrumentation script
5. **EDOT Configuration Section** - Ready-to-apply settings

---

## EDOT Zero-Code Instrumentation Context

### Registry Configuration Levels

#### Global Level (IIS Service - All Pools)
```registry
HKLM\SYSTEM\CurrentControlSet\Services\W3SVC
- OTEL_EXPORTER_OTLP_ENDPOINT = "https://elastic-endpoint:443"
- OTEL_EXPORTER_OTLP_HEADERS = "Authorization=Bearer <token>"
- OTEL_DOTNET_AUTO_HOME = "C:\CustomPath\OpenTelemetry"
```

#### Application Pool Level (Per Pool)
```registry
HKLM\SYSTEM\CurrentControlSet\Services\WAS\Parameters\AppPoolEnvironmentVariables\[AppPoolName]
- COR_ENABLE_PROFILING = "1"
- COR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
- COR_PROFILER_PATH = "C:\CustomPath\OpenTelemetry\win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
- OTEL_SERVICE_NAME = "1234-API-Tier"
- OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=production,service.namespace=CustomerPortal,eai.code=1234"
- OTEL_DOTNET_AUTO_TRACES_INSTRUMENTATION_ENABLED = "true"
```

### Deployment Script Workflow

The JSON service registry enables:

1. **Selective Instrumentation**:
   ```powershell
   # Deploy EDOT to specific EAI codes or services
   .\Deploy-EDOTInstrumentation.ps1 -EAICode "1234" -ServiceRegistry "serviceRegistration.json"
   ```

2. **Per-Pool Configuration**:
   ```powershell
   # For each service in registry:
   # 1. Get application pool name
   # 2. Set registry keys for that pool
   # 3. Configure OTEL_SERVICE_NAME from service_name
   # 4. Set resource attributes
   # 5. Restart application pool
   ```

3. **Validation**:
   ```powershell
   # Verify instrumentation is working
   .\Test-EDOTInstrumentation.ps1 -ServiceRegistry "serviceRegistration.json"
   ```

---

## Technical Implementation Notes

### IIS to Application Pool Mapping

**Critical Function**:
```powershell
function Get-ApplicationPoolForSite {
    param(
        [string]$SiteName,
        [string]$ApplicationPath
    )
    
    Import-Module WebAdministration
    
    if ($ApplicationPath -eq "/" -or [string]::IsNullOrEmpty($ApplicationPath)) {
        # Root application uses site's default app pool
        $site = Get-Website -Name $SiteName
        return $site.ApplicationPool
    }
    else {
        # Virtual application has its own app pool
        $app = Get-WebApplication -Site $SiteName | 
               Where-Object { $_.Path -eq $ApplicationPath }
        
        if ($app) {
            return $app.ApplicationPool
        }
        else {
            Write-Warning "Application not found: $SiteName$ApplicationPath"
            return $null
        }
    }
}
```

### AppDynamics Configuration Modes

#### Manual Mode (Explicit)
```xml
<IIS>
  <applications>
    <application controller-application="1234-CustomerPortal" path="/api" site="Default Web Site">
      <tier name="API-Tier"/>
    </application>
  </applications>
</IIS>
```
**Handling**: Parse each `<application>` element directly.

#### Automatic Mode (All Sites)
```xml
<IIS>
  <automatic />
</IIS>
```
**Handling**: 
1. Detect automatic mode
2. Enumerate all IIS sites: `Get-ChildItem IIS:\Sites`
3. For each site, check if it matches AppDynamics naming pattern (has EAI code)
4. Extract EAI from site name or prompt for mapping
5. Log warning: "Automatic mode detected - EAI mapping may require manual verification"

**Challenge**: In automatic mode, tier names are auto-generated by AppDynamics.
**Solution**: 
- Use site name as tier name
- Or use site name + application path
- Or prompt for tier name during discovery

---

## Example Mapping Flow

### Given AppDynamics Config:
```xml
<application controller-application="1234-CustomerPortal" path="/api" site="Default Web Site">
  <tier name="API-Tier"/>
</application>
```

### Processing Steps:
```
1. Extract EAI Code:
   - Input: "1234-CustomerPortal"
   - Regex: ^(\d{4,5})[-_](.+)$
   - Output: EAI = "1234", App = "CustomerPortal"

2. Get Tier Name:
   - Input: <tier name="API-Tier"/>
   - Output: "API-Tier"

3. Build Service Name:
   - Format: {EAI}{delimiter}{TierName}
   - Output: "1234-API-Tier"

4. Query IIS:
   - Site: "Default Web Site"
   - Path: "/api"
   - Query: Get-WebApplication -Site "Default Web Site" | Where { $_.Path -eq "/api" }
   - Result: ApplicationPool = "1234-CustomerPortal-API"

5. Build JSON Entry:
   {
     "service_name": "1234-API-Tier",
     "tier_name": "API-Tier",
     "iis_site": "Default Web Site",
     "application_path": "/api",
     "application_pool": "1234-CustomerPortal-API",
     "edot_configuration": {
       "OTEL_SERVICE_NAME": "1234-API-Tier",
       ...
     }
   }
```

---

## Script Deliverables

### 1. Main Script: `Build-EDOTServiceRegistry.ps1`
**Purpose**: Generate JSON service registry from AppDynamics config

**Parameters**:
```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,  # Override config.xml location
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\serviceRegistry.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('-', '_')]
    [string]$EAIDelimiter = '-',  # Delimiter for service names
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = 'production',  # For OTEL_RESOURCE_ATTRIBUTES
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeStandaloneApps,  # Include Windows services
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
    [string]$LogLevel = 'INFO',
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\Build-EDOTServiceRegistry.log"
)
```

### 2. Deployment Script: `Deploy-EDOTInstrumentation.ps1` (Future)
**Purpose**: Apply EDOT configuration from service registry

**Parameters**:
```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceRegistryPath,
    
    [Parameter(Mandatory=$false)]
    [string[]]$EAICodes,  # Deploy specific EAI codes only
    
    [Parameter(Mandatory=$false)]
    [string[]]$ServiceNames,  # Deploy specific services only
    
    [Parameter(Mandatory=$true)]
    [string]$OTLPEndpoint,
    
    [Parameter(Mandatory=$true)]
    [string]$BearerToken,
    
    [Parameter(Mandatory=$false)]
    [string]$CustomInstrumentationPath = "C:\CustomPath\OpenTelemetry"
)
```

### 3. Output: `serviceRegistry.json`
- Structured JSON as defined above
- Grouped by EAI code
- Complete IIS → App Pool mapping
- EDOT configuration ready for deployment

---

## Success Criteria

✅ **Script Functions**:
- Detects AppDynamics installation reliably
- Parses config.xml for both automatic and manual modes
- Extracts EAI codes from controller-application names (4-5 digits with - or _ delimiter)
- Maps AppDynamics tiers to EDOT service names
- Queries IIS to find application pools for each site/application
- Generates valid JSON service registry
- Handles missing or malformed data gracefully

✅ **JSON Output**:
- Groups services by EAI code
- Includes all data needed for EDOT deployment script
- Contains application pool names for registry configuration
- Provides suggested OTEL_SERVICE_NAME values
- Includes resource attributes template

✅ **Performance**:
- Executes in under 60 seconds for typical server configuration
- Works on Windows Server 2012+
- No external dependencies

✅ **Usability**:
- Clear error messages
- Detailed logging
- Dry-run mode for testing
- Configurable delimiters and environment tags

---

## Next Steps

1. ✅ Requirements fully clarified
2. ⏳ Update script implementation with clarified logic
3. ⏳ Create example/test config.xml for validation
4. ⏳ Build `Deploy-EDOTInstrumentation.ps1` companion script
5. ⏳ Test on sample Windows Server 2012 environment
6. ⏳ Document deployment workflow

---

## Open Questions (Minor)

1. **Delimiter Preference**: Should the script use `-` or `_` for service names, or detect from AppDynamics config?
   - **Recommendation**: Make it a parameter, default to match what's in controller-application name

2. **Automatic Mode Tier Naming**: If AppDynamics is in automatic mode, how should tier names be determined?
   - **Recommendation**: Use IIS site name as tier name, or provide a mapping file

3. **Standalone Applications**: Should Windows services (StandaloneApplications) be included?
   - **Recommendation**: Make it optional via switch parameter

4. **Multiple Applications per Pool**: Can one application pool host multiple applications with different EAI codes?
   - **Assumption**: Each app pool maps to one EAI code
   - **Validation**: Script should warn if conflicting EAI codes detected

Would you like me to proceed with updating the script implementation based on these clarified requirements?