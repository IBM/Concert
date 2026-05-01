# Customer control to audit and evidence Sovereignty:
This workflow checks for CSCF-TRN-03 : Customer Control over Identity & Access Sovereignty Control and uploads the assessed data to concert to bring up a compliance posture.

# Workflow logic: 
The workflow have three sub workflows of validation checks they are Configuration changes , User activity and MFA is detected. The configuration changes check if there are any policy been changed through config pod logs. The User activity check if there are any user is trying to authenticate through config pod logs. The MFA Detected check if mfa is enabled or not through runtime pod logs. 
- **Environment linkage**: Compliance postures are linked to specific Environment in Concert. So, it is an input for the Workflow.
- **Compliance Profile**: A profile must be created on concert to upload posture; this is also an input for the Workflow.
- **Rules and Checks**: These are done based on standards and procedures followed by the IBM Sovereign Core team.
- **Data upload**: Generated posture is uploaded to concert.
## Prerequisite:
- There must be a Compliance catalog.
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
- *ocp_namespace*: Custom Openshift namespace 

# Assumption and Rules Explained:
  For Customer Control over Identity & Access is by checking config changes , user activity and mfa is detected in the pod logs of msp-ibm-verify 

