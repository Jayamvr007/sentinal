"""Pydantic Models for Sentinel API"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from enum import Enum


class AlertCondition(str, Enum):
    """Types of alert conditions"""
    PRICE_ABOVE = "price_above"
    PRICE_BELOW = "price_below"
    PERCENT_CHANGE_UP = "percent_change_up"
    PERCENT_CHANGE_DOWN = "percent_change_down"
    VOLUME_SPIKE = "volume_spike"


class PriceData(BaseModel):
    """Real-time price data for a symbol"""
    symbol: str
    price: float
    previous_close: float
    change: float
    change_percent: float
    volume: int
    timestamp: datetime
    
    @classmethod
    def create(cls, symbol: str, price: float, previous_close: float, volume: int):
        """Factory method to create PriceData with calculated fields"""
        change = round(price - previous_close, 2)
        change_percent = round((change / previous_close) * 100, 2) if previous_close else 0
        return cls(
            symbol=symbol,
            price=price,
            previous_close=previous_close,
            change=change,
            change_percent=change_percent,
            volume=volume,
            timestamp=datetime.utcnow()
        )


class AlertConfig(BaseModel):
    """User-defined alert configuration"""
    id: Optional[str] = None
    symbol: str
    condition: AlertCondition
    threshold: float
    is_active: bool = True
    created_at: Optional[datetime] = None
    
    class Config:
        use_enum_values = True


class AlertTrigger(BaseModel):
    """Alert trigger event when conditions are met"""
    alert_id: str
    symbol: str
    triggered_price: float
    condition_met: str
    timestamp: datetime


class SymbolInfo(BaseModel):
    """Information about a tradeable symbol"""
    symbol: str
    name: str
    sector: str
    current_price: Optional[float] = None


class MarketSummary(BaseModel):
    """Summary of market state"""
    symbols: List[SymbolInfo]
    last_updated: datetime
    market_status: str = "open"  # open, closed, pre-market, after-hours


class WebSocketMessage(BaseModel):
    """Generic WebSocket message wrapper"""
    type: str  # price_update, alert_trigger, heartbeat, error
    data: dict
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class EmergencyStopRequest(BaseModel):
    """Request to activate emergency stop"""
    reason: Optional[str] = None
    
    
class EmergencyStopResponse(BaseModel):
    """Response from emergency stop activation"""
    success: bool
    message: str
    workers_stopped: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)
