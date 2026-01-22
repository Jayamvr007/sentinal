/**
 * Alert types for the Sentinel app
 */

export interface Alert {
    id: string;
    symbol: string;
    condition: 'above' | 'below';
    target_price: number;
    is_triggered: boolean;
    is_active: boolean;
    created_at: string;
    triggered_at: string | null;
}

export interface AlertCreate {
    symbol: string;
    condition: 'above' | 'below';
    target_price: number;
}
