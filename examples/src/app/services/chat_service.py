from azure.cosmos import CosmosClient, exceptions
from typing import List, Optional
from app.models import ChatMessage, ChatSession
from app.config import config_manager
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class ChatHistoryService:
    def __init__(self):
        self.client = None
        self.database = None
        self.container = None
        self._initialize_cosmos_client()
    
    def _initialize_cosmos_client(self):
        """Initialize Cosmos DB client and container"""
        try:
            config_manager.load_azure_config()
            endpoint = config_manager.settings.cosmos_db_endpoint
            key = config_manager.settings.cosmos_db_key
            
            if not endpoint or not key:
                logger.warning("Cosmos DB configuration not available. Chat history will not be persisted.")
                return
            
            self.client = CosmosClient(endpoint, key)
            
            # Create database if it doesn't exist
            database_name = config_manager.settings.cosmos_db_database
            try:
                self.database = self.client.create_database_if_not_exists(id=database_name)
                logger.info(f"Connected to Cosmos DB database: {database_name}")
            except exceptions.CosmosHttpResponseError as e:
                logger.error(f"Failed to create/access database {database_name}: {e}")
                return
            
            # Create container if it doesn't exist
            container_name = config_manager.settings.cosmos_db_container
            try:
                self.container = self.database.create_container_if_not_exists(
                    id=container_name,
                    partition_key="/session_id",
                    offer_throughput=400
                )
                logger.info(f"Connected to Cosmos DB container: {container_name}")
            except exceptions.CosmosHttpResponseError as e:
                logger.error(f"Failed to create/access container {container_name}: {e}")
                
        except Exception as e:
            logger.error(f"Failed to initialize Cosmos DB client: {e}")
    
    async def save_message(self, message: ChatMessage) -> bool:
        """Save a chat message to Cosmos DB"""
        if not self.container:
            logger.warning("Cosmos DB not available. Message not saved.")
            return False
        
        try:
            message_dict = message.dict()
            message_dict['timestamp'] = message_dict['timestamp'].isoformat()
            
            self.container.create_item(message_dict)
            logger.debug(f"Saved message {message.id} to Cosmos DB")
            return True
            
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"Failed to save message to Cosmos DB: {e}")
            return False
    
    async def get_session_messages(self, session_id: str, limit: int = 50) -> List[ChatMessage]:
        """Retrieve messages for a specific chat session"""
        if not self.container:
            logger.warning("Cosmos DB not available. Returning empty message list.")
            return []
        
        try:
            query = "SELECT * FROM c WHERE c.session_id = @session_id ORDER BY c.timestamp"
            parameters = [{"name": "@session_id", "value": session_id}]
            
            items = list(self.container.query_items(
                query=query,
                parameters=parameters,
                max_item_count=limit
            ))
            
            messages = []
            for item in items:
                # Convert timestamp back to datetime
                if isinstance(item['timestamp'], str):
                    item['timestamp'] = datetime.fromisoformat(item['timestamp'])
                messages.append(ChatMessage(**item))
            
            logger.debug(f"Retrieved {len(messages)} messages for session {session_id}")
            return messages
            
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"Failed to retrieve messages from Cosmos DB: {e}")
            return []
    
    async def create_session(self, title: str = "New Chat") -> ChatSession:
        """Create a new chat session"""
        session = ChatSession(title=title)
        
        if not self.container:
            logger.warning("Cosmos DB not available. Session created in memory only.")
            return session
        
        try:
            session_dict = session.dict()
            session_dict['created_at'] = session_dict['created_at'].isoformat()
            session_dict['updated_at'] = session_dict['updated_at'].isoformat()
            session_dict['doc_type'] = 'session'  # Distinguish from messages
            
            self.container.create_item(session_dict)
            logger.debug(f"Created session {session.id} in Cosmos DB")
            
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"Failed to save session to Cosmos DB: {e}")
        
        return session
    
    async def get_recent_sessions(self, limit: int = 10) -> List[ChatSession]:
        """Get recent chat sessions"""
        if not self.container:
            logger.warning("Cosmos DB not available. Returning empty session list.")
            return []
        
        try:
            query = "SELECT * FROM c WHERE c.doc_type = 'session' ORDER BY c.updated_at DESC"
            
            items = list(self.container.query_items(
                query=query,
                max_item_count=limit
            ))
            
            sessions = []
            for item in items:
                # Convert timestamps back to datetime
                if isinstance(item['created_at'], str):
                    item['created_at'] = datetime.fromisoformat(item['created_at'])
                if isinstance(item['updated_at'], str):
                    item['updated_at'] = datetime.fromisoformat(item['updated_at'])
                
                # Remove doc_type before creating ChatSession
                item.pop('doc_type', None)
                sessions.append(ChatSession(**item))
            
            logger.debug(f"Retrieved {len(sessions)} recent sessions")
            return sessions
            
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"Failed to retrieve sessions from Cosmos DB: {e}")
            return []
    
    async def update_session(self, session_id: str, title: Optional[str] = None) -> bool:
        """Update a chat session"""
        if not self.container:
            return False
            
        try:
            # First, get the existing session
            query = "SELECT * FROM c WHERE c.id = @session_id AND c.doc_type = 'session'"
            parameters = [{"name": "@session_id", "value": session_id}]
            
            items = list(self.container.query_items(query=query, parameters=parameters))
            if not items:
                logger.warning(f"Session {session_id} not found")
                return False
            
            session_item = items[0]
            
            # Update fields
            if title:
                session_item['title'] = title
            session_item['updated_at'] = datetime.utcnow().isoformat()
            
            # Replace the item
            self.container.replace_item(session_item, session_item)
            logger.debug(f"Updated session {session_id}")
            return True
            
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"Failed to update session {session_id}: {e}")
            return False