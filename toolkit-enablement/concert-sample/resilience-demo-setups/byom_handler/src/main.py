# IBM Confidential
# PID: 5900-BD6, 5900-BBE
# Copyright IBM Corp. 2024

import logging
import sys
from typing import Optional
import uvicorn
from fastapi import FastAPI, HTTPException, Request, status
from pydantic import BaseModel

from src.config_loader import ConfigLoader
from src.llm_client import BYOMLLMClient

# Initialize logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# Load configuration
try:
    config_loader = ConfigLoader("config.yaml")
    logger.info("Configuration loaded successfully")
except Exception as e:
    logger.error(f"Failed to load configuration: {e}")
    sys.exit(1)

# Initialize FastAPI app
app = FastAPI(
    title="BYOM BYOM Handler",
    description="BYOM handler for Concert GenAI supporting any LLM provider",
    version="1.0.0"
)

# Initialize LLM client
try:
    llm_config = config_loader.config.get("llm_endpoint", {})
    llm_client = BYOMLLMClient(llm_config)
    logger.info("LLM client initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize LLM client: {e}")
    sys.exit(1)


class GenAIRequest(BaseModel):
    """Request model for Concert GenAI contract."""
    prompt: str


class GenAIResponse(BaseModel):
    """Response model for Concert GenAI contract."""
    model: str
    response: str


def verify_authentication(request: Request) -> bool:
    """
    Verify Concert authentication from request headers.
    
    Args:
        request: FastAPI request object
        
    Returns:
        True if authenticated, False otherwise
    """
    auth_config = config_loader.get_auth_config()
    
    if not auth_config:
        # No authentication configured
        return True
    
    auth_type = auth_config.get("type", "")
    
    if auth_type == "api_key":
        header_name = auth_config.get("header_name", "Authentication")
        expected_key = auth_config.get("api_key", "")
        
        # Skip auth check if no key is configured
        if not expected_key:
            return True
        
        # Get the key from request headers
        provided_key = request.headers.get(header_name, "")
        
        return provided_key == expected_key
    
    # Unknown auth type, allow by default
    return True


@app.get("/")
async def root():
    """Root endpoint - health check."""
    return {
        "status": "healthy",
        "service": "BYOM BYOM Handler",
        "version": "1.0.0"
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post(f"/{config_loader.get_handler_config().get('prefix', 'custom_handler')}/genai")
async def genai_handler(request: Request) -> GenAIResponse:
    """
    GenAI endpoint implementing Concert's /genai contract.
    
    This endpoint:
    1. Accepts Concert's GenAI request format: {"prompt": "text"}
    2. Translates it to the configured LLM's format
    3. Calls the LLM
    4. Translates the LLM response back to Concert format: {"model": "...", "response": "..."}
    5. Returns HTTP 200 on success
    
    Args:
        request: FastAPI request object
        
    Returns:
        GenAIResponse with model and response fields
        
    Raises:
        HTTPException: On authentication failure or LLM errors
    """
    # Verify authentication
    if not verify_authentication(request):
        logger.warning("Authentication failed")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )
    
    # Parse request body
    try:
        body = await request.json()
        genai_request = GenAIRequest(**body)
        logger.info(f"Received GenAI request with prompt length: {len(genai_request.prompt)}")
    except Exception as e:
        logger.error(f"Invalid request payload: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid request format. Expected: {\"prompt\": \"text\"}"
        )
    
    # Call LLM
    try:
        # Translate Concert format → LLM format → Concert format
        result = await llm_client.generate(genai_request.prompt)
        
        # Assisted by watsonx Code Assistant

        logger.info(f"Successfully generated response from model{result['model']}: {result['response']}")
        
        # Return in Concert format
        return GenAIResponse(
            model=result["model"],
            response=result["response"]
        )
        
    except Exception as e:
        logger.error(f"LLM generation failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"LLM generation failed: {str(e)}"
        )


@app.get("/registration")
async def get_registration_payload():
    """
    Get the Concert handler registration payload.
    
    This endpoint returns the JSON payload that should be used
    to register this handler with Concert.
    
    Returns:
        Registration payload for Concert
    """
    try:
        payload = config_loader.get_concert_registration_payload()
        return payload
    except Exception as e:
        logger.error(f"Failed to generate registration payload: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate registration payload: {str(e)}"
        )


if __name__ == "__main__":
    handler_config = config_loader.get_handler_config()
    host = "0.0.0.0"
    port = handler_config.get("port", 8082)
    
    # SSL configuration
    ssl_enabled = handler_config.get("ssl_enabled", False)
    ssl_certfile = handler_config.get("ssl_certfile", "certs/cert.pem")
    ssl_keyfile = handler_config.get("ssl_keyfile", "certs/key.pem")
    
    protocol = "https" if ssl_enabled else "http"
    logger.info(f"Starting BYOM Handler on {protocol}://{host}:{port}")
    logger.info(f"SSL Enabled: {ssl_enabled}")
    if ssl_enabled:
        logger.info(f"SSL Certificate: {ssl_certfile}")
        logger.info(f"SSL Key: {ssl_keyfile}")
    logger.info(f"Handler prefix: /{handler_config.get('prefix', 'custom_handler')}")
    logger.info(f"GenAI endpoint: /{handler_config.get('prefix', 'custom_handler')}/genai")
    
    # Build uvicorn configuration
    uvicorn_config = {
        "app": app,
        "host": host,
        "port": port,
        "log_level": "info"
    }
    
    # Add SSL configuration if enabled
    if ssl_enabled:
        uvicorn_config["ssl_certfile"] = ssl_certfile
        uvicorn_config["ssl_keyfile"] = ssl_keyfile
    
    uvicorn.run(**uvicorn_config)


