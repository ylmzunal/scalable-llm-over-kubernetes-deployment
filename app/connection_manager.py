from fastapi import WebSocket
import logging
from typing import Dict, List
import asyncio
import json
from datetime import datetime

logger = logging.getLogger(__name__)

class ConnectionManager:
    """Manages WebSocket connections for the chatbot"""
    
    def __init__(self):
        # Active connections: client_id -> WebSocket
        self.active_connections: Dict[str, WebSocket] = {}
        # Connection metadata
        self.connection_metadata: Dict[str, dict] = {}
        # Total connections served (for metrics)
        self.total_connections_served = 0
        
    async def connect(self, websocket: WebSocket, client_id: str):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        self.connection_metadata[client_id] = {
            "connected_at": datetime.now(),
            "messages_sent": 0,
            "last_activity": datetime.now()
        }
        self.total_connections_served += 1
        
        logger.info(f"Client {client_id} connected. Total active: {len(self.active_connections)}")
        
        # Send welcome message
        welcome_message = {
            "type": "system",
            "message": "Connected to LLM Chatbot! Start typing to chat.",
            "timestamp": datetime.now().isoformat(),
            "client_id": client_id
        }
        await self.send_personal_message(json.dumps(welcome_message), client_id)
    
    def disconnect(self, client_id: str):
        """Remove a WebSocket connection"""
        if client_id in self.active_connections:
            del self.active_connections[client_id]
        if client_id in self.connection_metadata:
            del self.connection_metadata[client_id]
        
        logger.info(f"Client {client_id} disconnected. Total active: {len(self.active_connections)}")
    
    async def send_personal_message(self, message: str, client_id: str):
        """Send a message to a specific client"""
        if client_id in self.active_connections:
            try:
                websocket = self.active_connections[client_id]
                await websocket.send_text(message)
                
                # Update metadata
                if client_id in self.connection_metadata:
                    self.connection_metadata[client_id]["messages_sent"] += 1
                    self.connection_metadata[client_id]["last_activity"] = datetime.now()
                    
                logger.debug(f"Message sent to client {client_id}")
                
            except Exception as e:
                logger.error(f"Error sending message to client {client_id}: {e}")
                # Remove stale connection
                self.disconnect(client_id)
    
    async def broadcast(self, message: str, exclude_client: str = None):
        """Broadcast a message to all connected clients"""
        disconnected_clients = []
        
        for client_id, websocket in self.active_connections.items():
            if exclude_client and client_id == exclude_client:
                continue
                
            try:
                await websocket.send_text(message)
                
                # Update metadata
                if client_id in self.connection_metadata:
                    self.connection_metadata[client_id]["messages_sent"] += 1
                    self.connection_metadata[client_id]["last_activity"] = datetime.now()
                    
            except Exception as e:
                logger.error(f"Error broadcasting to client {client_id}: {e}")
                disconnected_clients.append(client_id)
        
        # Clean up disconnected clients
        for client_id in disconnected_clients:
            self.disconnect(client_id)
        
        logger.info(f"Broadcasted message to {len(self.active_connections)} clients")
    
    async def send_status_update(self, status: dict):
        """Send status update to all connected clients"""
        status_message = {
            "type": "status",
            "data": status,
            "timestamp": datetime.now().isoformat()
        }
        await self.broadcast(json.dumps(status_message))
    
    async def ping_all_connections(self):
        """Send ping to all connections to check connectivity"""
        ping_message = {
            "type": "ping",
            "timestamp": datetime.now().isoformat()
        }
        await self.broadcast(json.dumps(ping_message))
    
    def get_connection_count(self) -> int:
        """Get number of active connections"""
        return len(self.active_connections)
    
    def get_total_connections(self) -> int:
        """Get total connections served since startup"""
        return self.total_connections_served
    
    def get_client_info(self, client_id: str) -> dict:
        """Get information about a specific client"""
        if client_id not in self.connection_metadata:
            return None
        
        metadata = self.connection_metadata[client_id]
        return {
            "client_id": client_id,
            "connected_at": metadata["connected_at"].isoformat(),
            "messages_sent": metadata["messages_sent"],
            "last_activity": metadata["last_activity"].isoformat(),
            "is_connected": client_id in self.active_connections
        }
    
    def get_all_clients_info(self) -> List[dict]:
        """Get information about all clients"""
        return [
            self.get_client_info(client_id) 
            for client_id in self.connection_metadata.keys()
        ]
    
    async def cleanup_stale_connections(self, timeout_minutes: int = 30):
        """Remove connections that haven't been active for a while"""
        current_time = datetime.now()
        stale_clients = []
        
        for client_id, metadata in self.connection_metadata.items():
            time_diff = current_time - metadata["last_activity"]
            if time_diff.total_seconds() > (timeout_minutes * 60):
                stale_clients.append(client_id)
        
        for client_id in stale_clients:
            logger.info(f"Removing stale connection: {client_id}")
            self.disconnect(client_id)
        
        return len(stale_clients)
    
    def get_connection_stats(self) -> dict:
        """Get comprehensive connection statistics"""
        return {
            "active_connections": len(self.active_connections),
            "total_connections_served": self.total_connections_served,
            "clients": self.get_all_clients_info(),
            "timestamp": datetime.now().isoformat()
        } 