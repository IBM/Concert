# IBM Concert - Container Security:

Container Security dimension revolves under auto discovery of golden master images (base images), identification of vulnerabilities and their remediation thereby producing a new remediated version of the image which is then pushed to the remote registry and utilised by its microservices

# Use case specific files:

* Ingest application SBOMs per the files in container_security/app_sboms folder
    - The application SBOMs contain application, repository and microservice image details associated with the application
    - This data is required to load the blast radius page which shows the connection between application, microservices and base image

* Ingest image scan reports corresponding to golden master images
    - Ingest the .csv image scan report from container_security/image_scans folder
    - This data is required to load the cve details and subsequent actions for remediation

Note:- The sample files attached are for reference. There are workflows available in automation library that are specific to container security and serve the end to end flow of auto discovery of images, generating cve results, actions and applying the patch for remediation