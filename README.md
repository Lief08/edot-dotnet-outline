# EDOT .NET Migration Automation Suite

PowerShell automation suite for migrating from AppDynamics .NET agent to Elastic Distribution of OpenTelemetry (EDOT) .NET agent.

## Project Status

**Current Phase**: Phase 1 - Discovery & Assessment Infrastructure  
**Target Deployment**: 2025-11-18 (Monday) to QA  
**Scale**: 300-400 Windows Servers (2012-2022)

## Overview

This project provides automated tooling to:
1. **Discover** AppDynamics installations and IIS configurations across your fleet
2. **Generate** service registries mapping EAI codes to application pools
3. **Deploy** EDOT .NET zero-code instrumentation selectively

## Repository Structure

```
edot-dotnet-outline/
├── docs/                           # Documentation
│   ├── PROJECT_CONTEXT_v3.md       # Complete requirements
│   ├── DISCOVERY_REQUIREMENTS_SPEC.md
│   └── REQUIREMENTS_CLARIFICATION_QUESTIONNAIRE.md
├── scripts/                        # PowerShell scripts
│   ├── Invoke-ServerDiscovery.ps1  # Discovery script
│   ├── Build-EDOTServiceRegistry.ps1 (coming)
│   └── Deploy-EDOTInstrumentation.ps1 (coming)
├── schemas/                        # JSON schemas
│   └── discovery-output-schema.json
├── examples/                       # Example outputs
├── tests/                          # Test scripts
└── DEVELOPMENT_ACTIVITIES_SEQUENCE.md  # Project roadmap
```

## Quick Start

### Prerequisites
- Windows Server 2012 or newer
- PowerShell 5.1+ (4.0 minimum)
- Administrator privileges
- WebAdministration module (for IIS)

### Discovery Phase

```powershell
# Run discovery on local server
.\scripts\Invoke-ServerDiscovery.ps1 -OutputPath ".\output\discovery.json"

# Run discovery on remote servers
.\scripts\Invoke-FleetDiscovery.ps1 -ServerList servers.txt -OutputPath ".\output\"
```

### Service Registry Generation

```powershell
# Generate service registry from discovery data
.\scripts\Build-EDOTServiceRegistry.ps1 -DiscoveryPath ".\output\discovery.json" -OutputPath ".\output\serviceRegistry.json"
```

### Deployment

```powershell
# Deploy EDOT to specific EAI codes
.\scripts\Deploy-EDOTInstrumentation.ps1 -ServiceRegistry ".\output\serviceRegistry.json" -EAICode "1234" -OTLPEndpoint "https://elastic:443" -BearerToken "your-token"
```

## Key Concepts

### EAI Codes
- **Definition**: 4-5 digit internal application inventory codes
- **Format**: Prefixed to AppDynamics application names (e.g., `1234-CustomerPortal`)
- **Delimiter**: Hyphen `-` or underscore `_`
- **Purpose**: Group and track applications in service registry

### Service Names
- **AppDynamics Tier** → **EDOT Service Name**
- Example: Tier `API-Tier` in app `1234-CustomerPortal` → Service `1234-API-Tier`

### EDOT Deployment
- **Method**: Zero-code instrumentation via registry configuration
- **Scope**: Selective per-application-pool deployment
- **Configuration**: 
  - Global: OTLP endpoint, bearer token (IIS service level)
  - Per-Pool: Profiler settings, service naming

## Development Timeline

**Saturday 2025-11-16**:
- ✅ Requirements clarification
- ✅ Project structure
- 🔄 Discovery script implementation (in progress)

**Sunday 2025-11-17**:
- Service registry builder
- Deployment script
- Remote execution capability

**Monday 2025-11-18**:
- Final testing
- QA deployment

## Documentation

- [Complete Requirements](docs/PROJECT_CONTEXT_v3.md)
- [Discovery Specification](docs/DISCOVERY_REQUIREMENTS_SPEC.md)
- [Development Roadmap](DEVELOPMENT_ACTIVITIES_SEQUENCE.md)
- [Requirements Q&A](docs/REQUIREMENTS_CLARIFICATION_QUESTIONNAIRE.md)

## Environment Scale

- **Servers**: 300-400 Windows Servers
- **OS Versions**: Windows Server 2012 through 2022
- **Applications**: .NET Framework and .NET Core in IIS
- **Scenarios**: Single-EAI and multi-EAI shared servers
- **Configuration**: Shared, custom, and default IIS configurations

## Support

For questions or issues, contact: Lief08

## License

Internal use only.
