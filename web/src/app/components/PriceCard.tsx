'use client';

import { PriceData } from '../types/market';
import { useEffect, useRef, useState } from 'react';

interface PriceCardProps {
    price: PriceData;
}

// Sector icons mapping for NIFTY 50
const sectorIcons: Record<string, string> = {
    Technology: '💻',
    Finance: '🏦',
    Consumer: '🛒',
    Energy: '⚡',
    Telecom: '📱',
};

export function PriceCard({ price }: PriceCardProps) {
    const [flash, setFlash] = useState<'up' | 'down' | null>(null);
    const prevPriceRef = useRef<number>(price.price);

    useEffect(() => {
        if (price.price !== prevPriceRef.current) {
            const direction = price.price > prevPriceRef.current ? 'up' : 'down';
            setFlash(direction);
            prevPriceRef.current = price.price;

            const timeout = setTimeout(() => setFlash(null), 500);
            return () => clearTimeout(timeout);
        }
    }, [price.price]);

    const isPositive = price.change_percent >= 0;
    const changeColor = isPositive ? 'text-emerald-400' : 'text-red-400';
    const changeBg = isPositive ? 'bg-emerald-500/10' : 'bg-red-500/10';
    const flashBg = flash === 'up'
        ? 'ring-2 ring-emerald-500/50'
        : flash === 'down'
            ? 'ring-2 ring-red-500/50'
            : '';

    const formatVolume = (vol: number) => {
        if (vol >= 1_000_000) return `${(vol / 1_000_000).toFixed(1)}M`;
        if (vol >= 1_000) return `${(vol / 1_000).toFixed(0)}K`;
        return vol.toString();
    };

    return (
        <div
            className={`group relative overflow-hidden rounded-2xl bg-gradient-to-br from-zinc-800/80 to-zinc-900/80 backdrop-blur-sm border border-zinc-700/50 p-6 transition-all duration-300 hover:border-zinc-600/50 hover:shadow-lg hover:shadow-black/20 hover:scale-[1.02] cursor-pointer ${flashBg}`}
        >
            {/* Background gradient effect */}
            <div
                className={`
          absolute inset-0 opacity-0 group-hover:opacity-100 
          transition-opacity duration-500 pointer-events-none
          ${isPositive
                        ? 'bg-gradient-to-br from-emerald-500/5 to-transparent'
                        : 'bg-gradient-to-br from-red-500/5 to-transparent'}
        `}
            />

            {/* Header */}
            <div className="flex items-start justify-between mb-4 relative">
                <div>
                    <div className="flex items-center gap-2">
                        <span className="text-lg font-bold text-white">{price.symbol}</span>
                        <span className="text-lg">{sectorIcons[getSector(price.symbol)] || '📈'}</span>
                    </div>
                    <p className="text-xs text-zinc-500 mt-0.5">{getCompanyName(price.symbol)}</p>
                </div>
                <div className={`px-2.5 py-1 rounded-full text-xs font-semibold ${changeBg} ${changeColor}`}>
                    {isPositive ? '▲' : '▼'} {Math.abs(price.change_percent).toFixed(2)}%
                </div>
            </div>

            {/* Price */}
            <div className="mb-4 relative">
                <span className="text-3xl font-bold text-white tracking-tight">
                    ₹{price.price.toFixed(2)}
                </span>
                <div className="flex items-center gap-2 mt-1">
                    <span className={`text-sm font-medium ${changeColor}`}>
                        {isPositive ? '+' : ''}{price.change.toFixed(2)}
                    </span>
                    <span className="text-xs text-zinc-500">vs prev close</span>
                </div>
            </div>

            {/* Footer stats */}
            <div className="flex items-center justify-between text-xs text-zinc-500 relative">
                <div className="flex items-center gap-1">
                    <span className="text-zinc-600">Vol:</span>
                    <span className="text-zinc-400 font-medium">{formatVolume(price.volume)}</span>
                </div>
                <div className="flex items-center gap-1">
                    <span className="text-zinc-600">Prev:</span>
                    <span className="text-zinc-400">₹{price.previous_close.toFixed(2)}</span>
                </div>
            </div>
        </div>
    );
}

// Helper functions for NIFTY 50 Indian stocks
function getCompanyName(symbol: string): string {
    const names: Record<string, string> = {
        RELIANCE: 'Reliance Industries',
        TCS: 'Tata Consultancy Services',
        HDFCBANK: 'HDFC Bank Ltd.',
        INFY: 'Infosys Ltd.',
        ICICIBANK: 'ICICI Bank Ltd.',
        HINDUNILVR: 'Hindustan Unilever',
        ITC: 'ITC Ltd.',
        SBIN: 'State Bank of India',
        BHARTIARTL: 'Bharti Airtel Ltd.',
        KOTAKBANK: 'Kotak Mahindra Bank',
    };
    return names[symbol] || symbol;
}

function getSector(symbol: string): string {
    const sectors: Record<string, string> = {
        RELIANCE: 'Energy',
        TCS: 'Technology',
        HDFCBANK: 'Finance',
        INFY: 'Technology',
        ICICIBANK: 'Finance',
        HINDUNILVR: 'Consumer',
        ITC: 'Consumer',
        SBIN: 'Finance',
        BHARTIARTL: 'Telecom',
        KOTAKBANK: 'Finance',
    };
    return sectors[symbol] || 'Other';
}
