'use client';

import {
    LineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    ReferenceLine,
    Area,
    ComposedChart,
} from 'recharts';

interface HistoricalPrice {
    date: string;
    price: number;
}

interface Prediction {
    date: string;
    predicted_price: number;
    change_percent: number;
    confidence: number;
}

interface PredictionChartProps {
    historicalPrices: HistoricalPrice[];
    predictions: Prediction[];
    currentPrice: number;
    symbol: string;
}

export function PredictionChart({
    historicalPrices,
    predictions,
    currentPrice,
    symbol,
}: PredictionChartProps) {
    // Combine historical and predicted data for the chart
    const chartData = [
        ...historicalPrices.map((h) => ({
            date: h.date,
            historical: h.price,
            predicted: null as number | null,
            type: 'historical',
        })),
        // Add current price as bridge point
        {
            date: historicalPrices[historicalPrices.length - 1]?.date || '',
            historical: currentPrice,
            predicted: currentPrice,
            type: 'bridge',
        },
        ...predictions.map((p) => ({
            date: p.date,
            historical: null as number | null,
            predicted: p.predicted_price,
            type: 'predicted',
        })),
    ];

    // Calculate min/max for Y axis
    const allPrices = [
        ...historicalPrices.map((h) => h.price),
        ...predictions.map((p) => p.predicted_price),
    ];
    const minPrice = Math.floor(Math.min(...allPrices) * 0.98);
    const maxPrice = Math.ceil(Math.max(...allPrices) * 1.02);

    // Format date for display
    const formatDate = (dateStr: string) => {
        const date = new Date(dateStr);
        return date.toLocaleDateString('en-IN', { month: 'short', day: 'numeric' });
    };

    // Custom tooltip
    const CustomTooltip = ({ active, payload, label }: any) => {
        if (active && payload && payload.length) {
            const data = payload[0];
            const isPrediction = data.dataKey === 'predicted';
            const price = data.value;

            return (
                <div className="bg-zinc-900 border border-zinc-700 rounded-lg px-4 py-3 shadow-xl">
                    <p className="text-zinc-400 text-sm mb-1">{formatDate(label)}</p>
                    <p className={`text-lg font-bold ${isPrediction ? 'text-purple-400' : 'text-blue-400'}`}>
                        ₹{price?.toFixed(2)}
                    </p>
                    {isPrediction && (
                        <p className="text-xs text-purple-400/70 mt-1">AI Predicted</p>
                    )}
                </div>
            );
        }
        return null;
    };

    return (
        <div className="glass rounded-2xl p-6">
            <div className="flex items-center justify-between mb-6">
                <h4 className="text-xl font-semibold text-white flex items-center gap-3">
                    📊 Price Trend & Forecast
                </h4>
                <div className="flex items-center gap-4 text-sm">
                    <span className="flex items-center gap-2">
                        <span className="w-3 h-3 bg-blue-500 rounded-full"></span>
                        <span className="text-zinc-400">Historical</span>
                    </span>
                    <span className="flex items-center gap-2">
                        <span className="w-3 h-3 bg-purple-500 rounded-full"></span>
                        <span className="text-zinc-400">Predicted</span>
                    </span>
                </div>
            </div>

            <div className="h-[300px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                    <ComposedChart data={chartData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                        <defs>
                            <linearGradient id="historicalGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                            </linearGradient>
                            <linearGradient id="predictedGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#a855f7" stopOpacity={0.3} />
                                <stop offset="95%" stopColor="#a855f7" stopOpacity={0} />
                            </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
                        <XAxis
                            dataKey="date"
                            tickFormatter={formatDate}
                            stroke="#71717a"
                            tick={{ fill: '#71717a', fontSize: 12 }}
                            axisLine={{ stroke: '#27272a' }}
                        />
                        <YAxis
                            domain={[minPrice, maxPrice]}
                            stroke="#71717a"
                            tick={{ fill: '#71717a', fontSize: 12 }}
                            axisLine={{ stroke: '#27272a' }}
                            tickFormatter={(value) => `₹${value}`}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <ReferenceLine
                            y={currentPrice}
                            stroke="#fbbf24"
                            strokeDasharray="5 5"
                            label={{
                                value: `Current: ₹${currentPrice.toFixed(0)}`,
                                fill: '#fbbf24',
                                fontSize: 11,
                                position: 'insideTopRight',
                            }}
                        />
                        {/* Historical Area */}
                        <Area
                            type="monotone"
                            dataKey="historical"
                            stroke="#3b82f6"
                            strokeWidth={2}
                            fill="url(#historicalGradient)"
                            connectNulls={false}
                            dot={false}
                        />
                        {/* Predicted Area */}
                        <Area
                            type="monotone"
                            dataKey="predicted"
                            stroke="#a855f7"
                            strokeWidth={2}
                            strokeDasharray="5 5"
                            fill="url(#predictedGradient)"
                            connectNulls={false}
                            dot={{ fill: '#a855f7', strokeWidth: 0, r: 3 }}
                        />
                    </ComposedChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
}
