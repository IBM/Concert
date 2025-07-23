# Concert workflows samples

This folder contains some workflows that can be imported into a Concert Workflows instance.

To import a workflow, follow [these instructions][00].

## Available workflows

### trivy-github-scan

Fetches a GitHub repository, performs a scan using [trivy][01], and submits the resulting
[CycloneDX][02] report to Concert.

Once imported, this workflow can be manually triggered from your Concert Workflows instance.
The parameters for the workflow are:

| Name                     | Type     | Description                                                                             |
|--------------------------|----------|-----------------------------------------------------------------------------------------|
| `gh_repo_url`            | Required | URL to the GitHub repository to be scanned                                              |
| `gh_api_token`           | Optional | Authentication token, only needed for private repositories                              |
| `concert_url`            | Required | URL of the Concert API gateway                                                          |
| `concert_api_key `       | Required | API Key to authenticate upon Concert                                                    |
|` concert_instance_id `   | Required | Instance ID to which the report will be uploaded                                        |
| `concert_allow_insecure` | Optional | Disables TLS certificate validation (useful is Concert instance uses self-signed certs) |

A good repository to test this workflows is [golang/mock][03]

**Link to the workflow:** [trivy-github-scan](./trivy-github-scan.zip)

[//]: # ( ------------------- Place references below this line ------------------- )

[00]: https://www.ibm.com/docs/en/rapid-network-auto/1.1.x?topic=workflows-importing-exporting
[01]: https://github.com/aquasecurity/trivy
[02]: https://github.com/CycloneDX
[03]: https://github.com/golang/mock
