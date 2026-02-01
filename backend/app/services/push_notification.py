"""Push Notification Service using APNs"""
import os
from pathlib import Path
from typing import Optional, Set
from datetime import datetime

from aioapns import APNs, NotificationRequest, PushType

from ..config import get_settings


class PushNotificationService:
    """Service for sending APNs push notifications"""
    
    def __init__(self):
        self.settings = get_settings()
        self._apns_client: Optional[APNs] = None
        self._device_tokens: Set[str] = set()
        self._initialized = False
        
        # APNs configuration
        self.key_id = "85TC74KRDA"
        self.team_id = "V76XWK6797"
        self.bundle_id = "com.sentinelmarket.app"  # Update with your actual bundle ID
        self.key_path = Path(__file__).parent.parent.parent / "apns_key.p8"
    
    async def initialize(self):
        """Initialize APNs client"""
        if self._initialized:
            return
            
        if not self.key_path.exists():
            print(f"[APNs] Warning: Key file not found at {self.key_path}")
            print("[APNs] Push notifications will not work until key is added")
            return
        
        try:
            with open(self.key_path, "r") as f:
                key_content = f.read()

            self._apns_client = APNs(
                key=key_content,
                key_id=self.key_id,
                team_id=self.team_id,
                topic=self.bundle_id,
                use_sandbox=True
            )
            self._initialized = True
            print("[APNs] Push notification service initialized")
        except Exception as e:
            print(f"[APNs] Failed to initialize: {e}")
    
    def register_device(self, token: str):
        """Register a device token for push notifications"""
        self._device_tokens.add(token)
        print(f"[APNs] Device registered. Total devices: {len(self._device_tokens)}")
    
    def unregister_device(self, token: str):
        """Unregister a device token"""
        self._device_tokens.discard(token)
        print(f"[APNs] Device unregistered. Total devices: {len(self._device_tokens)}")
    
    @property
    def registered_devices(self) -> int:
        """Get count of registered devices"""
        return len(self._device_tokens)
    
    async def send_alert_notification(
        self,
        symbol: str,
        condition: str,
        target_price: float,
        current_price: Optional[float] = None
    ):
        """Send push notification for triggered alert"""
        if not self._initialized or not self._apns_client:
            print("[APNs] Service not initialized, skipping push")
            return
        
        if not self._device_tokens:
            print("[APNs] No registered devices, skipping push")
            return
        
        # Build notification payload
        title = f"🎯 Alert Triggered: {symbol}"
        body = f"Price went {condition} ${target_price:.2f}"
        if current_price:
            body += f" (now ${current_price:.2f})"
        
        for token in self._device_tokens:
            try:
                request = NotificationRequest(
                    device_token=token,
                    message={
                        "aps": {
                            "alert": {
                                "title": title,
                                "body": body
                            },
                            "sound": "default",
                            "badge": 1
                        },
                        "alert_data": {
                            "symbol": symbol,
                            "condition": condition,
                            "target_price": target_price,
                            "current_price": current_price,
                            "timestamp": datetime.utcnow().isoformat()
                        }
                    },
                    push_type=PushType.ALERT
                )
                
                response = await self._apns_client.send_notification(request)
                
                if response.is_successful:
                    print(f"[APNs] ✅ Notification sent to device: {token[:10]}...")
                    # print(f"[APNs] Response details: {response}")
                else:
                    print(f"[APNs] ❌ Failed to send to {token[:10]}...")
                    print(f"[APNs] Status: {response.description}")
                    print(f"[APNs] Reason: {response.reason}")
                    
                    # Remove invalid tokens
                    if response.reason in ["BadDeviceToken", "Unregistered", "DeviceTokenNotForTopic"]:
                        print(f"[APNs] Removing invalid token: {token[:10]}...")
                        self._device_tokens.discard(token)
                        
            except Exception as e:
                print(f"[APNs] Error sending notification: {e}")


# Singleton instance
push_service = PushNotificationService()
