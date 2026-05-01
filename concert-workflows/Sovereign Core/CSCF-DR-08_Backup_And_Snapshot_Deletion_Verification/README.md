# ISCF-DR-08: Backup & Snapshot Deletion Verification

## Control Expectation
Deleted customer data SHALL not persist in backups or snapshots beyond approved retention periods. Ensure data lifecycle sovereignty including secure deletion.

## Control Description
Backup systems shall enforce retention policies and automatically delete expired backups and snapshots. Deletion shall be verifiable through audit logs.

## Scope
This control ensures that deleted customer data does not persist in backups or snapshots beyond approved retention periods, maintaining data lifecycle sovereignty including secure deletion. The workflow validates:
- Verification that backups exist and are available for deletion
- Confirmation that backup systems are operational and maintaining backups in the sovereign region
- Readiness for deletion operations when retention periods expire
- Geographic verification that backups available for deletion are within the sovereign region

## Expectation
The workflow performs automated compliance checks to ensure:
1. **Backup Existence Verification**: Confirm that backups exist by checking the backup pipeline execution status
2. **Backup Availability for Deletion**: Verify that successful backup pipeline runs indicate backups are available and can be deleted when retention periods expire
3. **Regional Sovereignty Compliance**: Validate that backups available for deletion are stored within the specified CIDR range (sovereign region)
4. **Audit Trail Generation**: Create verifiable OSCAL-compliant audit logs demonstrating backup availability and readiness for deletion
5. **Deletion Readiness**: Confirm that backup systems maintain backups that can be deleted according to retention policies

### Expected Outcomes:
- **Pass**: Backup pipeline runs successfully (backups exist and are available for deletion), backups are within sovereign region
- **Fail**: Backup pipeline missing/failed (no backups available for deletion), or backups outside sovereign region
- **Skip**: For tenant clusters where regional validation is not applicable

## Prerequisites/Dependency

### Required Infrastructure:
1. **OpenShift Cluster**: Running cluster with Tekton pipelines installed
2. **Tekton Pipeline**: Backup pipeline deployed in the specified namespace
3. **Backup Secret**: Kubernetes secret containing backup host configuration for verification
4. **IBM Concert**: Access to Concert API for compliance data upload and audit log storage
5. **Retention Policy Configuration**: Defined retention periods for backup and snapshot lifecycle management

### Required Permissions:
- OpenShift API access with permissions to:
  - List and read PipelineRuns in the specified namespace
  - Read Secrets in the specified namespace
  - Access pipeline execution logs for audit verification
- IBM Concert API authentication key

### Network Requirements:
- DNS resolution capability for backup host lookup
- Network connectivity to OpenShift API server
- Network connectivity to IBM Concert API

## Assumptions
1. The backup pipeline follows the naming convention specified in `backup_pipeline_name` parameter
2. Successful backup pipeline execution indicates that backups exist and are available for deletion
3. The workflow checks the backup pipeline (not a separate deletion pipeline) to verify backup availability
4. Backup secret contains a `BACKUP_HOST` field encoded in Base64 that represents the backup storage location
5. The CIDR range provided accurately represents the sovereign region boundaries
6. Tekton pipeline runs maintain standard status conditions (`Succeeded` type with `True`/`False` status)
7. The backup host is resolvable via DNS and returns a valid internal IP address
8. For tenant clusters, regional validation can be skipped (controlled by `isTenant` flag)
9. Pipeline execution records serve as audit logs for backup availability verification
10. When retention periods expire, backups verified by this workflow can be deleted
11. The workflow verifies that backups maintain sovereignty by being stored within the designated region

## Design

### Workflow Architecture:
The solution consists of three interconnected workflows:

#### 1. **Assessment Upload** (Main Workflow)
- **Purpose**: Orchestrates the entire backup deletion verification compliance assessment process
- **Components**:
  - Input validation
  - Backup existence and availability compliance checks
  - UUID generation for OSCAL identifiers
  - OSCAL assessment result construction with audit evidence
  - Upload to IBM Concert for audit trail persistence

#### 2. **Backup and Snapshot Check** (Validation Workflow)
- **Purpose**: Performs technical validation of backup existence and availability for deletion
- **Validation Steps**:
  1. Retrieve all pipeline runs from the specified namespace
  2. Filter runs matching the backup pipeline name
  3. Verify that backup pipeline has run successfully (confirms backups exist)
  4. Identify the latest run and verify success status (confirms backups are available for deletion)
  5. Retrieve backup secret and decode backup host
  6. Perform DNS lookup to get internal IP address of backup storage location
  7. Validate IP address is within the specified CIDR range to confirm backups are in sovereign region

#### 3. **Generate UUIDs** (Helper Workflow)
- **Purpose**: Generate unique identifiers for OSCAL components
- **Function**: Creates specified number of UUID v4 identifiers for assessment artifacts and audit records

### Compliance Checks:
1. **verify_backup_exist_for_deletion**: Validates that backup pipeline runs successfully, confirming backups exist and are available for deletion
2. **verify_backup_exist_region_for_deletion**: Validates that backups available for deletion are stored within sovereign boundaries

### OSCAL Output Structure:
- Assessment Results with observations serving as audit logs
- Component definitions for sovereign software
- Inventory items with target information
- Assessment assets (validator information)
- Evidence collection with:
  - Backup existence verification
  - Backup availability for deletion
  - Pipeline run details serving as audit trail
  - Regional sovereignty verification

## Input

### Required Parameters:

| Parameter | Type | Description | Default Value |
|-----------|------|-------------|---------------|
| `environment` | string | Target environment identifier | - |
| `profile_name` | string | Compliance profile name | - |
| `ocp_host` | string | OpenShift cluster API host URL | - |
| `ocp_bearer_token` | string | OpenShift bearer token for authentication | - |
| `ocp_namespace` | string | Kubernetes namespace for backup pipelines | `"openshift-pipelines"` |
| `backup_pipeline_name` | string | Name of the backup pipeline to validate | `"sovereign-cloud-backup-v1"` |
| `backup_secret_name` | string | Name of the Kubernetes secret containing backup configuration | `"backup-secret"` |
| `cidr_range` | string | CIDR range representing the sovereign region | - |
| `data_type` | string | Type of data being uploaded to Concert | `"compliance_posture"` |
| `concert_api_auth` | string | IBM Concert API authentication key | - |

### Optional Parameters:

| Parameter | Type | Description | Default Value |
|-----------|------|-------------|---------------|
| `isTenant` | boolean | Flag indicating if this is a tenant cluster (skips regional validation) | `false` |

## Output

### Success Response:
The workflow generates an OSCAL-compliant assessment result containing:

#### Assessment Metadata:
- UUID-identified assessment result
- Title: "Backup & Snapshot Deletion Results"
- Timestamp information (start/end) serving as audit timestamp

#### Component Definitions:
- Sovereign Software component with operational status
- Validator component with scanner information

#### Observations (2) - Serving as Audit Logs:
1. **verify_backup_exist_for_deletion**:
   - Result: `pass` or `fail`
   - Evidence: Total backup runs found, latest run name, backup status
   - Severity: high
   - Description: Validates that backup pipeline executed successfully, confirming backups exist and are available for deletion when retention periods expire
   - Audit Information: Pipeline execution details demonstrating backup availability

2. **verify_backup_exist_region_for_deletion**:
   - Result: `pass` or `fail`
   - Evidence: Backup storage location, internal IP, CIDR range validation
   - Severity: high
   - Description: Validates that backups available for deletion are stored within the sovereign region
   - Audit Information: Geographic verification of backup storage location

#### Inventory Items:
- Target environment information
- Network policy details
- Finding count

### Output Variables:

| Variable | Type | Description |
|----------|------|-------------|
| `result` | object | Complete OSCAL assessment result uploaded to Concert (serves as audit log) |
| `backup_exist` | string | Status of backup existence check (`pass`/`fail`) - indicates backups are available for deletion |
| `backup_exist_in_region` | string | Status of regional validation for backups (`pass`/`fail`) |
| `total_runs` | number | Total number of backup pipeline runs found (audit trail count) |
| `latest_run` | string | Name of the most recent backup pipeline run (latest audit entry) |
| `backup_status` | string | Status of the latest backup run (`SUCCESS`/`FAILED`) |
| `backup_host` | string | Decoded backup host from secret (backup storage location) |
| `backup_ip_address` | array | Internal IP address(es) of backup host |
| `backup_in_region` | boolean | Boolean indicating if backups are in sovereign region |
| `secret_found` | boolean | Boolean indicating if backup secret was found |
| `skippedDueToTenant` | boolean | Boolean indicating if validation was skipped for tenant cluster |

### Error Handling:
- **400 Bad Request**: Missing required input fields (detailed error message lists missing fields)
- **Failed Validation**: Assessment results will show `fail` status with evidence details
- **Tenant Cluster Skip**: Regional validation skipped with `skip` status when `isTenant=true`
- **Secret Not Found**: If backup secret is not found, regional validation will fail
- **No Backups Found**: If backup pipeline hasn't run successfully, verification will fail

### Concert Upload - Audit Log Persistence:
The assessment result is uploaded to IBM Concert as a JSON file with:
- Data type: `compliance_posture`
- Format: OSCAL Assessment Results (serves as verifiable audit log)
- Authentication: Concert API key
- Purpose: Persistent audit trail demonstrating backup availability for deletion and retention policy compliance

---

## Usage Example

```json
{
  "environment": "production-eu",
  "profile_name": "sovereign-compliance-profile",
  "ocp_host": "https://api.cluster.example.com:6443",
  "ocp_bearer_token": "sha256~xxxxx",
  "ocp_namespace": "openshift-pipelines",
  "backup_pipeline_name": "sovereign-cloud-backup-v1",
  "backup_secret_name": "backup-secret",
  "cidr_range": "10.0.0.0/8",
  "data_type": "compliance_posture",
  "concert_api_auth": "concert-api-key",
  "isTenant": false
}
```

## Compliance Verification

This workflow ensures compliance with ISCF-DR-08 by:

1. **Backup Existence Verification**: Confirming that backups exist by checking backup pipeline execution status
2. **Deletion Readiness**: Verifying that successful backup pipeline runs indicate backups are available and can be deleted when retention periods expire
3. **Audit Trail Creation**: Generating OSCAL-compliant assessment results that serve as verifiable audit logs
4. **Sovereignty Maintenance**: Ensuring backups available for deletion are stored within sovereign region boundaries
5. **Lifecycle Management**: Validating that backup systems maintain backups that can be managed according to retention policies
6. **Deletion Capability**: Confirming that backups exist and are accessible for deletion operations when needed

The workflow provides evidence that:
- Backups exist in the system and are available for deletion
- Backup systems are operational and maintaining backups in the sovereign region
- Backups can be deleted according to retention policies when periods expire
- All backup operations maintain data sovereignty requirements
- Deletion is verifiable through audit logs stored in IBM Concert