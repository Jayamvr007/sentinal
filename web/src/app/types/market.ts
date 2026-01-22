// Types for Sentinel Market Data

export interface PriceData {
  symbol: string;
  price: number;
  previous_close: number;
  change: number;
  change_percent: number;
  volume: number;
  timestamp: string;
}

export interface SymbolInfo {
  symbol: string;
  name: string;
  sector: string;
  current_price?: number;
}

export interface WebSocketMessage {
  type: 'price_update' | 'initial_data' | 'heartbeat' | 'alert_trigger' | 'alert_triggered' | 'error';
  data: {
    prices?: PriceData[];
    [key: string]: unknown;
  };
  timestamp: string;
}

export interface MarketSummary {
  symbols: SymbolInfo[];
  last_updated: string;
  market_status: 'open' | 'closed' | 'pre-market' | 'after-hours';
}

export type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'reconnecting';
