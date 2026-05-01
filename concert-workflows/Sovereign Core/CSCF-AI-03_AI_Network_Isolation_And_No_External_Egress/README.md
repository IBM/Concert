# AI Network Isolation & No External Egress

**Control ID:** ISCF-AI-03  
**Control Name:** AI Network Isolation & No External Egress  

## Control Synopsis
AI workloads do not communicate with external networks except explicitly approved sovereign endpoints. Prevent AI workloads from transferring data outside the sovereign boundary.

## Control Description
Network controls restrict AI workloads from accessing external services. Allowed endpoints are limited to approved internal services and sovereign infrastructure components.

## Control Check
- Checks for deny-all egress/ingress policies **and** additional explicit allow policies in AI namespaces  
- Verifies egress firewall configurations exist  

## Control Output

### PASS
- All AI namespaces have deny-all network policies configured  
- Additional explicit allow policies exist for approved traffic  
- Egress firewall rules are configured in AI namespaces  

### FAIL
- Missing deny-all network policies in AI namespaces  
- No additional network policies for allowed traffic  
- No egress firewall configurations found  

## Control Pass/Fail
**Pass**

---

## Overview
This workflow checks for **ISCF-AI-03: AI Network Isolation & No External Egress Control** and uploads the assessed data to Concert to provide a compliance posture.

## Prerequisites
1. A compliance catalog must exist  
2. A profile must be created using the catalog (default: `profile_sovereign`)  
3. An environment must be created (default: `production`)  
4. OpenShift cluster with OVN networking for egress firewall support  

## Required Authentication

### 1. concert_auth_key
- Navigate to **Workflows → Authentications → Create IBM Hub Self Auth**  
- Provide the created authentication in the `concert_auth_key` input variable  

### 2. ocp_auth
- Navigate to **Workflows → Authentications → Create OpenShift Authentication**  
- Provide:
  - Host  
  - Port  
  - Protocol  
  - OpenShift API key  
- Assign this to the `ocp_auth` input variable  

### 3. ocp_bearer_auth
- Navigate to **Workflows → Authentications → Create Bearer Token Authentication**  
- Provide the OpenShift API key  
- Assign this to the `ocp_bearer_auth` input variable  

## Input Variable Details

1. **profile_name**
   - Compliance profile name  
   - Default: `profile_sovereign`  

2. **environment**
   - Environment name  
   - Default: `prod`  

3. **hostname**
   - OpenShift cluster API endpoint with port  
   - Example: `https://api.cluster.example.com:6443`  

4. **list_of_included_namespaces_network_policies**
   - Array of AI namespace names to check for network policies  
   - Example: `["concert", "ai-workload"]`  

5. **list_of_included_namespaces_firewall**
   - Array of namespace names to check for egress firewalls  
   - Example: `["concert", "ai-workload"]`  

## Output
The workflow validates AI network isolation controls and generates compliance status:

- **PASS:** All AI namespaces have proper network policies and egress firewall configurations  
- **FAIL:** Missing network policies or egress firewall rules in AI namespaces