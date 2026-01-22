'use client';

import type { Alert } from '../types/alert';

interface AlertListProps {
    alerts: Alert[];
    onDelete: (id: string) => Promise<void>;
    loading?: boolean;
}

/**
 * List component displaying all active alerts
 */
export function AlertList({ alerts, onDelete, loading }: AlertListProps) {
    if (loading) {
        return (
            <div className="alert-list loading">
                <div className="loading-spinner" />
                <p>Loading alerts...</p>
                <style jsx>{`
          .alert-list.loading {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 2rem;
            color: rgba(255, 255, 255, 0.5);
          }
          .loading-spinner {
            width: 24px;
            height: 24px;
            border: 2px solid rgba(255, 255, 255, 0.2);
            border-top-color: var(--accent-primary);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            margin-bottom: 1rem;
          }
          @keyframes spin {
            to { transform: rotate(360deg); }
          }
        `}</style>
            </div>
        );
    }

    if (alerts.length === 0) {
        return (
            <div className="alert-list empty">
                <div className="empty-icon">🔔</div>
                <p>No alerts yet</p>
                <span>Create an alert above to get notified when prices change</span>
                <style jsx>{`
          .alert-list.empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 3rem;
            color: rgba(255, 255, 255, 0.5);
            background: rgba(255, 255, 255, 0.02);
            border-radius: 12px;
            border: 1px dashed rgba(255, 255, 255, 0.1);
          }
          .empty-icon {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            opacity: 0.4;
          }
          p {
            font-size: 1.1rem;
            margin: 0 0 0.5rem;
          }
          span {
            font-size: 0.9rem;
          }
        `}</style>
            </div>
        );
    }

    return (
        <div className="alert-list">
            {alerts.map((alert) => (
                <AlertItem key={alert.id} alert={alert} onDelete={onDelete} />
            ))}
            <style jsx>{`
        .alert-list {
          display: flex;
          flex-direction: column;
          gap: 0.75rem;
        }
      `}</style>
        </div>
    );
}

interface AlertItemProps {
    alert: Alert;
    onDelete: (id: string) => Promise<void>;
}

function AlertItem({ alert, onDelete }: AlertItemProps) {
    const handleDelete = async () => {
        if (confirm(`Delete alert for ${alert.symbol}?`)) {
            await onDelete(alert.id);
        }
    };

    const conditionText = alert.condition === 'above' ? '↗ Above' : '↘ Below';
    const statusClass = alert.is_triggered ? 'triggered' : 'active';

    return (
        <div className={`alert-item ${statusClass}`}>
            <div className="alert-symbol">{alert.symbol}</div>
            <div className="alert-condition">
                <span className="condition-label">{conditionText}</span>
                <span className="target-price">${alert.target_price.toFixed(2)}</span>
            </div>
            <div className="alert-status">
                {alert.is_triggered ? (
                    <span className="badge triggered">✓ Triggered</span>
                ) : (
                    <span className="badge active">Active</span>
                )}
            </div>
            <button className="delete-btn" onClick={handleDelete} aria-label="Delete alert">
                ✕
            </button>

            <style jsx>{`
        .alert-item {
          display: flex;
          align-items: center;
          gap: 1.5rem;
          padding: 1rem 1.25rem;
          background: rgba(255, 255, 255, 0.05);
          border: 1px solid rgba(255, 255, 255, 0.08);
          border-radius: 12px;
          transition: all 0.2s ease;
        }

        .alert-item:hover {
          background: rgba(255, 255, 255, 0.08);
          border-color: rgba(255, 255, 255, 0.15);
        }

        .alert-item.triggered {
          background: rgba(34, 197, 94, 0.1);
          border-color: rgba(34, 197, 94, 0.3);
        }

        .alert-symbol {
          font-size: 1.1rem;
          font-weight: 700;
          color: white;
          min-width: 60px;
        }

        .alert-condition {
          flex: 1;
          display: flex;
          gap: 0.75rem;
          align-items: center;
        }

        .condition-label {
          font-size: 0.85rem;
          color: rgba(255, 255, 255, 0.6);
        }

        .target-price {
          font-size: 1rem;
          font-weight: 600;
          color: white;
        }

        .alert-status {
          min-width: 100px;
        }

        .badge {
          padding: 0.35rem 0.75rem;
          border-radius: 20px;
          font-size: 0.75rem;
          font-weight: 600;
          text-transform: uppercase;
        }

        .badge.active {
          background: rgba(59, 130, 246, 0.2);
          color: #60a5fa;
        }

        .badge.triggered {
          background: rgba(34, 197, 94, 0.2);
          color: #4ade80;
        }

        .delete-btn {
          padding: 0.5rem;
          background: transparent;
          border: none;
          color: rgba(255, 255, 255, 0.4);
          cursor: pointer;
          font-size: 1rem;
          line-height: 1;
          border-radius: 6px;
          transition: all 0.2s ease;
        }

        .delete-btn:hover {
          background: rgba(239, 68, 68, 0.2);
          color: #f87171;
        }
      `}</style>
        </div>
    );
}
