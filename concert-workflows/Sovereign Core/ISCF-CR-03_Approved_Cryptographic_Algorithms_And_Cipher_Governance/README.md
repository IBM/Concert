# ISCF-CR-03: Approved Cryptographic Algorithms & Cipher Governance

## Control Name

**ISCF-CR-03: Approved Cryptographic Algorithms & Cipher Governance**

This control ensures that cryptographic algorithms, key sizes, and cipher suites used within the environment comply with approved governance policies and industry standards, preventing weak or deprecated cryptography.

------------------------------------------------------------------------

## Scope

This control applies to all components within the platform that handle cryptographic operations, including:

- Web servers and ingress controllers  
- Application services that use TLS/SSL  
- Internal services exchanging encrypted data  
- Any service storing or transmitting sensitive information  

The workflow evaluates whether:

- Only approved cryptographic algorithms and ciphers are in use  
- Deprecated or weak algorithms (e.g., TLS 1.0, RC4, 3DES) are prohibited  
- The configuration aligns with recognized national or regional guidance (e.g., BSI, ANSSI)  

The compliance result is uploaded to Concert to establish the security posture of the environment.

------------------------------------------------------------------------

## Expectation

The platform must enforce cryptography governance according to approved standards:

- Weak or deprecated cipher suites must not be enabled.  
- Minimum TLS version must meet organizational policy (TLS 1.2+).  
- Only explicitly approved algorithms for encryption, hashing, and key exchange may be used.  
- Configuration deviations should be detected and logged.  

Presence of compliant algorithms and ciphers confirms the environment enforces cryptographic security and reduces risk of data compromise.

------------------------------------------------------------------------

## Prerequisites / Dependencies

The following resources must exist before executing the workflow:

- A **Compliance Catalog** created in Concert.  
- A **Compliance Profile** created using the catalog.  
- A **Target Environment** defined in Concert.  
- Components (e.g., web servers, ingress, applications) configured with TLS.  
- Access to OpenShift cluster or service configurations where TLS/cipher settings are defined.  

Required authentications:

- **OpenShift authentication (`ocp_auth`)**  
- **Concert authentication (`concert_auth_key`)** (optional for Concert version 2.2.0 and above)  

------------------------------------------------------------------------

## Assumptions

The workflow assumes:

- TLS configurations are correctly applied on the components being evaluated.  
- Logs or configuration endpoints exposing cipher information are accessible.  
- The platform allows retrieval of TLS versions and cipher suite information.  
- Cryptography policies are defined and available for reference during evaluation.  

------------------------------------------------------------------------

## Design

The workflow performs automated checks of cryptography configurations to validate compliance:

High-level workflow steps:

1. Retrieve TLS/cipher configurations from components in the specified namespaces.  
2. Parse the configurations to extract supported TLS versions and cipher suites.  
3. Compare extracted algorithms and ciphers against the approved list defined in the cryptography policy.  
4. Identify weak, deprecated, or unapproved algorithms.  
5. Determine compliance status.  
6. Upload the compliance result to Concert as an OSCAL-compliant assessment result.  

------------------------------------------------------------------------

## Input

  -----------------------------------------------------------------------
  Input                  Description
  ---------------------- ------------------------------------------------
  profile_name           Compliance profile name in Concert  

  environment            Target environment where the compliance posture
                         will be recorded  

  targetNamespaces       List of Kubernetes/OpenShift namespaces to evaluate
                         TLS/cipher configurations (e.g., ["vault", "vault-prod", "hashicorp-vault"])  

  weakCiphers            List of weak or deprecated cipher suites to check
                         against the target components (see example below)  

  ocp_auth               OpenShift authentication used to retrieve TLS/cipher configurations  

  concert_auth_key       Concert authentication key used to upload assessment results
  -----------------------------------------------------------------------

Example defaults:

profile_name: profile_sovereign  
environment: production  
targetNamespaces: ["vault", "vault-prod", "hashicorp-vault"]  
weakCiphers:  
```
[
  "TLS_RSA_WITH_RC4_128_SHA",
  "TLS_RSA_WITH_RC4_128_MD5",
  "TLS_ECDHE_RSA_WITH_RC4_128_SHA",
  "TLS_RSA_WITH_3DES_EDE_CBC_SHA",
  "TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA",
  "TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA",
  "TLS_RSA_WITH_DES_CBC_SHA",
  "TLS_RSA_WITH_NULL_SHA",
  "TLS_RSA_WITH_NULL_MD5",
  "TLS_RSA_EXPORT_WITH_RC4_40_MD5",
  "TLS_RSA_EXPORT_WITH_DES40_CBC_SHA",
  "TLS_RSA_WITH_AES_128_CBC_SHA",
  "TLS_RSA_WITH_AES_256_CBC_SHA",
  "TLS_RSA_WITH_AES_128_CBC_SHA256",
  "TLS_RSA_WITH_AES_256_CBC_SHA256",
  "TLS_DH_anon_WITH_AES_128_CBC_SHA",
  "TLS_DH_anon_WITH_AES_256_CBC_SHA"
]
```

Output

The workflow produces a compliance status and uploads it to Concert.

PASS

All cryptographic algorithms, key sizes, and cipher suites are approved and no weak/deprecated ciphers are detected.
This confirms that cryptography governance is enforced correctly in the environment.

FAIL

One or more weak, deprecated, or unapproved algorithms/ciphers are detected.
This indicates that:

Cryptography policies are not enforced, or

Misconfigured services may expose security vulnerabilities.