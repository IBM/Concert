# Supported LLM Providers

This document provides configuration examples for various LLM providers.

## 1. Watsonx.ai

```yaml
llm_endpoint:
  url: "https://us-south.ml.cloud.ibm.com/ml/v1/text/generation"
  method: "POST"
  headers:
    Authorization: "Bearer ${WATSONX_API_KEY}"
    Content-Type: "application/json"
  request_body:
    input: "{prompt}"
    model_id: "meta-llama/llama-3-3-70b-instruct"
    project_id: "${WATSONX_PROJECT_ID}"
    parameters:
      max_new_tokens: 600
      temperature: 0.7
  response_path: "results[0].generated_text"
  model_path: "model_id"
  timeout: 60
```

**Environment Variables:**
```bash
WATSONX_API_KEY=your_watsonx_api_key
WATSONX_PROJECT_ID=your_project_id
```

## 2. OpenAI

```yaml
llm_endpoint:
  url: "https://api.openai.com/v1/chat/completions"
  method: "POST"
  headers:
    Authorization: "Bearer ${OPENAI_API_KEY}"
    Content-Type: "application/json"
  request_body:
    model: "gpt-4"
    messages:
      - role: "user"
        content: "{prompt}"
    max_tokens: 600
    temperature: 0.7
  response_path: "choices[0].message.content"
  model_path: "model"
  timeout: 60
```

**Environment Variables:**
```bash
OPENAI_API_KEY=sk-proj-your-openai-key
```

**Available Models:**
- `gpt-4`
- `gpt-4-turbo`
- `gpt-3.5-turbo`

## 3. Azure OpenAI

```yaml
llm_endpoint:
  url: "${AZURE_OPENAI_ENDPOINT}/openai/deployments/gpt-4/chat/completions?api-version=2024-02-15-preview"
  method: "POST"
  headers:
    api-key: "${AZURE_OPENAI_API_KEY}"
    Content-Type: "application/json"
  request_body:
    messages:
      - role: "user"
        content: "{prompt}"
    max_tokens: 600
    temperature: 0.7
  response_path: "choices[0].message.content"
  model_path: "model"
  timeout: 60
```

**Environment Variables:**
```bash
AZURE_OPENAI_API_KEY=your_azure_api_key
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
```

## 4. Google Gemini

```yaml
llm_endpoint:
  url: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
  method: "POST"
  headers:
    x-goog-api-key: "${GEMINI_API_KEY}"
    Content-Type: "application/json"
  request_body:
    contents:
      - parts:
          - text: "{prompt}"
    generationConfig:
      temperature: 0.7
  response_path: "candidates[0].content.parts[0].text"
  model_path: "modelVersion"
  timeout: 60
```

**Environment Variables:**
```bash
GEMINI_API_KEY=your_gemini_api_key
```

## 5. Anthropic Claude

```yaml
llm_endpoint:
  url: "https://api.anthropic.com/v1/messages"
  method: "POST"
  headers:
    x-api-key: "${ANTHROPIC_API_KEY}"
    anthropic-version: "2023-06-01"
    Content-Type: "application/json"
  request_body:
    model: "claude-3-5-sonnet-20241022"
    max_tokens: 2048
    messages:
      - role: "user"
        content: "{prompt}"
  response_path: "content[0].text"
  model_path: "model"
  timeout: 60
```

**Environment Variables:**
```bash
ANTHROPIC_API_KEY=your_anthropic_api_key
```

## 6. Mistral AI

```yaml
llm_endpoint:
  url: "https://api.mistral.ai/v1/chat/completions"
  method: "POST"
  headers:
    Authorization: "Bearer ${MISTRAL_API_KEY}"
    Content-Type: "application/json"
  request_body:
    model: "mistral-large-latest"
    messages:
      - role: "user"
        content: "{prompt}"
    max_tokens: 600
    temperature: 0.7
  response_path: "choices[0].message.content"
  model_path: "model"
  timeout: 60
```

**Environment Variables:**
```bash
MISTRAL_API_KEY=your_mistral_api_key
```

## 7. Groq

```yaml
llm_endpoint:
  url: "https://api.groq.com/openai/v1/chat/completions"
  method: "POST"
  headers:
    Authorization: "Bearer ${GROQ_API_KEY}"
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

**Environment Variables:**
```bash
GROQ_API_KEY=gsk_your_groq_api_key
```

**Available Models:**
- `llama-3.3-70b-versatile`
- `llama-3.1-70b-versatile`
- `mixtral-8x7b-32768`
- `gemma2-9b-it`

## 8. HuggingFace Inference API

```yaml
llm_endpoint:
  url: "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2"
  method: "POST"
  headers:
    Authorization: "Bearer ${HUGGINGFACE_API_KEY}"
    Content-Type: "application/json"
  request_body:
    inputs: "{prompt}"
    parameters:
      max_new_tokens: 600
      temperature: 0.7
  response_path: "[0].generated_text"
  timeout: 60
```

**Environment Variables:**
```bash
HUGGINGFACE_API_KEY=your_huggingface_api_key
```

## 9. Local Ollama

```yaml
llm_endpoint:
  url: "http://localhost:11434/api/generate"
  method: "POST"
  headers:
    Content-Type: "application/json"
  request_body:
    model: "llama2"
    prompt: "{prompt}"
    stream: false
  response_path: "response"
  model_path: "model"
  timeout: 60
```

**No API key required** - runs locally

**Available Models:** Any model you've pulled with `ollama pull`

## 10. vLLM Server

```yaml
llm_endpoint:
  url: "http://localhost:8000/v1/completions"
  method: "POST"
  headers:
    Content-Type: "application/json"
  request_body:
    model: "meta-llama/Llama-2-7b-hf"
    prompt: "{prompt}"
    max_tokens: 600
    temperature: 0.7
  response_path: "choices[0].text"
  model_path: "model"
  timeout: 60
```

**No API key required** - runs locally

## Custom LLM Endpoint

For any other LLM provider, use this template:

```yaml
llm_endpoint:
  url: "${CUSTOM_LLM_URL}"
  method: "POST"
  headers:
    Authorization: "Bearer ${CUSTOM_API_KEY}"
    Content-Type: "application/json"
  request_body:
    model: "your-model-name"
    messages:
      - role: "user"
        content: "{prompt}"
    max_tokens: 600
    temperature: 0.7
  response_path: "choices[0].message.content"
  model_path: "model"
  timeout: 60
```

**Environment Variables:**
```bash
CUSTOM_LLM_URL=https://your-llm-endpoint.com/v1/chat/completions
CUSTOM_API_KEY=your_api_key
```

## Switching Between Providers

To switch providers:

1. **Comment out** the current active `llm_endpoint` configuration
2. **Uncomment** the desired provider's configuration
3. **Update** `.env` with the required API keys
4. **Restart** the container:
   ```bash
   docker-compose restart
   ```

## Testing Your Configuration

After configuring a provider, test it:

```bash
curl -X POST http://localhost:8082/custom_handler/genai \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Say hello"}'
```

Expected response:
```json
{
  "model": "your-model-name",
  "response": "Hello! How can I help you today?"
}