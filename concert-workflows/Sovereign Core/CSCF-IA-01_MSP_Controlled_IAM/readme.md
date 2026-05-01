# MSP-Controlled IAM Sovereignty:
This workflow checks for ISCF-IA-01: MSP-Controlled IAM Sovereignty Control and uploads the assessed data to concert to bring up a compliance posture.

# Workflow logic: 
The workflow checks whether the ibm verify route is pointing to account-iam service . If then its been proceed to check if the account iam service in boundary by checking whether they have clusterIp address.
- **Environment linkage**: Compliance postures are linked to specific Environment in Concert. So, it is an input for the Workflow.
- **Compliance Profile**: A profile must be created on concert to upload posture; this is also an input for the Workflow.
- **Rules and Checks**: These are done based on standards and procedures followed by the IBM Sovereign Core team.
- **Data upload**: Generated posture is uploaded to concert.
## Prerequisite:
- There must be Compliance catalog.
- A profile must be created using the catalog (default profile created is profile_sovereign).
- Environment must be created (default environment is production)
- **Required Authentication and Inputs**:
- *concert_auth_key* : This is Optional for concert 2.2.0 and above.
    - Navigate to Workflows > Authentications and create an API key for Concert.
    - Provide the created authentication in the concert_auth_key input variable.
- *ocp_auth* : This is Openshift cluster authentication.
    - Navigate to Workflows > Authentications and create an API key for Openshift cluster.
    - Provide the created authentication in the ocp_auth input variable.
- **Input Variable Details**:
- *profile_name*: Compliance Profile created/default is profile_sovereign.
- *Environment*: Environment created/default is production.
- *ocp_namespace*: Custom Openshift namespace . Eg. msp-ibm-verify

# Assumption and Rules Explained:
  For MSP-Controlled IAM the check is whether the ibm verify route is pointing to account-iam service and check if account iam service is in boundary. 

