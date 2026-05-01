# CSCF-DR-09: Cross-Tenant Data Exposure Prevention

## Control Name
CSCF-DR-09: Cross-Tenant Data Exposure Prevention

## Scope
Validates storage class isolation across operational accounts to prevent cross-tenant data exposure.

## Control Expectation
Controls shall continuously validate that data belonging to one tenant cannot be accessed by another tenant. Maintain strict tenant isolation.

## Prerequisites/Dependency
- MSP API accessible at `/xpm/api/v1/accounts/operational`
- Concert Compliance Center with API authentication
- Operational accounts with storage class data
- OpenShift Data Foundation (ODF) or compatible storage backend

## Assumptions
- Concert and MSP deployed on same OpenShift cluster
- Storage classes follow `parameters["storage-class-data"]` format
- Each operational account represents a distinct tenant
- Storage class data provided during account creation

## Design
1. Fetch operational accounts with storage data from MSP API
2. Extract storage classes from `parameters["storage-class-data"]`
3. Detect storage classes shared between multiple accounts
4. Generate OSCAL-compliant assessment results
5. Upload compliance status to Concert

## Input
| Variable | Type | Required | Default |
|----------|------|----------|---------|
| `msp_url` | String | No | `mspui.apps.gori-int-44.cp.fyre.ibm.com` |
| `msp_token` | Authentication | Yes | `""` |
| `environment` | String | Yes | `production` |
| `profile_name` | String | Yes | `profile_sovereign` |
| `concert_auth_key` | Authentication | No | `gori_admin@ibm.com/concertAPIKeyAuth` |

## Output
```json
{
  "compliance_status": "pass|fail",
  "shared_sc_violations": [],
  "account_storage_map": {},
  "assessment_result": {}
}
```

**Status:**
- **PASS**: All accounts have unique storage classes
- **FAIL**: Storage classes shared between accounts