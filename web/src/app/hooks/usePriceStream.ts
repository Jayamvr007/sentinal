'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { PriceData, WebSocketMessage, ConnectionStatus } from '../types/market';

const WS_URL = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/price/stream';
const RECONNECT_DELAY_BASE = 1000;
const MAX_RECONNECT_DELAY = 30000;
const MAX_RECONNECT_ATTEMPTS = 10;
const HEARTBEAT_TIMEOUT = 35000; // If no message received in 35s, consider connection stale
const PING_INTERVAL = 25000; // Send ping every 25 seconds to keep connection alive

// Alert triggered event type
export interface TriggeredAlert {
    id: string;
    symbol: string;
    condition: string;
    target_price: number;
}

interface UsePriceStreamOptions {
    onAlertTriggered?: (alert: TriggeredAlert) => void;
}

interface UsePriceStreamReturn {
    prices: Map<string, PriceData>;
    connectionStatus: ConnectionStatus;
    lastUpdate: Date | null;
    reconnect: () => void;
}

export function usePriceStream(options?: UsePriceStreamOptions): UsePriceStreamReturn {
    const [prices, setPrices] = useState<Map<string, PriceData>>(new Map());
    const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('connecting');
    const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

    const wsRef = useRef<WebSocket | null>(null);
    const reconnectAttempts = useRef(0);
    const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);
    const heartbeatTimeoutRef = useRef<NodeJS.Timeout | null>(null);
    const pingIntervalRef = useRef<NodeJS.Timeout | null>(null);
    const onAlertTriggeredRef = useRef(options?.onAlertTriggered);

    // Update ref when callback changes
    useEffect(() => {
        onAlertTriggeredRef.current = options?.onAlertTriggered;
    }, [options?.onAlertTriggered]);

    // Clear all timers helper
    const clearTimers = useCallback(() => {
        if (heartbeatTimeoutRef.current) {
            clearTimeout(heartbeatTimeoutRef.current);
            heartbeatTimeoutRef.current = null;
        }
        if (pingIntervalRef.current) {
            clearInterval(pingIntervalRef.current);
            pingIntervalRef.current = null;
        }
        if (reconnectTimeoutRef.current) {
            clearTimeout(reconnectTimeoutRef.current);
            reconnectTimeoutRef.current = null;
        }
    }, []);

    const connect = useCallback(() => {
        if (wsRef.current?.readyState === WebSocket.OPEN) {
            return;
        }

        // Clear any existing timers before connecting
        clearTimers();
        setConnectionStatus('connecting');

        try {
            const ws = new WebSocket(WS_URL);
            wsRef.current = ws;

            // Helper to reset heartbeat timeout - called on every message
            const resetHeartbeat = () => {
                if (heartbeatTimeoutRef.current) {
                    clearTimeout(heartbeatTimeoutRef.current);
                }
                heartbeatTimeoutRef.current = setTimeout(() => {
                    console.warn('[WS] No data received for 35s - connection appears stale, reconnecting...');
                    // Force close and reconnect
                    if (wsRef.current) {
                        wsRef.current.close();
                    }
                }, HEARTBEAT_TIMEOUT);
            };

            ws.onopen = () => {
                console.log('[WS] Connected to price stream');
                setConnectionStatus('connected');
                reconnectAttempts.current = 0;

                // Start heartbeat timeout
                resetHeartbeat();

                // Start ping interval to keep connection alive
                pingIntervalRef.current = setInterval(() => {
                    if (ws.readyState === WebSocket.OPEN) {
                        try {
                            ws.send(JSON.stringify({ type: 'ping', timestamp: Date.now() }));
                            console.log('[WS] Sent ping');
                        } catch (e) {
                            console.error('[WS] Failed to send ping:', e);
                        }
                    }
                }, PING_INTERVAL);
            };

            ws.onmessage = (event) => {
                // Reset heartbeat on ANY message (including heartbeats from server)
                resetHeartbeat();

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

                    // Handle alert triggered events
                    if (message.type === 'alert_triggered') {
                        console.log('[WS] Alert triggered:', message.data);
                        if (onAlertTriggeredRef.current) {
                            onAlertTriggeredRef.current(message.data as unknown as TriggeredAlert);
                        }
                    }

                    // Log heartbeat acknowledgment
                    if (message.type === 'heartbeat') {
                        console.log('[WS] Received heartbeat from server');
                    }
                } catch (error) {
                    console.error('[WS] Error parsing message:', error);
                }
            };

            ws.onclose = (event) => {
                console.log('[WS] Connection closed:', event.code, event.reason);
                setConnectionStatus('disconnected');
                wsRef.current = null;

                // Clear timers on close
                clearTimers();

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
    }, [clearTimers]);

    const reconnect = useCallback(() => {
        // Clear all timers
        clearTimers();

        // Close existing connection
        if (wsRef.current) {
            wsRef.current.close();
            wsRef.current = null;
        }

        // Reset attempts and connect
        reconnectAttempts.current = 0;
        connect();
    }, [connect, clearTimers]);

    useEffect(() => {
        connect();

        return () => {
            clearTimers();
            if (wsRef.current) {
                wsRef.current.close();
            }
        };
    }, [connect, clearTimers]);

    return { prices, connectionStatus, lastUpdate, reconnect };
}
