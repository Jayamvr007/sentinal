"""
Yahoo Finance Real-Time Market Data Service for Indian Stocks (NIFTY 50)

Uses yfinance for real-time stock prices from NSE.
Falls back to mock data if yfinance fails.
"""
import asyncio
from datetime import datetime
from typing import Dict, List, AsyncGenerator, Optional
import yfinance as yf

from ..models import PriceData, SymbolInfo
from ..config import get_settings


# NIFTY 50 Indian Stocks (use .NS suffix for NSE)
TRACKED_SYMBOLS: Dict[str, dict] = {
    "RELIANCE.NS": {"name": "Reliance Industries", "sector": "Energy", "display": "RELIANCE"},
    "TCS.NS": {"name": "Tata Consultancy Services", "sector": "Technology", "display": "TCS"},
    "HDFCBANK.NS": {"name": "HDFC Bank Ltd.", "sector": "Finance", "display": "HDFCBANK"},
    "INFY.NS": {"name": "Infosys Ltd.", "sector": "Technology", "display": "INFY"},
    "ICICIBANK.NS": {"name": "ICICI Bank Ltd.", "sector": "Finance", "display": "ICICIBANK"},
    "HINDUNILVR.NS": {"name": "Hindustan Unilever", "sector": "Consumer", "display": "HINDUNILVR"},
    "ITC.NS": {"name": "ITC Ltd.", "sector": "Consumer", "display": "ITC"},
    "SBIN.NS": {"name": "State Bank of India", "sector": "Finance", "display": "SBIN"},
    "BHARTIARTL.NS": {"name": "Bharti Airtel Ltd.", "sector": "Telecom", "display": "BHARTIARTL"},
    "KOTAKBANK.NS": {"name": "Kotak Mahindra Bank", "sector": "Finance", "display": "KOTAKBANK"},
}


class FinnhubMarketDataService:
    """
    Service for real-time market data from Yahoo Finance (Indian NSE stocks).
    
    Uses yfinance library for live stock data.
    Maintains last known prices for each symbol.
    
    Note: Class name kept as FinnhubMarketDataService for backward compatibility.
    """
    
    def __init__(self):
        self._current_prices: Dict[str, float] = {}
        self._previous_close: Dict[str, float] = {}
        self._volumes: Dict[str, int] = {}
        self._last_update: Dict[str, datetime] = {}
        self._connected = False
        self._use_mock = False
        
        # Initialize with real prices from Yahoo Finance
        self._initialize_prices()
    
    def _initialize_prices(self):
        """Initialize with real prices from Yahoo Finance"""
        print("[Yahoo Finance] Fetching initial prices for NIFTY 50 stocks...")
        
        try:
            # Fetch all symbols at once for efficiency
            symbols = list(TRACKED_SYMBOLS.keys())
            tickers = yf.Tickers(" ".join(symbols))
            
            for symbol in symbols:
                try:
                    ticker = tickers.tickers[symbol]
                    info = ticker.fast_info
                    
                    self._current_prices[symbol] = round(info.last_price, 2) if info.last_price else 0
                    self._previous_close[symbol] = round(info.previous_close, 2) if info.previous_close else self._current_prices[symbol]
                    self._volumes[symbol] = int(info.last_volume) if info.last_volume else 0
                    self._last_update[symbol] = datetime.now()
                    
                    print(f"[Yahoo Finance] {TRACKED_SYMBOLS[symbol]['display']}: ₹{self._current_prices[symbol]}")
                    
                except Exception as e:
                    print(f"[Yahoo Finance] Error fetching {symbol}: {e}")
                    self._current_prices[symbol] = 100.0
                    self._previous_close[symbol] = 100.0
                    self._volumes[symbol] = 0
            
            self._connected = True
            print("[Yahoo Finance] Initial prices loaded successfully")
            
        except Exception as e:
            print(f"[Yahoo Finance] Failed to initialize: {e}")
            print("[Yahoo Finance] Falling back to mock data...")
            self._use_mock = True
            self._initialize_mock_prices()
    
    def _initialize_mock_prices(self):
        """Initialize with mock prices if Yahoo Finance fails"""
        mock_prices = {
            "RELIANCE.NS": 2850.0, "TCS.NS": 3750.0, "HDFCBANK.NS": 1650.0,
            "INFY.NS": 1550.0, "ICICIBANK.NS": 1050.0, "HINDUNILVR.NS": 2450.0,
            "ITC.NS": 465.0, "SBIN.NS": 780.0, "BHARTIARTL.NS": 1150.0,
            "KOTAKBANK.NS": 1850.0
        }
        for symbol in TRACKED_SYMBOLS:
            self._current_prices[symbol] = mock_prices.get(symbol, 1000.0)
            self._previous_close[symbol] = self._current_prices[symbol]
            self._volumes[symbol] = 0
    
    @property
    def is_connected(self) -> bool:
        return self._connected and not self._use_mock
    
    async def connect(self):
        """Refresh prices from Yahoo Finance"""
        self._initialize_prices()
    
    async def disconnect(self):
        """Cleanup (no-op for yfinance)"""
        self._connected = False
        print("[Yahoo Finance] Disconnected")
    
    async def _refresh_prices(self):
        """Refresh prices from Yahoo Finance"""
        try:
            symbols = list(TRACKED_SYMBOLS.keys())
            tickers = yf.Tickers(" ".join(symbols))
            
            for symbol in symbols:
                try:
                    ticker = tickers.tickers[symbol]
                    info = ticker.fast_info
                    
                    if info.last_price:
                        self._previous_close[symbol] = self._current_prices.get(symbol, info.previous_close or 0)
                        self._current_prices[symbol] = round(info.last_price, 2)
                        self._volumes[symbol] = int(info.last_volume) if info.last_volume else self._volumes[symbol]
                        self._last_update[symbol] = datetime.now()
                        
                except Exception as e:
                    pass  # Keep existing price on error
                    
        except Exception as e:
            print(f"[Yahoo Finance] Error refreshing prices: {e}")
    
    def _mock_update_prices(self):
        """Generate mock price updates when Yahoo Finance is not available"""
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
                symbol=info["display"],  # Use display name without .NS
                name=info["name"],
                sector=info["sector"],
                current_price=self._current_prices.get(symbol)
            )
            for symbol, info in TRACKED_SYMBOLS.items()
        ]
    
    def get_current_price(self, symbol: str) -> PriceData | None:
        """Get current price data for a symbol"""
        # Handle both formats: "RELIANCE" or "RELIANCE.NS"
        full_symbol = symbol if symbol.endswith(".NS") else f"{symbol}.NS"
        
        if full_symbol not in TRACKED_SYMBOLS:
            return None
        
        display_symbol = TRACKED_SYMBOLS[full_symbol]["display"]
        
        return PriceData.create(
            symbol=display_symbol,
            price=self._current_prices.get(full_symbol, 0),
            previous_close=self._previous_close.get(full_symbol, 0),
            volume=self._volumes.get(full_symbol, 0)
        )
    
    def get_all_prices(self) -> List[PriceData]:
        """Get current prices for all tracked symbols"""
        prices = []
        for symbol in TRACKED_SYMBOLS:
            price = self.get_current_price(symbol)
            if price:
                prices.append(price)
        return prices
    
    async def stream_prices(self, interval: float = 1.0) -> AsyncGenerator[List[PriceData], None]:
        """
        Async generator that yields price updates.
        
        Fetches from Yahoo Finance every 5 seconds, yields every 1 second.
        """
        refresh_counter = 0
        refresh_interval = 5  # Refresh from Yahoo Finance every 5 ticks
        
        while True:
            if self._use_mock:
                # Use mock data
                self._mock_update_prices()
            else:
                # Refresh from Yahoo Finance every 5 seconds
                if refresh_counter % refresh_interval == 0:
                    await self._refresh_prices()
                refresh_counter += 1
            
            # Yield current prices
            prices = self.get_all_prices()
            yield prices
            
            await asyncio.sleep(interval)


# Singleton instance
market_data_service = FinnhubMarketDataService()
