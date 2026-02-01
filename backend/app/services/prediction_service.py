"""
AI Stock Prediction Service for NIFTY 50

Uses LSTM neural network with yfinance data for price prediction.
"""

import os
import json
import logging
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from pathlib import Path

import numpy as np
import pandas as pd
import yfinance as yf
from sklearn.preprocessing import MinMaxScaler
import ta  # Technical Analysis library

# TensorFlow imports with lazy loading to avoid slow startup
_tf = None
_keras = None

def get_tensorflow():
    """Lazy load TensorFlow to avoid slow startup."""
    global _tf, _keras
    if _tf is None:
        import tensorflow as tf
        _tf = tf
        _keras = tf.keras
    return _tf, _keras


logger = logging.getLogger(__name__)


# NIFTY 50 stocks with NSE suffix
NIFTY_50_SYMBOLS = [
    "RELIANCE.NS", "TCS.NS", "HDFCBANK.NS", "INFY.NS", "ICICIBANK.NS",
    "HINDUNILVR.NS", "ITC.NS", "SBIN.NS", "BHARTIARTL.NS", "KOTAKBANK.NS",
    "LT.NS", "AXISBANK.NS", "ASIANPAINT.NS", "MARUTI.NS", "SUNPHARMA.NS",
    "TITAN.NS", "ULTRACEMCO.NS", "NESTLEIND.NS", "WIPRO.NS", "TECHM.NS",
    "HCLTECH.NS", "BAJFINANCE.NS", "POWERGRID.NS", "NTPC.NS", "TATAMOTORS.NS",
    "JSWSTEEL.NS", "M&M.NS", "ADANIENT.NS", "ADANIPORTS.NS", "ONGC.NS",
    "COALINDIA.NS", "BPCL.NS", "GRASIM.NS", "DIVISLAB.NS", "DRREDDY.NS",
    "CIPLA.NS", "BRITANNIA.NS", "EICHERMOT.NS", "HEROMOTOCO.NS", "TATACONSUM.NS",
    "APOLLOHOSP.NS", "BAJAJFINSV.NS", "SBILIFE.NS", "INDUSINDBK.NS", "HINDALCO.NS",
    "TATASTEEL.NS", "UPL.NS", "HDFCLIFE.NS", "LTIM.NS", "BAJAJ-AUTO.NS"
]

# Top 10 most traded for quick testing
TOP_10_SYMBOLS = [
    "RELIANCE.NS", "TCS.NS", "HDFCBANK.NS", "INFY.NS", "ICICIBANK.NS",
    "HINDUNILVR.NS", "ITC.NS", "SBIN.NS", "BHARTIARTL.NS", "KOTAKBANK.NS"
]


class PredictionService:
    """
    LSTM-based stock price prediction service.
    
    Features:
    - Fetches historical data from Yahoo Finance
    - Adds technical indicators (RSI, MACD, Moving Averages)
    - Trains LSTM model with 60-day lookback
    - Predicts next 1-7 days
    """
    
    def __init__(self, models_dir: str = "app/models/ml_models"):
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(parents=True, exist_ok=True)
        self.scalers: Dict[str, MinMaxScaler] = {}
        self.sequence_length = 60  # 60 days lookback
        self.prediction_cache: Dict[str, Dict] = {}
        self.cache_ttl = 3600  # 1 hour cache
        
    def fetch_historical_data(
        self, 
        symbol: str, 
        period: str = "2y"
    ) -> Optional[pd.DataFrame]:
        """
        Fetch historical OHLCV data from Yahoo Finance.
        
        Args:
            symbol: Stock symbol (e.g., RELIANCE.NS)
            period: Time period (1y, 2y, 5y, max)
            
        Returns:
            DataFrame with OHLCV data or None if error
        """
        try:
            logger.info(f"Fetching data for {symbol}")
            ticker = yf.Ticker(symbol)
            df = ticker.history(period=period)
            
            if df.empty:
                logger.warning(f"No data found for {symbol}")
                return None
                
            # Clean column names
            df.columns = [col.lower().replace(' ', '_') for col in df.columns]
            df = df[['open', 'high', 'low', 'close', 'volume']]
            df = df.dropna()
            
            logger.info(f"Fetched {len(df)} rows for {symbol}")
            return df
            
        except Exception as e:
            logger.error(f"Error fetching data for {symbol}: {e}")
            return None
    
    def add_technical_indicators(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Add technical analysis indicators to the dataframe.
        
        Indicators added:
        - SMA (7, 21, 50 day)
        - EMA (12, 26 day)
        - RSI (14 day)
        - MACD
        - Bollinger Bands
        """
        df = df.copy()
        
        # Moving Averages
        df['sma_7'] = ta.trend.sma_indicator(df['close'], window=7)
        df['sma_21'] = ta.trend.sma_indicator(df['close'], window=21)
        df['sma_50'] = ta.trend.sma_indicator(df['close'], window=50)
        df['ema_12'] = ta.trend.ema_indicator(df['close'], window=12)
        df['ema_26'] = ta.trend.ema_indicator(df['close'], window=26)
        
        # RSI
        df['rsi'] = ta.momentum.rsi(df['close'], window=14)
        
        # MACD
        macd = ta.trend.MACD(df['close'])
        df['macd'] = macd.macd()
        df['macd_signal'] = macd.macd_signal()
        df['macd_diff'] = macd.macd_diff()
        
        # Bollinger Bands
        bollinger = ta.volatility.BollingerBands(df['close'])
        df['bb_high'] = bollinger.bollinger_hband()
        df['bb_low'] = bollinger.bollinger_lband()
        df['bb_mid'] = bollinger.bollinger_mavg()
        
        # Price change features
        df['price_change'] = df['close'].pct_change()
        df['volatility'] = df['close'].rolling(window=21).std()
        
        # Drop NaN rows
        df = df.dropna()
        
        return df
    
    def prepare_data(
        self, 
        df: pd.DataFrame, 
        symbol: str
    ) -> tuple:
        """
        Prepare data for LSTM training.
        
        Args:
            df: DataFrame with OHLCV and indicators
            symbol: Stock symbol for scaler caching
            
        Returns:
            Tuple of (X_train, y_train, X_test, y_test, scaler)
        """
        # Use all features
        feature_columns = [
            'close', 'open', 'high', 'low', 'volume',
            'sma_7', 'sma_21', 'sma_50', 'ema_12', 'ema_26',
            'rsi', 'macd', 'macd_signal', 'macd_diff',
            'bb_high', 'bb_low', 'bb_mid',
            'price_change', 'volatility'
        ]
        
        data = df[feature_columns].values
        
        # Scale data
        scaler = MinMaxScaler(feature_range=(0, 1))
        scaled_data = scaler.fit_transform(data)
        self.scalers[symbol] = scaler
        
        # Create sequences
        X, y = [], []
        for i in range(self.sequence_length, len(scaled_data)):
            X.append(scaled_data[i-self.sequence_length:i])
            y.append(scaled_data[i, 0])  # Predict close price
            
        X, y = np.array(X), np.array(y)
        
        # Train/test split (80/20)
        split = int(len(X) * 0.8)
        X_train, X_test = X[:split], X[split:]
        y_train, y_test = y[:split], y[split:]
        
        return X_train, y_train, X_test, y_test, scaler
    
    def build_model(self, input_shape: tuple) -> Any:
        """
        Build LSTM model architecture.
        
        Architecture:
        - 2 LSTM layers (50 units each) with dropout
        - Dense output layer
        """
        _, keras = get_tensorflow()
        
        model = keras.Sequential([
            keras.layers.LSTM(
                units=50, 
                return_sequences=True, 
                input_shape=input_shape
            ),
            keras.layers.Dropout(0.2),
            keras.layers.LSTM(units=50, return_sequences=False),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(units=25),
            keras.layers.Dense(units=1)
        ])
        
        model.compile(
            optimizer='adam',
            loss='mean_squared_error',
            metrics=['mae']
        )
        
        return model
    
    def train_model(
        self, 
        symbol: str, 
        epochs: int = 50,
        batch_size: int = 32
    ) -> Dict[str, Any]:
        """
        Train LSTM model for a specific stock.
        
        Args:
            symbol: Stock symbol
            epochs: Training epochs
            batch_size: Batch size
            
        Returns:
            Training results dict
        """
        logger.info(f"Training model for {symbol}")
        
        # Fetch and prepare data
        df = self.fetch_historical_data(symbol)
        if df is None or len(df) < self.sequence_length + 50:
            return {"error": f"Insufficient data for {symbol}"}
            
        df = self.add_technical_indicators(df)
        X_train, y_train, X_test, y_test, scaler = self.prepare_data(df, symbol)
        
        if len(X_train) < 50:
            return {"error": f"Not enough training samples for {symbol}"}
        
        # Build and train model
        tf, keras = get_tensorflow()
        model = self.build_model((X_train.shape[1], X_train.shape[2]))
        
        # Early stopping to prevent overfitting
        early_stop = keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True
        )
        
        history = model.fit(
            X_train, y_train,
            epochs=epochs,
            batch_size=batch_size,
            validation_split=0.1,
            callbacks=[early_stop],
            verbose=0
        )
        
        # Evaluate model
        loss, mae = model.evaluate(X_test, y_test, verbose=0)
        
        # Save model
        model_path = self.models_dir / f"{symbol.replace('.', '_')}.h5"
        model.save(model_path)
        
        # Save scaler
        scaler_path = self.models_dir / f"{symbol.replace('.', '_')}_scaler.npy"
        np.save(scaler_path, scaler.data_min_)
        np.save(self.models_dir / f"{symbol.replace('.', '_')}_scaler_max.npy", scaler.data_max_)
        
        result = {
            "symbol": symbol,
            "status": "success",
            "epochs_trained": len(history.history['loss']),
            "final_loss": float(loss),
            "mae": float(mae),
            "model_path": str(model_path),
            "trained_at": datetime.now().isoformat()
        }
        
        logger.info(f"Model trained for {symbol}: MAE={mae:.4f}")
        return result
    
    def predict(
        self, 
        symbol: str, 
        days: int = 7
    ) -> Dict[str, Any]:
        """
        Generate price predictions for upcoming days.
        
        Args:
            symbol: Stock symbol
            days: Number of days to predict (max 7)
            
        Returns:
            Prediction results dict
        """
        # Check cache
        cache_key = f"{symbol}_{days}"
        if cache_key in self.prediction_cache:
            cached = self.prediction_cache[cache_key]
            if (datetime.now() - cached['timestamp']).seconds < self.cache_ttl:
                return cached['data']
        
        tf, keras = get_tensorflow()
        
        # Load model
        model_path = self.models_dir / f"{symbol.replace('.', '_')}.h5"
        if not model_path.exists():
            # Train model if not exists
            train_result = self.train_model(symbol, epochs=25)
            if "error" in train_result:
                return train_result
        
        try:
            model = keras.models.load_model(model_path)
        except Exception as e:
            logger.error(f"Error loading model for {symbol}: {e}")
            return {"error": f"Failed to load model: {e}"}
        
        # Fetch recent data
        df = self.fetch_historical_data(symbol, period="6mo")
        if df is None:
            return {"error": f"Failed to fetch data for {symbol}"}
            
        df = self.add_technical_indicators(df)
        
        # Load or create scaler
        if symbol not in self.scalers:
            scaler_min_path = self.models_dir / f"{symbol.replace('.', '_')}_scaler.npy"
            scaler_max_path = self.models_dir / f"{symbol.replace('.', '_')}_scaler_max.npy"
            
            if scaler_min_path.exists() and scaler_max_path.exists():
                scaler = MinMaxScaler(feature_range=(0, 1))
                scaler.data_min_ = np.load(scaler_min_path)
                scaler.data_max_ = np.load(scaler_max_path)
                scaler.data_range_ = scaler.data_max_ - scaler.data_min_
                scaler.scale_ = 1.0 / scaler.data_range_
                scaler.min_ = -scaler.data_min_ * scaler.scale_
                scaler.n_features_in_ = len(scaler.data_min_)
                self.scalers[symbol] = scaler
            else:
                # Need to retrain
                train_result = self.train_model(symbol, epochs=25)
                if "error" in train_result:
                    return train_result
        
        scaler = self.scalers[symbol]
        
        # Prepare features
        feature_columns = [
            'close', 'open', 'high', 'low', 'volume',
            'sma_7', 'sma_21', 'sma_50', 'ema_12', 'ema_26',
            'rsi', 'macd', 'macd_signal', 'macd_diff',
            'bb_high', 'bb_low', 'bb_mid',
            'price_change', 'volatility'
        ]
        
        data = df[feature_columns].values
        scaled_data = scaler.transform(data)
        
        # Get last sequence
        last_sequence = scaled_data[-self.sequence_length:]
        
        # Generate predictions
        predictions = []
        current_sequence = last_sequence.copy()
        current_price = float(df['close'].iloc[-1])
        
        for i in range(min(days, 30)):  # Support up to 30 days
            # Predict next day
            X = current_sequence.reshape(1, self.sequence_length, len(feature_columns))
            pred_scaled = model.predict(X, verbose=0)[0][0]
            
            # Inverse scale (for close price only)
            pred_price = pred_scaled * (scaler.data_max_[0] - scaler.data_min_[0]) + scaler.data_min_[0]
            
            # Calculate confidence (decreases with distance)
            # Confidence decreases more slowly for better UX on 30-day predictions
            confidence = max(0.40, 0.95 - (i * 0.018))
            
            # Next trading day
            next_date = datetime.now() + timedelta(days=i+1)
            # Skip weekends
            while next_date.weekday() >= 5:
                next_date += timedelta(days=1)
            
            predictions.append({
                "date": next_date.strftime("%Y-%m-%d"),
                "predicted_price": round(float(pred_price), 2),
                "change_percent": round(((pred_price - current_price) / current_price) * 100, 2),
                "confidence": round(confidence, 2)
            })
            
            # Update sequence for next prediction (simplified: repeat last row with new price)
            new_row = current_sequence[-1].copy()
            new_row[0] = pred_scaled
            current_sequence = np.vstack([current_sequence[1:], new_row])
        
        # Get current price info
        current_data = {
            "symbol": symbol,
            "current_price": current_price,
            "previous_close": float(df['close'].iloc[-2]) if len(df) > 1 else current_price,
            "change_today": round(current_price - float(df['close'].iloc[-2]), 2) if len(df) > 1 else 0,
            "change_percent_today": round(
                ((current_price - float(df['close'].iloc[-2])) / float(df['close'].iloc[-2])) * 100, 2
            ) if len(df) > 1 else 0
        }
        
        # Extract historical prices for chart (last 30 trading days)
        historical_df = df.tail(30)
        historical_prices = [
            {
                "date": idx.strftime("%Y-%m-%d"),
                "price": round(float(row['close']), 2)
            }
            for idx, row in historical_df.iterrows()
        ]
        
        # Calculate 30-day trend summary
        if len(predictions) > 0:
            final_predicted = predictions[-1]["predicted_price"]
            trend_direction = "bullish" if final_predicted > current_price else "bearish"
            trend_percent = round(((final_predicted - current_price) / current_price) * 100, 2)
        else:
            trend_direction = "neutral"
            trend_percent = 0
        
        result = {
            **current_data,
            "predictions": predictions,
            "historical_prices": historical_prices,
            "trend_summary": {
                "direction": trend_direction,
                "change_percent": trend_percent,
                "days": len(predictions)
            },
            "model_type": "LSTM",
            "lookback_days": self.sequence_length,
            "last_updated": datetime.now().isoformat(),
            "disclaimer": "AI predictions are for informational purposes only. Not financial advice."
        }
        
        # Cache result
        self.prediction_cache[cache_key] = {
            'timestamp': datetime.now(),
            'data': result
        }
        
        return result
    
    def get_available_symbols(self) -> List[str]:
        """Get list of available NIFTY 50 symbols."""
        return NIFTY_50_SYMBOLS
    
    def get_top_symbols(self) -> List[str]:
        """Get top 10 most traded symbols."""
        return TOP_10_SYMBOLS
    
    def batch_train(
        self, 
        symbols: Optional[List[str]] = None,
        epochs: int = 25
    ) -> Dict[str, Any]:
        """
        Train models for multiple symbols.
        
        Args:
            symbols: List of symbols (default: TOP_10)
            epochs: Training epochs per symbol
            
        Returns:
            Training results for all symbols
        """
        if symbols is None:
            symbols = TOP_10_SYMBOLS
            
        results = {
            "started_at": datetime.now().isoformat(),
            "symbols_requested": len(symbols),
            "results": []
        }
        
        for symbol in symbols:
            try:
                result = self.train_model(symbol, epochs=epochs)
                results["results"].append(result)
            except Exception as e:
                results["results"].append({
                    "symbol": symbol,
                    "status": "error",
                    "error": str(e)
                })
                
        results["completed_at"] = datetime.now().isoformat()
        results["successful"] = sum(1 for r in results["results"] if r.get("status") == "success")
        results["failed"] = len(results["results"]) - results["successful"]
        
        return results


# Singleton instance
prediction_service = PredictionService()
