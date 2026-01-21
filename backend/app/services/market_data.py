"""
Finnhub Real-Time Market Data Service

Connects to Finnhub WebSocket for real-time stock prices.
Falls back to mock data if Finnhub connection fails.

Get your free API key at: https://finnhub.io/register
"""
import asyncio
import json
from datetime import datetime
from typing import Dict, List, AsyncGenerator, Optional
import websockets
from websockets.exceptions import ConnectionClosed

from ..models import PriceData, SymbolInfo
from ..config import get_settings


# Finnhub WebSocket URL
FINNHUB_WS_URL = "wss://ws.finnhub.io"

# Symbols to track (US stocks that work with Finnhub free tier)
TRACKED_SYMBOLS: Dict[str, dict] = {
    "AAPL": {"name": "Apple Inc.", "sector": "Technology"},
    "GOOGL": {"name": "Alphabet Inc.", "sector": "Technology"},
    "TSLA": {"name": "Tesla Inc.", "sector": "Automotive"},
    "MSFT": {"name": "Microsoft Corp.", "sector": "Technology"},
    "AMZN": {"name": "Amazon.com Inc.", "sector": "Consumer"},
    "NVDA": {"name": "NVIDIA Corp.", "sector": "Technology"},
    "META": {"name": "Meta Platforms", "sector": "Technology"},
    "JPM": {"name": "JPMorgan Chase", "sector": "Finance"},
    "V": {"name": "Visa Inc.", "sector": "Finance"},
    "SPY": {"name": "S&P 500 ETF", "sector": "Index"},
}


class FinnhubMarketDataService:
    """
    Service for real-time market data from Finnhub.
    
    Uses WebSocket connection for live trade data.
    Maintains last known prices for each symbol.
    """
    
    def __init__(self):
        settings = get_settings()
        self._api_key: str = settings.finnhub_api_key or ""
        self._current_prices: Dict[str, float] = {}
        self._previous_close: Dict[str, float] = {}
        self._volumes: Dict[str, int] = {}
        self._last_update: Dict[str, datetime] = {}
        self._websocket: Optional[websockets.WebSocketClientProtocol] = None
        self._connected = False
        self._use_mock = False
        
        # Initialize with estimated prices (will be updated by real data)
        self._initialize_estimated_prices()
    
    def _initialize_estimated_prices(self):
        """Initialize with estimated prices until real data arrives"""
        estimated = {
            "AAPL": 175.0, "GOOGL": 142.0, "TSLA": 245.0, "MSFT": 378.0,
            "AMZN": 178.0, "NVDA": 495.0, "META": 385.0, "JPM": 195.0,
            "V": 275.0, "SPY": 475.0
        }
        for symbol in TRACKED_SYMBOLS:
            self._current_prices[symbol] = estimated.get(symbol, 100.0)
            self._previous_close[symbol] = self._current_prices[symbol]
            self._volumes[symbol] = 0
    
    @property
    def is_connected(self) -> bool:
        return self._connected and not self._use_mock
    
    async def connect(self):
        """Connect to Finnhub WebSocket and subscribe to symbols"""
        if not self._api_key:
            print("[Finnhub] No API key found. Set FINNHUB_API_KEY environment variable.")
            print("[Finnhub] Get your free key at: https://finnhub.io/register")
            print("[Finnhub] Falling back to mock data...")
            self._use_mock = True
            return
        
        try:
            url = f"{FINNHUB_WS_URL}?token={self._api_key}"
            self._websocket = await websockets.connect(url)
            self._connected = True
            print("[Finnhub] Connected to WebSocket")
            
            # Subscribe to all tracked symbols
            for symbol in TRACKED_SYMBOLS:
                subscribe_msg = json.dumps({"type": "subscribe", "symbol": symbol})
                await self._websocket.send(subscribe_msg)
                print(f"[Finnhub] Subscribed to {symbol}")
            
        except Exception as e:
            print(f"[Finnhub] Connection failed: {e}")
            print("[Finnhub] Falling back to mock data...")
            self._use_mock = True
            self._connected = False
    
    async def disconnect(self):
        """Disconnect from Finnhub WebSocket"""
        if self._websocket:
            # Unsubscribe from all symbols
            for symbol in TRACKED_SYMBOLS:
                try:
                    unsubscribe_msg = json.dumps({"type": "unsubscribe", "symbol": symbol})
                    await self._websocket.send(unsubscribe_msg)
                except:
                    pass
            
            await self._websocket.close()
            self._websocket = None
            self._connected = False
            print("[Finnhub] Disconnected")
    
    async def _receive_trades(self):
        """Receive and process trade data from Finnhub"""
        if not self._websocket:
            return
        
        try:
            message = await asyncio.wait_for(
                self._websocket.recv(),
                timeout=5.0
            )
            data = json.loads(message)
            
            if data.get("type") == "trade" and "data" in data:
                for trade in data["data"]:
                    symbol = trade.get("s")
                    price = trade.get("p")
                    volume = trade.get("v", 0)
                    
                    if symbol in TRACKED_SYMBOLS and price:
                        # Store previous price as "previous close" for change calculation
                        if symbol not in self._last_update or \
                           (datetime.now() - self._last_update[symbol]).seconds > 60:
                            self._previous_close[symbol] = self._current_prices.get(symbol, price)
                        
                        self._current_prices[symbol] = float(price)
                        self._volumes[symbol] += int(volume)
                        self._last_update[symbol] = datetime.now()
                        print(f"[Finnhub] REAL TRADE: {symbol} @ ${price:.2f}")
            
            elif data.get("type") == "ping":
                # Respond to ping to keep connection alive
                pass
                
        except asyncio.TimeoutError:
            # No data received, market might be closed
            print("[Finnhub] No trades (market may be closed) - prices unchanged")
        except ConnectionClosed:
            print("[Finnhub] Connection closed, reconnecting...")
            self._connected = False
            await self.connect()
        except Exception as e:
            print(f"[Finnhub] Error receiving data: {e}")
    
    def _mock_update_prices(self):
        """Generate mock price updates when Finnhub is not available"""
        import random
        for symbol in TRACKED_SYMBOLS:
            current = self._current_prices[symbol]
            # Random walk: +/- 0.3% max change per tick
            change = random.uniform(-0.003, 0.003)
            self._current_prices[symbol] = round(current * (1 + change), 2)
            self._volumes[symbol] += random.randint(1000, 10000)
    
    def get_symbols(self) -> List[SymbolInfo]:
        """Get list of all tracked symbols"""
        return [
            SymbolInfo(
                symbol=symbol,
                name=info["name"],
                sector=info["sector"],
                current_price=self._current_prices.get(symbol)
            )
            for symbol, info in TRACKED_SYMBOLS.items()
        ]
    
    def get_current_price(self, symbol: str) -> PriceData | None:
        """Get current price data for a symbol"""
        if symbol not in TRACKED_SYMBOLS:
            return None
        
        return PriceData.create(
            symbol=symbol,
            price=self._current_prices.get(symbol, 0),
            previous_close=self._previous_close.get(symbol, 0),
            volume=self._volumes.get(symbol, 0)
        )
    
    def get_all_prices(self) -> List[PriceData]:
        """Get current prices for all tracked symbols"""
        return [self.get_current_price(s) for s in TRACKED_SYMBOLS if self.get_current_price(s)]
    
    async def stream_prices(self, interval: float = 1.0) -> AsyncGenerator[List[PriceData], None]:
        """
        Async generator that yields price updates.
        
        Connects to Finnhub WebSocket for real data, or falls back to mock data.
        """
        # Connect on first stream request
        if not self._connected and not self._use_mock:
            await self.connect()
        
        while True:
            if self._use_mock:
                # Use mock data
                self._mock_update_prices()
            else:
                # Receive real data from Finnhub
                await self._receive_trades()
            
            # Yield current prices
            prices = self.get_all_prices()
            yield prices
            
            await asyncio.sleep(interval)


# Singleton instance
market_data_service = FinnhubMarketDataService()
