'use client';

import { useState, useEffect } from 'react';
import { PredictionChart } from './PredictionChart';

interface Prediction {
    date: string;
    predicted_price: number;
    change_percent: number;
    confidence: number;
}

interface PredictionData {
    symbol: string;
    current_price: number;
    previous_close: number;
    change_today: number;
    change_percent_today: number;
    predictions: Prediction[];
    historical_prices: { date: string; price: number }[];
    trend_summary: {
        direction: string;
        change_percent: number;
        days: number;
    };
    model_type: string;
    lookback_days: number;
    last_updated: string;
    disclaimer: string;
}

// Top NIFTY 50 symbols
const NIFTY_SYMBOLS = [
    'RELIANCE', 'TCS', 'HDFCBANK', 'INFY', 'ICICIBANK',
    'HINDUNILVR', 'ITC', 'SBIN', 'BHARTIARTL', 'KOTAKBANK'
];

export function AIPrediction() {
    const [selectedSymbol, setSelectedSymbol] = useState('RELIANCE');
    const [prediction, setPrediction] = useState<PredictionData | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [selectedDays, setSelectedDays] = useState<7 | 30>(7);

    // Refetch when days changes (only if we already have a prediction)
    useEffect(() => {
        if (prediction) {
            fetchPrediction();
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [selectedDays]);

    const fetchPrediction = async () => {
        setLoading(true);
        setError(null);
        setPrediction(null);

        try {
            const response = await fetch(
                `http://192.168.29.252:8000/api/v1/prediction/${selectedSymbol}?days=${selectedDays}`
            );

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.detail || 'Failed to get prediction');
            }

            const data = await response.json();
            setPrediction(data);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Network error');
        } finally {
            setLoading(false);
        }
    };

    const formatDate = (dateStr: string) => {
        const date = new Date(dateStr);
        return date.toLocaleDateString('en-IN', { weekday: 'short', month: 'short', day: 'numeric' });
    };

    return (
        <div className="mb-16 mt-8">
            {/* Section Header */}
            <h3 className="text-2xl font-bold text-white py-6 mb-6">🧠 AI Price Predictions</h3>

            {/* Symbol Selector Card */}
            <div className="glass rounded-2xl p-8 mb-8">
                <p className="text-sm text-zinc-400 py-2  mb-4">Select NIFTY 50 Stock</p>

                {/* Symbol Buttons - More gap */}
                <div className="flex flex-wrap gap-3 py-4 mb-6">
                    {NIFTY_SYMBOLS.map((symbol) => (
                        <button
                            key={symbol}
                            onClick={() => setSelectedSymbol(symbol)}
                            className={`px-5 py-2.5 rounded-full text-sm font-medium transition-all ${selectedSymbol === symbol
                                ? 'bg-purple-600 text-white shadow-lg shadow-purple-500/30'
                                : 'bg-zinc-800 text-zinc-300 hover:bg-zinc-700'
                                }`}
                        >
                            {symbol}
                        </button>
                    ))}
                </div>

                {/* Get Prediction Button */}
                <button
                    onClick={fetchPrediction}
                    disabled={loading}
                    className="w-full py-4 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 text-white font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 text-lg"
                >
                    {loading ? (
                        <span className="flex items-center justify-center gap-3">
                            <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                            </svg>
                            Analyzing Market Data...
                        </span>
                    ) : (
                        '🔮 Get AI Prediction'
                    )}
                </button>

                {loading && (
                    <p className="text-xs text-zinc-500 mt-4 text-center">
                        First prediction may take 30-60 seconds (model training)
                    </p>
                )}
            </div>

            {/* Error State */}
            {error && (
                <div className="glass rounded-2xl p-8 mb-8 border border-red-500/30">
                    <div className="flex items-center gap-4 text-red-400">
                        <span className="text-3xl">⚠️</span>
                        <div>
                            <p className="font-semibold text-lg">Prediction Failed</p>
                            <p className="text-sm text-red-400/80 mt-1">{error}</p>
                        </div>
                    </div>
                </div>
            )}

            {/* Prediction Results */}
            {prediction && (
                <div className="space-y-8 py-4">
                    {/* Current Price Card */}
                    <div className="glass rounded-2xl p-8 py-4">
                        <div className="flex items-start justify-between">
                            <div>
                                <h4 className="text-3xl font-bold text-white mb-2">
                                    {prediction.symbol.replace('.NS', '')}
                                </h4>
                                <p className="text-sm text-zinc-500">
                                    {prediction.model_type} Model • {prediction.lookback_days} day lookback
                                </p>
                            </div>
                            <div className="text-right">
                                <p className="text-4xl font-bold text-white mb-1">
                                    ₹{prediction.current_price.toFixed(2)}
                                </p>
                                <p className={`text-lg font-medium ${prediction.change_percent_today >= 0 ? 'text-emerald-400' : 'text-red-400'
                                    }`}>
                                    {prediction.change_percent_today >= 0 ? '+' : ''}
                                    {prediction.change_percent_today.toFixed(2)}% today
                                </p>
                            </div>
                        </div>
                        {/* Trend Summary Badge */}
                        {prediction.trend_summary && (
                            <div className={`mt-4 px-4 py-2 rounded-lg inline-flex items-center gap-2 ${prediction.trend_summary.direction === 'bullish'
                                ? 'bg-emerald-500/10 text-emerald-400'
                                : 'bg-red-500/10 text-red-400'
                                }`}>
                                <span>{prediction.trend_summary.direction === 'bullish' ? '📈' : '📉'}</span>
                                <span className="font-medium">
                                    {prediction.trend_summary.direction === 'bullish' ? 'Bullish' : 'Bearish'} trend
                                </span>
                                <span className="text-sm opacity-80">
                                    ({prediction.trend_summary.change_percent >= 0 ? '+' : ''}{prediction.trend_summary.change_percent}% in {prediction.trend_summary.days} days)
                                </span>
                            </div>
                        )}
                    </div>

                    {/* Prediction Chart */}
                    {prediction.historical_prices && prediction.historical_prices.length > 0 && (
                        <PredictionChart
                            historicalPrices={prediction.historical_prices}
                            predictions={prediction.predictions}
                            currentPrice={prediction.current_price}
                            symbol={prediction.symbol}
                        />
                    )}

                    {/* Predictions List */}
                    <div className="glass rounded-2xl p-8">
                        <div className="flex items-center justify-between mb-6">
                            <h4 className="text-xl font-semibold text-white flex items-center gap-3">
                                📈 {selectedDays}-Day Forecast
                            </h4>
                            {/* Days Toggle */}
                            <div className="flex items-center gap-2 bg-zinc-800 rounded-lg p-1">
                                <button
                                    onClick={() => setSelectedDays(7)}
                                    className={`px-3 py-1.5 rounded-md text-sm font-medium transition-all ${selectedDays === 7
                                        ? 'bg-purple-600 text-white'
                                        : 'text-zinc-400 hover:text-white'
                                        }`}
                                >
                                    7 Days
                                </button>
                                <button
                                    onClick={() => setSelectedDays(30)}
                                    className={`px-3 py-1.5 rounded-md text-sm font-medium transition-all ${selectedDays === 30
                                        ? 'bg-purple-600 text-white'
                                        : 'text-zinc-400 hover:text-white'
                                        }`}
                                >
                                    30 Days
                                </button>
                            </div>
                        </div>

                        <div className="space-y-1">
                            {prediction.predictions.map((pred, idx) => (
                                <div
                                    key={pred.date}
                                    className="flex items-center justify-between py-5 border-b border-zinc-800/50 last:border-0"
                                >
                                    <div>
                                        <p className="font-medium text-white text-lg">{formatDate(pred.date)}</p>
                                        <div className="flex items-center gap-2 text-sm text-zinc-500 mt-1">
                                            <span className="flex items-center gap-1">
                                                ✓ {Math.round(pred.confidence * 100)}% confidence
                                            </span>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-xl font-bold text-white">
                                            ₹{pred.predicted_price.toFixed(2)}
                                        </p>
                                        <p className={`text-base font-medium mt-1 ${pred.change_percent >= 0 ? 'text-emerald-400' : 'text-red-400'
                                            }`}>
                                            {pred.change_percent >= 0 ? '+' : ''}{pred.change_percent.toFixed(2)}%
                                        </p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Disclaimer */}
                    <div className="flex items-start gap-4 p-6 rounded-xl bg-amber-500/10 border border-amber-500/20">
                        <span className="text-2xl">⚠️</span>
                        <p className="text-sm text-amber-400/90 leading-relaxed">{prediction.disclaimer}</p>
                    </div>
                </div>
            )
            }
        </div >
    );
}

