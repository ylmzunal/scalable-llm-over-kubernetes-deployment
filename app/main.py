from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
import json
import logging
import os
from typing import List
import asyncio
from datetime import datetime
from pydantic import BaseModel

from .models import ChatMessage, ChatResponse
from .llm_service import LLMService
from .connection_manager import ConnectionManager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Scalable LLM Chatbot",
    description="A scalable chatbot service powered by multiple LLM providers on Kubernetes",
    version="2.0.0"
)

# CORS middleware for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
llm_service = LLMService()
connection_manager = ConnectionManager()

# New models for model management
class ModelSwitchRequest(BaseModel):
    provider: str
    model_name: str

class ModelSwitchResponse(BaseModel):
    success: bool
    message: str
    current_provider: str
    current_model: str

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("Starting LLM Chatbot Service...")
    await llm_service.initialize()
    logger.info("LLM Service initialized successfully")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down LLM Chatbot Service...")
    await llm_service.cleanup()

@app.get("/")
async def read_root():
    """Health check endpoint"""
    return {
        "service": "Multi-Model LLM Chatbot",
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "2.0.0",
        "current_model": llm_service.current_model_info
    }

@app.get("/health")
async def health_check():
    """Kubernetes health check endpoint"""
    try:
        # Check if LLM service is responsive
        is_healthy = await llm_service.health_check()
        if is_healthy:
            return {"status": "healthy", "timestamp": datetime.now().isoformat()}
        else:
            raise HTTPException(status_code=503, detail="LLM service not available")
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

@app.get("/models")
async def get_available_models():
    """Get list of available models and current model info"""
    try:
        models_info = await llm_service.get_available_models()
        return {
            "available_models": models_info,
            "description": "Free models available for selection",
            "providers": {
                "ollama": "Local models running on your machine (privacy-focused)",
                "huggingface": "Free Hugging Face Inference API models"
            }
        }
    except Exception as e:
        logger.error(f"Failed to get available models: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching models: {str(e)}")

@app.post("/models/switch", response_model=ModelSwitchResponse)
async def switch_model(request: ModelSwitchRequest):
    """Switch to a different model"""
    try:
        success = await llm_service.switch_model(request.provider, request.model_name)
        
        current_model_info = llm_service.current_model_info or {}
        
        if success:
            return ModelSwitchResponse(
                success=True,
                message=f"Successfully switched to {request.provider}:{request.model_name}",
                current_provider=llm_service.model_provider,
                current_model=current_model_info.get("display_name", request.model_name)
            )
        else:
            return ModelSwitchResponse(
                success=False,
                message=f"Failed to switch to {request.provider}:{request.model_name}",
                current_provider=llm_service.model_provider,
                current_model=current_model_info.get("display_name", "Unknown")
            )
            
    except Exception as e:
        logger.error(f"Model switch error: {e}")
        raise HTTPException(status_code=500, detail=f"Error switching model: {str(e)}")

@app.get("/models/current")
async def get_current_model():
    """Get current model information"""
    return {
        "provider": llm_service.model_provider,
        "model_name": llm_service.model_name,
        "model_info": llm_service.current_model_info,
        "status": {
            "loaded": llm_service.model_loaded,
            "initialized": llm_service.is_initialized,
            "last_health_check": llm_service.last_health_check.isoformat() if llm_service.last_health_check else None
        }
    }

@app.get("/metrics")
async def get_metrics():
    """Basic metrics endpoint for monitoring"""
    return {
        "active_connections": connection_manager.get_connection_count(),
        "total_messages_processed": llm_service.get_message_count(),
        "uptime_seconds": llm_service.get_uptime(),
        "model_status": await llm_service.get_model_status()
    }

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(message: ChatMessage):
    """REST endpoint for chat messages"""
    try:
        response = await llm_service.process_message(message.message, message.conversation_id)
        return ChatResponse(
            response=response,
            conversation_id=message.conversation_id,
            timestamp=datetime.now().isoformat()
        )
    except Exception as e:
        logger.error(f"Error processing chat message: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing message: {str(e)}")

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    """WebSocket endpoint for real-time chat"""
    await connection_manager.connect(websocket, client_id)
    logger.info(f"Client {client_id} connected via WebSocket")
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Process message with LLM
            response = await llm_service.process_message(
                message_data.get("message", ""),
                message_data.get("conversation_id", client_id)
            )
            
            # Send response back to client
            response_data = {
                "response": response,
                "timestamp": datetime.now().isoformat(),
                "conversation_id": message_data.get("conversation_id", client_id)
            }
            
            await connection_manager.send_personal_message(
                json.dumps(response_data), client_id
            )
            
            logger.info(f"Processed message for client {client_id}")
            
    except WebSocketDisconnect:
        connection_manager.disconnect(client_id)
        logger.info(f"Client {client_id} disconnected")
    except Exception as e:
        logger.error(f"WebSocket error for client {client_id}: {e}")
        connection_manager.disconnect(client_id)

@app.get("/stats")
async def get_stats():
    """Get detailed service statistics"""
    return {
        "service_info": {
            "name": "Scalable LLM Chatbot",
            "version": "1.0.0",
            "environment": os.getenv("ENVIRONMENT", "development")
        },
        "connections": {
            "active_websocket_connections": connection_manager.get_connection_count(),
            "total_connections_served": connection_manager.get_total_connections()
        },
        "llm_service": {
            "messages_processed": llm_service.get_message_count(),
            "average_response_time": llm_service.get_average_response_time(),
            "model_loaded": await llm_service.is_model_loaded(),
            "uptime_seconds": llm_service.get_uptime()
        },
        "system": {
            "timestamp": datetime.now().isoformat(),
            "pod_name": os.getenv("HOSTNAME", "unknown"),
            "namespace": os.getenv("POD_NAMESPACE", "default")
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        reload=True,
        log_level="info"
    ) 