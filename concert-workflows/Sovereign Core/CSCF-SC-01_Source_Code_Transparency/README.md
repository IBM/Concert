# ISCF-SC-01: Source Code Transparency


## Control Expectation
The control expects that:
- MSPs are able to inspect relevant source artifacts associated with the
sovereign platform. Provide transparency into software components used in the sovereign
environment and enable independent security review.


## Control Description

Source code or relevant build artifacts for platform components are accessible for inspection by the MSP or authorized reviewers. This enables validation of software behavior, dependency composition, and security posture.

Transparency may be provided through:
- open source repositories
- controlled internal source repositories
- software bill of materials (SBOM)

## Scope
This control validates that all container images deployed in the sovereign cloud environment have transparent and accessible source code repositories.

The assessment covers:
- Container images from Quay registries
- Open-source repositories (OpenShift, HashiCorp, etc.)
- GitHub repository accessibility validation

**Compliance Criteria:**
- **Pass**: All repositories are either public OR private with verified read access for the specified user
- **Fail**: Any repository is private without proper read access permissions

## Prerequisites/Dependency

### Authentication Requirements
1. **Concert Authentication** (`concert_auth`)
   - Type: IBM Concert API Key or Hub Self authentication
   - Purpose: Upload assessment results to Concert platform

2. **GitHub Authentication** (`github_auth`)
   - Type: API Key or Bearer Token
   - Purpose: Access GitHub API to verify repository permissions
   - Required Scopes: `repo` (for private repository access)

3. **Quay Token** (`Quay_token`)
   - Type: Bearer Token
   - Purpose: Access Quay registry API to retrieve container images and tags

### External Services
1. **Quay Registry** - Container image registry
2. **GitHub API** - Source code repository verification
3. **Red Hat Catalog API** - Container image metadata and source mapping
4. **IBM Concert** - Compliance posture data upload

## Assumptions

1. **Image Naming Convention**: Container images follow standard naming patterns that can be mapped to source repositories
2. **Metadata Availability**: Container images contain source code references in one of the following:
   - Environment variables (`SOURCE_GIT_URL`)
   - Labels (`io.openshift.build.source-location`, `org.opencontainers.image.source`, `io.openshift.build.commit.url`, `url`)
   - Red Hat Catalog metadata
3. **GitHub Hosting**: All source code repositories are hosted on GitHub
4. **API Accessibility**: All required APIs (Quay, GitHub, Red Hat Catalog) are accessible from the execution environment
5. **Permissions Model**: Private repositories use GitHub's collaborator permission model
6. **Fallback Mappings**: Known images without metadata have predefined source URL mappings
7. **Repository Structure**: GitHub repositories follow standard owner/repo naming convention

## Design

### Workflow Architecture
The control consists of three interconnected workflows:

#### 1. **Generate_uuids.json**
- **Purpose**: Generate unique identifiers for OSCAL compliance artifacts
- **Logic**: Iteratively generates specified number of UUID v4 identifiers
- **Output**: Array of UUIDs used for assessment components

#### 2. **source_code_transparency_checks.json** (Core Logic)
- **Purpose**: Perform actual source code transparency validation
- **Process Flow**:
  1. **Repository Discovery**
     - Query Quay registry for container images matching open-source patterns
     - Filter by target organizations (or all if "all_org" specified)
     - Handle pagination for large result sets
  
  2. **Tag Extraction**
     - Retrieve latest tag for each discovered repository
     - Build image URI with manifest digest
  
  3. **Source URL Resolution** (Priority Order)
     - Check environment variable: `SOURCE_GIT_URL`
     - Check label: `io.openshift.build.source-location`
     - Check label: `org.opencontainers.image.source`
     - Check label: `io.openshift.build.commit.url` (strip commit hash)
     - Check label: `url`
     - Apply hardcoded overrides for known images
     - Fallback to Red Hat Catalog repository metadata
  
  4. **GitHub Validation**
     - Parse owner and repository from GitHub URL
     - Fetch repository details via GitHub API
     - Check repository visibility (public/private)
     - For private repos: Verify user has read permissions
  
  5. **Compliance Determination**
     - Public repositories: Automatically compliant
     - Private repositories: Compliant only if user has verified access
     - Generate compliance report with per-image results

#### 3. **Assessment_Upload.json** (Orchestrator)
- **Purpose**: Orchestrate the assessment and upload results to Concert
- **Process Flow**:
  1. Validate all required input parameters
  2. Generate UUIDs for OSCAL components
  3. Execute source code transparency checks
  4. Transform results into OSCAL Assessment Results format
  5. Upload compliance posture to IBM Concert

### Data Flow
```
Input Parameters
    ↓
Parameter Validation
    ↓
UUID Generation (10 UUIDs)
    ↓
Source Code Transparency Checks
    ├─→ Quay Registry Query
    ├─→ Red Hat Catalog Lookup
    ├─→ GitHub API Validation
    └─→ Compliance Determination
    ↓
OSCAL Assessment Results Generation
    ↓
Concert Upload
    ↓
Result Output
```

## Input

### Required Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `concert_auth` | String (Auth) | Concert API authentication key | `"concert_hub"` |
| `github_auth` | String (Auth) | GitHub API authentication token | `"github_bearer"` |
| `environment` | String | Target environment identifier | `"production"` |
| `profile_name` | String | Compliance profile name | `"ISCF-SC-01"` |
| `Quay_url` | String | Quay registry base URL | `"quay.io"` |
| `Quay_token` | String (Auth) | Quay API bearer token | `"Bearer xyz..."` |
| `target_org` | Array | Target organizations to scan | `["all_org"]` or `["org1", "org2"]` |
| `opensource_repo_list` | Array | Open-source patterns to search | `["openshift", "hashicorp"]` |
| `redhat_catalog_url` | String | Red Hat Catalog API URL | `"https://catalog.redhat.com"` |
| `data_type` | String | Concert data type for upload | `"compliance_posture"` |
| `git_user` | String | GitHub username for permission checks | `"myuser"` |
| `git_host` | String | GitHub API host | `"https://api.github.com"` |

### Optional Parameters
- `number_of_uuids` (Generate_uuids): Number of UUIDs to generate (default: 10)

## Output

### Primary Output Structure

#### Assessment Results (OSCAL Format)
```json
{
  "results": [{
    "uuid": "<generated-uuid>",
    "title": "Source Code Transparency Compliance Results",
    "description": "Source Code Transparency compliance assessment results.",
    "start": "<ISO-8601-timestamp>",
    "end": "<ISO-8601-timestamp>",
    "local-definitions": {
      "components": [...],
      "inventory-items": [...],
      "assessment-assets": {...}
    },
    "reviewed-controls": {...},
    "observations": [{
      "uuid": "<generated-uuid>",
      "description": "Compliance check for Source Code Transparency: verify_source_code_has_read_access",
      "props": [
        {
          "name": "idref",
          "value": "verify_source_code_has_read_access"
        },
        {
          "name": "result",
          "value": "pass|fail"
        },
        {
          "name": "time",
          "value": "<ISO-8601-timestamp>"
        },
        {
          "name": "severity",
          "value": "high"
        }
      ],
      "methods": ["TEST-AUTOMATED"],
      "relevant-evidence": [...]
    }]
  }]
}
```

#### Detailed Compliance Report
```json
{
  "is_compliant": "true|false",
  "total_repositories_checked": <number>,
  "non_compliant_repositories": <number>,
  "compliant_repositories": <number>
}
```

#### Per-Repository Results
```json
[
  {
    "is_compliant": true|false,
    "image_name": "image-name",
    "repository_url": "https://github.com/owner/repo",
    "repository_visibility": "public|private"
  }
]
```

### Output Variables

| Variable | Type | Description |
|----------|------|-------------|
| `result` | Any | Final workflow execution result |
| `source_code_transparency` | Boolean | Overall compliance status |
| `source_code_transparency_result` | String | "pass" or "fail" |
| `github_urls_result` | Array | Detailed per-repository compliance results |

### Concert Upload
The assessment results are automatically uploaded to IBM Concert as a compliance posture file in JSON format, enabling:
- Centralized compliance tracking
- Historical trend analysis
- Audit trail maintenance
- Integration with broader compliance frameworks

## Execution Example

```bash
# Workflow execution with required parameters
{
  "concert_auth": "concert_hub",
  "github_auth": "github_bearer",
  "environment": "production-cluster",
  "profile_name": "ISCF-SC-01",
  "Quay_url": "quay.io",
  "Quay_token": "Bearer <token>",
  "target_org": ["all_org"],
  "opensource_repo_list": ["openshift", "hashicorp"],
  "redhat_catalog_url": "https://catalog.redhat.com",
  "data_type": "compliance_posture",
  "git_user": "compliance-user",
  "git_host": "https://api.github.com"
}
```

## Error Handling

### Validation Errors
- **400 Bad Request**: Missing required input fields (lists all missing parameters)

### API Errors
- **Quay API Failure**: Throws error with status code if Quay API call fails
- **GitHub API Failure**: Handles private repository permission checks gracefully
- **Red Hat Catalog Failure**: Continues with fallback mechanisms

### Fallback Mechanisms
1. Hardcoded source URL mappings for known images
2. Repository name-based GitHub URL construction
3. Graceful handling of missing metadata

## Compliance Mapping

- **OSCAL Framework**: Results formatted as OSCAL Assessment Results
- **ISCF Control**: ISCF-SC-01 (Source Code Transparency)
- **Severity**: High
- **Test Method**: TEST-AUTOMATED
