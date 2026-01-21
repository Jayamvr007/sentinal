"""
Sentinel API - Main Application Entry Point

A real-time market monitoring system with WebSocket price streaming.
"""
import asyncio
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .models import PriceData, SymbolInfo, MarketSummary, WebSocketMessage
from .services import market_data_service
from .websocket import connection_manager


settings = get_settings()

# Background task reference
price_broadcast_task = None


async def broadcast_prices_loop():
    """Background task that continuously broadcasts price updates"""
    print("[Background] Starting price broadcast loop...")
    try:
        async for prices in market_data_service.stream_prices(settings.price_update_interval):
            if connection_manager.connection_count > 0:
                await connection_manager.broadcast_prices(prices)
    except asyncio.CancelledError:
        print("[Background] Price broadcast loop cancelled")
        raise


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup/shutdown tasks"""
    global price_broadcast_task
    
    # Startup
    print(f"[Startup] {settings.app_name} starting...")
    price_broadcast_task = asyncio.create_task(broadcast_prices_loop())
    
    yield
    
    # Shutdown
    print("[Shutdown] Cleaning up...")
    if price_broadcast_task:
        price_broadcast_task.cancel()
        try:
            await price_broadcast_task
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title=settings.app_name,
    description="Real-time market monitoring and alert system",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware for web frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# REST API Endpoints
# ============================================================================

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "name": settings.app_name,
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "connections": connection_manager.connection_count
    }


@app.get("/api/v1/symbols", response_model=list[SymbolInfo])
async def get_symbols():
    """Get list of all available market symbols"""
    return market_data_service.get_symbols()


@app.get("/api/v1/symbols/{symbol}/price", response_model=PriceData)
async def get_symbol_price(symbol: str):
    """Get current price for a specific symbol"""
    price = market_data_service.get_current_price(symbol.upper())
    if not price:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail=f"Symbol {symbol} not found")
    return price


@app.get("/api/v1/market/summary", response_model=MarketSummary)
async def get_market_summary():
    """Get summary of all market data"""
    symbols = market_data_service.get_symbols()
    return MarketSummary(
        symbols=symbols,
        last_updated=datetime.utcnow(),
        market_status="open"
    )


# ============================================================================
# WebSocket Endpoints
# ============================================================================

@app.websocket("/price/stream")
async def price_stream(websocket: WebSocket):
    """
    WebSocket endpoint for real-time price streaming.
    
    Clients connect to this endpoint to receive continuous price updates
    for all market symbols. Updates are broadcast at 1-second intervals.
    
    Message format:
    {
        "type": "price_update",
        "data": {
            "prices": [
                {"symbol": "AAPL", "price": 175.50, ...},
                ...
            ]
        },
        "timestamp": "2024-01-15T10:30:00Z"
    }
    """
    await connection_manager.connect(websocket)
    
    try:
        # Send initial prices immediately
        prices = [market_data_service.get_current_price(s) for s in 
                  [sym.symbol for sym in market_data_service.get_symbols()]]
        prices = [p for p in prices if p is not None]
        
        initial_message = WebSocketMessage(
            type="initial_data",
            data={"prices": [p.model_dump() for p in prices]},
            timestamp=datetime.utcnow()
        )
        await websocket.send_json(initial_message.model_dump(mode="json"))
        
        # Keep connection alive and listen for client messages
        while True:
            try:
                # Wait for any client messages (ping/pong, commands)
                data = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=settings.ws_heartbeat_interval
                )
                # Handle any client commands here
                print(f"[WS] Received from client: {data}")
            except asyncio.TimeoutError:
                # Send heartbeat on timeout
                await connection_manager.send_heartbeat()
                
    except WebSocketDisconnect:
        connection_manager.disconnect(websocket)
    except Exception as e:
        print(f"[WS] Error: {e}")
        connection_manager.disconnect(websocket)


@app.websocket("/alerts/stream")
async def alerts_stream(websocket: WebSocket):
    """
    WebSocket endpoint for real-time alert notifications.
    
    Clients connect to receive alert triggers when market conditions
    match their configured alert rules.
    """
    await connection_manager.connect(websocket)
    
    try:
        while True:
            # Keep connection alive
            data = await websocket.receive_text()
            print(f"[WS Alerts] Received: {data}")
    except WebSocketDisconnect:
        connection_manager.disconnect(websocket)


# ============================================================================
# Emergency Stop Endpoint
# ============================================================================

@app.post("/api/v1/emergency-stop")
async def emergency_stop():
    """
    Emergency stop endpoint - kills all background workers.
    
    This endpoint should be protected with authentication in production.
    Currently returns a mock response for development.
    """
    from .models import EmergencyStopResponse
    
    # In production, this would:
    # 1. Revoke all Celery tasks
    # 2. Set a global stop flag in Redis
    # 3. Notify all connected clients
    
    return EmergencyStopResponse(
        success=True,
        message="Emergency stop activated. All workers halted.",
        workers_stopped=0  # Would be actual count in production
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
