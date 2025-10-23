from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from app.routers import chat, network
from app.config import config_manager
import logging
import os
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    """Create and configure FastAPI application"""
    
    # Load configuration
    config_manager.load_azure_config()
    
    # Configure Azure Monitor if connection string is available
    if config_manager.settings.applicationinsights_connection_string:
        try:
            configure_azure_monitor(
                connection_string=config_manager.settings.applicationinsights_connection_string
            )
            logger.info("Application Insights configured successfully")
        except Exception as e:
            logger.error(f"Failed to configure Application Insights: {e}")
    
    # Create FastAPI app
    app = FastAPI(
        title="AI Landing Zone Chat Application",
        description="Chat application with network connectivity testing for Azure AI Landing Zone",
        version="1.0.0"
    )
    
    # Instrument FastAPI with OpenTelemetry
    FastAPIInstrumentor.instrument_app(app)
    
    # Include routers
    app.include_router(chat.router)
    app.include_router(network.router)
    
    # Mount static files
    static_path = os.path.join(os.path.dirname(__file__), "static")
    app.mount("/static", StaticFiles(directory=static_path), name="static")
    
    @app.get("/")
    async def root():
        """Serve the main chat interface"""
        return FileResponse(os.path.join(static_path, "index.html"))
    
    @app.get("/health")
    async def health_check():
        """Health check endpoint"""
        return {
            "status": "healthy",
            "app_name": config_manager.settings.app_name,
            "ai_service_available": await _check_ai_service(),
            "cosmos_db_available": _check_cosmos_db()
        }
    
    @app.on_event("startup")
    async def startup_event():
        """Application startup event"""
        logger.info("Starting AI Landing Zone Chat Application")
        logger.info(f"Azure OpenAI Endpoint: {config_manager.settings.azure_openai_endpoint}")
        logger.info(f"Cosmos DB Endpoint: {config_manager.settings.cosmos_db_endpoint}")
        logger.info(f"Application Insights: {'Configured' if config_manager.settings.applicationinsights_connection_string else 'Not configured'}")
        
        # Log startup event to Application Insights
        tracer = trace.get_tracer(__name__)
        with tracer.start_as_current_span("application_startup"):
            logger.info("Application startup completed")
    
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        """Log HTTP requests"""
        start_time = time.time()
        
        response = await call_next(request)
        
        process_time = time.time() - start_time
        logger.info(
            f"{request.method} {request.url.path} - "
            f"Status: {response.status_code} - "
            f"Time: {process_time:.4f}s"
        )
        
        return response
    
    return app


async def _check_ai_service() -> bool:
    """Check if AI service is available"""
    try:
        from app.services.ai_service import AIService
        ai_service = AIService()
        return ai_service.is_available()
    except Exception:
        return False


def _check_cosmos_db() -> bool:
    """Check if Cosmos DB is available"""
    try:
        from app.services.chat_service import ChatHistoryService
        chat_service = ChatHistoryService()
        return chat_service.container is not None
    except Exception:
        return False


# Create the app instance
app = create_app()

if __name__ == "__main__":
    import uvicorn
    import time
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=config_manager.settings.debug
    )