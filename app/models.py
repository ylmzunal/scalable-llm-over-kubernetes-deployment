from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class ChatMessage(BaseModel):
    """Model for incoming chat messages"""
    message: str = Field(..., description="The user's message")
    conversation_id: Optional[str] = Field(None, description="Conversation identifier")
    user_id: Optional[str] = Field(None, description="User identifier")
    metadata: Optional[dict] = Field(None, description="Additional metadata")

class ChatResponse(BaseModel):
    """Model for chat responses"""
    response: str = Field(..., description="The chatbot's response")
    conversation_id: Optional[str] = Field(None, description="Conversation identifier")
    timestamp: str = Field(..., description="Response timestamp")
    metadata: Optional[dict] = Field(None, description="Response metadata")

class ConversationHistory(BaseModel):
    """Model for conversation history"""
    conversation_id: str = Field(..., description="Conversation identifier")
    messages: List[dict] = Field(..., description="List of messages in conversation")
    created_at: datetime = Field(..., description="Conversation creation time")
    updated_at: datetime = Field(..., description="Last update time")

class HealthStatus(BaseModel):
    """Model for health check responses"""
    status: str = Field(..., description="Service status")
    timestamp: str = Field(..., description="Health check timestamp")
    details: Optional[dict] = Field(None, description="Additional health details")

class MetricsResponse(BaseModel):
    """Model for metrics responses"""
    active_connections: int = Field(..., description="Number of active connections")
    total_messages_processed: int = Field(..., description="Total messages processed")
    uptime_seconds: float = Field(..., description="Service uptime in seconds")
    model_status: dict = Field(..., description="LLM model status information") 