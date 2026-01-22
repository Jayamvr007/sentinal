'use client';

import { useCallback } from 'react';
import { usePriceStream, TriggeredAlert } from './hooks/usePriceStream';
import { useAlerts } from './hooks/useAlerts';
import { ConnectionStatus } from './components/ConnectionStatus';
import { PriceCard } from './components/PriceCard';
import { AlertForm } from './components/AlertForm';
import { AlertList } from './components/AlertList';
import { ToastContainer, showToast } from './components/Toast';

// Available symbols for alerts
const SYMBOLS = ['AAPL', 'GOOGL', 'TSLA', 'MSFT', 'AMZN', 'NVDA', 'META', 'JPM', 'V', 'SPY'];

export default function Home() {
  // Handle alert triggers with toast notification
  const handleAlertTriggered = useCallback((alert: TriggeredAlert) => {
    showToast({
      type: 'alert',
      title: `🎯 Alert Triggered: ${alert.symbol}`,
      message: `Price went ${alert.condition} $${alert.target_price.toFixed(2)}`,
      duration: 8000,
    });
  }, []);

  const { prices, connectionStatus, lastUpdate, reconnect } = usePriceStream({
    onAlertTriggered: handleAlertTriggered,
  });
  const { alerts, loading: alertsLoading, createAlert, deleteAlert, refetchAlerts } = useAlerts();

  const priceArray = Array.from(prices.values());

  // Group by sector
  const sectors = priceArray.reduce((acc, price) => {
    const sector = getSector(price.symbol);
    if (!acc[sector]) acc[sector] = [];
    acc[sector].push(price);
    return acc;
  }, {} as Record<string, typeof priceArray>);

  return (
    <div className="min-h-screen bg-mesh">
      {/* Toast Notifications */}
      <ToastContainer />

      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 glass">
        <div className="w-full px-6 lg:px-12">
          <div className="flex items-center justify-between h-16">
            {/* Logo & Title */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
                <span className="text-xl">🛡️</span>
              </div>
              <div>
                <h1 className="text-lg font-bold text-white">Sentinel</h1>
                <p className="text-xs text-zinc-500">Market Watchdog</p>
              </div>
            </div>

            {/* Connection Status */}
            <ConnectionStatus
              status={connectionStatus}
              lastUpdate={lastUpdate}
              onReconnect={reconnect}
            />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="pt-24 pb-12 px-6 lg:px-12">
        {/* Hero Section */}
        <div className="text-center mb-12 py-4">
          <h2 className="text-4xl sm:text-5xl font-bold mb-4">
            <span className="gradient-text">Real-Time Market</span>
            <br />
            <span className="text-white">Intelligence</span>
          </h2>
          <p className="text-zinc-400 max-w-lg" style={{ margin: '0 auto', marginTop: '1.5rem', textAlign: 'center' }}>
            Monitor your portfolio with live price updates, custom alerts, and cross-platform sync.
          </p>
        </div>

        {/* Stats Bar */}
        <div className='pb-12'>
          <div className="glass rounded-2xl p-4 mb-8 flex flex-wrap items-center justify-center gap-6 sm:gap-12">
            <div className="text-center">
              <p className="text-2xl font-bold text-white">{priceArray.length}</p>
              <p className="text-xs text-zinc-500">Symbols</p>
            </div>
            <div className="w-px h-8 bg-zinc-700 hidden sm:block" />
            <div className="text-center">
              <p className="text-2xl font-bold text-emerald-400">
                {priceArray.filter(p => p.change_percent > 0).length}
              </p>
              <p className="text-xs text-zinc-500">Gainers</p>
            </div>
            <div className="w-px h-8 bg-zinc-700 hidden sm:block" />
            <div className="text-center">
              <p className="text-2xl font-bold text-red-400">
                {priceArray.filter(p => p.change_percent < 0).length}
              </p>
              <p className="text-xs text-zinc-500">Losers</p>
            </div>
            <div className="w-px h-8 bg-zinc-700 hidden sm:block" />
            <div className="text-center">
              <p className="text-2xl font-bold text-white">
                {connectionStatus === 'connected' ? '1s' : '--'}
              </p>
              <p className="text-xs text-zinc-500">Update Rate</p>
            </div>
          </div>

          {/* Loading State */}
          {priceArray.length === 0 && (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="h-40 rounded-2xl animate-shimmer" />
              ))}
            </div>
          )}
        </div>

        {/* Alerts Section */}
        <div className="mb-12">
          <h3 className="text-xl font-bold text-white mb-4">📢 Price Alerts</h3>
          <AlertForm
            symbols={SYMBOLS}
            onSubmit={async (alert) => { await createAlert(alert); }}
            disabled={connectionStatus !== 'connected'}
          />
          <AlertList
            alerts={alerts}
            onDelete={async (id) => { await deleteAlert(id); }}
            loading={alertsLoading}
          />
        </div>

        {/* Price Grid - All cards in continuous flow */}
        {priceArray.length > 0 && (
          <div>
            <h3 className="text-xl font-bold text-white mb-4">📊 Live Prices</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {priceArray.map((price) => (
                <PriceCard key={price.symbol} price={price} />
              ))}
            </div>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-zinc-800 py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p className="text-sm text-zinc-500">
            Sentinel Market Watchdog • Real-time data powered by Finnhub
          </p>
        </div>
      </footer>
    </div>
  );
}

// Helper functions
function getSector(symbol: string): string {
  const sectors: Record<string, string> = {
    AAPL: 'Technology',
    GOOGL: 'Technology',
    TSLA: 'Automotive',
    MSFT: 'Technology',
    AMZN: 'Consumer',
    NVDA: 'Technology',
    META: 'Technology',
    SLV: 'Commodities',
    GLD: 'Commodities',
    SPY: 'Index',
  };
  return sectors[symbol] || 'Other';
}

function getSectorIcon(sector: string): string {
  const icons: Record<string, string> = {
    Technology: '💻',
    Automotive: '🚗',
    Consumer: '🛒',
    Commodities: '🪙',
    Index: '📊',
    Other: '📈',
  };
  return icons[sector] || '📈';
}
