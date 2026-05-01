# Inter-Namespace Data Flow Control

## Control Information

**Control ID:** ISCF--DR-04

**Control Name:** Inter-Namespace Data Flow Control

**Control Synopsis:** Data flows between namespaces SHALL be explicitly restricted to approved paths. Prevent lateral movement and cross-tenant data exposure.

**Control Description:** Namespace segmentation SHALL be enforced using Kubernetes Network Policies and RBAC restrictions. Cross-namespace communication SHALL only occur through explicitly defined service endpoints.

**Control Check:** There are two checks for this control:
1. Check network policies of all namespaces for default deny and controlled allow list
2. Check for EgressFirewall enable and controlled allow list

**Control Output:** All namespaces must have network policies with default deny and all namespaces must have EgressFirewall.

**Control Pass/Fail:** Pass if both conditions are met:
- All non-system namespaces have network policies with default-deny posture and controlled allow list for inter-namespace communication
- At least one namespace has an EgressFirewall configured with controlled allow list

## Overview

This IBM Concert workflow validates inter-namespace data flow controls in OpenShift clusters to ensure compliance with sovereignty requirements. The workflow performs automated checks on Network Policies and Egress Firewalls to verify that proper controls are in place to restrict and monitor data movement between namespaces, preventing unauthorized lateral data movement within the cluster.

## Purpose

The workflow performs automated compliance checks to verify that:
- Network Policies implement proper deny-all posture with selective allow rules for inter-namespace communication
- Egress Firewalls are configured to control outbound traffic from namespaces
- All non-system namespaces have appropriate controls to prevent unauthorized data flow
- Data sovereignty is maintained through proper namespace isolation and traffic restrictions

## Workflow Components

### Main Workflow: `AssessmentUpload.json`

Orchestrates the complete inter-namespace data flow control assessment and uploads results to IBM Concert in OSCAL format.

**Key Steps:**
1. **Validate Inputs** - Ensures all required parameters are provided
2. **Generate UUIDs** - Creates unique identifiers for OSCAL components
3. **Network Policy Check** - Validates network policy configurations for namespace isolation
4. **Egress Firewall Check** - Verifies egress firewall existence and configuration
5. **Format OSCAL Results** - Structures findings in OSCAL Assessment Results format
6. **Upload to Concert** - Submits compliance data to IBM Concert platform

**Required Input Variables:**
- `Hostname` - OpenShift cluster hostname with port (e.g., "api.cluster.example.com:6443")
- `ocp_auth` - OpenShift authentication credentials
- `ocp_bearer_auth` - Bearer token for API authentication
- `concert_auth_key` - IBM Concert API authentication key
- `environment` - Environment identifier (e.g., "production")
- `profile_name` - Compliance profile name (default: "profile_sovereign")
- `list_of_ingnored_namespaces_network_policies` - Array of namespaces to exclude from network policy checks
- `list_of_ingnored_namespaces_firewall` - Array of namespaces to exclude from firewall checks

**Default Ignored Namespaces:**
```json
{
  "network_policies": [
    "openshift",
    "kube",
    "default",
    "concert",
    "faas",
    "netobserv",
    "product",
    "tenant",
    "vault",
    "metallb",
    "ibm"
  ],
  "firewall": [
    "openshift",
    "kube",
    "default",
    "concert",
    "faas",
    "netobserv",
    "tenant",
    "vault",
    "metallb",
    "ibm"
  ]
}
```

**Output Variables:**
- `result` - Assessment upload result from IBM Concert

### Sub-Workflow: `NetworkEgressNetworkPolicy.json`

Validates Network Policy configurations across all namespaces to ensure proper inter-namespace isolation.

**Validation Logic:**
The workflow checks for a proper "deny-by-default" security posture by verifying:

1. **Deny Posture** - One of the following must exist:
   - Both "egress-deny-all" AND "ingress-deny-all" policies
   - OR a "deny-traffic" policy

2. **Additional Rules** - At least one additional policy with:
   - "egress" OR "ingress" in the name
   - That is NOT one of the deny-all policies
   - These represent controlled allow-list rules for authorized inter-namespace communication

**Required Input Variables:**
- `ocp_auth` - OpenShift authentication
- `concert_auth_key` - IBM Concert API key
- `list_of_ingnored_namespaces_network_policies` - Namespaces to exclude

**Output Variables:**
- `EgressDisabledFlag` - "pass" if all namespaces have proper policies, "fail" otherwise
- `list_of_egress_status` - Array of boolean values for each namespace
- `regex_string` - Generated regex pattern for namespace filtering

**Pass Criteria:**
- All non-ignored namespaces must have:
  - A deny-all posture (egress-deny-all + ingress-deny-all OR deny-traffic)
  - At least one additional egress or ingress policy for controlled communication

### Sub-Workflow: `NetworkEgressFirewall.json`

Validates Egress Firewall configurations across all namespaces to control inter-namespace and external traffic.

**Key Steps:**
1. **List Projects** - Retrieves all OpenShift projects/namespaces
2. **Filter Namespaces** - Excludes system and ignored namespaces using regex
3. **Check Firewalls** - Queries for EgressFirewall resources in each namespace
4. **Count Firewalls** - Tracks namespaces with configured firewalls
5. **Determine Result** - Returns "pass" if any firewalls exist, "fail" otherwise

**Required Input Variables:**
- `Hostname` - OpenShift cluster hostname with port
- `ocp_bearer_auth` - Bearer token authentication
- `ocp_auth` - OpenShift authentication
- `list_of_ingnored_namespaces_firewall` - Namespaces to exclude

**Output Variables:**
- `result` - "pass" if firewalls exist, "fail" otherwise
- `namespace_with_firewall` - Count of namespaces with egress firewalls

**API Endpoint Used:**
- `/apis/k8s.ovn.org/v1/namespaces/{namespace}/egressfirewalls`

### Helper Workflow: `Generate_uuids.json`

Utility workflow that generates multiple UUID v4 identifiers for OSCAL component tracking.

**Input:**
- `number_of_uuids` - Number of UUIDs to generate (default: 10)

**Output:**
- `result` - Array of generated UUIDs

## Installation

1. Extract the workflow package:
   ```bash
   unzip flows_export_2026-02-19_12_00_16.zip
   ```

2. Import workflows into IBM Concert:
   - Import `AssessmentUpload.json` as the main orchestration workflow
   - Import `NetworkEgressNetworkPolicy.json` as a sub-workflow
   - Import `NetworkEgressFirewall.json` as a sub-workflow
   - Import `Helpers/Generate_uuids.json` as a helper workflow

## Usage

### Running the Assessment

Execute the `AssessmentUpload` workflow with the following parameters:

```json
{
  "Hostname": "api.cluster.example.com:6443",
  "ocp_auth": "<openshift-credentials>",
  "ocp_bearer_auth": "<bearer-token>",
  "concert_auth_key": "<concert-api-key>",
  "environment": "production",
  "profile_name": "profile_sovereign",
  "list_of_ingnored_namespaces_network_policies": [
    "openshift",
    "kube",
    "default",
    "concert",
    "faas",
    "netobserv",
    "product",
    "tenant",
    "vault",
    "metallb",
    "ibm"
  ],
  "list_of_ingnored_namespaces_firewall": [
    "openshift",
    "kube",
    "default",
    "concert",
    "faas",
    "netobserv",
    "tenant",
    "vault",
    "metallb",
    "ibm"
  ]
}
```

### Expected Results

**Pass Scenario:**
- All non-system namespaces have proper network policies (deny-all + additional allow rules)
- At least one namespace has an egress firewall configured
- Both checks return "pass"
- Inter-namespace communication is explicitly controlled

**Fail Scenario:**
- One or more namespaces lack proper network policies
- OR no egress firewalls are configured
- Either check returns "fail"
- Potential for unauthorized inter-namespace data flow

## Technical Details

### Network Policy Validation Algorithm

```javascript
const checkNetworkSecurity = (policies) => {
    // Helper to check if a name contains all provided keywords
    const matchesAll = (name, keywords) => {
        const lowerName = name.toLowerCase();
        return keywords.every(word => lowerName.includes(word));
    };

    // 1. Identify specific "Deny" policies
    const hasEgressDenyAll = policies.some(p => 
        matchesAll(p.metadata.name, ['egress', 'deny', 'all'])
    );
    const hasIngressDenyAll = policies.some(p => 
        matchesAll(p.metadata.name, ['ingress', 'deny', 'all'])
    );
    const hasDenyTraffic = policies.some(p => 
        matchesAll(p.metadata.name, ['deny', 'traffic'])
    );

    // 2. Determine if the "Deny Posture" condition is met
    const isDenyPostured = (hasEgressDenyAll && hasIngressDenyAll) || hasDenyTraffic;

    // 3. Check for "Additional" policies (Egress OR Ingress)
    const hasAdditional = policies.some(p => {
        const name = p.metadata.name.toLowerCase();
        const isDenyMarker = matchesAll(name, ['egress', 'deny', 'all']) || 
                             matchesAll(name, ['ingress', 'deny', 'all']) || 
                             matchesAll(name, ['deny', 'traffic']);
        return !isDenyMarker && (name.includes('egress') || name.includes('ingress'));
    });

    // Final result: True only if we have the Deny setup AND at least one additional rule
    return isDenyPostured && hasAdditional;
};
```

### Namespace Filtering

Both workflows use regex-based filtering to exclude system namespaces:

```javascript
const keywords = $list_of_ingnored_namespaces;
$regex_string = keywords.join('|');

// Check if namespace should be processed
if (!new RegExp($regex_string, "i").test(namespace_name)) {
    // Process this namespace
}
```

### OSCAL Compliance Format

Results are formatted according to OSCAL Assessment Results schema with two observations:

1. **Network Policy Observation**
   - ID: `verify_default_deny_network_policy_namespaces`
   - Severity: high
   - Result: pass/fail based on policy validation
   - Focus: Inter-namespace isolation controls

2. **Egress Firewall Observation**
   - ID: `verify_egress_firewall_exists_namespace`
   - Severity: high
   - Result: pass/fail based on firewall existence
   - Focus: Namespace-level egress controls

### API Endpoints Used

- `/apis/project.openshift.io/v1/projects` - List all projects
- `/apis/networking.k8s.io/v1/namespaces/{namespace}/networkpolicies` - Get network policies
- `/apis/k8s.ovn.org/v1/namespaces/{namespace}/egressfirewalls` - Get egress firewalls

## Dependencies

- **OpenShift Cluster**: Version 4.x with OVN-Kubernetes networking
- **Network Policies**: Kubernetes NetworkPolicy resources
- **Egress Firewalls**: OVN-Kubernetes EgressFirewall CRDs
- **IBM Concert**: Platform for compliance data ingestion
- **Network Access**: API access to OpenShift cluster

## Troubleshooting

### Common Issues

1. **Network Policy Check Fails**
   - Verify namespaces have both deny-all policies and additional allow rules
   - Check policy naming conventions match expected patterns
   - Ensure policies are properly applied to namespaces
   - Review inter-namespace communication requirements

2. **Egress Firewall Check Fails**
   - Confirm OVN-Kubernetes is the CNI plugin
   - Verify EgressFirewall CRDs are installed
   - Check that at least one namespace has an EgressFirewall resource
   - Review firewall rules for proper configuration

3. **Authentication Failures**
   - Validate OpenShift bearer token is current and has sufficient permissions
   - Check Concert API key is valid
   - Ensure service account has cluster-reader permissions

4. **Namespace Filtering Issues**
   - Review ignored namespace lists
   - Verify regex patterns are correctly generated
   - Check for typos in namespace names
   - Ensure system namespaces are properly excluded

## Security Considerations

- Bearer tokens and API keys should be stored securely
- Use service accounts with minimal required permissions (cluster-reader)
- Audit logs should be enabled for compliance tracking
- Network policies should follow principle of least privilege
- Egress firewalls should explicitly allow only required destinations
- Inter-namespace communication should be explicitly authorized
- Default-deny posture prevents unauthorized lateral movement

## Best Practices

### Network Policy Naming Conventions

For proper detection, use these naming patterns:

- **Deny All Egress**: `*egress*deny*all*`
- **Deny All Ingress**: `*ingress*deny*all*`
- **Deny All Traffic**: `*deny*traffic*`
- **Additional Rules**: Include "egress" or "ingress" in the name

### Example Network Policy Structure for Inter-Namespace Control

```yaml
# Deny all traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-traffic
  namespace: app-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Allow specific inter-namespace communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-monitoring
  namespace: app-namespace
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080

---
# Allow egress to specific namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-database
  namespace: app-namespace
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
```

### Example Egress Firewall for Namespace Isolation

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressFirewall
metadata:
  name: default
  namespace: app-namespace
spec:
  egress:
  # Allow DNS
  - type: Allow
    to:
      cidrSelector: 172.30.0.10/32
    ports:
    - protocol: UDP
      port: 53
  # Allow internal cluster communication
  - type: Allow
    to:
      cidrSelector: 10.128.0.0/14
  # Deny all other egress
  - type: Deny
    to:
      cidrSelector: 0.0.0.0/0
```

## Inter-Namespace Communication Patterns

### Secure Communication Flow

1. **Default Deny**: All traffic denied by default
2. **Explicit Allow**: Only authorized inter-namespace communication permitted
3. **Namespace Labels**: Use labels to identify authorized namespaces
4. **Port Restrictions**: Limit communication to specific ports
5. **Protocol Control**: Specify allowed protocols (TCP/UDP)

### Example Authorized Communication

```
Namespace A (Frontend)
  ↓ (allowed via NetworkPolicy)
Namespace B (Backend API)
  ↓ (allowed via NetworkPolicy)
Namespace C (Database)
```

All other inter-namespace communication is blocked by default-deny policies.

## Version Information

- **Workflow Version**: 5
- **Platform**: Node.js
- **Scanner Version**: 1.0.0
- **OSCAL Schema**: Assessment Results format
- **Last Updated**: 2026-02-19

## Support

For issues or questions regarding this workflow:
1. Check IBM Concert documentation
2. Review OpenShift networking documentation
3. Verify OVN-Kubernetes configuration
4. Review namespace isolation requirements
5. Contact your IBM Concert administrator

## License

This workflow is part of IBM Concert compliance automation framework.