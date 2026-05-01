# ISCF-OP-02: Offline Deployment Capability

## Overview

This workflow implements offline deployment capability compliance checks for the Sovereign Control Framework. It validates that an OpenShift cluster can operate in an air-gapped/offline environment using local container registries without external dependencies.

## Control Details

**Control ID:** ISCF-OP-02

**Control Name:** Offline Deployment Capability

**Control Synopsis:** The MSP must ensure that the sovereign cloud platform can be deployed and operated in an air-gapped/offline environment without requiring external network connectivity for core functionality.

**Control Description:** This control validates that an OpenShift cluster is configured to operate in a fully offline/air-gapped mode by verifying:
1. Local container registry availability and population
2. Image Content Source Policy (ICSP) or Image Digest Mirror Set (IDMS) configuration for mirroring external registries
3. Pod workloads pulling images exclusively from local registries

The control ensures sovereign cloud deployments can maintain operational independence from external dependencies, meeting data residency and security requirements.

**Control Check:** The workflow performs three primary validation checks:


#### Input Validation**: Validates all required parameters are provided

#### Check 1: Local Registry Catalog
- ✅ Registry route exists in `quay-enterprise` namespace
- ✅ Catalog endpoint (`/v2/_catalog`) is accessible
- ✅ Catalog contains > 0 repositories

#### Check 2: ICSP/IDMS Configuration
- ✅ IDMS/ICSP policies exist
- ✅ Policies mirror ALL of: quay.io, docker.io, registry.redhat.io
- ✅ Mirrors point to local Quay Enterprise registry

#### Check 3: Pod Image Sources
- ✅ ≥95% of images pulled from local registry
- ✅ Checked across all namespaces
- ✅ Includes both regular containers and init containers


#### Required Inputs

**Cluster-Specific (Must be updated for your environment):**
- `ocp_token` (authentication, required): OpenShift authentication token for your cluster
- `ocp_server` (string, required): OpenShift API server URL for your cluster (e.g., "https://api.your-cluster.example.com:6443")
- `local_registry_url` (string, required): Local Quay registry hostname for your cluster (e.g., "registry-quay-quay-enterprise.apps.your-cluster.example.com")
- `concert_auth_key` (authentication, required): concert authentication reference (e.g: "gori-admin/concert_auth_keyy")

**Standard Inputs (Can use defaults):**
- `environment` (string, optional): Target environment identifier (e.g., "production")
- `profile_name` (string, optional): Compliance profile name (e.g., "profile_sovereign")

**Control Output:** 
- Detailed compliance assessment results in OSCAL format
- Pass/fail status for each validation check
- Percentage of images using local registry
- OSCAL assessment uploaded to IBM Concert


### UUID Generation: Generates unique identifiers for OSCAL objects

**Control Pass/Fail:** 
- **PASS:** All three checks succeed (100% pass rate required)
- **FAIL:** Any check fails or <95% of images use local registry

### Assessment Creation: Builds OSCAL-compliant assessment-results document

### Upload to Concert
- Uploads the OSCAL assessment result to IBM Concert
- Data type: `compliance_posture`
- Format: JSON

- **Observations** (2 compliance checks):
     - Result: pass/fail
