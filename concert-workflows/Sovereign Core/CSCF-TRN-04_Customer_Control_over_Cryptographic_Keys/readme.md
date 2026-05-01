# Customer Control over Cryptographic Keys - Concert Workflow

## Overview

This Concert workflow validates customer control over cryptographic keys by checking HashiCorp Vault policies and roles in an OpenShift environment. The workflow performs automated compliance assessments and uploads results to IBM Concert in OSCAL (Open Security Controls Assessment Language) format.

## Control Information

### Control ID
**ISCF-TRN-04**

### Control Name
**Customer Control over Cryptographic Keys**

### Control Synopsis
Customers retain control over cryptographic keys used to protect their data. Ensure cryptographic sovereignty remains with the customer.

### Control Description
The platform enables customers to manage encryption keys used for protecting their data:
- Generate encryption keys
- Rotate encryption keys

Platform providers do not retain unilateral control over these keys.

### Control Check
Customer has access to Roles and Policies configured for the Vault.

### Control Output
If Roles and Policies are configured for the Vault.

### Control Pass/Fail
**Pass**

## Workflow Components

### Main Workflows

1. **Customer Control over Cryptographic Keys** (`Customer Control over Cryptographic Keys.json`)
   - Core validation workflow that checks Vault policies and roles
   - Validates cryptographic key management controls
   - Returns pass/fail status for policy and role checks

2. **AssessmentUpload** (`AssessmentUpload.json`)
   - Orchestrates the complete assessment process
   - Generates UUIDs for OSCAL compliance
   - Executes validation checks
   - Formats results in OSCAL format
   - Uploads assessment results to IBM Concert

### Helper Workflows

Located in the `Helpers/` directory:

- **Generate_uuids** (`Generate_uuids.json`)
  - Generates multiple UUID v4 identifiers
  - Used for OSCAL document structure compliance

## Workflow Architecture

```
AssessmentUpload (Main Entry Point)
├── Input Validation
├── Generate UUIDs (Helper)
├── Customer Control over Cryptographic Keys
│   ├── List OpenShift Services
│   ├── Find Vault Service & Extract URL
│   ├── Get Vault Token from Config
│   ├── Validate Vault Policies
│   └── Validate Vault Roles
└── Upload Results to Concert
```

## Prerequisites

### Required Authentication

1. **OpenShift Authentication** (`ocp_auth`)
   - Access to OpenShift cluster
   - Permissions to list services in target namespace

2. **Vault Token** (`vault_token`)
   - Stored in Concert Config Data
   - Must have permissions to read Vault policies and roles

3. **Concert API Key** (`concert_auth_key`)
   - IBM Concert authentication
   - Required for uploading assessment results

### Required Services

- HashiCorp Vault deployed in OpenShift
- IBM Concert instance for compliance data ingestion
- OpenShift cluster with accessible API

## Input Parameters

### Required Inputs

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `ocp_auth` | string | OpenShift authentication key | - |
| `vault_token` | string | Vault authentication token (from Config Data) | - |
| `concert_auth_key` | string | IBM Concert API key | - |
| `namespace_name` | string | OpenShift namespace where Vault is deployed | `"vault"` |
| `service_name` | string | Name of the Vault service | `"vault"` |
| `policies_to_be_validated` | array | List of Vault policies to validate | `["account-iam-policy", "eso-policy"]` |
| `roles_to_be_validated` | array | List of Vault roles to validate | `["account-iam-role", "eso-role"]` |
| `environment` | string | Target environment identifier | `"production"` |
| `profile_name` | string | Compliance profile name | `"profile_sovereign"` |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data_type` | string | `"compliance_posture"` | Type of data being uploaded to Concert |

## Output Parameters

### AssessmentUpload Outputs

- `result`: Complete Concert upload response including assessment results

### Customer Control over Cryptographic Keys Outputs

- `policy_check`: Status of policy validation (`"pass"` or `"fail"`)
- `role_check`: Status of role validation (`"pass"` or `"fail"`)

## Validation Logic

### Policy Validation

The workflow validates that all specified policies exist in Vault:
- Retrieves all policies from Vault via API (`GET /v1/sys/policy`)
- Checks if each policy in `policies_to_be_validated` exists
- Returns `"pass"` if all policies are found, `"fail"` otherwise

### Role Validation

The workflow validates that all specified roles exist in Vault:
- Retrieves all Kubernetes auth roles from Vault (`GET /v1/auth/kubernetes/role?list=true`)
- Checks if each role in `roles_to_be_validated` exists
- Returns `"pass"` if all roles are found, `"fail"` otherwise

## OSCAL Compliance Output

The workflow generates OSCAL-compliant assessment results with:

### Assessment Structure

- **Assessment Results**: Top-level container for compliance data
- **Components**: Sovereign Software system being assessed
- **Inventory Items**: Vault policy set being validated
- **Assessment Assets**: Validator tool information
- **Observations**: Individual compliance check results

### Compliance Checks

1. **Cryptographic Key Management Role Assignment Check**
   - Control ID: `cryptographic_key_management_role_assignment_check`
   - Validates Vault role configuration
   - Severity: High

2. **Vault Access Policy Configuration Check**
   - Control ID: `vault_access_policy_configuration_check`
   - Validates Vault policy configuration
   - Severity: High

## Usage Example

### Running the Workflow

```javascript
// Input configuration
{
  "ocp_auth": "<openshift-auth-token>",
  "vault_token": "<vault-config-data-key>",
  "concert_auth_key": "<concert-api-key>",
  "namespace_name": "vault",
  "service_name": "vault",
  "policies_to_be_validated": [
    "account-iam-policy",
    "eso-policy"
  ],
  "roles_to_be_validated": [
    "account-iam-role",
    "eso-role"
  ],
  "environment": "production",
  "profile_name": "profile_sovereign"
}
```

### Expected Output

```javascript
{
  "policy_check": "pass",
  "role_check": "pass",
  "result": {
    // Concert upload response
    "status": "success",
    "message": "Assessment uploaded successfully"
  }
}
```

## Error Handling

### Input Validation Errors

The workflow validates all required inputs and throws descriptive errors:
```
400 Bad Request: Missing required input field(s): <field_names>
```

### Service Discovery Errors

If the Vault service cannot be found:
```
400 Bad Request: service with the name: <service_name> could not be found in namespace <namespace>
```

### API Errors

- **Policy Retrieval Failure**: `Failed to retrieve Vault policy. API responded with status code: <code>`
- **Role Retrieval Failure**: `Failed to retrieve Vault Roles. API responded with status code: <code>`

## Workflow Execution Flow

1. **Input Validation**: Verify all required parameters are provided
2. **UUID Generation**: Create unique identifiers for OSCAL structure
3. **Service Discovery**: Locate Vault service in OpenShift namespace
4. **Vault URL Construction**: Build Vault API endpoint from service details
5. **Token Retrieval**: Fetch Vault token from Concert Config Data
6. **Policy Validation**: Check existence of required Vault policies
7. **Role Validation**: Check existence of required Vault roles
8. **OSCAL Formatting**: Structure results in OSCAL assessment format
9. **Concert Upload**: Submit compliance data to IBM Concert

## Technical Details

### API Endpoints Used

- **OpenShift**: List services in namespace
- **Vault**: 
  - `GET /v1/sys/policy` - List all policies
  - `GET /v1/auth/kubernetes/role?list=true` - List all roles
- **Concert**: Upload compliance posture data

### Security Considerations

- Vault token stored securely in Concert Config Data
- HTTPS protocol enforced for Vault communication
- Authentication required for all API calls
- Sensitive data not logged or exposed

## Troubleshooting

### Common Issues

1. **Service Not Found**
   - Verify `namespace_name` and `service_name` are correct
   - Ensure Vault is deployed and running in the specified namespace

2. **Authentication Failures**
   - Verify Vault token has required permissions
   - Check OpenShift authentication is valid
   - Ensure Concert API key is active

3. **Policy/Role Not Found**
   - Verify policy and role names are spelled correctly
   - Check that policies/roles exist in Vault
   - Ensure Vault token has read permissions

## Version Information

- **Workflow Version**: 5
- **Platform**: Node.js
- **Scanner Version**: 1.0.0
- **OSCAL Namespace**: `https://oscal-compass.github.io/compliance-trestle/schemas/oscal/ar/OpenSCAP`

## Support

For issues or questions regarding this workflow:
- Review Concert workflow logs for detailed error messages
- Verify all authentication credentials are valid
- Ensure Vault and OpenShift services are accessible
- Check Concert API connectivity

## License

This workflow is part of IBM Concert compliance automation framework.