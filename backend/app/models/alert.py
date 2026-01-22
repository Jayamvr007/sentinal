"""Alert model for price alerts"""
import uuid
from datetime import datetime
from enum import Enum
from sqlalchemy import String, Float, Boolean, DateTime, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column
from ..database import Base


class AlertCondition(str, Enum):
    """Alert trigger conditions"""
    ABOVE = "above"
    BELOW = "below"


class Alert(Base):
    """SQLAlchemy model for price alerts"""
    __tablename__ = "alerts"
    
    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4())
    )
    symbol: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    condition: Mapped[AlertCondition] = mapped_column(
        SQLEnum(AlertCondition),
        nullable=False
    )
    target_price: Mapped[float] = mapped_column(Float, nullable=False)
    is_triggered: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )
    triggered_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    
    def check_condition(self, current_price: float) -> bool:
        """Check if alert condition is met"""
        if not self.is_active or self.is_triggered:
            return False
        
        if self.condition == AlertCondition.ABOVE:
            return current_price >= self.target_price
        elif self.condition == AlertCondition.BELOW:
            return current_price <= self.target_price
        return False
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization"""
        return {
            "id": self.id,
            "symbol": self.symbol,
            "condition": self.condition.value,
            "target_price": self.target_price,
            "is_triggered": self.is_triggered,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat(),
            "triggered_at": self.triggered_at.isoformat() if self.triggered_at else None
        }
