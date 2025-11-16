# AppDynamics to Elastic EDOT .NET Migration - Configuration Builder Script

## Project Overview
This project creates a PowerShell script to facilitate the migration from AppDynamics .NET agent to Elastic Distribution of OpenTelemetry (EDOT) .NET agent by parsing existing AppDynamics configuration and generating a structured JSON configuration file for EDOT deployment.

## Version History
- **v1.0** - 2025-11-15 22:48:06 UTC - Initial draft with YAML output
- **v2.0** - 2025-11-16 02:17:06 UTC - Updated to JSON output format

## Created By
Lief08

## Project Requirements

### Platform Requirements
- **Target OS**: Windows Server 2012 and newer
- **Script Language**: PowerShell (4.0+ minimum, 5.1+ recommended)
- **Output Format**: **JSON** (native PowerShell support, no external dependencies)
- **Dependencies**: 
  - WebAdministration module (for IIS queries)
  - No Python required
  - No external modules required
- **Permissions**: Administrator access required for service and IIS queries

### Functional Requirements

#### Phase 1: AppDynamics Service Detection
- Detect the AppDynamics Coordinator service on the system
  - Service Name Pattern: `*AppDynamics.Agent.Coordinator*`
  - Alternative service names may exist
- Locate the installation directory from the service executable path
- Validate the installation by confirming required files exist

#### Phase 2: Configuration File Discovery
- Based on service location, find the `config.xml` file
- Standard location: `%ProgramData%\AppDynamics\DotNetAgent\Config\config.xml`
- Fallback locations for older versions: `%AllUsersProfile%\Application Data\AppDynamics\DotNetAgent\Config`
- Validate XML structure and parse configuration data

#### Phase 3: Configuration Data Extraction
Extract from AppDynamics config.xml:
- Controller connection details (host, port, SSL settings)
- Application names and configurations
- **Handle both automatic and manual IIS configuration modes**
  - Automatic mode: `<IIS><automatic /></IIS>`
  - Manual mode: `<IIS><applications>...</applications></IIS>`
- IIS applications and sites being monitored (if manual mode)
- Tier names and node configurations
- Standalone applications (Windows services, not IIS apps)
- Custom instrumentation settings

#### Phase 4: IIS Metadata Collection
- **Use WebAdministration module** (compatible with Windows Server 2012)
- Enumerate all IIS sites and their application pools using:
  - `Get-ChildItem IIS:\Sites`
  - `Get-ChildItem IIS:\AppPools`
  - `Get-Website`
  - `Get-WebApplication`
- Map instrumented applications to their application pools
- Collect application pool identity and runtime version
- Associate sites with service names based on EAI code extraction

#### Phase 5: EAI Code Association
- **[REQUIRES CLARIFICATION]** Parse service/pool/site names to extract EAI codes
- **[REQUIRES CLARIFICATION]** Determine EAI code location and format
- Group services by EAI code
- Associate application pools with their respective EAI codes

#### Phase 6: JSON Configuration Generation
Generate `serviceRegistration.json` with structure:
```json
{
  "eai_services": {
    "[EAI-CODE]": {
      "service_names": ["ServiceName1", "ServiceName2"],
      "application_pools": ["AppPool1", "AppPool2"],
      "iis_sites": [
        {
          "site": "Default Web Site",
          "path": "/app1",
          "tier": "WebTier1",
          "application_pool": "AppPool1"
        }
      ],
      "instrumentation": {
        "controller_application": "AppName",
        "tier": "TierName",
        "node_pattern": "{tier}-{hostname}"
      },
      "edot_configuration": {
        "otel_service_name": "AppName",
        "otel_resource_attributes": "deployment.environment=production,service.namespace=eai-[EAI-CODE]"
      }
    }
  },
  "metadata": {
    "generated_date": "2025-11-16T02:17:06Z",
    "appdynamics_controller": "controller.company.com:8090",
    "source_config": "C:\\ProgramData\\AppDynamics\\DotNetAgent\\Config\\config.xml"
  }
}
```

## AppDynamics Configuration Details

### Service Information
- **Primary Service**: `AppDynamics.Agent.Coordinator`
- **Extension Service** (if present): `AppDynamics.Agent.Extension`

### Config.xml Location
- **Windows 2008+**: `%ProgramData%\AppDynamics\DotNetAgent\Config\config.xml`
- **Windows 2003**: `%AllUsersProfile%\Application Data\AppDynamics\DotNetAgent\Config\config.xml`

### Config.xml Structure - Manual Mode
```xml
<?xml version="1.0" encoding="utf-8"?>
<appdynamics-agent xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <controller host="controller.company.com" port="8090" ssl="false">
    <application name="MyApp"/>
    <account name="customer1" password="secret"/>
  </controller>
  <machine-agent/>
  <app-agents>
    <IIS>
      <applications>
        <application controller-application="WebApp1" path="/site1" site="Default Web Site">
          <tier name="WebTier1"/>
        </application>
      </applications>
    </IIS>
    <StandaloneApplications>
      <StandaloneApplication executable="Service.exe" tier="ServiceTier" node="Node1"/>
    </StandaloneApplications>
  </app-agents>
</appdynamics-agent>
```

### Config.xml Structure - Automatic Mode
```xml
<?xml version="1.0" encoding="utf-8"?>
<appdynamics-agent xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <controller host="controller.company.com" port="8090" ssl="false">
    <application name="MyApp"/>
    <account name="customer1" password="secret"/>
  </controller>
  <machine-agent/>
  <app-agents>
    <IIS>
      <automatic />  <!-- All IIS sites auto-instrumented -->
    </IIS>
  </app-agents>
</appdynamics-agent>
```

**Note**: In automatic mode, the script must enumerate IIS sites directly rather than relying on config.xml listings.

## Elastic EDOT .NET Target Configuration

### Target Format
The generated JSON will be used to:
- **[REQUIRES CLARIFICATION]** Document the current AppDynamics configuration
- **[REQUIRES CLARIFICATION]** Provide input for EDOT configuration generation
- **[REQUIRES CLARIFICATION]** Feed into deployment automation tools

### EDOT Configuration Context
- Uses OpenTelemetry standards
- Requires service name and resource attributes
- Application pool mapping for IIS auto-instrumentation
- Supports distributed tracing and metrics collection
- Configuration via:
  - Code-based setup (ASP.NET Core)
  - Environment variables (IIS app pool level)
  - web.config modifications (.NET Framework)
  - Zero-code instrumentation PowerShell module

## Script Deliverables

1. **Main Script**: `Build-EDOTServiceRegistration.ps1`
   - Modular function-based design
   - Error handling and logging
   - Validation at each phase
   - Dry-run capability for testing
   - **JSON output** (no external dependencies)

2. **Output File**: `serviceRegistration.json`
   - Structured JSON format
   - EAI code-based organization
   - Complete metadata for migration
   - Native PowerShell parsing capability

3. **Log File**: `Build-EDOTServiceRegistration.log`
   - Detailed execution log
   - Warnings and errors
   - Discovery results

## Technical Requirements - Corrections Applied

### IIS Module Usage
- **Use WebAdministration module** (Windows Server 2012 compatible)
- **DO NOT use IISAdministration module** (requires Server 2016+)

### Correct PowerShell Cmdlets
```powershell
# Correct for Windows Server 2012:
Import-Module WebAdministration
Get-ChildItem IIS:\Sites
Get-ChildItem IIS:\AppPools
Get-Website -Name "Default Web Site"
Get-WebApplication -Site "Default Web Site"

# INCORRECT (Server 2016+ only):
Get-IISSite     # ❌ Not available on Server 2012
Get-IISAppPool  # ❌ Not available on Server 2012
```

### JSON Output Implementation
```powershell
# Use native ConvertTo-Json with sufficient depth
$json = $data | ConvertTo-Json -Depth 10
Set-Content -Path "serviceRegistration.json" -Value $json -Encoding UTF8
```

## Known Challenges & Open Questions

### Critical Clarifications Needed

1. **EAI Code Structure** (CRITICAL)
   - Where are EAI codes actually stored in your environment?
   - What is the format? (4 digits? 5 digits? alphanumeric?)
   - Are they in:
     - Application pool names? (e.g., `1234-AppPool`)
     - IIS site names? (e.g., `1234-MySite`)
     - AppDynamics tier names?
     - A separate configuration file?
     - IIS application physical path?
   - Provide 3-5 real examples (sanitized)

2. **Service Names vs Application Pools** (CRITICAL)
   - What are "service names" in your context?
   - Are these:
     - Windows service names (background services)?
     - AppDynamics service/application names?
     - IIS site names?
     - Logical business service names?
   - How do they relate to IIS application pools?

3. **JSON Output Purpose** (HIGH)
   - What tool/process will consume this JSON?
   - Is it for:
     - Manual reference during migration?
     - Input to another script?
     - Configuration management tool (Ansible, etc.)?
     - EDOT configuration generator?
     - Documentation/audit purposes?

4. **EDOT Deployment Approach** (HIGH)
   - How will you actually deploy EDOT .NET?
   - Options:
     - Zero-code instrumentation (PowerShell module)
     - Code-based (modify application code)
     - Environment variables only
     - web.config modifications
   - Do you need the JSON to generate these configurations?

5. **AppDynamics Configuration Mode** (MEDIUM)
   - Do your servers use automatic or manual IIS configuration?
   - If automatic, how should we determine EAI codes?

6. **Standalone Applications** (MEDIUM)
   - Are standalone applications (Windows services) in scope?
   - Should they be included in the output?
   - Do they have EAI codes associated with them?

## Migration Context

### Current State (AppDynamics)
- Proprietary agent and configuration
- XML-based configuration
- Controller-centric architecture
- Automatic or manual IIS instrumentation via Coordinator service

### Target State (EDOT .NET)
- OpenTelemetry-based agent
- Configuration via code, environment variables, or web.config
- OTLP endpoint for data export
- Manual or code-based service registration

### Migration Gap
The JSON output must bridge:
- AppDynamics' centralized config.xml → EDOT's distributed configuration
- AppDynamics' service discovery → EDOT's explicit service naming
- AppDynamics' tier/node concepts → OpenTelemetry's resource attributes

## References

### AppDynamics Documentation
- [.NET Agent Directory Structure](https://help.splunk.com/en/appdynamics-saas/application-performance-monitoring/25.4.0/install-app-server-agents/.net-agent/administer-the-.net-agent/.net-agent-directory-structure)
- [Configure Agent Properties](https://help.splunk.com/en/appdynamics-saas/application-performance-monitoring/25.4.0/install-app-server-agents/.net-agent/administer-the-.net-agent/configure-agent-properties)
- [Name .NET Tiers](https://help.splunk.com/en/appdynamics-on-premises/application-performance-monitoring/25.8.0/install-app-server-agents/.net-agent/install-the-.net-agent-for-windows/name-.net-tiers)
- [Automatic vs Manual Configuration](https://help.splunk.com/en/appdynamics-saas/application-performance-monitoring/25.8.0/install-app-server-agents/.net-agent/administer-the-.net-agent/example-minimal-config.xml)

### Elastic EDOT Documentation
- [EDOT .NET Setup Guide](https://www.elastic.co/docs/reference/opentelemetry/edot-sdks/dotnet/setup)
- [EDOT .NET Release Notes](https://www.elastic.co/docs/release-notes/edot/sdks/dotnet)
- [IIS Instrumentation](https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/blob/main/docs/iis-instrumentation.md)
- [GitHub Repository](https://github.com/elastic/elastic-otel-dotnet)

### PowerShell Documentation
- [WebAdministration Module](https://learn.microsoft.com/en-us/powershell/module/webadministration/)
- [ConvertTo-Json](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-json)

## Success Criteria

- Script successfully detects AppDynamics installation in 100% of standard deployments
- Parses config.xml without errors for well-formed configurations
- Handles both automatic and manual IIS configuration modes
- Generates valid JSON output that matches expected structure
- Maintains EAI code associations accurately (once format is clarified)
- Provides clear error messages for troubleshooting
- Executes in under 60 seconds for typical configurations
- Works on Windows Server 2012 without external dependencies
- Uses only WebAdministration module for IIS queries

## Next Steps

1. ✅ Update requirements to use JSON instead of YAML
2. ⏳ Clarify critical questions about EAI codes and service names
3. ⏳ Obtain sample config.xml from actual environment
4. ⏳ Define JSON output consumer and purpose
5. ⏳ Implement corrected script with WebAdministration cmdlets
6. ⏳ Test on Windows Server 2012 environment
7. ⏳ Validate with real AppDynamics configurations