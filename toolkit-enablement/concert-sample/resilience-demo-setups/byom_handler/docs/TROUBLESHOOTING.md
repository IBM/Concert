# Troubleshooting Guide

This guide helps you resolve common issues with the BYOM Handler.

## Container Issues

### Container Won't Start

**Symptoms:**
- Container exits immediately after starting
- `docker ps` shows no running container

**Solutions:**

1. **Check logs:**
   ```bash
   docker-compose logs byom-handler
   # or
   docker logs byom-handler
   ```

2. **Verify `.env` file exists:**
   ```bash
   ls -la .env
   ```

3. **Check port availability:**
   ```bash
   lsof -i :8082
   # or
   netstat -an | grep 8082
   ```
   If port 8082 is in use, either stop the other service or change the port in `config.yaml` and `docker-compose.yaml`.

4. **Rebuild without cache:**
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### Configuration Changes Not Taking Effect

**Symptoms:**
- Modified `config.yaml` but behavior hasn't changed
- Updated `.env` but still seeing old values

**Solutions:**

1. **Restart the container:**
   ```bash
   docker-compose restart
   ```

2. **If restart doesn't work, rebuild:**
   ```bash
   docker-compose down
   docker-compose build
   docker-compose up -d
   ```

3. **Verify the config is mounted correctly:**
   ```bash
   docker exec byom-handler cat /app/config.yaml
   ```

## API Key Issues

### Environment Variables Not Replaced

**Symptoms:**
- Error message shows `${OPENAI_API_KEY}` instead of actual key
- Logs show literal `${VAR_NAME}` strings

**Solutions:**

1. **Verify `.env` file has actual values:**
   ```bash
   cat .env | grep API_KEY
   ```
   Make sure values are NOT placeholders like `your_api_key_here`

2. **Check environment variable in container:**
   ```bash
   docker exec byom-handler env | grep OPENAI_API_KEY
   ```

3. **Rebuild the container:**
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

4. **Verify config_loader.py has the fix:**
   ```bash
   docker exec byom-handler cat /app/config_loader.py | grep -A 5 "import re"
   ```
   Should show regex-based replacement logic.

### API Authentication Errors

**Symptoms:**
- `401 Unauthorized` errors
- `Incorrect API key provided`
- `Invalid authentication credentials`

**Solutions:**

1. **Verify API key is correct:**
   - Check your LLM provider's dashboard
   - Regenerate the API key if needed
   - Update `.env` with the new key

2. **Check API key format:**
   - OpenAI: `sk-proj-...` or `sk-...`
   - Groq: `gsk_...`
   - Ensure no extra spaces or quotes

3. **Verify header format:**
   ```yaml
   # Correct for most providers
   Authorization: "Bearer ${API_KEY}"
   
   # Some providers use different headers
   X-API-Key: "${API_KEY}"
   api-key: "${API_KEY}"
   ```

4. **Test API key directly:**
   ```bash
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer YOUR_API_KEY"
   ```

## LLM Request Failures

### Model Not Found Error

**Symptoms:**
- `model_not_found` error
- `The model 'xyz' does not exist`

**Solutions:**

1. **Check model name is correct:**
   - OpenAI: `gpt-4`, `gpt-3.5-turbo`
   - Groq: `llama-3.3-70b-versatile`, `mixtral-8x7b-32768`
   - Refer to [PROVIDERS.md](PROVIDERS.md) for correct model names

2. **Verify you have access to the model:**
   - Some models require specific API tier or subscription
   - Check your provider's dashboard

3. **Update config.yaml with correct model:**
   ```yaml
   request_body:
     model: "llama-3.3-70b-versatile"  # Use correct model name
   ```

### Quota Exceeded Error

**Symptoms:**
- `insufficient_quota` error
- `You exceeded your current quota`
- `Rate limit exceeded`

**Solutions:**

1. **Check your billing:**
   - OpenAI: https://platform.openai.com/account/billing
   - Add payment method or purchase credits

2. **Check rate limits:**
   - You may be making too many requests
   - Implement rate limiting in your application

3. **Try a different model:**
   - Some models have higher quotas
   - Free tier models may have stricter limits

### Connection Timeout

**Symptoms:**
- `Connection timeout` errors
- Requests hang indefinitely

**Solutions:**

1. **Increase timeout in config.yaml:**
   ```yaml
   llm_endpoint:
     timeout: 120  # Increase from 60 to 120 seconds
   ```

2. **Check network connectivity:**
   ```bash
   docker exec byom-handler curl -I https://api.openai.com
   ```

3. **Verify URL is correct:**
   ```bash
   docker exec byom-handler python3 -c "from config_loader import ConfigLoader; c = ConfigLoader('config.yaml'); print(c.config.get('llm_endpoint', {}).get('url'))"
   ```

## Response Parsing Errors

### Cannot Extract Response

**Symptoms:**
- `Failed to parse LLM response`
- `KeyError` or `IndexError` in logs

**Solutions:**

1. **Check the actual response format:**
   ```bash
   # Enable debug logging to see raw responses
   docker-compose logs -f byom-handler
   ```

2. **Test your LLM endpoint directly:**
   ```bash
   curl -X POST https://api.openai.com/v1/chat/completions \
     -H "Authorization: Bearer YOUR_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "gpt-4",
       "messages": [{"role": "user", "content": "Hello"}]
     }'
   ```

3. **Adjust response_path to match actual structure:**
   ```yaml
   # If response is: {"data": {"text": "Hello"}}
   response_path: "data.text"
   
   # If response is: {"results": [{"output": "Hello"}]}
   response_path: "results[0].output"
   ```

4. **Verify response_path syntax:**
   - Use dot notation for nested objects: `"a.b.c"`
   - Use brackets for arrays: `"items[0]"`
   - Combine both: `"data.items[0].text"`

## Concert Integration Issues

### Handler Not Receiving Requests

**Symptoms:**
- Concert shows handler as registered but requests fail
- No logs in handler container

**Solutions:**

1. **Verify handler is accessible from Concert:**
   ```bash
   # From Concert server
   curl http://handler-hostname:8082/health
   ```

2. **Check firewall rules:**
   - Ensure port 8082 is open
   - Check network security groups

3. **Verify hostname in registration:**
   - Use IP address or fully qualified domain name
   - Avoid using `localhost` if Concert is on different machine

### Authentication Failures from Concert

**Symptoms:**
- `401 Unauthorized` when Concert calls handler
- Handler logs show authentication failures

**Solutions:**

1. **Verify Concert API key matches:**
   ```yaml
   # In config.yaml
   auth:
     type: "api_key"
     header_name: "Authentication"
     api_key: "${CONCERT_API_KEY}"
   ```

2. **Check Concert sends correct header:**
   - Header name must match exactly (case-sensitive)
   - Value must match the configured API key

3. **Test with correct header:**
   ```bash
   curl -X POST http://localhost:8082/custom_handler/genai \
     -H "Content-Type: application/json" \
     -H "Authentication: your-concert-api-key" \
     -d '{"prompt": "Hello"}'
   ```

## Debugging Tips

### Enable Debug Logging

1. **Update config.yaml:**
   ```yaml
   logging:
     level: "DEBUG"
   ```

2. **Restart container:**
   ```bash
   docker-compose restart
   ```

3. **View detailed logs:**
   ```bash
   docker-compose logs -f byom-handler
   ```

### Test Configuration

Run this command to verify your configuration is loaded correctly:

```bash
docker exec byom-handler python3 -c "
from config_loader import ConfigLoader
import json
c = ConfigLoader('config.yaml')
print('URL:', c.config.get('llm_endpoint', {}).get('url'))
print('Headers:', json.dumps(c.config.get('llm_endpoint', {}).get('headers', {}), indent=2))
print('Model:', c.config.get('llm_endpoint', {}).get('request_body', {}).get('model'))
"
```

### Test Handler Directly

```bash
# Simple test
curl -X POST http://localhost:8082/custom_handler/genai \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Say hello"}'

# With authentication
curl -X POST http://localhost:8082/custom_handler/genai \
  -H "Content-Type: application/json" \
  -H "Authentication: your-api-key" \
  -d '{"prompt": "Say hello"}'
```

## Getting Help

If you're still experiencing issues:

1. **Check logs:**
   ```bash
   docker-compose logs byom-handler | tail -100
   ```

2. **Verify configuration:**
   - Review [CONFIGURATION.md](CONFIGURATION.md)
   - Check [PROVIDERS.md](PROVIDERS.md) for provider-specific examples

3. **Test components individually:**
   - Test LLM API directly with curl
   - Test handler with simple curl request
   - Check Concert connectivity

4. **Collect diagnostic information:**
   - Container logs
   - Configuration files (redact API keys)
   - Error messages
   - Steps to reproduce