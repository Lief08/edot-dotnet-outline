# PowerShell Script Process Outline
## Build-EDOTServiceRegistration.ps1

## Overview
This document outlines the logical flow and process steps for building the EDOT service registration configuration from existing AppDynamics installation.

---

## Process Flow Diagram

```
┌─────────────────────────────────────┐
│  Start Script Execution             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Initialize Script Environment      │
│  - Set error handling               │
│  - Initialize logging               │
│  - Validate prerequisites           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 1: Detect AppDynamics        │
│  - Query Windows Services           │
│  - Locate Coordinator Service       │
│  - Extract installation path        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 2: Locate config.xml         │
│  - Check standard locations         │
│  - Validate file existence          │
│  - Test XML readability             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 3: Parse config.xml          │
│  - Load XML document                │
│  - Extract IIS applications         │
│  - Extract standalone apps          │
│  - Extract controller settings      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 4: Query IIS Configuration   │
│  - Enumerate IIS sites              │
│  - Enumerate application pools      │
│  - Map sites to app pools           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 5: Extract EAI Codes         │
│  - Parse service names              │
│  - Extract 4-5 digit prefixes       │
│  - Group by EAI code                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 6: Build Data Structure      │
│  - Create EAI-based hierarchy       │
│  - Associate services with pools    │
│  - Organize IIS site metadata       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 7: Generate YAML Output      │
│  - Convert data to YAML format      │
│  - Write to serviceRegistration.yaml│
│  - Validate output format           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Finalize and Report                │
│  - Generate summary report          │
│  - Close log file                   │
│  - Display results to user          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  End Script Execution               │
└─────────────────────────────────────┘
```

---

## Detailed Process Steps

### Phase 1: Detect AppDynamics Installation

#### Step 1.1: Query Windows Services
```powershell
# Query for AppDynamics Coordinator service
# Look for service name pattern: "AppDynamics.Agent.Coordinator*"
# Extract service properties including path to executable
```

**Expected Output:**
- Service name
- Service display name
- Service executable path
- Service status

**Error Handling:**
- Service not found → Exit with error message
- Multiple services found → Log warning, use first match
- Service path not accessible → Exit with error

#### Step 1.2: Extract Installation Directory
```powershell
# Parse service executable path
# Navigate to parent directory (installation root)
# Validate directory contains expected AppDynamics files
```

**Validation Checks:**
- Directory exists
- Contains AppDynamics binaries
- Contains Config subfolder

---

### Phase 2: Locate config.xml

#### Step 2.1: Check Standard Locations
```powershell
# Priority 1: %ProgramData%\AppDynamics\DotNetAgent\Config\config.xml
# Priority 2: Service path-relative location
# Priority 3: %AllUsersProfile%\Application Data\AppDynamics\DotNetAgent\Config\config.xml
```

**Validation:**
- File exists and is readable
- File is valid XML
- File contains expected root element `<appdynamics-agent>`

#### Step 2.2: Load and Validate XML
```powershell
# Load XML content
# Validate XML schema
# Check for required elements
```

---

### Phase 3: Parse config.xml

#### Step 3.1: Extract IIS Applications
```xml
<!-- Target structure -->
<IIS>
  <applications>
    <application controller-application="WebApp" path="/app" site="Default Web Site">
      <tier name="WebTier"/>
    </application>
  </applications>
</IIS>
```

**Data to Extract:**
- Controller application name
- Site name
- Application path
- Tier name

#### Step 3.2: Extract Standalone Applications
```xml
<!-- Target structure -->
<StandaloneApplications>
  <StandaloneApplication executable="Service.exe" tier="ServiceTier" node="Node1"/>
</StandaloneApplications>
```

**Data to Extract:**
- Executable name
- Tier name
- Node name

#### Step 3.3: Extract Controller Settings
```xml
<!-- Target structure -->
<controller host="controller.company.com" port="8090" ssl="false">
  <application name="MyApp"/>
  <account name="customer1"/>
</controller>
```

**Data to Extract:**
- Controller host
- Controller port
- SSL enabled/disabled
- Application name
- Account name

---

### Phase 4: Query IIS Configuration

#### Step 4.1: Enumerate IIS Sites
```powershell
# Use WebAdministration module
# Get all IIS sites
# Extract site name, bindings, physical path
```

**Required Data:**
- Site name
- Site ID
- Application pool name
- Physical path
- Bindings (protocol, port, hostname)

#### Step 4.2: Enumerate Application Pools
```powershell
# Get all application pools
# Extract pool name, .NET version, identity
```

**Required Data:**
- Application pool name
- .NET CLR version
- Managed pipeline mode
- Identity type
- Runtime version

#### Step 4.3: Map Sites to Application Pools
```powershell
# Create mapping between:
# IIS Site → Application Pool → Instrumented Service
```

**Mapping Logic:**
- Match site name from config.xml to IIS site
- Retrieve associated application pool
- Associate with EAI code from service naming

---

### Phase 5: Extract EAI Codes

#### Step 5.1: Parse Service Names
```powershell
# Expected patterns:
# - [4-digit]-ServiceName (e.g., "1234-WebService")
# - [5-digit]-ServiceName (e.g., "12345-ApiService")
# - ServiceName-[4-digit] (alternative format)
```

**Regex Patterns:**
```powershell
# Pattern 1: EAI at start
^\d{4,5}-(.+)$

# Pattern 2: EAI at end
^(.+)-\d{4,5}$

# Extract EAI code and clean service name
```

#### Step 5.2: Group Services by EAI Code
```powershell
# Create hashtable/dictionary:
# Key: EAI Code
# Value: Array of associated services, pools, sites
```

---

### Phase 6: Build Data Structure

#### Step 6.1: Create Hierarchical Structure
```powershell
# Structure:
@{
    eai_services = @{
        "1234" = @{
            service_names = @("Service1", "Service2")
            application_pools = @("AppPool1", "AppPool2")
            iis_sites = @(
                @{
                    site = "Default Web Site"
                    path = "/app1"
                    tier = "WebTier1"
                    application_pool = "AppPool1"
                }
            )
            instrumentation = @{
                controller_application = "MyApp"
                tier = "TierName"
                node_pattern = "NodeName-{hostname}"
            }
        }
    }
}
```

#### Step 6.2: Validate Data Relationships
```powershell
# Ensure:
# - No orphaned services
# - All app pools have associated sites
# - EAI codes are valid
# - No duplicate entries
```

---

### Phase 7: Generate YAML Output

#### Step 7.1: Convert to YAML Format
```powershell
# Use ConvertTo-Yaml or manual formatting
# Maintain proper indentation
# Handle special characters
# Preserve structure
```

**Output Format:**
```yaml
eai_services:
  "1234":
    service_names:
      - "WebService1"
      - "WebService2"
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
      node_pattern: "Node-{hostname}"
```

#### Step 7.2: Write Output File
```powershell
# Write to: serviceRegistration.yaml
# Location: Script directory or specified output path
# Encoding: UTF8
# Line endings: CRLF or LF based on parameter
```

#### Step 7.3: Validate Output
```powershell
# Read back generated file
# Validate YAML structure
# Verify all data was written
# Check file permissions
```

---

## Error Handling Strategy

### Global Error Handler
- Catch all unhandled exceptions
- Log to file with stack trace
- Display user-friendly message
- Exit with appropriate error code

### Phase-Specific Error Handling

| Phase | Potential Errors | Handling Strategy |
|-------|-----------------|-------------------|
| Phase 1 | Service not found | Exit with clear error message |
| Phase 1 | Multiple services | Warn and use first match |
| Phase 2 | config.xml not found | Check fallback locations |
| Phase 2 | Invalid XML | Log error details and exit |
| Phase 3 | Missing XML elements | Use default values where safe |
| Phase 4 | IIS not installed | Skip IIS enumeration, warn user |
| Phase 4 | Access denied | Request admin rights |
| Phase 5 | EAI pattern not matched | Use full service name, log warning |
| Phase 6 | Data inconsistencies | Log warnings, continue |
| Phase 7 | Cannot write file | Check permissions, retry alternate path |

---

## Logging Strategy

### Log Levels
- **INFO**: Normal progress messages
- **WARN**: Non-critical issues that don't stop execution
- **ERROR**: Critical issues that stop execution
- **DEBUG**: Detailed diagnostic information (optional)

### Log Format
```
[2025-11-15 22:48:06] [INFO] Starting AppDynamics detection...
[2025-11-15 22:48:07] [INFO] Found service: AppDynamics.Agent.Coordinator
[2025-11-15 22:48:08] [WARN] Multiple config.xml files found, using first: C:\ProgramData\...
[2025-11-15 22:48:09] [INFO] Parsed 5 IIS applications from config.xml
```

---

## Validation Checkpoints

### Pre-Execution Validation
- [ ] PowerShell version 5.1 or higher
- [ ] Running with Administrator privileges
- [ ] WebAdministration module available (if IIS check required)
- [ ] Output directory is writable

### Post-Phase Validation
- [ ] Phase 1: AppDynamics service found and validated
- [ ] Phase 2: config.xml located and readable
- [ ] Phase 3: Valid data extracted from config.xml
- [ ] Phase 4: IIS configuration retrieved (if applicable)
- [ ] Phase 5: EAI codes extracted successfully
- [ ] Phase 6: Data structure is complete and valid
- [ ] Phase 7: YAML file generated and validated

---

## Performance Considerations

### Expected Performance Targets
- Total execution time: < 60 seconds for typical environment
- XML parsing: < 5 seconds
- IIS enumeration: < 10 seconds
- YAML generation: < 5 seconds

### Optimization Strategies
- Use efficient XML parsing (XPath queries)
- Cache IIS queries results
- Minimize WMI calls
- Use pipeline processing where possible
- Avoid unnecessary loops

---

## Output Artifacts

### Primary Output
**File:** `serviceRegistration.yaml`
- Contains all extracted and mapped configuration
- Ready for EDOT configuration integration

### Secondary Output
**File:** `Build-EDOTServiceRegistration.log`
- Detailed execution log
- Warnings and errors
- Discovery statistics

### Console Output
```
AppDynamics to EDOT Configuration Builder
==========================================

[✓] AppDynamics service detected
[✓] config.xml located and parsed
[✓] Found 5 IIS applications
[✓] Extracted 3 unique EAI codes
[✓] Generated serviceRegistration.yaml

Summary:
--------
EAI Codes: 3
Services: 7
Application Pools: 5
IIS Sites: 5

Output: C:\Temp\serviceRegistration.yaml
Log: C:\Temp\Build-EDOTServiceRegistration.log

Migration preparation complete!
```

---

## Testing Strategy

### Unit Testing Scenarios
1. AppDynamics service detection with various service names
2. XML parsing with different config.xml structures
3. EAI code extraction with various naming patterns
4. YAML generation with edge cases

### Integration Testing Scenarios
1. End-to-end execution on test server
2. Execution on server without AppDynamics (error handling)
3. Execution on server with multiple IIS sites
4. Execution with malformed config.xml

### Validation Testing
1. Compare generated YAML with expected output
2. Validate YAML syntax
3. Verify all discovered services are included
4. Confirm EAI code accuracy

---

## Script Parameters (Recommended)

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,  # Override config.xml location
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\serviceRegistration.yaml",  # Output file path
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeIIS = $true,  # Include IIS discovery
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,  # Test mode - don't write output
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
    [string]$LogLevel = 'INFO',  # Logging verbosity
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\Build-EDOTServiceRegistration.log"  # Log file path
)
```

---

## Next Steps

1. Implement each phase as a separate function
2. Create helper functions for common operations
3. Add comprehensive error handling
4. Implement logging infrastructure
5. Test on sample environments
6. Refine and optimize based on testing results
7. Add parameter validation and help documentation