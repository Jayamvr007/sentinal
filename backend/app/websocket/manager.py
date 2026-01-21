"""WebSocket Connection Manager"""
import asyncio
import json
from typing import Dict, Set
from fastapi import WebSocket
from datetime import datetime

from ..models import PriceData, WebSocketMessage


class ConnectionManager:
    """
    Manages WebSocket connections for real-time price streaming.
    Supports multiple clients and broadcasts price updates to all.
    """
    
    def __init__(self):
        # Active WebSocket connections
        self._active_connections: Set[WebSocket] = set()
        # Track subscriptions per connection
        self._subscriptions: Dict[WebSocket, Set[str]] = {}
    
    @property
    def connection_count(self) -> int:
        return len(self._active_connections)
    
    async def connect(self, websocket: WebSocket, symbols: list[str] | None = None):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        self._active_connections.add(websocket)
        # Subscribe to all symbols by default, or specific ones
        self._subscriptions[websocket] = set(symbols) if symbols else set()
        print(f"[WS] Client connected. Total connections: {self.connection_count}")
    
    def disconnect(self, websocket: WebSocket):
        """Handle WebSocket disconnection"""
        self._active_connections.discard(websocket)
        self._subscriptions.pop(websocket, None)
        print(f"[WS] Client disconnected. Total connections: {self.connection_count}")
    
    async def send_personal(self, websocket: WebSocket, message: dict):
        """Send a message to a specific client"""
        try:
            await websocket.send_json(message)
        except Exception as e:
            print(f"[WS] Error sending to client: {e}")
            self.disconnect(websocket)
    
    async def broadcast(self, message: dict):
        """Broadcast a message to all connected clients"""
        if not self._active_connections:
            return
        
        # Create tasks for parallel sending
        disconnected = []
        for connection in self._active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                disconnected.append(connection)
        
        # Clean up disconnected clients
        for conn in disconnected:
            self.disconnect(conn)
    
    async def broadcast_prices(self, prices: list[PriceData]):
        """Broadcast price updates to all clients"""
        if not self._active_connections:
            return
        
        message = WebSocketMessage(
            type="price_update",
            data={"prices": [p.model_dump() for p in prices]},
            timestamp=datetime.utcnow()
        )
        
        await self.broadcast(message.model_dump(mode="json"))
    
    async def send_heartbeat(self):
        """Send heartbeat to keep connections alive"""
        message = WebSocketMessage(
            type="heartbeat",
            data={"status": "alive"},
            timestamp=datetime.utcnow()
        )
        await self.broadcast(message.model_dump(mode="json"))


# Singleton instance
connection_manager = ConnectionManager()
