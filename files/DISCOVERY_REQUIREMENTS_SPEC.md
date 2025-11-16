# Server Discovery Requirements Specification
## AppDynamics to EDOT .NET Migration - Discovery Phase

**Version**: 1.0  
**Date**: 2025-11-16 02:39:44 UTC  
**Owner**: Lief08  
**Purpose**: Comprehensive server assessment for EDOT migration at scale

---

## 🎯 DISCOVERY OBJECTIVES

### Primary Goals
1. **Assess 300-400 Windows Servers** for migration readiness
2. **Discover all IIS applications** and application pools
3. **Identify AppDynamics configuration** and instrumentation
4. **Map EAI codes** to application pools
5. **Detect configuration locations** (shared, custom, default)
6. **Generate actionable data** for service registry creation

### Success Criteria
- ✅ Successfully discovers 95%+ of servers without manual intervention
- ✅ Identifies all IIS application pools and their active configurations
- ✅ Correctly maps AppDynamics config to IIS applications
- ✅ Handles Windows Server 2012-2022 without modification
- ✅ Completes single server discovery in < 2 minutes
- ✅ Generates valid, parseable JSON output
- ✅ Flags edge cases and conflicts for manual review

---

## 📋 DISCOVERY SCOPE

### In Scope
✅ Windows OS and PowerShell version detection  
✅ IIS installation and configuration mode detection  
✅ AppDynamics service and config.xml location discovery  
✅ IIS sites, applications, and application pools enumeration  
✅ Application pool active configuration location detection  
✅ AppDynamics configuration parsing (manual and automatic modes)  
✅ EAI code extraction from AppDynamics application names  
✅ Existing instrumentation detection (AppDynamics profiler settings)  
✅ Multi-EAI server scenario identification  
✅ Configuration conflict detection  

### Out of Scope
❌ Actual EDOT deployment or configuration  
❌ AppDynamics agent uninstallation  
❌ IIS application pool modification  
❌ Network connectivity testing to OTLP endpoints  
❌ Application code analysis  
❌ Performance testing or monitoring  

---

## 🔍 DETECTION SCENARIOS

### Scenario 1: Standard Single-EAI Server
**Description**: Server running one application (one EAI code) with one or more application pools

**Characteristics**:
- AppDynamics installed in default location
- IIS using default configuration location
- All application pools belong to same EAI code
- AppDynamics in manual configuration mode

**Expected Discovery**:
- AppDynamics config.xml location
- Single EAI code extracted
- N application pools mapped to that EAI
- Clear service registry generation path

---

### Scenario 2: Multi-EAI Shared Server
**Description**: Server hosting multiple applications with different EAI codes

**Characteristics**:
- AppDynamics installed in default location
- IIS using default configuration location
- Application pools tagged with different EAI codes (e.g., "1234-AppPool", "5678-AppPool")
- AppDynamics in manual configuration mode with multiple controller-application entries

**Expected Discovery**:
- Multiple EAI codes extracted
- Application pools grouped by EAI code
- Potential configuration conflicts flagged
- Service registry with multiple EAI groups

---

### Scenario 3: IIS Shared Configuration
**Description**: Server using IIS shared configuration from network location

**Characteristics**:
- IIS configuration stored on file share (\\server\share\config)
- Application pools may reference shared or local applicationHost.config
- AppDynamics config may reference shared IIS sites

**Expected Discovery**:
- Detection of shared configuration mode
- Shared configuration path identified
- Application pool configuration location determined (shared vs local)
- Warning if shared config complicates registry-based deployment

**Challenge**: Registry changes may not apply if pools use shared config

---

### Scenario 4: Custom IIS Configuration Location
**Description**: Server with IIS configuration in non-standard location

**Characteristics**:
- applicationHost.config in custom location (not %SystemRoot%\System32\inetsrv\config)
- May use environment variables or custom paths

**Expected Discovery**:
- Custom configuration path detected
- Application pool configuration location validated
- Configuration writeable location identified

---

### Scenario 5: AppDynamics Non-Standard Installation
**Description**: AppDynamics installed in non-default location

**Characteristics**:
- Service exists but in custom directory
- config.xml not in %ProgramData%\AppDynamics\...
- May be portable/xcopy deployment

**Expected Discovery**:
- Service detected via Windows Service Manager query
- Installation path extracted from service executable path
- config.xml found relative to service location or via search

---

### Scenario 6: AppDynamics Automatic Mode
**Description**: AppDynamics configured to auto-instrument all IIS applications

**Characteristics**:
- config.xml contains `<IIS><automatic /></IIS>`
- No explicit application listings in config
- All IIS sites auto-instrumented by AppDynamics

**Expected Discovery**:
- Automatic mode flag set
- All IIS sites enumerated
- EAI codes must be extracted from IIS site names or prompted
- Warning: Manual EAI mapping may be required

---

### Scenario 7: AppDynamics Not Installed
**Description**: Server has IIS but no AppDynamics

**Characteristics**:
- IIS detected
- No AppDynamics service found
- No config.xml

**Expected Discovery**:
- AppDynamics installation: NOT FOUND
- IIS applications enumerated
- EAI codes: UNKNOWN (requires manual mapping)
- Flag: Requires manual configuration for EDOT

---

### Scenario 8: Mixed .NET Framework and .NET Core
**Description**: Server hosts both .NET Framework and .NET Core applications

**Characteristics**:
- Application pools with different .NET CLR versions
- Some pools set to "No Managed Code" (.NET Core)
- Some pools set to "v4.0" (.NET Framework)

**Expected Discovery**:
- .NET version per application pool identified
- Different EDOT instrumentation requirements flagged (.NET Framework vs Core)
- Configuration differences noted in output

---

### Scenario 9: Configuration Conflicts
**Description**: Inconsistent or conflicting configuration detected

**Characteristics**:
- Application pool in IIS but not in AppDynamics config
- Application in AppDynamics config but IIS site doesn't exist
- Multiple EAI codes mapped to same application pool
- Inconsistent delimiter usage (mixed - and _)

**Expected Discovery**:
- Conflicts flagged with severity level
- Conflicting entities listed
- Recommendations for resolution
- Flag: Requires manual intervention

---

### Scenario 10: Older Windows Server (2012/2012 R2)
**Description**: Windows Server 2012 with PowerShell 4.0, older IIS version

**Characteristics**:
- PowerShell 4.0 (not 5.1)
- IISAdministration module not available
- Must use WebAdministration module only
- Limited cmdlet availability

**Expected Discovery**:
- OS and PowerShell version detected
- Appropriate module selection (WebAdministration)
- All discovery completes successfully
- No failures due to missing cmdlets

---

## 📊 DISCOVERY DATA MODEL

### JSON Output Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Server Discovery Data",
  "type": "object",
  "required": ["metadata", "server", "iis", "appdynamics", "discovery_status"],
  "properties": {
    "metadata": {
      "type": "object",
      "required": ["discovery_date", "script_version", "execution_duration_seconds"],
      "properties": {
        "discovery_date": { "type": "string", "format": "date-time" },
        "script_version": { "type": "string" },
        "execution_duration_seconds": { "type": "number" },
        "hostname": { "type": "string" },
        "discovery_mode": { "type": "string", "enum": ["local", "remote"] }
      }
    },
    "server": {
      "type": "object",
      "required": ["hostname", "os_version", "powershell_version"],
      "properties": {
        "hostname": { "type": "string" },
        "fqdn": { "type": "string" },
        "os_version": { "type": "string" },
        "os_build": { "type": "string" },
        "powershell_version": { "type": "string" },
        "architecture": { "type": "string", "enum": ["x64", "x86"] },
        "domain": { "type": "string" },
        "ip_addresses": { "type": "array", "items": { "type": "string" } }
      }
    },
    "iis": {
      "type": "object",
      "required": ["installed", "version"],
      "properties": {
        "installed": { "type": "boolean" },
        "version": { "type": "string" },
        "modules_available": {
          "type": "object",
          "properties": {
            "WebAdministration": { "type": "boolean" },
            "IISAdministration": { "type": "boolean" }
          }
        },
        "configuration_mode": {
          "type": "string",
          "enum": ["default", "shared", "custom", "unknown"]
        },
        "configuration_path": { "type": "string" },
        "shared_configuration": {
          "type": "object",
          "properties": {
            "enabled": { "type": "boolean" },
            "physical_path": { "type": "string" },
            "username": { "type": "string" }
          }
        },
        "sites": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "id", "state"],
            "properties": {
              "name": { "type": "string" },
              "id": { "type": "integer" },
              "state": { "type": "string" },
              "application_pool": { "type": "string" },
              "physical_path": { "type": "string" },
              "bindings": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "protocol": { "type": "string" },
                    "binding_information": { "type": "string" }
                  }
                }
              },
              "applications": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "path": { "type": "string" },
                    "application_pool": { "type": "string" },
                    "physical_path": { "type": "string" },
                    "enabled_protocols": { "type": "string" }
                  }
                }
              }
            }
          }
        },
        "application_pools": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "state"],
            "properties": {
              "name": { "type": "string" },
              "state": { "type": "string" },
              "dotnet_clr_version": { "type": "string" },
              "managed_pipeline_mode": { "type": "string" },
              "enable_32bit_app_on_win64": { "type": "boolean" },
              "identity_type": { "type": "string" },
              "identity_username": { "type": "string" },
              "auto_start": { "type": "boolean" },
              "configuration_location": { "type": "string" },
              "environment_variables": {
                "type": "object",
                "additionalProperties": { "type": "string" }
              },
              "profiler_configured": { "type": "boolean" },
              "profiler_type": { "type": "string", "enum": ["AppDynamics", "EDOT", "Other", "None"] }
            }
          }
        }
      }
    },
    "appdynamics": {
      "type": "object",
      "required": ["installed"],
      "properties": {
        "installed": { "type": "boolean" },
        "service_name": { "type": "string" },
        "service_status": { "type": "string" },
        "installation_path": { "type": "string" },
        "config_xml_path": { "type": "string" },
        "config_xml_found": { "type": "boolean" },
        "configuration": {
          "type": "object",
          "properties": {
            "controller": {
              "type": "object",
              "properties": {
                "host": { "type": "string" },
                "port": { "type": "integer" },
                "ssl_enabled": { "type": "boolean" },
                "account_name": { "type": "string" }
              }
            },
            "iis_mode": {
              "type": "string",
              "enum": ["automatic", "manual", "not_configured"]
            },
            "applications": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "controller_application": { "type": "string" },
                  "site": { "type": "string" },
                  "path": { "type": "string" },
                  "tier": { "type": "string" },
                  "eai_code": { "type": "string" },
                  "eai_delimiter": { "type": "string" },
                  "application_name": { "type": "string" },
                  "iis_site_exists": { "type": "boolean" },
                  "iis_application_exists": { "type": "boolean" },
                  "mapped_application_pool": { "type": "string" }
                }
              }
            },
            "standalone_applications": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "executable": { "type": "string" },
                  "tier": { "type": "string" },
                  "node": { "type": "string" }
                }
              }
            }
          }
        }
      }
    },
    "eai_mapping": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "application_name": { "type": "string" },
          "application_pools": { "type": "array", "items": { "type": "string" } },
          "services": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "service_name": { "type": "string" },
                "tier_name": { "type": "string" },
                "iis_site": { "type": "string" },
                "application_path": { "type": "string" },
                "application_pool": { "type": "string" }
              }
            }
          }
        }
      }
    },
    "discovery_status": {
      "type": "object",
      "required": ["overall_status", "errors", "warnings"],
      "properties": {
        "overall_status": {
          "type": "string",
          "enum": ["success", "partial_success", "failed"]
        },
        "errors": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": { "type": "string" },
              "message": { "type": "string" },
              "severity": { "type": "string", "enum": ["critical", "high", "medium", "low"] }
            }
          }
        },
        "warnings": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "category": { "type": "string" },
              "message": { "type": "string" }
            }
          }
        },
        "conflicts": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "type": { "type": "string" },
              "description": { "type": "string" },
              "entities": { "type": "array", "items": { "type": "string" } },
              "recommendation": { "type": "string" }
            }
          }
        },
        "migration_readiness": {
          "type": "string",
          "enum": ["ready", "ready_with_warnings", "requires_manual_intervention", "not_ready"]
        },
        "readiness_notes": { "type": "array", "items": { "type": "string" } }
      }
    }
  }
}
```

---

## 🔧 TECHNICAL REQUIREMENTS

### Module Detection Strategy

```powershell
function Get-AvailableIISModule {
    # Try IISAdministration first (Server 2016+)
    if (Get-Module -ListAvailable -Name IISAdministration) {
        return "IISAdministration"
    }
    # Fall back to WebAdministration (Server 2012+)
    elseif (Get-Module -ListAvailable -Name WebAdministration) {
        return "WebAdministration"
    }
    else {
        throw "No IIS management module available"
    }
}
```

### IIS Configuration Location Detection

**Shared Configuration Check**:
```powershell
# Check if shared configuration is enabled
$serverManager = Get-IISServerManager
$sharedConfig = $serverManager.GetApplicationHostConfiguration().GetSection("configurationRedirection")
$enabled = $sharedConfig.Attributes["enabled"].Value

if ($enabled) {
    $path = $sharedConfig.Attributes["path"].Value
    $username = $sharedConfig.Attributes["userName"].Value
    # Return shared config details
}
```

**Custom Configuration Path Check**:
```powershell
# Check environment variables
$customPath = [Environment]::GetEnvironmentVariable("IIS_CONFIGURATION_PATH", "Machine")

# Or check registry
$regPath = "HKLM:\SOFTWARE\Microsoft\InetStp"
$configPath = (Get-ItemProperty -Path $regPath).ConfigPath
```

**Application Pool Configuration Location**:
```powershell
# For each app pool, determine where its config is read from
# Check environment variables set for that specific pool
$appPoolEnvVars = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WAS\Parameters\AppPoolEnvironmentVariables\$appPoolName"
```

### AppDynamics Service Detection

**Flexible Service Search**:
```powershell
# Search by pattern (don't assume exact name)
$service = Get-Service -DisplayName "*AppDynamics*Agent*Coordinator*" -ErrorAction SilentlyContinue

if (-not $service) {
    # Try by name pattern
    $service = Get-Service | Where-Object { $_.Name -like "*AppDynamics*" -and $_.Name -like "*Coordinator*" }
}

if ($service) {
    # Extract installation path from service executable
    $servicePath = (Get-WmiObject Win32_Service -Filter "Name='$($service.Name)'").PathName
    $installPath = Split-Path (Split-Path $servicePath -Parent) -Parent
}
```

**Config.xml Search Strategy**:
```powershell
# Priority order for config.xml search
$configPaths = @(
    "$env:ProgramData\AppDynamics\DotNetAgent\Config\config.xml",
    "$installPath\Config\config.xml",
    "$installPath\..\Config\config.xml",
    "$env:AllUsersProfile\Application Data\AppDynamics\DotNetAgent\Config\config.xml"
)

foreach ($path in $configPaths) {
    if (Test-Path $path) {
        return $path
    }
}
```

### EAI Code Extraction

```powershell
function Get-EAICodeFromName {
    param(
        [string]$Name
    )
    
    # Match 4-5 digit code with - or _ delimiter at start
    if ($Name -match '^(\d{4,5})([-_])(.+)$') {
        return @{
            EAICode = $Matches[1]
            Delimiter = $Matches[2]
            Name = $Matches[3]
            FullMatch = $true
        }
    }
    
    # Match 4-5 digit code with - or _ delimiter at end
    if ($Name -match '^(.+)([-_])(\d{4,5})$') {
        return @{
            EAICode = $Matches[3]
            Delimiter = $Matches[2]
            Name = $Matches[1]
            FullMatch = $true
        }
    }
    
    return @{
        EAICode = $null
        Delimiter = $null
        Name = $Name
        FullMatch = $false
    }
}
```

---

## ⚠️ EDGE CASES & ERROR HANDLING

### Edge Case 1: Partial IIS Enumeration Failure
**Scenario**: Some IIS sites enumerate successfully, others fail

**Handling**:
- Continue discovery for successful sites
- Log errors for failed sites
- Flag partial discovery in output
- Set `overall_status = "partial_success"`

---

### Edge Case 2: AppDynamics Config.xml Malformed
**Scenario**: config.xml exists but is invalid XML

**Handling**:
- Log parsing error with details
- Set `config_xml_found = true` but configuration section empty
- Flag as requiring manual intervention
- Continue with IIS discovery

---

### Edge Case 3: EAI Code Not Found
**Scenario**: AppDynamics application name doesn't contain EAI code

**Handling**:
- Log warning for that application
- Set `eai_code = null`
- Continue processing other applications
- Flag in warnings section

---

### Edge Case 4: Multiple EAI Codes for Same Application Pool
**Scenario**: One application pool mapped to multiple applications with different EAI codes

**Handling**:
- Flag as critical conflict
- List all EAI codes involved
- Recommend manual resolution
- Set `migration_readiness = "requires_manual_intervention"`

---

### Edge Case 5: IIS Shared Configuration Access Denied
**Scenario**: Shared configuration path requires network credentials

**Handling**:
- Detect shared configuration
- Attempt to read with current credentials
- If failed, log error and path
- Flag as requiring manual review
- Note: May need to run discovery with appropriate credentials

---

### Edge Case 6: AppDynamics Configured but IIS Site Missing
**Scenario**: AppDynamics config references IIS site that doesn't exist

**Handling**:
- Flag mismatch in warnings
- Set `iis_site_exists = false`
- Continue processing
- Include in discovery report for cleanup

---

## 📈 PERFORMANCE REQUIREMENTS

### Execution Time Targets
- Single server discovery: < 2 minutes
- 100 servers (parallel): < 15 minutes
- 400 servers (parallel): < 30 minutes

### Resource Utilization
- Memory: < 100 MB per server
- Network: Minimal (PowerShell remoting only)
- CPU: Low priority, non-intrusive

### Scalability
- Support parallel execution (10-20 servers simultaneously)
- Implement throttling to prevent overwhelming network/AD
- Support resume capability for interrupted bulk runs

---

## 🎯 OUTPUT DELIVERABLES

### Per-Server Discovery JSON
**Filename**: `{Hostname}_discovery_{timestamp}.json`
**Location**: Configurable output directory
**Format**: JSON matching schema above
**Size**: Estimated 10-50 KB per server

### Fleet-Wide Aggregated Summary
**Filename**: `fleet_discovery_summary_{timestamp}.json`
**Content**:
```json
{
  "summary": {
    "total_servers": 387,
    "successful": 375,
    "partial_success": 10,
    "failed": 2,
    "total_eai_codes": 42,
    "total_application_pools": 1243,
    "total_iis_sites": 891
  },
  "server_status": [
    {
      "hostname": "WEB01",
      "status": "success",
      "eai_codes": ["1234", "5678"],
      "application_pools": 8
    }
  ],
  "eai_distribution": {
    "1234": {
      "server_count": 23,
      "application_pool_count": 67
    }
  },
  "readiness_summary": {
    "ready": 350,
    "ready_with_warnings": 20,
    "requires_manual_intervention": 15,
    "not_ready": 2
  },
  "top_issues": [
    {
      "issue": "EAI code not found",
      "count": 15,
      "affected_servers": ["WEB23", "WEB45", ...]
    }
  ]
}
```

### Human-Readable Report (HTML)
**Filename**: `discovery_report_{timestamp}.html`
**Content**:
- Executive summary
- Server inventory table
- EAI code distribution chart
- Migration readiness breakdown
- Issues and warnings list
- Recommendations

---

## ✅ VALIDATION & QUALITY CHECKS

### Discovery Output Validation
- [ ] Valid JSON format
- [ ] Matches schema
- [ ] All required fields present
- [ ] No null values in required fields
- [ ] Timestamps in correct format
- [ ] EAI codes match pattern (4-5 digits)

### Data Consistency Checks
- [ ] Application pools referenced in sites actually exist
- [ ] AppDynamics config sites exist in IIS
- [ ] EAI codes consistent across application/tier references
- [ ] Configuration paths are valid and accessible

### Quality Metrics
- Discovery success rate: > 95%
- False positive rate (incorrect detections): < 2%
- False negative rate (missed applications): < 1%
- Data accuracy: > 98%

---

## 📝 NEXT STEPS

1. **Review and approve** this discovery specification
2. **Begin implementation** of `Invoke-ServerDiscovery.ps1`
3. **Create test environments** representing each scenario
4. **Develop unit tests** for each detection function
5. **Build integration tests** for end-to-end discovery
6. **Test on Windows Server 2012** as baseline
7. **Scale test** with 10-20 servers

---

**Status**: Awaiting approval to proceed with implementation  
**Owner**: Lief08  
**Next Review**: TBD