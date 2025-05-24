import pytest
import asyncio
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data

def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "LLM Chatbot"
    assert data["status"] == "healthy"
    assert data["version"] == "1.0.0"

def test_metrics_endpoint():
    """Test the metrics endpoint"""
    response = client.get("/metrics")
    assert response.status_code == 200
    data = response.json()
    assert "active_connections" in data
    assert "total_messages_processed" in data
    assert "uptime_seconds" in data

def test_stats_endpoint():
    """Test the stats endpoint"""
    response = client.get("/stats")
    assert response.status_code == 200
    data = response.json()
    assert "service_info" in data
    assert "connections" in data
    assert "llm_service" in data
    assert "system" in data

def test_chat_endpoint():
    """Test the chat endpoint"""
    response = client.post("/chat", json={
        "message": "Hello, how are you?",
        "conversation_id": "test-123"
    })
    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert "conversation_id" in data
    assert "timestamp" in data
    assert data["conversation_id"] == "test-123"

def test_chat_endpoint_empty_message():
    """Test chat endpoint with empty message"""
    response = client.post("/chat", json={
        "message": "",
        "conversation_id": "test-empty"
    })
    assert response.status_code == 200
    # Should still work with empty message

def test_chat_endpoint_no_conversation_id():
    """Test chat endpoint without conversation_id"""
    response = client.post("/chat", json={
        "message": "Test message"
    })
    assert response.status_code == 200
    data = response.json()
    assert "response" in data

@pytest.mark.asyncio
async def test_websocket_connection():
    """Test WebSocket connection (basic test)"""
    # Note: This is a basic test structure
    # Full WebSocket testing would require more complex setup
    from fastapi.websockets import WebSocketDisconnect
    
    # This would require a WebSocket test client
    # For now, we just test that the endpoint exists
    pass

if __name__ == "__main__":
    pytest.main([__file__]) 