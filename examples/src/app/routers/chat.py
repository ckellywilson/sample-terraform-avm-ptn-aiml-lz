from fastapi import APIRouter, HTTPException, Depends
from typing import List
from app.models import ChatRequest, ChatResponse, ChatMessage, ChatSession
from app.services.chat_service import ChatHistoryService
from app.services.ai_service import AIService
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/chat", tags=["chat"])

# Service instances
chat_history_service = ChatHistoryService()
ai_service = AIService()


@router.post("/", response_model=ChatResponse)
async def send_message(request: ChatRequest):
    """Send a message and get AI response"""
    try:
        # Create or use existing session
        session_id = request.session_id
        if not session_id:
            # Create new session
            session = await chat_history_service.create_session()
            session_id = session.id
        
        # Create user message
        user_message = ChatMessage(
            session_id=session_id,
            role="user",
            content=request.message
        )
        
        # Save user message
        await chat_history_service.save_message(user_message)
        
        # Get conversation history for context
        message_history = await chat_history_service.get_session_messages(session_id)
        
        # Generate AI response
        ai_response_content = await ai_service.generate_response(message_history)
        
        # Create assistant message
        assistant_message = ChatMessage(
            session_id=session_id,
            role="assistant", 
            content=ai_response_content
        )
        
        # Save assistant message
        await chat_history_service.save_message(assistant_message)
        
        # If this is the first message, generate a title for the session
        if len(message_history) <= 2:  # user + assistant message
            title = await ai_service.generate_chat_title(request.message)
            await chat_history_service.update_session(session_id, title=title)
        
        return ChatResponse(
            message=ai_response_content,
            session_id=session_id,
            message_id=assistant_message.id
        )
        
    except Exception as e:
        logger.error(f"Error processing chat message: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/sessions", response_model=List[ChatSession])
async def get_recent_sessions():
    """Get recent chat sessions"""
    try:
        sessions = await chat_history_service.get_recent_sessions()
        return sessions
    except Exception as e:
        logger.error(f"Error retrieving sessions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/sessions/{session_id}/messages", response_model=List[ChatMessage])
async def get_session_messages(session_id: str):
    """Get messages for a specific session"""
    try:
        messages = await chat_history_service.get_session_messages(session_id)
        return messages
    except Exception as e:
        logger.error(f"Error retrieving session messages: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/sessions", response_model=ChatSession)
async def create_new_session():
    """Create a new chat session"""
    try:
        session = await chat_history_service.create_session()
        return session
    except Exception as e:
        logger.error(f"Error creating new session: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/test")
async def test_ai_service():
    """Test AI service connectivity"""
    try:
        test_result = await ai_service.test_connection()
        return test_result
    except Exception as e:
        logger.error(f"Error testing AI service: {e}")
        raise HTTPException(status_code=500, detail=str(e))