'use client';

import { ConnectionStatus as ConnectionStatusType } from '../types/market';

interface ConnectionStatusProps {
    status: ConnectionStatusType;
    lastUpdate: Date | null;
    onReconnect: () => void;
}

export function ConnectionStatus({ status, lastUpdate, onReconnect }: ConnectionStatusProps) {
    const statusConfig = {
        connecting: {
            color: 'bg-amber-500',
            pulseColor: 'bg-amber-400',
            text: 'Connecting...',
            showPulse: true,
        },
        connected: {
            color: 'bg-emerald-500',
            pulseColor: 'bg-emerald-400',
            text: 'Live',
            showPulse: true,
        },
        disconnected: {
            color: 'bg-red-500',
            pulseColor: 'bg-red-400',
            text: 'Disconnected',
            showPulse: false,
        },
        reconnecting: {
            color: 'bg-amber-500',
            pulseColor: 'bg-amber-400',
            text: 'Reconnecting...',
            showPulse: true,
        },
    };

    const config = statusConfig[status];

    return (
        <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
                <div className="relative flex items-center justify-center">
                    {config.showPulse && (
                        <span
                            className={`absolute inline-flex h-3 w-3 animate-ping rounded-full ${config.pulseColor} opacity-75`}
                        />
                    )}
                    <span className={`relative inline-flex h-2.5 w-2.5 rounded-full ${config.color}`} />
                </div>
                <span className="text-sm font-medium text-zinc-300">{config.text}</span>
            </div>

            {lastUpdate && status === 'connected' && (
                <span className="text-xs text-zinc-500">
                    Updated {lastUpdate.toLocaleTimeString()}
                </span>
            )}

            {status === 'disconnected' && (
                <button
                    onClick={onReconnect}
                    className="text-xs text-blue-400 hover:text-blue-300 transition-colors"
                >
                    Retry
                </button>
            )}
        </div>
    );
}
