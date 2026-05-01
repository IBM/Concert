ISCF-DR-01: REGION Data Residency
Control Name

ISCF-DR-01: REGION Data Residency

This control ensures that all storage resources and associated
infrastructure are confined within an approved REGION by validating
network boundaries (CIDR ranges) and storage endpoint configurations.

Scope

This control applies to storage infrastructure within the OpenShift
environment, specifically:

StorageClasses used for persistent storage provisioning
ODF (OpenShift Data Foundation) configuration
Worker node network placement (Internal IPs)
REGION boundary definition via CIDR ranges

The workflow validates whether storage provisioning and underlying
infrastructure operate strictly within approved REGION network
boundaries.

The final compliance result is uploaded to Concert for posture tracking.

Expectation

All storage resources must be REGION-resident.

Specifically:

Worker node Internal IPs must fall within approved REGION CIDR
ranges.
Storage classes must indirectly map only to REGION-compliant
infrastructure.
No storage resource should be backed by nodes outside the approved
CIDR boundary.
REGION boundary is enforced using CIDR-based validation logic.

Compliance is achieved only when all evaluated nodes and storage
mappings fall within the allowed REGION network range.

Prerequisites / Dependencies

The following resources must exist before executing the workflow:

A Compliance Catalog created in Concert.
A Compliance Profile created using the catalog.
An Environment defined in Concert.
OpenShift cluster with:
Worker nodes
StorageClasses configured
ODF deployed (if applicable)
Network CIDR definition available via pipeline variable
(GORI_NETWORK).

Required authentications:

OpenShift authentication (ocp_auth)
OpenShift bearer token (ocp_bearer_auth)
Cluster API hostname (hostname)
Concert authentication (concert_auth_key) (optional for
Concert version 2.2.0 and above)
Assumptions

The workflow assumes:

Worker nodes expose InternalIP via Kubernetes API.
REGION boundary is defined using a valid CIDR (e.g., 10.x.x.x/16).
The pipeline provides GORI_NETWORK dynamically at runtime.
All storage traffic is routed through worker nodes being evaluated.
No external storage endpoints bypass node-level enforcement.
Kubernetes API responses are consistent and accessible.
Design

The workflow performs network-based REGION validation using CIDR
checks.

High-level Workflow Steps
Fetch ODF ConfigMap (if present)
$get_odf_cm
Used to validate presence of storage configuration context
Conditional validation
Proceed only if:
$get_odf_cm != null
$get_odf_cm.result.data != null
$get_odf_cm.result.data.data != null
Retrieve StorageClasses
API:
GET /apis/storage.k8s.io/v1/storageclasses
Fetch REGION boundary
Source: Pipeline variable GORI_NETWORK
Example:
10.0.0.0/16
Perform CIDR Validation
Convert IP → numeric
Compare against CIDR range
Logic ensures:
All node IPs ∈ GORI_NETWORK
Aggregate Results
If all nodes pass → PASS
If any node fails → FAIL
Upload Result to Concert
OSCAL-compliant assessment result



Input

Input Description

profile_name Compliance profile name in Concert

environment Target environment for compliance result

ocp_namespace Namespace for ODF ConfigMap lookup

hostname OpenShift cluster API endpoint

ocp_auth OpenShift authentication reference

ocp_bearer_auth Bearer token for Kubernetes API access

GORI_NETWORK REGION CIDR range (pipeline-provided)

concert_auth_key Concert authentication key (optional)




Output

The workflow produces a compliance status and uploads it to Concert.

PASS
All worker node Internal IPs fall within the defined REGION CIDR.
Storage infrastructure is fully REGION-resident.

This confirms that data residency requirements are enforced at the
network level.

FAIL
One or more node IPs fall outside the REGION CIDR.

This indicates that:

Infrastructure is partially outside REGION, or
Incorrect CIDR configuration, or
Misaligned cluster networking setup

The result is uploaded to Concert as an OSCAL assessment result for
the specified environment.

Key Validation Principle

This control enforces data residency indirectly via infrastructure
locality:

If compute nodes are within REGION network boundaries, then storage
provisioned on those nodes is also REGION-resident.
