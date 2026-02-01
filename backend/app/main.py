"""
Sentinel API - Main Application Entry Point

A real-time market monitoring system with WebSocket price streaming.
"""
import asyncio
from contextlib import asynccontextmanager
from datetime import datetime
from typing import List

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .config import get_settings
from .models import PriceData, SymbolInfo, MarketSummary, WebSocketMessage, AlertCreate, AlertResponse
from .services import market_data_service
from .services.alert_service import alert_service
from .services.push_notification import push_service
from .websocket import connection_manager
from .database import init_db


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
            
            # Evaluate alerts against current prices
            price_dict = {p.symbol: p.price for p in prices}
            triggered_alerts = await alert_service.evaluate_alerts(price_dict)
            
            # Broadcast triggered alerts and send push notifications
            for alert in triggered_alerts:
                await connection_manager.broadcast(WebSocketMessage(
                    type="alert_triggered",
                    data=alert.to_dict(),
                    timestamp=datetime.utcnow()
                ).model_dump(mode="json"))
                print(f"[Alert] TRIGGERED: {alert.symbol} {alert.condition.value} ${alert.target_price}")
                
                # Send push notification
                current_price = price_dict.get(alert.symbol)
                await push_service.send_alert_notification(
                    symbol=alert.symbol,
                    condition=alert.condition.value,
                    target_price=alert.target_price,
                    current_price=current_price
                )
                
    except asyncio.CancelledError:
        print("[Background] Price broadcast loop cancelled")
        raise


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup/shutdown tasks"""
    global price_broadcast_task
    
    # Startup
    print(f"[Startup] {settings.app_name} starting...")
    
    # Initialize database
    await init_db()
    print("[Startup] Database initialized")
    
    # Initialize push notification service
    await push_service.initialize()
    
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
# Alert API Endpoints
# ============================================================================

@app.get("/api/v1/alerts", response_model=List[AlertResponse])
async def get_alerts():
    """Get all active alerts"""
    alerts = await alert_service.get_all_alerts()
    return [AlertResponse(
        id=a.id,
        symbol=a.symbol,
        condition=a.condition.value,
        target_price=a.target_price,
        is_triggered=a.is_triggered,
        is_active=a.is_active,
        created_at=a.created_at,
        triggered_at=a.triggered_at
    ) for a in alerts]


@app.post("/api/v1/alerts", response_model=AlertResponse, status_code=201)
async def create_alert(alert_data: AlertCreate):
    """Create a new price alert"""
    alert = await alert_service.create_alert(
        symbol=alert_data.symbol.upper(),
        condition=alert_data.condition,
        target_price=alert_data.target_price
    )
    
    # Immediately check if this alert should trigger against current prices
    current_price_data = market_data_service.get_current_price(alert.symbol)
    if current_price_data:
        current_price = current_price_data.price
        # Check condition manually for immediate evaluation
        should_trigger = False
        if alert.condition.value == "above" and current_price >= alert.target_price:
            should_trigger = True
        elif alert.condition.value == "below" and current_price <= alert.target_price:
            should_trigger = True
        
        if should_trigger:
            # Trigger the alert
            triggered_alert = await alert_service.trigger_alert(alert.id)
            if triggered_alert:
                alert = triggered_alert
                print(f"[Alert] TRIGGERED immediately: {alert.symbol} {alert.condition.value} ${alert.target_price}")
                
                # Broadcast to WebSocket clients
                await connection_manager.broadcast(WebSocketMessage(
                    type="alert_triggered",
                    data=alert.to_dict(),
                    timestamp=datetime.utcnow()
                ).model_dump(mode="json"))
                
                # Send push notification
                await push_service.send_alert_notification(
                    symbol=alert.symbol,
                    condition=alert.condition.value,
                    target_price=alert.target_price,
                    current_price=current_price
                )
    
    return AlertResponse(
        id=alert.id,
        symbol=alert.symbol,
        condition=alert.condition.value,
        target_price=alert.target_price,
        is_triggered=alert.is_triggered,
        is_active=alert.is_active,
        created_at=alert.created_at,
        triggered_at=alert.triggered_at
    )

@app.delete("/api/v1/alerts/{alert_id}")
async def delete_alert(alert_id: str):
    """Delete an alert by ID"""
    success = await alert_service.delete_alert(alert_id)
    if not success:
        raise HTTPException(status_code=404, detail=f"Alert {alert_id} not found")
    return {"success": True, "message": "Alert deleted"}


# ============================================================================
# Device Token Endpoints (for Push Notifications)
# ============================================================================

class DeviceTokenRequest(BaseModel):
    """Request body for device token registration"""
    token: str


@app.post("/api/v1/devices/register")
async def register_device(request: DeviceTokenRequest):
    """Register a device token for push notifications"""
    push_service.register_device(request.token)
    return {
        "success": True,
        "message": "Device registered for push notifications",
        "registered_devices": push_service.registered_devices
    }


@app.post("/api/v1/devices/unregister")
async def unregister_device(request: DeviceTokenRequest):
    """Unregister a device token"""
    push_service.unregister_device(request.token)
    return {
        "success": True,
        "message": "Device unregistered"
    }


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


# ============================================================================
# AI Prediction Endpoints
# ============================================================================

from .models import PredictionResponse, TrainingResponse, BatchTrainingResponse, SymbolListResponse
from .services.prediction_service import prediction_service


@app.get("/api/v1/prediction/symbols/all", response_model=SymbolListResponse)
async def get_nifty50_symbols():
    """Get all NIFTY 50 symbols available for prediction"""
    symbols = prediction_service.get_available_symbols()
    return SymbolListResponse(total=len(symbols), symbols=symbols)


@app.get("/api/v1/prediction/symbols/top", response_model=SymbolListResponse)
async def get_top_symbols():
    """Get top 10 most traded symbols"""
    symbols = prediction_service.get_top_symbols()
    return SymbolListResponse(total=len(symbols), symbols=symbols)


@app.get("/api/v1/prediction/{symbol}")
async def get_prediction(symbol: str, days: int = 7):
    """
    Get AI price prediction for a stock symbol.
    
    Args:
        symbol: Stock symbol (e.g., RELIANCE.NS)
        days: Number of days to predict (1-30)
        
    Returns:
        Prediction with current price, predicted prices, historical data, and confidence scores.
        
    Note: First request may take 30-60 seconds if model needs training.
    """
    # Add .NS suffix if not present
    if not symbol.endswith(".NS"):
        symbol = f"{symbol.upper()}.NS"
    
    days = min(max(days, 1), 30)  # Clamp to 1-30
    
    result = prediction_service.predict(symbol, days)
    
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    
    return result


@app.post("/api/v1/prediction/{symbol}/train", response_model=TrainingResponse)
async def train_model(symbol: str, epochs: int = 50):
    """
    Train or retrain LSTM model for a specific symbol.
    
    Args:
        symbol: Stock symbol (e.g., RELIANCE.NS)
        epochs: Training epochs (default 50)
        
    Returns:
        Training results including loss, MAE, and model path.
        
    Note: This will replace any existing model for the symbol.
    """
    # Add .NS suffix if not present
    if not symbol.endswith(".NS"):
        symbol = f"{symbol.upper()}.NS"
    
    result = prediction_service.train_model(symbol, epochs=epochs)
    return result


@app.post("/api/v1/prediction/train/batch")
async def batch_train_models(symbols: list[str] = None, epochs: int = 25):
    """
    Train models for multiple symbols (batch training).
    
    Args:
        symbols: List of symbols (default: top 10)
        epochs: Training epochs per symbol
        
    Returns:
        Batch training results.
        
    Note: This is a long-running operation (5-10 min for 10 symbols).
    """
    if symbols:
        symbols = [s.upper() if not s.endswith(".NS") else s for s in symbols]
        symbols = [s if s.endswith(".NS") else f"{s}.NS" for s in symbols]
    
    result = prediction_service.batch_train(symbols, epochs=epochs)
    return result


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

