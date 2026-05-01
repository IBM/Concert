# CSCF-SC-03: Transitive Dependency Risk Management

## Control Name
Transitive Dependency Risk Management

## Scope
This control ensures sovereignty risks introduced through indirect (transitive) dependencies are identified and managed. The platform identifies and assesses transitive software dependencies for:
- Security risk
- Jurisdictional exposure
- Unsupported or abandoned components

Material risks are documented and mitigated through SBOM analysis that includes transitive dependencies. High-risk components are reviewed and remediated.

## Expectation
Transitive software dependencies are identified, assessed, and managed to prevent sovereignty or security risks. Ensure that indirect software dependencies do not introduce hidden vulnerabilities, unsupported components, or jurisdictional exposure.

The platform identifies and maintains visibility into all software dependencies including:
- Direct dependencies
- Transitive dependencies
- Runtime libraries

Dependencies are evaluated for:
- Security vulnerabilities
- Unsupported or abandoned components
- Jurisdictional exposure risks

## Prerequisites/Dependency
- IBM Concert platform with API access
- Concert authentication credentials (API key)
- Application registered in Concert with associated SBOM
- SBOM data available in Concert Evidence Locker (CycloneDX or ConcertDef format)
- Network access to Concert API endpoints
- Vulnerability assessment data (optional, enhances analysis)

## Assumptions
- SBOM data is current and accurately reflects deployed software components
- Concert API is accessible and operational
- Application ID and cluster ID are correctly configured
- SBOM includes complete dependency tree with transitive dependencies
- Restricted registry list is maintained and up-to-date
- Vulnerability data is synchronized with Concert

## Design

### Workflow Architecture
The workflow implements a multi-stage assessment process:

1. **Application Discovery**
   - Fetches all applications from Concert
   - Identifies target application by cluster ID
   - Retrieves application metadata

2. **SBOM Retrieval**
   - Queries Concert for application SBOMs
   - Downloads SBOM content from Evidence Locker
   - Parses SBOM structure (CycloneDX/ConcertDef)

3. **Risk Analysis**
   - **Jurisdictional Risk Assessment**: Scans component URIs against restricted registry list
   - **Lifecycle Status Check**: Evaluates component age and maintenance status
   - **Vulnerability Assessment**: Analyzes security vulnerabilities in dependencies

4. **Validator Checks**
   - `restricted_registry_origin_check`: Validates no dependencies from restricted jurisdictions
   - `dependency_lifecycle_status_check`: Validates no abandoned components (>730 days)
   - `transitive_vulnerability_exposure_check`: Validates no critical/high CVEs

5. **OSCAL Assessment Generation**
   - Creates OSCAL-compliant assessment result
   - Generates three separate observations (one per validator check)
   - Includes detailed risk metadata and findings

6. **Result Upload**
   - Uploads assessment to Concert Evidence Locker
   - Creates compliance posture in Concert dashboard
   - Returns comprehensive result summary

### Restricted Registries
The workflow checks against these restricted sources:
- `registry.npmmirror.com` (Chinese npm mirror)
- `pypi.douban.com` (Chinese PyPI mirror)
- `maven.aliyun.com` (Chinese Maven mirror)
- `npm.taobao.org` (Chinese npm mirror)

### Risk Thresholds
- **Abandoned**: No updates for >730 days (2 years)
- **Unsupported**: No updates for >365 days (1 year)
- **Critical Vulnerabilities**: CVEs with severity "critical" or "high"

## Input

| Variable | Type | Required | Description | Default Value |
|----------|------|----------|-------------|---------------|
| `cluster_id` | string | Yes | Target cluster identifier | `"management_cluster"` |
| `environment` | string | Yes | Environment name | `"production"` |
| `profile_name` | string | Yes | Compliance profile name | `"profile_sovereign"` |
| `concert_auth_key` | string | Yes | Concert API authentication key | `"gori_admin@ibm.com/concertAPIKeyAuth"` |
| `instance_id` | string | Yes | Concert instance ID | `"0000-0000-0000-0000"` |

## Output

### Success Response
```json
{
  "status": "pass|fail",
  "upload_result": {
    "record_paths": ["path/to/assessment.json"],
    "event_ids": ["uuid"],
    "job_data": {"message": "202 Accepted"}
  },
  "application_id": "uuid",
  "sbom_count": 1,
  "check_results": {
    "restricted_registry_origin_check": "pass|fail",
    "dependency_lifecycle_status_check": "pass|fail",
    "transitive_vulnerability_exposure_check": "pass|fail"
  },
  "risk_summary": {
    "high_risks": 0,
    "medium_risks": 0,
    "low_risks": 0,
    "jurisdictional_risks": 0,
    "abandoned_components": 0,
    "vulnerabilities": 0
  },
  "cluster_id": "management_cluster",
  "environment": "production",
  "assessment_uploaded": true
}
```

### OSCAL Assessment Structure
- **Assessment Result**: OSCAL-compliant assessment with metadata
- **Observations**: Three separate observations for each validator check
- **Properties**: Risk counts, severity levels, timestamps
- **Evidence**: SBOM reference, component details, vulnerability data

### Compliance Posture
The workflow creates a compliance posture in Concert that displays:
- Overall control status (pass/fail)
- Individual validator check results
- Risk metrics and trends
- Historical assessment data