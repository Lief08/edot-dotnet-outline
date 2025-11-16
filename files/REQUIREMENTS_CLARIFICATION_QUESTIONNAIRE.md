# Requirements Clarification Questionnaire
## AppDynamics to EDOT .NET Migration Script

**Date**: 2025-11-16 02:17:06 UTC  
**Requestor**: Lief08  
**Purpose**: Clarify critical assumptions and requirements before implementation

---

## 🔴 CRITICAL PRIORITY QUESTIONS

### Q1: EAI Code Structure and Location

**Context**: The entire grouping mechanism depends on extracting EAI codes, but the source and format are unclear.

**Questions**:

1.1. **Where are EAI codes stored in your environment?** (Select all that apply)
- [ ] In IIS application pool names
- [ ] In IIS site names
- [ ] In IIS application physical path
- [ ] In AppDynamics tier names
- [ ] In AppDynamics application names
- [ ] In a separate configuration file (specify location: _____________)
- [ ] Other (describe: _____________)

1.2. **What is the exact format of EAI codes?**
- Format: `____` digits (e.g., 4 or 5)
- Character type: 
  - [ ] Numeric only (e.g., 1234)
  - [ ] Alphanumeric (e.g., AB12)
  - [ ] Other: _____________

1.3. **What is the naming pattern?** (Select all that apply)
- [ ] `[EAI]-Name` (e.g., "1234-WebAppPool")
- [ ] `Name-[EAI]` (e.g., "WebAppPool-1234")
- [ ] `[EAI]_Name` (e.g., "1234_WebAppPool")
- [ ] Other: _____________

1.4. **Please provide 5 real examples** (sanitized if needed):

| Example # | Source (Pool/Site/Tier) | Full Name | EAI Code |
|-----------|-------------------------|-----------|----------|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

1.5. **Are all entities tagged with EAI codes?**
- [ ] Yes, all IIS application pools have EAI codes
- [ ] Yes, all IIS sites have EAI codes
- [ ] No, some are missing EAI codes
- [ ] Other: _____________

1.6. **If an entity lacks an EAI code, how should the script handle it?**
- [ ] Skip it and log a warning
- [ ] Create a "UNKNOWN" or "NO-EAI" group
- [ ] Fail the script with an error
- [ ] Other: _____________

---

### Q2: Service Names Definition

**Context**: The requirement mentions "service names" but it's ambiguous what this refers to.

**Questions**:

2.1. **What are "service names" in your context?** (Select one)
- [ ] Windows service names (background services like `MyService.exe`)
- [ ] IIS site names (e.g., "Default Web Site")
- [ ] IIS application pool names (e.g., "DefaultAppPool")
- [ ] AppDynamics application/tier names
- [ ] Logical business service names (e.g., "Customer API")
- [ ] Other: _____________

2.2. **How do service names relate to IIS application pools?**
- Describe the relationship: _____________________________________________
- Example: "Service name '1234-CustomerService' uses app pool '1234-CustomerAppPool'"

2.3. **Are service names stored in:**
- [ ] AppDynamics config.xml
- [ ] IIS configuration (applicationHost.config)
- [ ] A separate mapping file
- [ ] Derived from IIS site/pool names
- [ ] Other: _____________

---

### Q3: JSON Output Consumer

**Context**: Understanding what will consume the JSON determines its structure and content.

**Questions**:

3.1. **What tool/process will consume the generated JSON file?** (Select all that apply)
- [ ] Manual reference during migration (human-readable documentation)
- [ ] Another PowerShell script (specify purpose: _____________)
- [ ] Configuration management tool (Ansible/Chef/Puppet/etc.)
- [ ] Custom EDOT configuration generator
- [ ] CI/CD pipeline (Jenkins/Azure DevOps/GitHub Actions)
- [ ] API or web service
- [ ] Other: _____________

3.2. **Does the JSON need to be machine-parseable and actionable, or just documentation?**
- [ ] Machine-parseable - will be programmatically processed
- [ ] Documentation only - for human review
- [ ] Both

3.3. **Are there any specific JSON schema requirements?**
- [ ] No specific schema
- [ ] Must match a predefined schema (provide schema or example)
- [ ] Must be compatible with specific tooling (specify: _____________)

3.4. **What will you do with the JSON after it's generated?**
- Describe the workflow: _____________________________________________

---

### Q4: EDOT Deployment Approach

**Context**: The deployment method affects what information the JSON needs to contain.

**Questions**:

4.1. **How will you deploy EDOT .NET agent to IIS applications?** (Select primary method)
- [ ] Zero-code auto-instrumentation (PowerShell: `Register-OpenTelemetryForIIS`)
- [ ] Code-based configuration (modify `Program.cs`/`Startup.cs` in each app)
- [ ] Environment variables set at IIS app pool level
- [ ] web.config modifications for .NET Framework apps
- [ ] Combination of above (describe: _____________)
- [ ] Not yet decided
- [ ] Other: _____________

4.2. **Will the JSON output be used to generate EDOT configuration automatically?**
- [ ] Yes - another script will consume it to generate EDOT configs
- [ ] No - it's just for reference
- [ ] Partially - some manual intervention required

4.3. **If yes to 4.2, what specific EDOT configurations need to be generated?**
- [ ] Environment variables script (e.g., `Set-AppPoolEnvironmentVariables.ps1`)
- [ ] web.config modifications
- [ ] EDOT configuration code snippets
- [ ] OpenTelemetry resource attributes
- [ ] OTLP exporter configurations
- [ ] Other: _____________

4.4. **Do you need the JSON to include EDOT-specific mappings?**
- [ ] Yes - include suggested `OTEL_SERVICE_NAME` values
- [ ] Yes - include suggested `OTEL_RESOURCE_ATTRIBUTES` values
- [ ] Yes - include suggested exporter endpoints
- [ ] No - just AppDynamics configuration extraction
- [ ] Other: _____________

---

## 🟡 HIGH PRIORITY QUESTIONS

### Q5: AppDynamics Configuration Mode

**Questions**:

5.1. **Which configuration mode does your AppDynamics deployment use?** (Select one)
- [ ] Automatic mode (`<IIS><automatic /></IIS>`) for all servers
- [ ] Manual mode (`<IIS><applications>...</applications></IIS>`) for all servers
- [ ] Mixed - some servers automatic, some manual
- [ ] Don't know - need to check

5.2. **If automatic mode, how should EAI codes be determined?**
- Since config.xml won't list applications explicitly:
  - [ ] Extract from IIS site names
  - [ ] Extract from IIS application pool names
  - [ ] Look up from external mapping file
  - [ ] Prompt operator for each site
  - [ ] Other: _____________

5.3. **Are there IIS sites that should be excluded from migration?**
- [ ] No - migrate all IIS sites
- [ ] Yes - exclude based on site name pattern (specify: _____________)
- [ ] Yes - exclude based on app pool name pattern (specify: _____________)
- [ ] Yes - exclude based on external list/file

---

### Q6: Sample Configuration Files

**Questions**:

6.1. **Can you provide a sanitized sample of your actual config.xml?**
- [ ] Yes - attached below or in separate file
- [ ] Yes - will provide separately
- [ ] No - cannot share due to security policies
- [ ] No - don't have access to it currently

If yes, please attach or paste (sanitize sensitive data):
```xml
<!-- Paste sanitized config.xml here -->


```

6.2. **Can you provide sample IIS site and app pool names?**

| IIS Site Name | Application Path | App Pool Name | Expected EAI Code |
|---------------|------------------|---------------|-------------------|
| | | | |
| | | | |
| | | | |

---

### Q7: Standalone Applications Scope

**Questions**:

7.1. **Should the script process standalone applications (Windows services)?**
- [ ] Yes - include in JSON output
- [ ] No - IIS applications only
- [ ] Optional - make it a script parameter

7.2. **If yes, do standalone applications have EAI codes?**
- [ ] Yes - same format as IIS apps
- [ ] No - they use a different naming scheme
- [ ] Some do, some don't
- [ ] Not applicable

7.3. **Where are standalone application EAI codes located?**
- [ ] In the executable name
- [ ] In AppDynamics tier name
- [ ] In Windows service name
- [ ] Other: _____________

---

## 🟢 MEDIUM PRIORITY QUESTIONS

### Q8: Environment and Scale

**Questions**:

8.1. **How many servers will this script run on?**
- [ ] 1-10 servers
- [ ] 11-50 servers
- [ ] 51-100 servers
- [ ] 100+ servers

8.2. **What is the typical number of IIS sites per server?**
- [ ] 1-5 sites
- [ ] 6-20 sites
- [ ] 21-50 sites
- [ ] 50+ sites

8.3. **What Windows Server versions are in use?** (Select all that apply)
- [ ] Windows Server 2012
- [ ] Windows Server 2012 R2
- [ ] Windows Server 2016
- [ ] Windows Server 2019
- [ ] Windows Server 2022
- [ ] Other: _____________

8.4. **What .NET Framework/Core versions are running?** (Select all that apply)
- [ ] .NET Framework 4.5.x
- [ ] .NET Framework 4.6.x
- [ ] .NET Framework 4.7.x
- [ ] .NET Framework 4.8.x
- [ ] .NET Core 3.1
- [ ] .NET 5
- [ ] .NET 6
- [ ] .NET 7
- [ ] .NET 8
- [ ] Other: _____________

---

### Q9: Additional Metadata

**Questions**:

9.1. **What additional information should be included in the JSON output?** (Select all desired)
- [ ] Controller connection details
- [ ] Tier naming patterns
- [ ] Node naming patterns
- [ ] Application pool identities
- [ ] .NET runtime versions
- [ ] Physical paths of applications
- [ ] SSL/binding information
- [ ] Custom instrumentation rules
- [ ] Environment type (dev/test/prod)
- [ ] Other: _____________

9.2. **Should the output include AppDynamics settings that don't directly map to EDOT?**
- [ ] Yes - include everything for reference
- [ ] No - only include mappable configuration
- [ ] Include but mark as "not applicable to EDOT"

---

### Q10: Error Handling and Edge Cases

**Questions**:

10.1. **How should the script handle missing EAI codes?**
- (See Q1.6, but any additional preferences?)
- Additional notes: _____________________________________________

10.2. **How should the script handle invalid or malformed config.xml?**
- [ ] Fail immediately with error
- [ ] Skip invalid sections and continue
- [ ] Attempt best-effort parsing
- [ ] Other: _____________

10.3. **Should the script validate that IIS sites in config.xml actually exist in IIS?**
- [ ] Yes - warn if config.xml references non-existent sites
- [ ] No - just extract what's in config.xml
- [ ] Yes - and exclude non-existent sites from output

10.4. **What if an app pool is shared by multiple EAI codes?**
- [ ] This should never happen (validation error)
- [ ] Associate with first EAI found
- [ ] Associate with all applicable EAIs (duplicate in output)
- [ ] Other: _____________

---

## 📝 ADDITIONAL INFORMATION

### Space for Additional Context

Please provide any additional information that would help clarify requirements:

```
[Your notes here]




```

---

## 📤 NEXT STEPS AFTER COMPLETION

1. **Review this questionnaire** and answer all critical (🔴) questions
2. **Provide sample files** (sanitized config.xml, IIS configuration examples)
3. **Clarify any ambiguous answers** with additional context
4. **Return completed questionnaire** to Lief08
5. **Script implementation** will begin once critical questions are answered

---

## 📋 COMPLETION CHECKLIST

- [ ] All CRITICAL questions answered (Q1-Q4)
- [ ] Sample config.xml provided or explained why not possible
- [ ] Sample IIS site/pool names provided (Q6.2)
- [ ] EAI code examples provided (Q1.4)
- [ ] JSON output consumer clarified (Q3)
- [ ] EDOT deployment approach defined (Q4)
- [ ] Additional context provided in notes section

**Estimated time to complete**: 20-30 minutes

---

**Once this questionnaire is complete, we can proceed with high confidence that the implementation will meet your actual requirements.**