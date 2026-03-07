# IBM Confidential
# PID: 5900-BD6, 5900-BBE
# Copyright IBM Corp. 2024

import os
import yaml
from typing import Dict, Any, Optional
from pathlib import Path
from dotenv import load_dotenv


class ConfigLoader:
    """Load and manage configuration for the byom handler."""
    
    def __init__(self, config_path: str = "config.yaml"):
        """
        Initialize the configuration loader.
        
        Args:
            config_path: Path to the YAML configuration file
        """
        self.config_path = config_path
        self.config: Dict[str, Any] = {}
        self._load_config()
    
    def _load_config(self) -> None:
        """Load configuration from YAML file and environment variables."""
        # Load environment variables from .env file
        load_dotenv()
        
        # Load YAML configuration
        config_file = Path(self.config_path)
        if not config_file.exists():
            raise FileNotFoundError(f"Configuration file not found: {self.config_path}")
        
        with open(config_file, 'r', encoding='utf-8') as f:
            self.config = yaml.safe_load(f)
        
        # Replace environment variable placeholders
        self.config = self._replace_env_vars(self.config)
    
    def _replace_env_vars(self, obj: Any) -> Any:
        """
        Recursively replace environment variable placeholders in configuration.
        
        Args:
            obj: Configuration object (dict, list, or string)
            
        Returns:
            Object with environment variables replaced
        """
        if isinstance(obj, dict):
            return {k: self._replace_env_vars(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self._replace_env_vars(item) for item in obj]
        elif isinstance(obj, str):
            # Handle both standalone placeholders and embedded ones
            # e.g., "${API_KEY}" or "Bearer ${API_KEY}"
            import re
            
            def replace_match(match):
                env_var = match.group(1)
                value = os.getenv(env_var)
                if value is None:
                    # Return empty string if env var not set (allows optional configs)
                    return ""
                return value
            
            # Replace all ${VAR_NAME} patterns in the string
            return re.sub(r'\$\{([^}]+)\}', replace_match, obj)
        return obj
    
    def get_handler_config(self) -> Dict[str, Any]:
        """Get handler configuration."""
        return self.config.get("handler", {})
    
    def get_llm_provider_type(self) -> str:
        """Get the configured LLM provider type."""
        return self.config.get("llm_provider", {}).get("type", "watsonx")
    
    def get_llm_config(self, provider: Optional[str] = None) -> Dict[str, Any]:
        """
        Get LLM provider configuration.
        
        Args:
            provider: Provider name (if None, uses configured provider)
            
        Returns:
            Provider configuration dictionary
        """
        if provider is None:
            provider = self.get_llm_provider_type()
        
        return self.config.get("llm_provider", {}).get(provider, {})
    
    def get_auth_config(self) -> Dict[str, Any]:
        """Get authentication configuration."""
        return self.config.get("auth", {})
    
    def get_default_headers(self) -> Dict[str, str]:
        """Get default headers configuration."""
        return self.config.get("default_headers", {})
    
    def get_logging_config(self) -> Dict[str, Any]:
        """Get logging configuration."""
        return self.config.get("logging", {})
    
    def get_concert_registration_payload(self) -> Dict[str, Any]:
        """
        Generate the payload for registering this handler with Concert.
        
        Returns:
            Registration payload matching Concert's handler registration format
        """
        handler_config = self.get_handler_config()
        auth_config = self.get_auth_config()
        default_headers = self.get_default_headers()
        
        payload = {
            "name": handler_config.get("name", "byom_handler"),
            "description": handler_config.get("description", "BYOM Handler"),
            "protocol": handler_config.get("protocol", "http"),
            "hostname": handler_config.get("hostname", "localhost"),
            "port": handler_config.get("port", 8082),
            "prefix": handler_config.get("prefix", "custom_handler"),
            "auth": {
                "type": auth_config.get("type", "api_key"),
                "data": {
                    auth_config.get("header_name", "Authentication"): auth_config.get("api_key", "")
                }
            },
            "supports": {
                "genai": {
                    "default_payload": {}
                }
            },
            "default_headers": default_headers,
            "accessibility": "open"
        }
        
        return payload
