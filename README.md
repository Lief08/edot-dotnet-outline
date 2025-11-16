# EDOT .NET Migration Suite
PowerShell automation suite for migrating from AppDynamics to Elastic Distribution of OpenTelemetry (EDOT) .NET

## Project Overview
This project provides automated discovery, configuration generation, and deployment scripts for migrating 300-400 Windows servers from AppDynamics .NET agent to Elastic EDOT .NET zero-code instrumentation.

## Components
- **Discovery Script**: Comprehensive server assessment and configuration discovery
- **Service Registry Builder**: Generates JSON service registry from AppDynamics configuration
- **Deployment Script**: Automated EDOT zero-code instrumentation deployment

## Status
🚧 In Development - Target QA Deployment: Monday, 2025-11-18

## Documentation
- [Project Context](./docs/PROJECT_CONTEXT_v3.md) - Complete requirements and specifications
- [Development Activities](./docs/DEVELOPMENT_ACTIVITIES_SEQUENCE.md) - Project roadmap and timeline
- [Discovery Requirements](./docs/DISCOVERY_REQUIREMENTS_SPEC.md) - Discovery phase specifications

## Quick Start
```powershell
# Run discovery on local server
.\scripts\Invoke-ServerDiscovery.ps1 -OutputPath ".\output\discovery.json"

# Build service registry from discovery data
.\scripts\Build-EDOTServiceRegistry.ps1 -DiscoveryPath ".\output\discovery.json"

# Deploy EDOT instrumentation
.\scripts\Deploy-EDOTInstrumentation.ps1 -ServiceRegistryPath ".\output\serviceRegistry.json"
```

## Requirements
- Windows Server 2012 or newer
- PowerShell 5.1+ (4.0 minimum)
- IIS with WebAdministration module
- Administrator privileges

## License
Internal use only