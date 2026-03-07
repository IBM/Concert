# IBM Confidential
# PID: 5900-BD6, 5900-BBE
# Copyright IBM Corp. 2024

import json
import logging
from typing import Dict, Any, Optional
import httpx

logger = logging.getLogger(__name__)


class BYOMLLMClient:
    """
    BYOM LLM client that can connect to any HTTP-based LLM service.
    Uses configuration to adapt to different API formats.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize the BYOM LLM client.
        
        Args:
            config: LLM endpoint configuration from config.yaml
        """
        self.config = config
        self.url = config.get("url", "")
        self.method = config.get("method", "POST").upper()
        self.headers = config.get("headers", {})
        self.request_body_template = config.get("request_body", {})
        self.response_path = config.get("response_path", "")
        self.model_path = config.get("model_path", "")
        self.timeout = config.get("timeout", 60)
    
    def _replace_placeholders(self, obj: Any, prompt: str, params: Optional[Dict[str, Any]] = None) -> Any:
        """
        Recursively replace {prompt} and other placeholders in the request body.
        
        Args:
            obj: Object to process (dict, list, or string)
            prompt: The user's prompt to insert
            params: Optional additional parameters
            
        Returns:
            Object with placeholders replaced
        """
        if isinstance(obj, dict):
            return {k: self._replace_placeholders(v, prompt, params) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self._replace_placeholders(item, prompt, params) for item in obj]
        elif isinstance(obj, str):
            # Replace {prompt} placeholder
            result = obj.replace("{prompt}", prompt)
            # Replace any other {param_name} placeholders if params provided
            if params:
                for key, value in params.items():
                    result = result.replace(f"{{{key}}}", str(value))
            return result
        return obj
    
    def _get_nested_value(self, data: Any, path: str) -> Any:
        """
        Extract value from nested structure using path notation.
        Supports:
        - Dot notation: "results.text"
        - Array indexing: "results[0].text"
        - Mixed: "choices[0].message.content"
        
        Args:
            data: Data structure to navigate
            path: Path to the desired value
            
        Returns:
            Value at the specified path
            
        Raises:
            KeyError: If path is invalid
        """
        if not path:
            return data
        
        # Parse path into segments
        segments = []
        current = ""
        in_bracket = False
        
        for char in path:
            if char == '[':
                if current:
                    segments.append(('key', current))
                    current = ""
                in_bracket = True
            elif char == ']':
                if in_bracket and current:
                    segments.append(('index', int(current)))
                    current = ""
                in_bracket = False
            elif char == '.' and not in_bracket:
                if current:
                    segments.append(('key', current))
                    current = ""
            else:
                current += char
        
        if current:
            segments.append(('key', current))
        
        # Navigate through the data structure
        result = data
        for seg_type, seg_value in segments:
            if seg_type == 'key':
                if isinstance(result, dict):
                    result = result[seg_value]
                else:
                    raise KeyError(f"Cannot access key '{seg_value}' on non-dict type")
            elif seg_type == 'index':
                if isinstance(result, (list, tuple)):
                    result = result[seg_value]
                else:
                    raise KeyError(f"Cannot access index {seg_value} on non-list type")
        
        return result
    
    async def generate(self, prompt: str, parameters: Optional[Dict[str, Any]] = None) -> Dict[str, str]:
        """
        Generate a response from the LLM.
        
        Args:
            prompt: The input prompt from Concert
            parameters: Optional generation parameters
            
        Returns:
            Dictionary with 'model' and 'response' keys for Concert
            
        Raises:
            Exception: If the LLM request fails
        """
        try:
            # Build request body by replacing placeholders
            request_body = self._replace_placeholders(
                self.request_body_template.copy(),
                prompt,
                parameters
            )
            
            logger.info(f"Sending request to LLM: {self.url}")
            logger.debug(f"Request body: {json.dumps(request_body, indent=2)}")
            
            # Make HTTP request to LLM
            async with httpx.AsyncClient() as client:
                response = await client.request(
                    method=self.method,
                    url=self.url,
                    headers=self.headers,
                    json=request_body,
                    timeout=self.timeout
                )
                
                response.raise_for_status()
                response_data = response.json()
                
                logger.debug(f"LLM response: {json.dumps(response_data, indent=2)}")
                
                # Extract generated text using configured path
                generated_text = self._get_nested_value(response_data, self.response_path)
                
                # Clean up the response (remove markdown, extract JSON content, etc.)
                cleaned_text = self._clean_response(str(generated_text))
                
                # Extract model name if path is configured
                model_name = "unknown"
                if self.model_path:
                    try:
                        model_name = self._get_nested_value(response_data, self.model_path)
                    except (KeyError, IndexError):
                        logger.warning(f"Could not extract model name from path: {self.model_path}")
                logger.info(f"Generated text from model {model_name}: {cleaned_text}")
                # Return in Concert format
                return {
                    "model": str(model_name),
                    "response": cleaned_text
                }
                
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error from LLM: {e.response.status_code} - {e.response.text}")
            raise Exception(f"LLM request failed: {e.response.status_code}")
        except (KeyError, IndexError) as e:
            logger.error(f"Failed to parse LLM response: {e}")
            raise Exception(f"Invalid response format from LLM: {e}")
        except Exception as e:
            logger.error(f"LLM generation failed: {e}")
            raise
    
    def _clean_response(self, text: str) -> str:
        """
        Clean up LLM response by removing markdown code blocks.
        
        For structured JSON responses (action plans, etc.), returns the JSON as a string.
        For simple text responses, returns plain text.
        
        Args:
            text: Raw text from LLM
            
        Returns:
            Cleaned text - either valid JSON string or plain text
        """
        import re
        
        # Remove any backticks (2 or 3) with optional language identifier
        # Pattern: ``json or ```json or `` or ```
        text = re.sub(r'`{2,3}(?:\w+)?\s*', '', text)
        text = text.strip()
        
        # Try to parse as JSON to validate it
        try:
            parsed = json.loads(text)
            
            # If it's a structured response (dict or list), return as JSON string
            if isinstance(parsed, (dict, list)):
                # Return the cleaned JSON as a string (the calling code will parse it)
                return json.dumps(parsed)
                
        except (json.JSONDecodeError, ValueError, TypeError):
            # Not JSON, return as plain text
            pass
        
        return text.strip()


