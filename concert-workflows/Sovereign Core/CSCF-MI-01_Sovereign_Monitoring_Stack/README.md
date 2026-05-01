# Sovereign Monitoring Stack Sovereignty:
This workflow checks for ISCF-MI-01 : Sovereign Monitoring Stack Sovereignty Control and uploads the assessed data to concert to bring up a compliance posture.

# Workflow logic: 
The workflow checks whether Prometheus, Loki, Thanos, and Perses are deployed locally. Prometheus , Perses and thanos Pods are check whether installed in the Cluster Observability Operator . Loki Pod is checked in Loki Operator. These Operators are checked in the global namespace of openshift-operators.
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
- *ocp_bearer_auth* : This is Bearer Token Authentication.
    - Navigate to Workflows > Authentications and create an API key for Openshift cluster.
    - Provide the created authentication in the ocp_bearer_auth input variable.
- **Input Variable Details**:
- *profile_name*: Compliance Profile created/default is profile_sovereign.
- *Environment*: Environment created/default is production.
- *ocp_namespace*: Custom Openshift namespace . Default : openshift-operators 
- *list_ocp_operator_names*: can provide list of custom operators
- *ocp_url*: provide complete ocp cluster host url with port eg : https://<OCP_HOST>:<OCP_PORT>

# Assumption and Rules Explained:
    Prometheus, Loki, Thanos, and Perses operators should be pre installed in the res