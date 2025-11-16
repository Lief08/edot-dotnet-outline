# Development Activities Sequence
## AppDynamics to EDOT .NET Migration - Script Suite

**Project**: AppDynamics to Elastic EDOT .NET Migration  
**Owner**: Lief08  
**Started**: 2025-11-16 02:39:44 UTC  
**Status**: Planning Phase

---

## 📋 PROJECT SCOPE

### Environment Scale
- **Servers**: 300-400 Windows Servers
- **OS Range**: Windows Server 2012 through 2022
- **Applications**: .NET Framework and .NET Core in IIS
- **Complexity**: 
  - Single EAI per server (1-N application pools)
  - Multi-EAI per server (shared infrastructure)
  - Mixed configuration locations

### Critical Unknowns (Pre-Discovery)
- ❓ AppDynamics installation locations (not standardized)
- ❓ IIS configuration mode (shared, custom, default)
- ❓ Application pool distribution (single vs multi-EAI servers)
- ❓ Module availability across OS versions
- ❓ Configuration file locations per pool

---

## 🎯 DEVELOPMENT PHASES

### PHASE 0: Project Setup ✅
**Status**: Complete  
**Deliverables**:
- [x] Requirements clarification (v3.0)
- [x] EAI code structure defined
- [x] Service name mapping clarified
- [x] JSON output structure designed
- [x] EDOT deployment approach defined

---

### PHASE 1: Discovery & Assessment Infrastructure 🔄
**Status**: IN PROGRESS  
**Priority**: CRITICAL  
**Goal**: Build universal discovery tooling for 300-400 server assessment

#### Activity 1.1: Discovery Script Specification
**Status**: Next  
**Owner**: Lief08  
**Estimated Time**: 2-4 hours  

**Tasks**:
- [ ] Document discovery requirements
- [ ] Define discovery data model
- [ ] Specify output format (JSON schema)
- [ ] Identify all detection scenarios
- [ ] Plan for edge cases and failures

**Deliverables**:
- `DISCOVERY_REQUIREMENTS.md` - Complete specification
- `DISCOVERY_DATA_MODEL.json` - JSON schema for output
- `DISCOVERY_EDGE_CASES.md` - Edge case handling

---

#### Activity 1.2: Discovery Script - Core Detection
**Status**: Pending  
**Dependencies**: 1.1  
**Estimated Time**: 4-6 hours  

**Tasks**:
- [ ] Windows OS version detection
- [ ] PowerShell version detection
- [ ] IIS installation detection
- [ ] Module availability check (WebAdministration, IISAdministration)
- [ ] AppDynamics service detection (flexible location)
- [ ] AppDynamics config.xml location discovery
- [ ] Hostname and server metadata collection

**Deliverables**:
- `Invoke-ServerDiscovery.ps1` (Core detection logic)
- Unit tests for detection functions

**Script Name**: `Invoke-ServerDiscovery.ps1`

---

#### Activity 1.3: Discovery Script - IIS Configuration Assessment
**Status**: Pending  
**Dependencies**: 1.2  
**Estimated Time**: 6-8 hours  

**Tasks**:
- [ ] Detect IIS configuration mode:
  - [ ] Shared configuration detection
  - [ ] Custom configuration location detection
  - [ ] Default configuration location validation
- [ ] Enumerate all IIS sites
- [ ] Enumerate all application pools
- [ ] Map sites → applications → application pools
- [ ] Determine active configuration path per pool
- [ ] Collect application pool properties:
  - [ ] .NET CLR version
  - [ ] Pipeline mode
  - [ ] Identity
  - [ ] Auto-start configuration
  - [ ] Process model settings
- [ ] Detect existing instrumentation (AppDynamics profiler settings)

**Deliverables**:
- `Get-IISConfigurationAssessment.ps1` (IIS discovery functions)
- Configuration location detection logic
- Application pool enumeration functions

---

#### Activity 1.4: Discovery Script - AppDynamics Configuration Analysis
**Status**: Pending  
**Dependencies**: 1.2, 1.3  
**Estimated Time**: 4-6 hours  

**Tasks**:
- [ ] Parse config.xml (handle automatic vs manual mode)
- [ ] Extract controller configuration
- [ ] Extract IIS application configurations
- [ ] Extract standalone application configurations
- [ ] Detect instrumentation mode (automatic/manual)
- [ ] Map AppDynamics config to discovered IIS sites
- [ ] Identify gaps (configured but not present, or vice versa)

**Deliverables**:
- `Get-AppDynamicsConfiguration.ps1` (Config parsing functions)
- Validation logic for config.xml
- Mapping functions

---

#### Activity 1.5: Discovery Script - EAI Code Detection & Validation
**Status**: Pending  
**Dependencies**: 1.4  
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Extract EAI codes from AppDynamics application names
- [ ] Validate EAI code format (4-5 digits with delimiter)
- [ ] Detect delimiter type (`-` or `_`)
- [ ] Group application pools by EAI code
- [ ] Detect multi-EAI scenarios (shared servers)
- [ ] Flag application pools without EAI codes
- [ ] Validate EAI code consistency

**Deliverables**:
- `Get-EAICodeMapping.ps1` (EAI extraction functions)
- Validation and conflict detection

---

#### Activity 1.6: Discovery Script - Output Generation
**Status**: Pending  
**Dependencies**: 1.2, 1.3, 1.4, 1.5  
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Define comprehensive JSON output schema
- [ ] Aggregate all discovery data
- [ ] Generate structured JSON output
- [ ] Include metadata (timestamps, script version, hostname)
- [ ] Generate summary statistics
- [ ] Create human-readable report (HTML or text)
- [ ] Implement validation for output JSON

**Deliverables**:
- `Export-DiscoveryData.ps1` (Output functions)
- JSON schema definition
- HTML report template
- Output validation logic

---

#### Activity 1.7: Discovery Script - Integration & Testing
**Status**: Pending  
**Dependencies**: 1.2-1.6  
**Estimated Time**: 4-6 hours  

**Tasks**:
- [ ] Integrate all discovery modules
- [ ] Create main discovery orchestration script
- [ ] Add error handling and logging
- [ ] Implement dry-run mode
- [ ] Test on Windows Server 2012
- [ ] Test on Windows Server 2016
- [ ] Test on Windows Server 2019
- [ ] Test on Windows Server 2022
- [ ] Test with shared IIS configuration
- [ ] Test with custom configuration locations
- [ ] Test with multiple EAI codes per server
- [ ] Test with missing AppDynamics installation
- [ ] Test with automatic AppDynamics mode
- [ ] Test with manual AppDynamics mode

**Deliverables**:
- `Invoke-ServerDiscovery.ps1` (Complete integrated script)
- Test scenarios and results documentation
- Known issues and workarounds document

---

#### Activity 1.8: Discovery Script - Remote Execution Capability
**Status**: Pending  
**Dependencies**: 1.7  
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Add PowerShell remoting support
- [ ] Create batch execution wrapper
- [ ] Implement parallel execution (for 300-400 servers)
- [ ] Add progress reporting for bulk runs
- [ ] Implement credential management
- [ ] Add retry logic for failed connections
- [ ] Aggregate results from multiple servers
- [ ] Generate fleet-wide summary report

**Deliverables**:
- `Invoke-FleetDiscovery.ps1` (Bulk execution script)
- Parallel execution logic
- Result aggregation functions
- Fleet-wide reporting

---

#### Activity 1.9: Discovery Output Analysis & Reporting
**Status**: Pending  
**Dependencies**: 1.8  
**Estimated Time**: 2-3 hours  

**Tasks**:
- [ ] Create analysis script for aggregated discovery data
- [ ] Generate migration readiness report
- [ ] Identify servers requiring manual intervention
- [ ] Create EAI code distribution report
- [ ] Identify configuration inconsistencies
- [ ] Generate risk assessment (edge cases, conflicts)
- [ ] Create migration priority recommendations

**Deliverables**:
- `Analyze-DiscoveryResults.ps1` (Analysis script)
- Migration readiness dashboard/report
- Risk assessment document

---

### PHASE 2: Service Registry Generation 🔜
**Status**: Not Started  
**Priority**: HIGH  
**Dependencies**: Phase 1 complete  
**Goal**: Transform discovery data into actionable service registry

#### Activity 2.1: Service Registry Builder - Core Logic
**Estimated Time**: 4-6 hours  

**Tasks**:
- [ ] Define service registry JSON schema (v2 based on discovery)
- [ ] Load and validate discovery JSON input
- [ ] Build EAI-grouped structure
- [ ] Map application pools to services
- [ ] Generate EDOT configuration blocks
- [ ] Handle multi-EAI scenarios
- [ ] Flag configuration conflicts

**Deliverables**:
- `Build-EDOTServiceRegistry.ps1` (v2.0 - based on discovery data)
- Service registry JSON schema
- Validation logic

---

#### Activity 2.2: Service Registry Builder - EDOT Configuration Templates
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Define OTEL_SERVICE_NAME patterns
- [ ] Define OTEL_RESOURCE_ATTRIBUTES templates
- [ ] Create profiler configuration blocks
- [ ] Create per-pool registry key definitions
- [ ] Create global registry key definitions
- [ ] Add environment-specific overrides (dev/test/prod)

**Deliverables**:
- Configuration templates
- Registry key documentation
- Environment variable mapping

---

#### Activity 2.3: Service Registry Builder - Validation & Testing
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Validate against discovery data
- [ ] Test with single-EAI scenarios
- [ ] Test with multi-EAI scenarios
- [ ] Test with edge cases from discovery
- [ ] Generate validation report

**Deliverables**:
- Validated service registry outputs
- Test cases and results
- Validation functions

---

### PHASE 3: EDOT Deployment Automation 🔜
**Status**: Not Started  
**Priority**: HIGH  
**Dependencies**: Phase 2 complete  
**Goal**: Automated EDOT zero-code instrumentation deployment

#### Activity 3.1: Deployment Script - Registry Configuration
**Estimated Time**: 6-8 hours  

**Tasks**:
- [ ] Implement global registry key setter (IIS service level)
- [ ] Implement per-pool registry key setter
- [ ] Add backup/rollback capability
- [ ] Validate registry key application
- [ ] Add registry permission checks

**Deliverables**:
- `Deploy-EDOTInstrumentation.ps1` (Core deployment)
- Registry management functions
- Rollback/backup functions

---

#### Activity 3.2: Deployment Script - Selective Deployment
**Estimated Time**: 4-5 hours  

**Tasks**:
- [ ] Filter by EAI code
- [ ] Filter by service name
- [ ] Filter by application pool
- [ ] Implement phased deployment support (N pools at a time)
- [ ] Add deployment state tracking

**Deliverables**:
- Selective deployment logic
- State tracking mechanism
- Deployment progress reporting

---

#### Activity 3.3: Deployment Script - Validation & Health Checks
**Estimated Time**: 4-5 hours  

**Tasks**:
- [ ] Validate registry keys applied correctly
- [ ] Test application pool restart
- [ ] Verify profiler loading
- [ ] Check OTLP connectivity
- [ ] Validate telemetry generation
- [ ] Generate deployment report

**Deliverables**:
- `Test-EDOTInstrumentation.ps1` (Validation script)
- Health check functions
- Deployment validation report

---

#### Activity 3.4: Deployment Script - Remote & Bulk Execution
**Estimated Time**: 4-6 hours  

**Tasks**:
- [ ] Add PowerShell remoting support
- [ ] Implement bulk deployment across fleet
- [ ] Add parallel execution with throttling
- [ ] Implement retry logic
- [ ] Add deployment rollback for failures
- [ ] Generate fleet-wide deployment report

**Deliverables**:
- `Deploy-EDOTFleet.ps1` (Bulk deployment script)
- Parallel execution logic
- Fleet deployment reporting

---

### PHASE 4: Monitoring & Validation Tools 🔜
**Status**: Not Started  
**Priority**: MEDIUM  
**Dependencies**: Phase 3 complete  

#### Activity 4.1: Post-Deployment Validation
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Verify all pools instrumented
- [ ] Check telemetry in Elastic
- [ ] Compare before/after metrics
- [ ] Identify silent failures
- [ ] Generate validation report

**Deliverables**:
- `Validate-EDOTDeployment.ps1`
- Validation report templates

---

#### Activity 4.2: AppDynamics to EDOT Comparison
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Compare service coverage (AppD vs EDOT)
- [ ] Identify missing services
- [ ] Compare metric collection
- [ ] Generate migration completeness report

**Deliverables**:
- `Compare-AppDynamicsToEDOT.ps1`
- Comparison report

---

### PHASE 5: Documentation & Runbooks 🔜
**Status**: Not Started  
**Priority**: MEDIUM  
**Dependencies**: Phases 1-4 complete  

#### Activity 5.1: User Documentation
**Estimated Time**: 4-6 hours  

**Tasks**:
- [ ] Discovery script usage guide
- [ ] Service registry builder guide
- [ ] Deployment script usage guide
- [ ] Troubleshooting guide
- [ ] FAQ document

**Deliverables**:
- User guide documentation set

---

#### Activity 5.2: Operational Runbooks
**Estimated Time**: 3-4 hours  

**Tasks**:
- [ ] Pre-migration checklist
- [ ] Discovery execution runbook
- [ ] Deployment execution runbook
- [ ] Rollback procedures
- [ ] Incident response guide

**Deliverables**:
- Operational runbook set

---

#### Activity 5.3: Architecture & Design Documentation
**Estimated Time**: 2-3 hours  

**Tasks**:
- [ ] Solution architecture diagram
- [ ] Data flow diagrams
- [ ] JSON schema documentation
- [ ] Registry key reference
- [ ] Script interaction diagrams

**Deliverables**:
- Architecture documentation
- Reference documentation

---

## 📊 PROGRESS TRACKING

### Current Phase
**Phase 1: Discovery & Assessment Infrastructure**
- Current Activity: 1.1 - Discovery Script Specification
- Status: Next
- Blockers: None
- Estimated Completion: TBD

### Overall Progress
```
Phase 0: [████████████████████] 100% Complete
Phase 1: [█░░░░░░░░░░░░░░░░░░░]   5% In Progress
Phase 2: [░░░░░░░░░░░░░░░░░░░░]   0% Not Started
Phase 3: [░░░░░░░░░░░░░░░░░░░░]   0% Not Started
Phase 4: [░░░░░░░░░░░░░░░░░░░░]   0% Not Started
Phase 5: [░░░░░░░░░░░░░░░░░░░░]   0% Not Started
```

### Estimated Timeline
- **Phase 1**: 30-40 hours (4-5 working days)
- **Phase 2**: 10-14 hours (1-2 working days)
- **Phase 3**: 18-24 hours (2-3 working days)
- **Phase 4**: 6-8 hours (1 working day)
- **Phase 5**: 9-13 hours (1-2 working days)

**Total Estimated Effort**: 73-99 hours (9-13 working days)

---

## 🎯 IMMEDIATE NEXT STEPS

### Step 1: Discovery Requirements Specification ⏭️
**Activity**: 1.1  
**Action**: Create comprehensive discovery requirements document  
**Owner**: Lief08  
**Due**: Next session  

**Specific Tasks**:
1. Define complete discovery data model
2. Specify all detection scenarios
3. Document edge cases and failure modes
4. Create JSON output schema for discovery
5. Plan for 300-400 server scale

---

### Step 2: Discovery Script Core Development
**Activity**: 1.2  
**Action**: Build core detection capabilities  
**Dependencies**: Step 1 complete  

---

### Step 3: IIS Configuration Assessment
**Activity**: 1.3  
**Action**: Build IIS configuration discovery  
**Dependencies**: Step 2 complete  

---

## 📝 NOTES & DECISIONS

### Key Decisions Made
- ✅ Use JSON for all data interchange (discovery, registry, configuration)
- ✅ Prioritize discovery before any configuration generation
- ✅ Support Windows Server 2012-2022 (use WebAdministration module)
- ✅ Design for 300-400 server scale from the start
- ✅ Support both single-EAI and multi-EAI server scenarios
- ✅ Detect and handle all IIS configuration modes (shared, custom, default)

### Open Questions
- ❓ Should discovery run locally on each server or remotely?
  - **Recommendation**: Support both, default to remote for fleet operations
- ❓ How to handle partial discovery failures?
  - **Recommendation**: Continue, log errors, flag for manual review
- ❓ Should discovery be idempotent and re-runnable?
  - **Recommendation**: Yes, support re-running to update data

### Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Inconsistent AppDynamics locations | High | Flexible service detection |
| Shared IIS config complexity | High | Dedicated detection logic |
| Multi-EAI conflicts | Medium | Validation and conflict detection |
| Scale (400 servers) performance | Medium | Parallel execution design |
| OS version compatibility | Medium | Test on all versions, use compatible cmdlets |

---

## 🔄 UPDATE LOG

| Date | Activity | Status | Notes |
|------|----------|--------|-------|
| 2025-11-16 02:39:44 | Created activities sequence | Active | Initial planning |
| 2025-11-16 02:39:44 | Phase 0 completed | Complete | Requirements clarified |
| 2025-11-16 02:39:44 | Phase 1 started | Active | Beginning discovery planning |

---

**Last Updated**: 2025-11-16 02:39:44 UTC by Lief08