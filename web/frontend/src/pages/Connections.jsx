import React, { useState } from 'react';
import { storeConnection } from '../api/store-connection';

const PROVIDERS = [
  { id: 'binance',  name: 'Binance',  icon: '🟡', desc: 'Spot + Futures + Margin', color: '#f59e0b', status: null },
  { id: 'bybit',    name: 'Bybit',    icon: '🔵', desc: 'Perpetuals + Options',     color: '#3b82f6', status: null },
  { id: 'bitget',   name: 'Bitget',   icon: '🟢', desc: 'Copy Trading + Spot',      color: '#10b981', status: null },
  { id: 'okx',      name: 'OKX',      icon: '⚫', desc: 'DeFi + Trading',           color: '#6b7280', status: null },
  { id: 'kraken',   name: 'Kraken',   icon: '🦑', desc: 'Staking + Spot',           color: '#7c3aed', status: null },
  { id: 'alpaca',   name: 'Alpaca',   icon: '🦙', desc: 'US Stocks + Crypto',       color: '#ec4899', status: null },
  { id: 'supabase', name: 'Supabase', icon: '🗄️', desc: 'Database Backend',         color: '#00d4ff', status: null },
  { id: 'custom',   name: 'Custom',   icon: '🔧', desc: 'Eigene API-Endpoint',      color: '#94a3b8', status: null },
];

function ConnectorCard({ provider, onConnect }) {
  const [showForm, setShowForm] = useState(false);
  const [key, setKey]    = useState('');
  const [secret, setSecret] = useState('');
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState(provider.status);

  async function handleConnect(e) {
    e.preventDefault();
    if (!key.trim()) return;
    setLoading(true);
    try {
      await storeConnection({ provider: provider.id, apiKey: key, apiSecret: secret, userId: 'user_local' });
      setStatus('connected');
      setShowForm(false);
      setKey(''); setSecret('');
    } catch (err) {
      setStatus('error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="card" style={{ border: status === 'connected' ? `1px solid ${provider.color}40` : undefined }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
        <div style={{
          width: 40, height: 40, borderRadius: 10,
          background: `${provider.color}15`,
          border: `1px solid ${provider.color}30`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 20, flexShrink: 0,
        }}>{provider.icon}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 700, fontSize: 14 }}>{provider.name}</div>
          <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{provider.desc}</div>
        </div>
        {status === 'connected' && <span className="badge badge-green">✓ Connected</span>}
        {status === 'error'     && <span className="badge badge-red">✗ Error</span>}
      </div>

      {!showForm ? (
        <button
          className="btn btn-secondary"
          style={{ width: '100%', justifyContent: 'center', color: status === 'connected' ? 'var(--accent-green)' : undefined }}
          onClick={() => setShowForm(true)}
        >
          {status === 'connected' ? '✏️ Neu verbinden' : '🔗 Verbinden'}
        </button>
      ) : (
        <form onSubmit={handleConnect} style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <input
            type="text" placeholder="API Key" value={key}
            onChange={e => setKey(e.target.value)} required
            style={{
              background: 'var(--bg-deep)', border: '1px solid var(--border)',
              borderRadius: 8, padding: '8px 12px', color: 'var(--text-primary)',
              fontSize: 13, outline: 'none', fontFamily: 'monospace',
            }}
          />
          <input
            type="password" placeholder="API Secret (optional)" value={secret}
            onChange={e => setSecret(e.target.value)}
            style={{
              background: 'var(--bg-deep)', border: '1px solid var(--border)',
              borderRadius: 8, padding: '8px 12px', color: 'var(--text-primary)',
              fontSize: 13, outline: 'none', fontFamily: 'monospace',
            }}
          />
          <div style={{ display: 'flex', gap: 8 }}>
            <button type="submit" className="btn btn-primary" style={{ flex: 1, justifyContent: 'center' }} disabled={loading}>
              {loading ? '⏳ Speichern...' : '✓ Speichern'}
            </button>
            <button type="button" className="btn btn-secondary" onClick={() => setShowForm(false)}>✕</button>
          </div>
          <div style={{ fontSize: 10, color: 'var(--text-muted)', textAlign: 'center' }}>
            🔒 Verschlüsselt gespeichert · API-Keys werden nie im Klartext übertragen
          </div>
        </form>
      )}
    </div>
  );
}

export default function Connections() {
  return (
    <div className="animate-fadein" style={{ maxWidth: 900, margin: '0 auto' }}>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 20, fontWeight: 800, color: 'var(--text-primary)' }}>Exchange Connections</h2>
        <p style={{ color: 'var(--text-muted)', fontSize: 13, marginTop: 4 }}>
          Verbinde deine Exchanges sicher · Alle Daten werden end-to-end verschlüsselt
        </p>
      </div>

      {/* Security Banner */}
      <div className="card" style={{ marginBottom: 20, borderColor: 'rgba(0,212,255,0.2)', background: 'rgba(0,212,255,0.04)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 24 }}>🔐</span>
          <div>
            <div style={{ fontWeight: 700, color: 'var(--accent-cyan)', fontSize: 13 }}>Enterprise Security</div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>
              AES-256 Verschlüsselung · Read-only Modus empfohlen · API Keys werden serverseitig gespeichert
            </div>
          </div>
        </div>
      </div>

      {/* Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 12 }}>
        {PROVIDERS.map(p => <ConnectorCard key={p.id} provider={p} />)}
      </div>

      {/* Supabase Config Hint */}
      <div className="card" style={{ marginTop: 16, background: 'rgba(139,92,246,0.05)', borderColor: 'rgba(139,92,246,0.2)' }}>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
          <strong style={{ color: 'var(--accent-purple)' }}>⚙️ Backend-Konfiguration:</strong>{' '}
          Setze <code style={{ background: 'var(--bg-deep)', padding: '1px 5px', borderRadius: 4 }}>VITE_SUPABASE_URL</code> und{' '}
          <code style={{ background: 'var(--bg-deep)', padding: '1px 5px', borderRadius: 4 }}>VITE_SUPABASE_ANON_KEY</code>{' '}
          in der <code>.env</code>-Datei um die Verbindungsspeicherung zu aktivieren.
        </div>
      </div>
    </div>
  );
}
