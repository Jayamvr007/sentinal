"""Alert service for CRUD operations and alert evaluation"""
from datetime import datetime
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.alert import Alert, AlertCondition
from ..database import async_session


class AlertService:
    """Service for managing price alerts"""
    
    async def create_alert(
        self,
        symbol: str,
        condition: str,
        target_price: float
    ) -> Alert:
        """Create a new alert"""
        async with async_session() as session:
            alert = Alert(
                symbol=symbol.upper(),
                condition=AlertCondition(condition),
                target_price=target_price
            )
            session.add(alert)
            await session.commit()
            await session.refresh(alert)
            return alert
    
    async def get_all_alerts(self, active_only: bool = True) -> List[Alert]:
        """Get all alerts, optionally filtered by active status"""
        async with async_session() as session:
            query = select(Alert).order_by(Alert.created_at.desc())
            if active_only:
                query = query.where(Alert.is_active == True)
            result = await session.execute(query)
            return list(result.scalars().all())
    
    async def get_alert_by_id(self, alert_id: str) -> Optional[Alert]:
        """Get a specific alert by ID"""
        async with async_session() as session:
            result = await session.execute(
                select(Alert).where(Alert.id == alert_id)
            )
            return result.scalar_one_or_none()
    
    async def delete_alert(self, alert_id: str) -> bool:
        """Delete an alert by ID"""
        async with async_session() as session:
            result = await session.execute(
                select(Alert).where(Alert.id == alert_id)
            )
            alert = result.scalar_one_or_none()
            if alert:
                await session.delete(alert)
                await session.commit()
                return True
            return False
    
    async def trigger_alert(self, alert_id: str) -> Optional[Alert]:
        """Mark an alert as triggered"""
        async with async_session() as session:
            result = await session.execute(
                select(Alert).where(Alert.id == alert_id)
            )
            alert = result.scalar_one_or_none()
            if alert:
                alert.is_triggered = True
                alert.triggered_at = datetime.utcnow()
                await session.commit()
                await session.refresh(alert)
                return alert
            return None
    
    async def evaluate_alerts(
        self,
        prices: dict[str, float]
    ) -> List[Alert]:
        """
        Evaluate all active alerts against current prices.
        Returns list of newly triggered alerts.
        """
        triggered = []
        async with async_session() as session:
            # Get all active, non-triggered alerts
            result = await session.execute(
                select(Alert).where(
                    Alert.is_active == True,
                    Alert.is_triggered == False
                )
            )
            alerts = list(result.scalars().all())
            
            for alert in alerts:
                if alert.symbol in prices:
                    current_price = prices[alert.symbol]
                    if alert.check_condition(current_price):
                        alert.is_triggered = True
                        alert.triggered_at = datetime.utcnow()
                        triggered.append(alert)
            
            if triggered:
                await session.commit()
        
        return triggered


# Singleton instance
alert_service = AlertService()
