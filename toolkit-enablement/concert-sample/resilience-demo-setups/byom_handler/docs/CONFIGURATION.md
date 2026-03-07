# Configuration Guide

This guide explains how to configure the BYOM Handler for different LLM providers.

## Configuration File Structure

The handler uses `config.yaml` for all configuration. Here's what you need to configure:

### Handler Configuration

```yaml
handler:
  name: "byom_handler"
  description: "BYOM Handler for Concert GenAI"
  protocol: "http"
  hostname: "localhost"
  port: 8082
  prefix: "custom_handler"
```

### LLM Endpoint Configuration

This is where you configure your LLM provider's HTTP endpoint:

```yaml
llm_endpoint:
  # The URL of your LLM service
  url: "https://api.example.com/v1/generate"
  
  # HTTP method (usually POST)
  method: "POST"
  
  # Authentication headers
  headers:
    Authorization: "Bearer ${LLM_API_KEY}"
    Content-Type: "application/json"
  
  # Request body template - use {prompt} for the user's prompt
  request_body:
    model: "your-model-name"
    messages:
      - role: "user"
        content: "{prompt}"
    max_tokens: 600
    temperature: 0.7
  
  # JSONPath to extract the generated text from response
  response_path: "choices[0].message.content"
  
  # JSONPath to extract the model name (optional)
  model_path: "model"
  
  # Request timeout in seconds
  timeout: 60
```

## Response Path Syntax

The `response_path` uses a simple path notation to extract values from nested JSON:

- **Dot notation**: `"results.text"` → `response["results"]["text"]`
- **Array indexing**: `"results[0]"` → `response["results"][0]`
- **Combined**: `"choices[0].message.content"` → `response["choices"][0]["message"]["content"]`

### Examples

**OpenAI Response:**
```json
{
  "choices": [
    {
      "message": {
        "content": "Hello!"
      }
    }
  ]
}
```
Response path: `"choices[0].message.content"`

**Watsonx Response:**
```json
{
  "results": [
    {
      "generated_text": "Hello!"
    }
  ]
}
```
Response path: `"results[0].generated_text"`

**Simple Response:**
```json
{
  "generated_text": "Hello!"
}
```
Response path: `"generated_text"`

## Environment Variables

Environment variables are referenced in `config.yaml` using the `${VAR_NAME}` syntax. They are automatically replaced with actual values from your `.env` file or container environment.

### Example

In `config.yaml`:
```yaml
headers:
  Authorization: "Bearer ${OPENAI_API_KEY}"
```

In `.env`:
```bash
OPENAI_API_KEY=sk-proj-your-actual-key-here
```

Result:
```yaml
headers:
  Authorization: "Bearer sk-proj-your-actual-key-here"
```

## Request Body Templates

The `request_body` section defines the structure of the request sent to your LLM. Use `{prompt}` as a placeholder for the user's input.

### OpenAI-Compatible Format

```yaml
request_body:
  model: "gpt-4"
  messages:
    - role: "user"
      content: "{prompt}"
  max_tokens: 600
  temperature: 0.7
```

### Simple Prompt Format

```yaml
request_body:
  prompt: "{prompt}"
  max_tokens: 600
  temperature: 0.7
```

### Custom Format

```yaml
request_body:
  input: "{prompt}"
  model_id: "your-model"
  parameters:
    max_new_tokens: 600
    temperature: 0.7
```

## Authentication Options

### Bearer Token

```yaml
headers:
  Authorization: "Bearer ${API_KEY}"
  Content-Type: "application/json"
```

### API Key Header

```yaml
headers:
  X-API-Key: "${API_KEY}"
  Content-Type: "application/json"
```

### Custom Header

```yaml
headers:
  api-key: "${API_KEY}"
  Content-Type: "application/json"
```

### No Authentication

```yaml
headers:
  Content-Type: "application/json"
```

## Model Field

The `model` field in the request body specifies which AI model the LLM provider should use. This is **provider-specific** and must match the models available from your LLM provider.

### Examples by Provider

**OpenAI:**
- `gpt-4`
- `gpt-4-turbo`
- `gpt-3.5-turbo`

**Groq:**
- `llama-3.3-70b-versatile`
- `llama-3.1-70b-versatile`
- `mixtral-8x7b-32768`
- `gemma2-9b-it`

**Watsonx:**
- `meta-llama/llama-3-3-70b-instruct`
- `ibm/granite-13b-chat-v2`

**Mistral:**
- `mistral-large-latest`
- `mistral-medium-latest`

Always check your LLM provider's documentation for available model names.

## Complete Example

Here's a complete configuration for Groq:

**config.yaml:**
```yaml
llm_endpoint:
  url: "${CUSTOM_LLM_URL}"
  method: "POST"
  headers:
    Authorization: "Bearer ${CUSTOM_API_KEY}"
    Content-Type: "application/json"
  request_body:
    model: "llama-3.3-70b-versatile"
    messages:
      - role: "user"
        content: "{prompt}"
    max_tokens: 600
    temperature: 0.7
  response_path: "choices[0].message.content"
  model_path: "model"
  timeout: 60
```

**.env:**
```bash
CUSTOM_LLM_URL=https://api.groq.com/openai/v1/chat/completions
CUSTOM_API_KEY=gsk_your_groq_api_key_here
```

## Applying Configuration Changes

After modifying `config.yaml` or `.env`, restart the container:

```bash
docker-compose restart
```

Or rebuild if you made code changes:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d