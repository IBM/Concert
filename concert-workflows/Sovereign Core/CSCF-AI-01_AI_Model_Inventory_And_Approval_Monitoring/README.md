# ISCF-AI-01: AI Model Inventory & Approval Monitoring

## Scope
This control ensures that only approved AI models are deployed and operational within the sovereign cloud environment. It validates that all AI models in use are from an authorized list and monitors their deployment status through the AIIaaS broker service.

## Control Expectation
Ensure only authorized AI models operate within the sovereign environment. 

## Control Description
The platform maintains a centralized inventory of deployed AI models including: 

- model name and version 

- deployment location 

- model owner 

Monitoring processes detect unauthorized model deployments. 

## Overview
The workflow validates compliance by:
- Verifying that only approved AI models are available in the system
- Confirming that deployed container images correspond to approved models
- Generating OSCAL-compliant assessment reports
- Uploading compliance results to IBM Concert for centralized monitoring

**Compliance Criteria:**
- All available models must be in the approved models list
- All approved models must have corresponding deployed images in the container registry
- Assessment results must be successfully uploaded to Concert

## Prerequisites/Dependency

### Required Services
1. **AIIaaS Broker Service**: Must be accessible and operational
   - Endpoint: `/v2/models` (list available models)
   - Endpoint: `/v2/quay/images` (list deployed images)

2. **IBM Concert**: For assessment report upload and compliance tracking
   - Valid Concert API authentication key required
   - Data type: `compliance_posture`

### Required Inputs
| Parameter | Type | Required | Description | Default Value |
|-----------|------|----------|-------------|---------------|
| `aiiaas_broker_service_url` | string | Yes | URL of the AI/IaaS service broker | - |
| `approved_models_list` | array | Yes | List of approved AI model names | `["granite-4.0-h-micro"]` |
| `environment` | string | Yes | Target environment identifier | - |
| `profile_name` | string | Yes | Compliance profile name | - |
| `data_type` | string | Yes | Type of data being uploaded | `"compliance_posture"` |
| `concert_auth` | string | Yes | Concert API authentication key | - |

### System Requirements
- Network access to AI/IaaS service broker
- Network access to IBM Concert API
- Appropriate permissions to query model and image registries

## Assumptions

1. **Service Availability**: The AI/IaaS broker service is running and accessible at the provided URL
2. **Authentication**: Valid credentials are provided for both the AI/IaaS broker and Concert
3. **Model Naming Convention**: Model names in the registry match exactly with approved model names
4. **Image Naming Convention**: Deployed container images include the model name in their identifier
5. **API Stability**: The AI/IaaS broker API endpoints (`/v2/models` and `/v2/quay/images`) are stable and return expected response formats
6. **Concert Integration**: IBM Concert is configured to accept compliance assessment uploads
7. **Network Connectivity**: All required services are reachable from the workflow execution environment

## Design

### Workflow Architecture
The solution consists of three interconnected workflows:

#### 1. **Generate_uuids.json**
- **Purpose**: Utility workflow to generate unique identifiers for OSCAL components
- **Logic**: 
  - Accepts number of UUIDs to generate as input
  - Uses a while loop to generate UUID v4 identifiers
  - Returns an array of generated UUIDs

#### 2. **AI_model_inventory_checks.json**
- **Purpose**: Core validation logic for AI model compliance
- **Logic Flow**:
  1. **List Available Models**: GET request to `/v2/models` endpoint
  2. **Validate Response**: Check if status code is 200
  3. **Extract Model Names**: Map model objects to model names
  4. **Approval Check**: Verify all available models are in approved list
  5. **List Deployed Images**: GET request to `/v2/quay/images` endpoint
  6. **Image Validation**: Confirm each approved model has a deployed image
  7. **Compliance Result**: Set result to "pass" or "fail" based on checks

**Validation Logic**:
```
models_found = true IF:
  - available_models.length > 0 AND
  - All models in available_models are in approved_models_list AND
  - All models have corresponding deployed images
```

#### 3. **Assessment_Upload.json**
- **Purpose**: Main orchestration workflow
- **Logic Flow**:
  1. **Input Validation**: Verify all required parameters are provided
  2. **UUID Generation**: Generate 10 UUIDs for OSCAL components
  3. **Model Validation**: Execute AI_model_inventory_checks workflow
  4. **Assessment Report Generation**: Create OSCAL-compliant assessment result
  5. **Upload to Concert**: Submit assessment to IBM Concert

### Error Handling
- **API Failures**: Throws descriptive errors if endpoints return non-200 status codes
- **Missing Inputs**: Validates all required fields and throws 400 Bad Request with missing field list
- **Validation Failures**: Sets compliance result to "fail" and includes details in evidence

## Input

### Workflow Inputs (Assessment_Upload)
```json
{
  "aiiaas_broker_service_url": "https://aiiaas-broker.example.com",
  "approved_models_list": ["granite-4.0-h-micro", "model-name-2"],
  "environment": "production-cluster-01",
  "profile_name": "ISCF-AI-01-Profile",
  "data_type": "compliance_posture",
  "concert_auth": "<Concert API Key>"
}
```

### Sub-workflow Inputs

**AI_model_inventory_checks**:
```json
{
  "aiiaas_service_broker_url": "https://aiiaas-broker.example.com",
  "approved_models_list": ["granite-4.0-h-micro"]
}
```

**Generate_uuids**:
```json
{
  "number_of_uuids": 10
}
```

## Output

### Success Response
```json
{"result":{"record_paths":["_data.json"],"event_ids":[""],"job_data":{"message":"202 Accepted"}}}
```

### Workflow Variables Output

**AI_model_inventory_checks**:
```json
{
  "models_found": true,
  "available_models": ["granite-4.0-h-micro"],
  "deployed_images": ["quay.io/namespace/granite-4.0-h-micro:latest"],
  "models_compliant_result": "pass"
}
```

### OSCAL Assessment Structure

The workflow generates a complete OSCAL Assessment Results document including:
- **Results**: Top-level assessment results container
- **Local Definitions**: Components, inventory items, and assessment assets
- **Observations**: Detailed compliance check results with evidence
- **Properties**: Metadata including scanner info, timestamps, and severity
- **Relevant Evidence**: Expected vs actual values in JSON format

The generated assessment includes:

1. **Observation Result**:
   - `idref`: "verify_only_approved_ai_models_deployed"
   - `result`: "pass" or "fail"
   - `severity`: "high"
   - `time`: ISO 8601 timestamp

2. **Evidence Section**:
   ```json
   {
     "is_compliant": "true",
     "approved_models": ["granite-4.0-h-micro"],
     "models_found": ["granite-4.0-h-micro"],
     "models_deployed_in_cluster": ["quay.io/namespace/granite-4.0-h-micro:latest"]
   }
   ```

3. **Assessment Metadata**:
   - Scanner: "Sovereign Validation"
   - Version: "1.0.0"
   - Method: "checks"
   - Profile ID: As provided in input

### Failure Scenarios

**Unapproved Model Detected**:
```json
{
  "models_compliant_result": "fail",
  "available_models": ["granite-4.0-h-micro", "unauthorized-model"],
  "approved_models_list": ["granite-4.0-h-micro"]
}
```

**Missing Deployed Image**:
```json
{
  "models_compliant_result": "fail",
  "models_found": false,
  "available_models": ["granite-4.0-h-micro"],
  "deployed_images": []
}
```

**API Error**:
```
Error: "Aiiaas broker service list models api endpoint is incorrect."
```

## Execution

### Running the Workflow
1. Ensure all prerequisites are met
2. Configure input parameters with valid values
3. Execute the `Assessment_Upload` workflow
4. Monitor status messages for progress
5. Verify assessment upload in IBM Concert

### Status Messages
- "Generating uuids"
- "Validating ai models deployed in the cluster."
- "Generating assessment report."
- "Uploading assessment file into concert."

### Validation Steps
1. Input validation (all required fields present)
2. UUID generation (10 unique identifiers)
3. AI model inventory check (models and images)
4. Assessment report generation (OSCAL format)
5. Concert upload (compliance data)

## Troubleshooting

| Issue | Possible Cause | Resolution |
|-------|---------------|------------|
| "Missing required input field(s)" | Required parameters not provided | Verify all required inputs are supplied |
| "Aiiaas broker service list models api endpoint is incorrect" | API returned non-200 status | Check broker URL and network connectivity |
| "Aiiaas broker service api endpoint to list images is incorrect" | Images API failed | Verify broker service health and permissions |
| models_compliant_result = "fail" | Unapproved models or missing images | Review available_models and deployed_images output |
| Concert upload failure | Invalid auth key or network issue | Verify Concert API key and connectivity |

## Compliance Mapping
- **Control**: ISCF-AI-01
- **Category**: AI Model Governance
- **Severity**: High
- **Assessment Method**: TEST-AUTOMATED
- **Evidence Type**: Technical validation with JSON output
