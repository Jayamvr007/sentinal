'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { PriceData, WebSocketMessage, ConnectionStatus } from '../types/market';

const WS_URL = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/price/stream';
const RECONNECT_DELAY_BASE = 1000;
const MAX_RECONNECT_DELAY = 30000;
const MAX_RECONNECT_ATTEMPTS = 10;

interface UsePriceStreamReturn {
    prices: Map<string, PriceData>;
    connectionStatus: ConnectionStatus;
    lastUpdate: Date | null;
    reconnect: () => void;
}

export function usePriceStream(): UsePriceStreamReturn {
    const [prices, setPrices] = useState<Map<string, PriceData>>(new Map());
    const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('connecting');
    const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

    const wsRef = useRef<WebSocket | null>(null);
    const reconnectAttempts = useRef(0);
    const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);

    const connect = useCallback(() => {
        if (wsRef.current?.readyState === WebSocket.OPEN) {
            return;
        }

        setConnectionStatus('connecting');

        try {
            const ws = new WebSocket(WS_URL);
            wsRef.current = ws;

            ws.onopen = () => {
                console.log('[WS] Connected to price stream');
                setConnectionStatus('connected');
                reconnectAttempts.current = 0;
            };

            ws.onmessage = (event) => {
                try {
                    const message: WebSocketMessage = JSON.parse(event.data);

                    if (message.type === 'price_update' || message.type === 'initial_data') {
                        const newPrices = message.data.prices;
                        if (newPrices) {
                            setPrices((prev) => {
                                const updated = new Map(prev);
                                newPrices.forEach((price) => {
                                    updated.set(price.symbol, price);
                                });
                                return updated;
                            });
                            setLastUpdate(new Date());
                        }
                    }
                } catch (error) {
                    console.error('[WS] Error parsing message:', error);
                }
            };

            ws.onclose = (event) => {
                console.log('[WS] Connection closed:', event.code, event.reason);
                setConnectionStatus('disconnected');
                wsRef.current = null;

                // Attempt reconnection with exponential backoff
                if (reconnectAttempts.current < MAX_RECONNECT_ATTEMPTS) {
                    const delay = Math.min(
                        RECONNECT_DELAY_BASE * Math.pow(2, reconnectAttempts.current),
                        MAX_RECONNECT_DELAY
                    );
                    console.log(`[WS] Reconnecting in ${delay}ms (attempt ${reconnectAttempts.current + 1})`);
                    setConnectionStatus('reconnecting');

                    reconnectTimeoutRef.current = setTimeout(() => {
                        reconnectAttempts.current++;
                        connect();
                    }, delay);
                }
            };

            ws.onerror = (error) => {
                console.error('[WS] WebSocket error:', error);
            };

        } catch (error) {
            console.error('[WS] Failed to create WebSocket:', error);
            setConnectionStatus('disconnected');
        }
    }, []);

    const reconnect = useCallback(() => {
        // Clear any pending reconnect
        if (reconnectTimeoutRef.current) {
            clearTimeout(reconnectTimeoutRef.current);
        }

        // Close existing connection
        if (wsRef.current) {
            wsRef.current.close();
            wsRef.current = null;
        }

        // Reset attempts and connect
        reconnectAttempts.current = 0;
        connect();
    }, [connect]);

    useEffect(() => {
        connect();

        return () => {
            if (reconnectTimeoutRef.current) {
                clearTimeout(reconnectTimeoutRef.current);
            }
            if (wsRef.current) {
                wsRef.current.close();
            }
        };
    }, [connect]);

    return { prices, connectionStatus, lastUpdate, reconnect };
}
