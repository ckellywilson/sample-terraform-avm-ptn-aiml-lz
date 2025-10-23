import os
from typing import Optional
from pydantic_settings import BaseSettings
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient


class Settings(BaseSettings):
    # Application settings
    app_name: str = "AI Landing Zone Chat App"
    debug: bool = False
    
    # Azure OpenAI settings
    azure_openai_endpoint: Optional[str] = None
    azure_openai_api_key: Optional[str] = None
    azure_openai_deployment: str = "gpt-4.1"  # Default deployment name from main.tf
    azure_openai_api_version: str = "2024-02-01"
    
    # Cosmos DB settings
    cosmos_db_endpoint: Optional[str] = None
    cosmos_db_key: Optional[str] = None
    cosmos_db_database: str = "chathistory"
    cosmos_db_container: str = "conversations"
    
    # Application Insights
    applicationinsights_connection_string: Optional[str] = None
    
    # Key Vault settings (for retrieving secrets)
    key_vault_url: Optional[str] = None
    
    # Network testing endpoints
    test_endpoints: list = [
        "privatelink.openai.azure.com",
        "privatelink.documents.azure.com",
        "privatelink.blob.core.windows.net", 
        "privatelink.services.ai.azure.com",
        "privatelink.cognitiveservices.azure.com",
        "privatelink.vaultcore.azure.net",
        "privatelink.azurecr.io",
        "privatelink.azconfig.io",
        "privatelink.azure-api.net"  # APIM if deployed
    ]
    
    class Config:
        env_file = ".env"
        case_sensitive = False


class ConfigManager:
    def __init__(self):
        self.settings = Settings()
        self._credential = None
        self._key_vault_client = None
        
    def get_credential(self):
        """Get Azure credential (Managed Identity in production, Default for development)"""
        if self._credential is None:
            try:
                # Try Managed Identity first (for Container Apps/VM deployment)
                self._credential = ManagedIdentityCredential()
            except Exception:
                # Fall back to DefaultAzureCredential for development
                self._credential = DefaultAzureCredential()
        return self._credential
    
    def get_key_vault_client(self):
        """Get Key Vault client if configured"""
        if self.settings.key_vault_url and self._key_vault_client is None:
            self._key_vault_client = SecretClient(
                vault_url=self.settings.key_vault_url,
                credential=self.get_credential()
            )
        return self._key_vault_client
    
    def get_secret(self, secret_name: str) -> Optional[str]:
        """Retrieve secret from Key Vault or environment variables"""
        # Try environment variable first
        env_value = os.getenv(secret_name.upper().replace('-', '_'))
        if env_value:
            return env_value
            
        # Try Key Vault if configured
        kv_client = self.get_key_vault_client()
        if kv_client:
            try:
                secret = kv_client.get_secret(secret_name)
                return secret.value
            except Exception as e:
                print(f"Failed to retrieve secret {secret_name} from Key Vault: {e}")
        
        return None
    
    def load_azure_config(self):
        """Load Azure service configurations"""
        # Load OpenAI config
        if not self.settings.azure_openai_endpoint:
            self.settings.azure_openai_endpoint = self.get_secret("azure-openai-endpoint")
        if not self.settings.azure_openai_api_key:
            self.settings.azure_openai_api_key = self.get_secret("azure-openai-api-key")
            
        # Load Cosmos DB config
        if not self.settings.cosmos_db_endpoint:
            self.settings.cosmos_db_endpoint = self.get_secret("cosmos-db-endpoint")
        if not self.settings.cosmos_db_key:
            self.settings.cosmos_db_key = self.get_secret("cosmos-db-key")
            
        # Load Application Insights config
        if not self.settings.applicationinsights_connection_string:
            self.settings.applicationinsights_connection_string = self.get_secret("applicationinsights-connection-string")


# Global configuration instance
config_manager = ConfigManager()
settings = config_manager.settings