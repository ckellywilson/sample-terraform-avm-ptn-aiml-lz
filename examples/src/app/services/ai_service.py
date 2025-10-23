from openai import AzureOpenAI
from typing import List, Dict, Any
from app.models import ChatMessage, ChatRequest, ChatResponse
from app.config import config_manager
import logging

logger = logging.getLogger(__name__)


class AIService:
    def __init__(self):
        self.client = None
        self._initialize_openai_client()
    
    def _initialize_openai_client(self):
        """Initialize Azure OpenAI client"""
        try:
            config_manager.load_azure_config()
            endpoint = config_manager.settings.azure_openai_endpoint
            api_key = config_manager.settings.azure_openai_api_key
            api_version = config_manager.settings.azure_openai_api_version
            
            if not endpoint or not api_key:
                logger.error("Azure OpenAI configuration not available")
                return
            
            self.client = AzureOpenAI(
                azure_endpoint=endpoint,
                api_key=api_key,
                api_version=api_version
            )
            logger.info("Azure OpenAI client initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Azure OpenAI client: {e}")
    
    async def generate_response(self, messages: List[ChatMessage], deployment_name: str = None) -> str:
        """Generate AI response using Azure OpenAI"""
        if not self.client:
            return "Sorry, AI service is not available. Please check the configuration."
        
        try:
            # Convert ChatMessage objects to OpenAI format
            openai_messages = []
            for msg in messages:
                openai_messages.append({
                    "role": msg.role,
                    "content": msg.content
                })
            
            # Use configured deployment name or default
            deployment = deployment_name or config_manager.settings.azure_openai_deployment
            
            # Call Azure OpenAI
            response = self.client.chat.completions.create(
                model=deployment,
                messages=openai_messages,
                max_tokens=1000,
                temperature=0.7,
                top_p=0.9
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            logger.error(f"Failed to generate AI response: {e}")
            return f"Sorry, I encountered an error: {str(e)}"
    
    async def generate_chat_title(self, first_message: str) -> str:
        """Generate a title for the chat session based on the first message"""
        if not self.client:
            return "New Chat"
        
        try:
            title_prompt = [
                {
                    "role": "system", 
                    "content": "Generate a short, descriptive title (4-6 words) for a chat conversation based on the user's first message. Only return the title, no explanation."
                },
                {
                    "role": "user", 
                    "content": first_message
                }
            ]
            
            deployment = config_manager.settings.azure_openai_deployment
            
            response = self.client.chat.completions.create(
                model=deployment,
                messages=title_prompt,
                max_tokens=50,
                temperature=0.3
            )
            
            title = response.choices[0].message.content.strip().strip('"')
            return title[:50]  # Limit title length
            
        except Exception as e:
            logger.error(f"Failed to generate chat title: {e}")
            return "New Chat"
    
    def is_available(self) -> bool:
        """Check if AI service is available"""
        return self.client is not None
    
    async def test_connection(self) -> Dict[str, Any]:
        """Test connection to Azure OpenAI service"""
        if not self.client:
            return {
                "status": "error",
                "message": "Azure OpenAI client not initialized"
            }
        
        try:
            # Simple test call
            response = self.client.chat.completions.create(
                model=config_manager.settings.azure_openai_deployment,
                messages=[{"role": "user", "content": "Hello"}],
                max_tokens=10
            )
            
            return {
                "status": "success",
                "message": "Azure OpenAI connection successful",
                "model": config_manager.settings.azure_openai_deployment,
                "response_preview": response.choices[0].message.content[:50]
            }
            
        except Exception as e:
            logger.error(f"Azure OpenAI connection test failed: {e}")
            return {
                "status": "error", 
                "message": f"Connection test failed: {str(e)}"
            }