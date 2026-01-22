'use client';

import { useState, useCallback, useEffect } from 'react';
import type { Alert, AlertCreate } from '../types/alert';

const API_BASE = 'http://localhost:8000/api/v1';

/**
 * Hook for managing alerts via the REST API
 */
export function useAlerts() {
    const [alerts, setAlerts] = useState<Alert[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // Fetch all alerts
    const fetchAlerts = useCallback(async () => {
        try {
            setLoading(true);
            const response = await fetch(`${API_BASE}/alerts`);
            if (!response.ok) throw new Error('Failed to fetch alerts');
            const data = await response.json();
            setAlerts(data);
            setError(null);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to fetch alerts');
        } finally {
            setLoading(false);
        }
    }, []);

    // Create a new alert
    const createAlert = useCallback(async (alertData: AlertCreate): Promise<Alert | null> => {
        try {
            const response = await fetch(`${API_BASE}/alerts`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(alertData),
            });
            if (!response.ok) throw new Error('Failed to create alert');
            const newAlert = await response.json();
            setAlerts(prev => [newAlert, ...prev]);
            return newAlert;
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to create alert');
            return null;
        }
    }, []);

    // Delete an alert
    const deleteAlert = useCallback(async (alertId: string): Promise<boolean> => {
        try {
            const response = await fetch(`${API_BASE}/alerts/${alertId}`, {
                method: 'DELETE',
            });
            if (!response.ok) throw new Error('Failed to delete alert');
            setAlerts(prev => prev.filter(a => a.id !== alertId));
            return true;
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to delete alert');
            return false;
        }
    }, []);

    // Fetch on mount
    useEffect(() => {
        fetchAlerts();
    }, [fetchAlerts]);

    return {
        alerts,
        loading,
        error,
        createAlert,
        deleteAlert,
        refetchAlerts: fetchAlerts,
    };
}
