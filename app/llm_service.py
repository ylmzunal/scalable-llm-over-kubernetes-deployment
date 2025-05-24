import asyncio
import time
import logging
import os
from typing import Dict, Optional, List
from datetime import datetime
import httpx
import json

logger = logging.getLogger(__name__)

class LLMService:
    """
    Enhanced LLM Service supporting multiple free model providers.
    Supports: Ollama (local), Hugging Face Inference API (free), and mock mode.
    """
    
    # Available free models configuration
    AVAILABLE_MODELS = {
        "ollama": {
            "tinyllama": {"name": "tinyllama", "display_name": "TinyLlama (Tiny)", "size": "1.1B"},
            "phi": {"name": "phi", "display_name": "Phi-2 (Microsoft)", "size": "2.7B"},
            "llama2": {"name": "llama2", "display_name": "Llama 2 (Meta)", "size": "7B"},
            "deepseek-coder": {"name": "deepseek-coder:6.7b", "display_name": "DeepSeek Coder", "size": "6.7B"},
            "codellama": {"name": "codellama", "display_name": "Code Llama (Meta)", "size": "7B"},
            "mistral": {"name": "mistral", "display_name": "Mistral 7B", "size": "7B"},
            "neural-chat": {"name": "neural-chat", "display_name": "Neural Chat (Intel)", "size": "7B"},
        },
        "huggingface": {
            "microsoft/DialoGPT-large": {"name": "microsoft/DialoGPT-large", "display_name": "DialoGPT Large", "size": "Large"},
            "google/flan-t5-large": {"name": "google/flan-t5-large", "display_name": "FLAN-T5 Large", "size": "Large"},
            "microsoft/DialoGPT-medium": {"name": "microsoft/DialoGPT-medium", "display_name": "DialoGPT Medium", "size": "Medium"},
            "deepseek-ai/deepseek-coder-1.3b-base": {"name": "deepseek-ai/deepseek-coder-1.3b-base", "display_name": "DeepSeek Coder 1.3B", "size": "1.3B"},
        }
    }
    
    def __init__(self):
        self.model_provider = os.getenv("LLM_MODEL_PROVIDER", "ollama")  # ollama, huggingface, mock
        self.model_name = os.getenv("LLM_MODEL_NAME", "phi")
        self.base_url = os.getenv("LLM_BASE_URL", "http://localhost:11434")
        self.hf_api_token = os.getenv("HF_API_TOKEN")  # Optional for higher rate limits
        
        # Service metrics
        self.start_time = time.time()
        self.message_count = 0
        self.total_response_time = 0.0
        self.is_initialized = False
        self.conversations: Dict[str, list] = {}
        
        # Model status
        self.model_loaded = False
        self.last_health_check = None
        self.current_model_info = None
        
    async def initialize(self):
        """Initialize the LLM service with selected provider"""
        try:
            logger.info(f"Initializing LLM service with provider: {self.model_provider}, model: {self.model_name}")
            
            if self.model_provider == "ollama":
                await self._initialize_ollama()
            elif self.model_provider == "huggingface":
                await self._initialize_huggingface()
            else:
                # Mock mode for testing
                await self._initialize_mock()
                
            self.is_initialized = True
            self.model_loaded = True
            logger.info("LLM service initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize LLM service: {e}")
            # Fallback to mock mode
            await self._initialize_mock()
            self.is_initialized = True
    
    async def _initialize_ollama(self):
        """Initialize Ollama with selected model"""
        try:
            async with httpx.AsyncClient() as client:
                # Check if Ollama is running
                response = await client.get(f"{self.base_url}/api/version", timeout=10.0)
                if response.status_code == 200:
                    logger.info("Ollama service is running")
                    
                    # Check available models
                    models_response = await client.get(f"{self.base_url}/api/tags")
                    if models_response.status_code == 200:
                        models = models_response.json()
                        available_models = [model['name'] for model in models.get('models', [])]
                        
                        # Check if exact model is available
                        model_found = False
                        for available_model in available_models:
                            if self.model_name in available_model or available_model.startswith(self.model_name):
                                self.model_name = available_model  # Use exact model name
                                model_found = True
                                break
                        
                        if model_found:
                            logger.info(f"Model {self.model_name} is available")
                            self.current_model_info = self.AVAILABLE_MODELS["ollama"].get(self.model_name.split(':')[0], {
                                "name": self.model_name,
                                "display_name": self.model_name,
                                "size": "Unknown"
                            })
                        else:
                            logger.warning(f"Model {self.model_name} not found. Available models: {available_models}")
                            logger.info("Attempting to pull model...")
                            await self._pull_ollama_model()
                else:
                    raise Exception("Ollama service not accessible")
                    
        except Exception as e:
            logger.error(f"Ollama initialization failed: {e}")
            raise
    
    async def _initialize_huggingface(self):
        """Initialize Hugging Face Inference API"""
        try:
            # Test Hugging Face API connectivity
            headers = {}
            if self.hf_api_token:
                headers["Authorization"] = f"Bearer {self.hf_api_token}"
            
            # Validate model exists
            if self.model_name in self.AVAILABLE_MODELS["huggingface"]:
                self.current_model_info = self.AVAILABLE_MODELS["huggingface"][self.model_name]
                logger.info(f"Hugging Face model {self.model_name} initialized")
            else:
                logger.warning(f"Model {self.model_name} not in predefined list, using anyway")
                self.current_model_info = {"name": self.model_name, "display_name": self.model_name, "size": "Unknown"}
                
        except Exception as e:
            logger.error(f"Hugging Face initialization failed: {e}")
            raise
    
    async def _pull_ollama_model(self):
        """Pull Ollama model if not available"""
        try:
            async with httpx.AsyncClient(timeout=300.0) as client:
                pull_data = {"name": self.model_name}
                response = await client.post(
                    f"{self.base_url}/api/pull",
                    json=pull_data
                )
                
                if response.status_code == 200:
                    logger.info(f"Successfully pulled model {self.model_name}")
                    self.current_model_info = self.AVAILABLE_MODELS["ollama"].get(self.model_name.split(':')[0], {
                        "name": self.model_name,
                        "display_name": self.model_name,
                        "size": "Unknown"
                    })
                else:
                    raise Exception(f"Failed to pull model: {response.text}")
                    
        except Exception as e:
            logger.error(f"Model pull failed: {e}")
            raise
    
    async def _initialize_mock(self):
        """Initialize mock LLM for testing"""
        logger.info("Initializing mock LLM service for testing")
        self.current_model_info = {"name": "mock", "display_name": "Mock Model", "size": "Test"}
        await asyncio.sleep(1)  # Simulate initialization time
    
    async def get_available_models(self) -> Dict[str, List[Dict]]:
        """Get list of available models by provider"""
        return {
            "ollama": list(self.AVAILABLE_MODELS["ollama"].values()),
            "huggingface": list(self.AVAILABLE_MODELS["huggingface"].values()),
            "current_provider": self.model_provider,
            "current_model": self.current_model_info
        }
    
    async def switch_model(self, provider: str, model_name: str) -> bool:
        """Switch to a different model"""
        try:
            logger.info(f"Switching to {provider}:{model_name}")
            
            # Validate provider and model
            if provider not in ["ollama", "huggingface", "mock"]:
                raise ValueError(f"Unsupported provider: {provider}")
            
            if provider != "mock":
                # For model validation, check both exact name and base name (without version)
                model_found = False
                if provider in self.AVAILABLE_MODELS:
                    available_models = self.AVAILABLE_MODELS[provider]
                    
                    # Check exact match first
                    if model_name in available_models:
                        model_found = True
                    else:
                        # Check if any of the available models match the requested name
                        for key, model_info in available_models.items():
                            if (model_info["name"] == model_name or 
                                key == model_name.split(':')[0] or  # Match base name
                                model_name.startswith(key)):
                                model_found = True
                                break
                
                if not model_found:
                    raise ValueError(f"Model {model_name} not available for provider {provider}")
            
            # Update configuration
            old_provider = self.model_provider
            old_model = self.model_name
            
            self.model_provider = provider
            self.model_name = model_name
            self.model_loaded = False
            
            # Reinitialize with new model
            try:
                await self.initialize()
                logger.info(f"Successfully switched to {provider}:{model_name}")
                return True
            except Exception as e:
                # Rollback on failure
                self.model_provider = old_provider
                self.model_name = old_model
                await self.initialize()
                logger.error(f"Failed to switch model, rolled back: {e}")
                return False
                
        except Exception as e:
            logger.error(f"Model switch failed: {e}")
            return False
    
    async def process_message(self, message: str, conversation_id: str = None) -> str:
        """Process a chat message and return response"""
        start_time = time.time()
        
        try:
            # Get or create conversation history
            if conversation_id not in self.conversations:
                self.conversations[conversation_id] = []
            
            # Add user message to history
            self.conversations[conversation_id].append({
                "role": "user",
                "content": message,
                "timestamp": datetime.now().isoformat()
            })
            
            # Generate response based on model type
            if self.model_provider == "ollama":
                response = await self._process_ollama_message(message, conversation_id)
            elif self.model_provider == "huggingface":
                response = await self._process_huggingface_message(message, conversation_id)
            else:
                response = await self._process_mock_message(message, conversation_id)
            
            # Add assistant response to history
            self.conversations[conversation_id].append({
                "role": "assistant",
                "content": response,
                "timestamp": datetime.now().isoformat()
            })
            
            # Update metrics
            response_time = time.time() - start_time
            self.message_count += 1
            self.total_response_time += response_time
            
            logger.info(f"Processed message in {response_time:.2f}s")
            return response
            
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            return f"I apologize, but I encountered an error processing your message: {str(e)}"
    
    async def _process_ollama_message(self, message: str, conversation_id: str) -> str:
        """Process message using Ollama"""
        try:
            async with httpx.AsyncClient(timeout=180.0, http2=False) as client:
                # Get conversation context
                context = self._get_conversation_context(conversation_id)
                
                prompt_data = {
                    "model": self.model_name,
                    "prompt": f"Context: {context}\nUser: {message}\nAssistant:",
                    "stream": False
                }
                
                response = await client.post(
                    f"{self.base_url}/api/generate",
                    json=prompt_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return result.get("response", "No response generated")
                else:
                    raise Exception(f"Ollama API error: {response.status_code}")
                    
        except Exception as e:
            logger.error(f"Ollama processing error: {e}")
            raise
    
    async def _process_huggingface_message(self, message: str, conversation_id: str) -> str:
        """Process message using Hugging Face Inference API"""
        try:
            async with httpx.AsyncClient() as client:
                # Prepare headers
                headers = {"Content-Type": "application/json"}
                if self.hf_api_token:
                    headers["Authorization"] = f"Bearer {self.hf_api_token}"
                
                # Build API URL
                api_url = f"https://api-inference.huggingface.co/models/{self.model_name}"
                
                # Get conversation context
                context = self._get_conversation_context(conversation_id)
                
                # Prepare payload based on model type
                if "flan-t5" in self.model_name.lower():
                    # For T5 models, format as question
                    payload = {
                        "inputs": f"Question: {message}",
                        "parameters": {
                            "max_length": 200,
                            "temperature": 0.7,
                            "do_sample": True
                        }
                    }
                elif "dialogpt" in self.model_name.lower():
                    # For DialoGPT, include conversation history
                    full_context = f"{context}\nUser: {message}\nBot:" if context else f"User: {message}\nBot:"
                    payload = {
                        "inputs": full_context,
                        "parameters": {
                            "max_length": 100,
                            "temperature": 0.7,
                            "return_full_text": False
                        }
                    }
                else:
                    # Generic text generation
                    payload = {
                        "inputs": f"User: {message}\nAssistant:",
                        "parameters": {
                            "max_length": 150,
                            "temperature": 0.7,
                            "return_full_text": False
                        }
                    }
                
                response = await client.post(
                    api_url,
                    headers=headers,
                    json=payload,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    
                    # Handle different response formats
                    if isinstance(result, list) and len(result) > 0:
                        if "generated_text" in result[0]:
                            generated_text = result[0]["generated_text"]
                            # Clean up the response
                            if full_context in generated_text:
                                generated_text = generated_text.replace(full_context, "").strip()
                            return generated_text or "I understand, but I don't have a specific response right now."
                        else:
                            return str(result[0])
                    else:
                        return "I received your message but couldn't generate a proper response."
                        
                elif response.status_code == 503:
                    return "The model is currently loading. Please try again in a moment."
                else:
                    logger.error(f"HF API error {response.status_code}: {response.text}")
                    raise Exception(f"Hugging Face API error: {response.status_code}")
                    
        except Exception as e:
            logger.error(f"Hugging Face processing error: {e}")
            # Fallback to a generic response
            return f"I apologize, but I'm having trouble processing your message right now. Error: {str(e)}"
    
    async def _process_mock_message(self, message: str, conversation_id: str) -> str:
        """Process message using mock responses for testing"""
        await asyncio.sleep(0.5)  # Simulate processing time
        
        mock_responses = [
            f"Thank you for your message: '{message}'. This is a mock response from the LLM service.",
            f"I understand you said: '{message}'. I'm a demo chatbot running on Kubernetes!",
            f"Hello! You mentioned: '{message}'. This response is generated by a scalable LLM service.",
            f"Interesting point about: '{message}'. I'm designed to scale automatically based on demand.",
            f"Thanks for sharing: '{message}'. This chatbot demonstrates Kubernetes deployment patterns."
        ]
        
        # Simple response selection based on message hash
        response_index = hash(message) % len(mock_responses)
        return mock_responses[response_index]
    
    def _get_conversation_context(self, conversation_id: str) -> str:
        """Get conversation context for Ollama prompts"""
        conversation = self.conversations.get(conversation_id, [])
        if not conversation:
            return "This is the start of a new conversation."
        
        # Format recent messages as context
        context_messages = []
        for msg in conversation[-5:]:  # Last 5 messages
            context_messages.append(f"{msg['role'].title()}: {msg['content']}")
        
        return "\n".join(context_messages)
    
    async def health_check(self) -> bool:
        """Check if the LLM service is healthy"""
        try:
            if self.model_provider == "ollama":
                async with httpx.AsyncClient() as client:
                    response = await client.get(f"{self.base_url}/api/version", timeout=5.0)
                    healthy = response.status_code == 200
            elif self.model_provider == "huggingface":
                # For HF, we can test with a simple inference call
                async with httpx.AsyncClient() as client:
                    headers = {"Content-Type": "application/json"}
                    if self.hf_api_token:
                        headers["Authorization"] = f"Bearer {self.hf_api_token}"
                    
                    api_url = f"https://api-inference.huggingface.co/models/{self.model_name}"
                    test_payload = {"inputs": "Hello"}
                    
                    response = await client.post(
                        api_url,
                        headers=headers,
                        json=test_payload,
                        timeout=10.0
                    )
                    # 200 (OK) or 503 (model loading) are both acceptable
                    healthy = response.status_code in [200, 503]
            else:
                healthy = True  # Mock is always healthy
            
            self.last_health_check = datetime.now()
            return healthy
            
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False
    
    async def get_model_status(self) -> dict:
        """Get current model status"""
        return {
            "model_provider": self.model_provider,
            "model_name": self.model_name,
            "model_loaded": self.model_loaded,
            "is_initialized": self.is_initialized,
            "last_health_check": self.last_health_check.isoformat() if self.last_health_check else None
        }
    
    async def is_model_loaded(self) -> bool:
        """Check if model is loaded"""
        return self.model_loaded
    
    def get_message_count(self) -> int:
        """Get total message count"""
        return self.message_count
    
    def get_uptime(self) -> float:
        """Get service uptime in seconds"""
        return time.time() - self.start_time
    
    def get_average_response_time(self) -> float:
        """Get average response time"""
        if self.message_count == 0:
            return 0.0
        return self.total_response_time / self.message_count
    
    async def cleanup(self):
        """Cleanup resources"""
        logger.info("Cleaning up LLM service resources")
        self.conversations.clear()
        self.is_initialized = False 