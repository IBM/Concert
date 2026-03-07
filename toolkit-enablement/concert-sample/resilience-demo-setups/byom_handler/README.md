# BYOM Handler for Concert GenAI

A universal handler that can connect to **any** LLM provider through simple configuration. No code changes needed - just configure your LLM endpoint details and you're ready to go!

## Features

✅ **Universal Compatibility**: Works with any HTTP-based LLM service
✅ **Configuration-Driven**: No code changes needed for different providers
✅ **Concert /genai Contract**: Fully implements Concert's GenAI contract
✅ **Format Translation**: Automatically translates between Concert and LLM formats
✅ **HTTPS Support**: Built-in SSL/TLS support for secure communication
✅ **Docker Ready**: Easy deployment with Docker and Docker Compose
✅ **Pre-configured Examples**: Includes configs for Watsonx, OpenAI, Azure, Mistral, HuggingFace, Ollama, vLLM

## Prerequisites

- Docker installed on your system
- API keys for your LLM provider(s)
- (Optional) SSL certificates for HTTPS support

## Quick Start

### 1. Configure Your LLM Provider

Copy the example environment file and add your credentials:

```bash
cd byom_handler
cp .env.example .env
# Edit .env with your API keys
```

Edit `config.yaml` to configure your LLM endpoint. The file includes example configurations for multiple LLM providers (Watsonx, OpenAI, Google Gemini, Anthropic Claude, Mistral, HuggingFace, Ollama, vLLM) - simply uncomment and configure the one you want to use.

**Note:** Only one LLM provider can be active at a time. Make sure all other provider configurations remain commented out.

### 2. (Optional) Generate SSL Certificates for HTTPS

For HTTPS support, generate self-signed certificates (development/testing):

```bash
# Generate certificates
./scripts/generate-certs.sh
```

This will generate self-signed certificates in the `certs/` directory. For Concert to trust these certificates, you need to add the `cert.pem` file to Concert's trust store.

For production, use the appropiate CA-signed certificates.

**Follow the IBM Concert documentation to add the certificate:**
- [Managing Custom Certificates - Adding and Managing Trusted Certificates](https://www.ibm.com/docs/en/concert/2.2.x?topic=systems-managing-custom-certificates-vm-kubernetes-deployments#adding_and_managing_trusted_certificates__title__3)


**To disable HTTPS and use HTTP:**
- Set `ssl_enabled: false` in `config.yaml`
- Change `protocol: "http"` in `config.yaml`

### 3. Build and Run

```bash
# Build and start the handler
./scripts/build-run.sh

# View logs
docker logs -f byom-handler

# Stop the container
docker stop byom-handler && docker rm byom-handler
```

The handler will start on:
- **HTTPS**: `https://localhost:8082` (if `ssl_enabled: true`)
- **HTTP**: `http://localhost:8082` (if `ssl_enabled: false`)

### 4. Register with Concert

Get the registration payload:

```bash
# For HTTPS (with self-signed certificate, use -k to skip verification)
curl -k https://localhost:8082/registration
```

Use this payload to register the handler with Concert:

```bash
curl -k -X POST https://your-concert-url.com:12443/core/api/v1/handler/YOUR_HANDLER_NAME \
  -H "Content-Type: application/json" \
  -H "instanceid: ${CONCERT_INSTANCE_ID}" \
  -H "Authorization: C_API_KEY ${CONCERT_API_KEY}" \
  -d @- << EOF
{
  "description": "BYOM Handler",
  "protocol": "https",
  "hostname": "YOUR_HANDLER_HOSTNAME",
  "port": 8082,
  "prefix": "custom_handler",
  "auth": {
    "type": "api_key",
    "data": {
      "Authentication": "your-api-key"
    }
  },
  "supports": {
    "genai": {
      "default_payload": {}
    }
  },
  "default_headers": {},
  "accessibility": "open"
}
EOF
```

**Note:** Change `"protocol": "https"` to `"protocol": "http"` if you're running the handler without SSL.

## ✅ Setup Complete!

**Your BYOM handler is now integrated with Concert.** All AI-powered features in Concert will automatically use your configured LLM provider - no further action required.

### What You've Achieved

✅ **Complete Control**: Your chosen LLM provider (Watsonx, OpenAI, Azure, Gemini, etc.) powers all Concert AI features
✅ **Cost Management**: You manage costs directly through your own API keys
✅ **Data Privacy**: Your data stays within your chosen provider's infrastructure
✅ **Flexibility**: Switch providers anytime by updating `config.yaml` and restarting the handler
✅ **Seamless Integration**: Concert automatically routes all AI requests to your handler

## Documentation

For detailed configuration guides and examples, see:
- **[Configuration Guide](docs/CONFIGURATION.md)** - Detailed LLM endpoint configuration and response path syntax
- **[Supported Providers](docs/PROVIDERS.md)** - Examples for Watsonx, OpenAI, Azure, Gemini, Groq, Mistral, and more
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Project Structure

```
byom_handler/
├── README.md                 # This file
├── requirements.txt         # Python dependencies
├── Dockerfile               # Docker image definition
├── config.yaml              # LLM endpoint configuration
├── .env.example             # Example environment variables
├── scripts/                 # Utility scripts
│   ├── build-run.sh        # Build and run script
│   └── generate-certs.sh   # SSL certificate generation script
├── src/                    # Source code
│   ├── main.py             # FastAPI application
│   ├── llm_client.py       # Universal LLM client
│   ├── config_loader.py    # Configuration management
│   └── __init__.py
├── certs/                  # SSL certificates (runtime mounted, not committed)
│   ├── cert.pem            # SSL certificate
│   └── key.pem             # SSL private key
└── docs/                   # Documentation
    ├── CONFIGURATION.md    # Configuration guide
    ├── PROVIDERS.md        # Provider examples
    └── TROUBLESHOOTING.md  # Troubleshooting guide
```

## License

IBM Confidential
PID: 5900-BD6, 5900-BBE
Copyright IBM Corp. 2024
