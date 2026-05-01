# Derived and Temporary Data Residency

## Control Information

**Control ID:** ISCF--DR-02

**Control Name:** Derived and Temporary Data Residency

**Control Synopsis:** Derived, cached, and temporary data shall remain in boundary region-resident. Prevent sovereignty violations through in data artifacts such as caches, temporary files, intermediate processing outputs, or derived datasets.

**Control Description:** The platform shall ensure that derived data artifacts, including system caches, analytics outputs, temporary files, and application buffers, are stored only within region infrastructure. Storage classes and ephemeral volumes shall inherit the same residency constraints as primary data.

**Control Check:** Check if Logs stored in Loki is within the boundary, Loki Stack pod IP is verified with the CIDR range.

**Control Output:** If the IP is in CIDR range.

**Control Pass/Fail:** Pass if the Loki storage IP is within the specified CIDR range, Fail otherwise.

## Overview

This IBM Concert workflow validates that derived and temporary data (specifically Loki telemetry logs) remains within the designated control plane CIDR range, ensuring data residency compliance for sovereign cloud environments.

## Purpose

The workflow performs automated compliance checks to verify that:
- Telemetry storage (Loki logs) is hosted within the control plane network boundary
- Temporary and derived data does not leave the designated sovereign region
- S3 storage backend for Loki is deployed on worker nodes within the control plane CIDR

## Workflow Components

### Main Workflow: `Derived_and_Temporary_Data_Residency.json`

**Key Steps:**
1. **Discover Loki API Version** - Queries OpenShift API to find the Loki operator API version
2. **Locate Loki Resources** - Identifies Loki stack resources in the cluster
3. **Extract Storage Configuration** - Retrieves Loki storage secret and S3 endpoint details
4. **Trace Storage Location** - Follows the service chain to identify the worker node hosting S3 storage
5. **Validate IP Range** - Checks if the worker node IP falls within the control plane CIDR
6. **Return Result** - Returns "pass" or "fail" based on validation

**Required Input Variables:**
- `openshift_host` - OpenShift cluster hostname (with port)
- `openshift_auth` - OpenShift authentication credentials
- `openshift_bearer_auth` - Bearer token for API authentication
- `control_plane_cidr` - CIDR range for the control plane network (e.g., "10.0.0.0/16")

**Output Variables:**
- `result` - "pass" if storage is within CIDR, "fail" otherwise
- `loki_api_version` - Discovered Loki API version
- `loki_secret` - Name of the Loki storage secret
- `loki_service` - Service name for Loki storage
- `worker_node` - Worker node hosting the storage
- `telemetry_storage_ip_in_cidr` - Boolean indicating if IP is in CIDR range

### Assessment Upload Workflow: `AssessmentUpload.json`

Orchestrates the compliance check and uploads results to IBM Concert in OSCAL format.

**Key Steps:**
1. **Validate Inputs** - Ensures all required parameters are provided
2. **Generate UUIDs** - Creates unique identifiers for OSCAL components
3. **Execute Compliance Check** - Runs the main data residency validation
4. **Format OSCAL Results** - Structures findings in OSCAL Assessment Results format
5. **Upload to Concert** - Submits compliance data to IBM Concert platform

**Required Input Variables:**
- `Hostname` - OpenShift cluster hostname with port
- `ocp_auth` - OpenShift authentication
- `ocp_bearer_auth` - Bearer token authentication
- `concert_auth_key` - IBM Concert API authentication key
- `control_plane_cidr` - Control plane CIDR range
- `environment` - Environment identifier (e.g., "production")
- `profile_name` - Compliance profile name (default: "profile_sovereign")

### Helper Workflow: `Generate_uuids.json`

Utility workflow that generates multiple UUID v4 identifiers for OSCAL component tracking.

**Input:**
- `number_of_uuids` - Number of UUIDs to generate

**Output:**
- `result` - Array of generated UUIDs

## Installation

1. Extract the workflow package:
   ```bash
   unzip Derived_and_Temporary_Data_Residency.zip
   ```

2. Import workflows into IBM Concert:
   - Import `Derived_and_Temporary_Data_Residency.json` as the main validation workflow
   - Import `AssessmentUpload.json` as the orchestration workflow
   - Import `Helpers/Generate_uuids.json` as a helper workflow

## Usage

### Running the Validation

Execute the `AssessmentUpload` workflow with the following parameters:

```json
{
  "Hostname": "api.cluster.example.com:6443",
  "ocp_auth": "<openshift-credentials>",
  "ocp_bearer_auth": "<bearer-token>",
  "concert_auth_key": "<concert-api-key>",
  "control_plane_cidr": "10.0.0.0/16",
  "environment": "production",
  "profile_name": "profile_sovereign"
}
```

### Expected Results

**Pass Scenario:**
- Loki storage worker node IP is within the control plane CIDR
- Result: `"pass"`
- OSCAL observation recorded with result "pass"

**Fail Scenario:**
- Loki storage worker node IP is outside the control plane CIDR
- Result: `"fail"`
- OSCAL observation recorded with result "fail"

## Technical Details

### Network Validation Logic

The workflow uses CIDR matching to validate IP addresses:
```javascript
function isIpInCidr(ip, cidr) {
  const [range, prefixLength] = cidr.split('/');
  const ipNum = ipToNumber(ip);
  const rangeNum = ipToNumber(range);
  const mask = ~(2 ** (32 - parseInt(prefixLength, 10)) - 1) >>> 0;
  return (ipNum & mask) === (rangeNum & mask);
}
```

### OSCAL Compliance Format

Results are formatted according to OSCAL Assessment Results schema:
- **Component**: Sovereign Software system
- **Inventory Item**: Derived and Temporary Data Residency check
- **Observation**: Compliance check result with severity "high"
- **Assessment Asset**: Sovereign Validation scanner (v1.0.0)

### API Endpoints Used

- `/apis` - OpenShift API version discovery
- `/apis/{loki-api-version}/{loki-resource}` - Loki stack resources
- `/api/v1/namespaces/{namespace}/secrets/{secret}` - Loki storage secrets
- `/api/v1/namespaces/{namespace}/services/s3` - S3 service details
- `/api/v1/namespaces/{namespace}/pods` - Pod information by label selector
- `/api/v1/nodes/{node-name}` - Worker node details

## Dependencies

- **OpenShift Cluster**: Version with Loki operator installed
- **Loki Operator**: Configured with S3 storage backend
- **IBM Concert**: Platform for compliance data ingestion
- **Network Access**: API access to OpenShift cluster

## Troubleshooting

### Common Issues

1. **Loki API Not Found**
   - Ensure Loki operator is installed in the cluster
   - Verify the operator is running in the expected namespace

2. **Authentication Failures**
   - Validate OpenShift bearer token is current and has sufficient permissions
   - Check Concert API key is valid

3. **CIDR Validation Fails**
   - Verify control plane CIDR is correctly specified
   - Ensure worker nodes are properly labeled and configured

4. **Missing Storage Configuration**
   - Confirm Loki is configured with S3 storage backend
   - Check that storage secret exists in the logging namespace

## Security Considerations

- Bearer tokens and API keys should be stored securely
- Use service accounts with minimal required permissions
- Audit logs should be enabled for compliance tracking
- CIDR ranges should be validated against organizational policies

## Version Information

- **Workflow Version**: 5
- **Platform**: Node.js
- **Scanner Version**: 1.0.0
- **OSCAL Schema**: Assessment Results format

## Support

For issues or questions regarding this workflow:
1. Check IBM Concert documentation
2. Review OpenShift Loki operator documentation
3. Contact your IBM Concert administrator

## License

This workflow is part of IBM Concert compliance automation framework.