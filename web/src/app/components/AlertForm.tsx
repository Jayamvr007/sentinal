'use client';

import { useState } from 'react';
import type { AlertCreate } from '../types/alert';

interface AlertFormProps {
    symbols: string[];
    onSubmit: (alert: AlertCreate) => Promise<void>;
    disabled?: boolean;
}

/**
 * Form component for creating new price alerts
 */
export function AlertForm({ symbols, onSubmit, disabled }: AlertFormProps) {
    const [symbol, setSymbol] = useState(symbols[0] || 'AAPL');
    const [condition, setCondition] = useState<'above' | 'below'>('below');
    const [targetPrice, setTargetPrice] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!targetPrice || isNaN(Number(targetPrice))) return;

        setIsSubmitting(true);
        try {
            await onSubmit({
                symbol,
                condition,
                target_price: Number(targetPrice),
            });
            setTargetPrice('');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <form onSubmit={handleSubmit} className="alert-form">
            <div className="form-row">
                <div className="form-group">
                    <label htmlFor="symbol">Symbol</label>
                    <select
                        id="symbol"
                        value={symbol}
                        onChange={(e) => setSymbol(e.target.value)}
                        disabled={disabled || isSubmitting}
                    >
                        {symbols.map((s) => (
                            <option key={s} value={s}>{s}</option>
                        ))}
                    </select>
                </div>

                <div className="form-group">
                    <label htmlFor="condition">Condition</label>
                    <select
                        id="condition"
                        value={condition}
                        onChange={(e) => setCondition(e.target.value as 'above' | 'below')}
                        disabled={disabled || isSubmitting}
                    >
                        <option value="above">Price Above</option>
                        <option value="below">Price Below</option>
                    </select>
                </div>

                <div className="form-group">
                    <label htmlFor="price">Target Price</label>
                    <input
                        id="price"
                        type="number"
                        step="0.01"
                        min="0"
                        placeholder="Enter price..."
                        value={targetPrice}
                        onChange={(e) => setTargetPrice(e.target.value)}
                        disabled={disabled || isSubmitting}
                    />
                </div>

                <button
                    type="submit"
                    className="submit-btn"
                    disabled={disabled || isSubmitting || !targetPrice}
                >
                    {isSubmitting ? 'Creating...' : 'Create Alert'}
                </button>
            </div>

            <style jsx>{`
        .alert-form {
          background: rgba(255, 255, 255, 0.05);
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: 16px;
          padding: 1.5rem;
          margin-bottom: 1.5rem;
        }

        .form-row {
          display: flex;
          gap: 1rem;
          flex-wrap: wrap;
          align-items: flex-end;
        }

        .form-group {
          flex: 1;
          min-width: 150px;
        }

        label {
          display: block;
          font-size: 0.85rem;
          color: rgba(255, 255, 255, 0.6);
          margin-bottom: 0.5rem;
        }

        select, input {
          width: 100%;
          padding: 0.75rem 1rem;
          background: rgba(255, 255, 255, 0.08);
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: 8px;
          color: white;
          font-size: 1rem;
          outline: none;
          transition: all 0.2s ease;
        }

        select:focus, input:focus {
          border-color: var(--accent-primary);
          box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
        }

        select option {
          background: #1a1a2e;
          color: white;
        }

        input::placeholder {
          color: rgba(255, 255, 255, 0.3);
        }

        .submit-btn {
          padding: 0.75rem 1.5rem;
          background: linear-gradient(135deg, var(--accent-primary), #6366f1);
          border: none;
          border-radius: 8px;
          color: white;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s ease;
          white-space: nowrap;
        }

        .submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 4px 15px rgba(59, 130, 246, 0.4);
        }

        .submit-btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
      `}</style>
        </form>
    );
}
