'use client';

import { useState, useEffect, useCallback } from 'react';

export interface Toast {
    id: string;
    type: 'success' | 'warning' | 'error' | 'alert';
    title: string;
    message: string;
    duration?: number;
}

interface ToastProviderProps {
    children: React.ReactNode;
}

// Global toast state
let toastListeners: ((toast: Toast) => void)[] = [];

export function showToast(toast: Omit<Toast, 'id'>) {
    const id = Math.random().toString(36).substring(7);
    toastListeners.forEach(listener => listener({ ...toast, id }));
}

export function ToastContainer() {
    const [toasts, setToasts] = useState<Toast[]>([]);

    useEffect(() => {
        const listener = (toast: Toast) => {
            setToasts(prev => [...prev, toast]);

            // Auto-dismiss after duration
            setTimeout(() => {
                setToasts(prev => prev.filter(t => t.id !== toast.id));
            }, toast.duration || 5000);
        };

        toastListeners.push(listener);
        return () => {
            toastListeners = toastListeners.filter(l => l !== listener);
        };
    }, []);

    const dismissToast = useCallback((id: string) => {
        setToasts(prev => prev.filter(t => t.id !== id));
    }, []);

    if (toasts.length === 0) return null;

    return (
        <div className="toast-container">
            {toasts.map((toast) => (
                <ToastItem key={toast.id} toast={toast} onDismiss={dismissToast} />
            ))}

            <style jsx>{`
        .toast-container {
          position: fixed;
          top: 80px;
          right: 20px;
          z-index: 9999;
          display: flex;
          flex-direction: column;
          gap: 12px;
          max-width: 400px;
        }
      `}</style>
        </div>
    );
}

interface ToastItemProps {
    toast: Toast;
    onDismiss: (id: string) => void;
}

function ToastItem({ toast, onDismiss }: ToastItemProps) {
    const iconMap = {
        success: '✓',
        warning: '⚠',
        error: '✕',
        alert: '🔔',
    };

    const colorMap = {
        success: { bg: 'rgba(34, 197, 94, 0.15)', border: 'rgba(34, 197, 94, 0.4)', icon: '#4ade80' },
        warning: { bg: 'rgba(234, 179, 8, 0.15)', border: 'rgba(234, 179, 8, 0.4)', icon: '#facc15' },
        error: { bg: 'rgba(239, 68, 68, 0.15)', border: 'rgba(239, 68, 68, 0.4)', icon: '#f87171' },
        alert: { bg: 'rgba(59, 130, 246, 0.15)', border: 'rgba(59, 130, 246, 0.4)', icon: '#60a5fa' },
    };

    const colors = colorMap[toast.type];

    return (
        <div
            className="toast-item"
            style={{
                background: colors.bg,
                borderColor: colors.border,
            }}
        >
            <div className="toast-icon" style={{ color: colors.icon }}>
                {iconMap[toast.type]}
            </div>
            <div className="toast-content">
                <div className="toast-title">{toast.title}</div>
                <div className="toast-message">{toast.message}</div>
            </div>
            <button
                className="toast-close"
                onClick={() => onDismiss(toast.id)}
            >
                ✕
            </button>

            <style jsx>{`
        .toast-item {
          display: flex;
          align-items: flex-start;
          gap: 12px;
          padding: 16px;
          border-radius: 12px;
          border: 1px solid;
          backdrop-filter: blur(20px);
          animation: slideIn 0.3s ease-out;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
        }

        @keyframes slideIn {
          from {
            transform: translateX(100%);
            opacity: 0;
          }
          to {
            transform: translateX(0);
            opacity: 1;
          }
        }

        .toast-icon {
          font-size: 1.25rem;
          flex-shrink: 0;
        }

        .toast-content {
          flex: 1;
          min-width: 0;
        }

        .toast-title {
          font-weight: 600;
          color: white;
          margin-bottom: 4px;
        }

        .toast-message {
          font-size: 0.875rem;
          color: rgba(255, 255, 255, 0.7);
          line-height: 1.4;
        }

        .toast-close {
          background: none;
          border: none;
          color: rgba(255, 255, 255, 0.4);
          cursor: pointer;
          padding: 4px;
          font-size: 0.75rem;
          line-height: 1;
          transition: color 0.2s;
        }

        .toast-close:hover {
          color: white;
        }
      `}</style>
        </div>
    );
}
