from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import uuid


class ChatMessage(BaseModel):
    id: str = None
    session_id: str
    role: str  # "user" or "assistant"
    content: str
    timestamp: datetime = None
    
    def __init__(self, **data):
        if data.get('id') is None:
            data['id'] = str(uuid.uuid4())
        if data.get('timestamp') is None:
            data['timestamp'] = datetime.utcnow()
        super().__init__(**data)


class ChatSession(BaseModel):
    id: str = None
    title: str = "New Chat"
    created_at: datetime = None
    updated_at: datetime = None
    message_count: int = 0
    
    def __init__(self, **data):
        if data.get('id') is None:
            data['id'] = str(uuid.uuid4())
        if data.get('created_at') is None:
            data['created_at'] = datetime.utcnow()
        if data.get('updated_at') is None:
            data['updated_at'] = datetime.utcnow()
        super().__init__(**data)


class NetworkTestResult(BaseModel):
    endpoint: str
    is_reachable: bool
    response_time_ms: Optional[float] = None
    ip_address: Optional[str] = None
    error_message: Optional[str] = None
    test_timestamp: datetime = None
    
    def __init__(self, **data):
        if data.get('test_timestamp') is None:
            data['test_timestamp'] = datetime.utcnow()
        super().__init__(**data)


class NetworkTestSummary(BaseModel):
    total_endpoints: int
    reachable_endpoints: int
    unreachable_endpoints: int
    average_response_time_ms: Optional[float] = None
    test_results: List[NetworkTestResult]
    overall_status: str  # "healthy", "degraded", or "unhealthy"
    last_test_time: datetime = None
    
    def __init__(self, **data):
        if data.get('last_test_time') is None:
            data['last_test_time'] = datetime.utcnow()
        super().__init__(**data)


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    message: str
    session_id: str
    message_id: str