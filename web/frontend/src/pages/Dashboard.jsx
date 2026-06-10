import React, { useState, useEffect } from 'react';

const COINS = [
  { sym: 'BTC', name: 'Bitcoin',  price: 67420,  change: +2.34, icon: '₿' },
  { sym: 'ETH', name: 'Ethereum', price: 3890,   change: +1.87, icon: 'Ξ' },
  { sym: 'SOL', name: 'Solana',   price: 178.50, change: -0.92, icon: '◎' },
  { sym: 'BNB', name: 'BNB',      price: 612,    change: +0.45, icon: '⬡' },
];

const SIGNALS = [
  { coin: 'BTC/USDT', signal: 'STRONG BUY', confidence: 87, regime: 'DTC-Ordered',  phase: 'dtcOrdered' },
  { coin: 'ETH/USDT', signal: 'BUY',        confidence: 74, regime: 'Trivial',      phase: 'trivial'    },
  { coin: 'SOL/USDT', signal: 'HOLD',       confidence: 61, regime: 'Chaotic',      phase: 'chaotic'    },
  { coin: 'BNB/USDT', signal: 'BUY',        confidence: 79, regime: 'MBL',          phase: 'mbl'        },
];

const PHASE_COLORS = {
  dtcOrdered: '#00d4ff',
  trivial:    '#10b981',
  chaotic:    '#ef4444',
  mbl:        '#8b5cf6',
};

const SIGNAL_COLORS = {
  'STRONG BUY': '#10b981',
  'BUY':        '#34d399',
  'HOLD':       '#f59e0b',
  'SELL':       '#ef4444',
};

function StatCard({ label, value, sub, color, icon }) {
  return (
    <div className="card" style={{ flex: 1, minWidth: 140 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{label}</div>
          <div style={{ fontSize: 22, fontWeight: 800, color: color || 'var(--text-primary)', marginTop: 4, fontFamily: 'monospace' }}>{value}</div>
          {sub && <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>{sub}</div>}
        </div>
        <span style={{ fontSize: 24 }}>{icon}</span>
      </div>
    </div>
  );
}

function CoinRow({ sym, name, price, change, icon }) {
  const up = change >= 0;
  const [animPrice, setAnimPrice] = useState(price);

  useEffect(() => {
    const t = setInterval(() => {
      setAnimPrice(p => +(p * (1 + (Math.random() - 0.5) * 0.0008)).toFixed(sym === 'BTC' ? 0 : 2));
    }, 2000 + Math.random() * 3000);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: 'var(--bg-surface)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 18, fontWeight: 700,
        color: 'var(--accent-cyan)',
        border: '1px solid var(--border)',
        flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontWeight: 700, fontSize: 13 }}>{sym}</div>
        <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{name}</div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <div style={{ fontFamily: 'monospace', fontWeight: 700, fontSize: 14 }}>
          ${animPrice.toLocaleString()}
        </div>
        <div style={{ fontSize: 12, color: up ? 'var(--accent-green)' : 'var(--accent-red)', fontWeight: 600 }}>
          {up ? '▲' : '▼'} {Math.abs(change).toFixed(2)}%
        </div>
      </div>
    </div>
  );
}

function MiniPhaseDiagram() {
  // Simple SVG phase diagram
  return (
    <svg width="100%" height="80" viewBox="0 0 200 80" style={{ borderRadius: 8 }}>
      <rect x="0" y="0" width="200" height="80" fill="#111827" rx="8"/>
      {/* Phase zones */}
      <rect x="0"   y="0"  width="100" height="40" fill="rgba(0,212,255,0.12)" rx="4"/>
      <rect x="100" y="0"  width="100" height="40" fill="rgba(139,92,246,0.12)" rx="4"/>
      <rect x="0"   y="40" width="100" height="40" fill="rgba(16,185,129,0.12)" rx="4"/>
      <rect x="100" y="40" width="100" height="40" fill="rgba(239,68,68,0.12)" rx="4"/>
      {/* Labels */}
      <text x="50"  y="22" textAnchor="middle" fill="#00d4ff" fontSize="9" fontWeight="bold">DTC</text>
      <text x="150" y="22" textAnchor="middle" fill="#8b5cf6" fontSize="9" fontWeight="bold">MBL</text>
      <text x="50"  y="62" textAnchor="middle" fill="#10b981" fontSize="9" fontWeight="bold">TRIVIAL</text>
      <text x="150" y="62" textAnchor="middle" fill="#ef4444" fontSize="9" fontWeight="bold">CHAOTIC</text>
      {/* Axis labels */}
      <text x="100" y="78" textAnchor="middle" fill="#64748b" fontSize="8">W (Drive strength) →</text>
      {/* Crosshair dot (current state) */}
      <circle cx="45" cy="18" r="5" fill="#00d4ff" opacity="0.9">
        <animate attributeName="opacity" values="1;0.3;1" dur="2s" repeatCount="indefinite"/>
      </circle>
      <circle cx="45" cy="18" r="10" fill="none" stroke="#00d4ff" strokeWidth="1" opacity="0.4"/>
    </svg>
  );
}

export default function Dashboard() {
  const [portfolio, setPortfolio] = useState(147820.50);

  useEffect(() => {
    const t = setInterval(() => {
      setPortfolio(p => +(p * (1 + (Math.random() - 0.499) * 0.001)).toFixed(2));
    }, 3000);
    return () => clearInterval(t);
  }, []);

  const pnlValue = +((portfolio - 130000)).toFixed(2);
  const pnlPct = +((pnlValue / 130000) * 100).toFixed(2);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 900, margin: '0 auto' }} className="animate-fadein">
      {/* Top Stats */}
      <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
        <StatCard
          label="Portfolio Total"
          value={`$${portfolio.toLocaleString()}`}
          sub={`${pnlPct >= 0 ? '▲' : '▼'} ${Math.abs(pnlPct)}% all-time`}
          color={pnlPct >= 0 ? 'var(--accent-green)' : 'var(--accent-red)'}
          icon="💼"
        />
        <StatCard label="24h P&L" value={`${pnlValue >= 0 ? '+' : ''}$${pnlValue.toLocaleString()}`} sub="vs. initial" color="var(--accent-green)" icon="📈" />
        <StatCard label="Quantum Score" value="87.4" sub="DTC Confidence" color="var(--accent-cyan)" icon="⚛️" />
        <StatCard label="Active Signals" value="4" sub="3 BUY · 1 HOLD" color="var(--accent-purple)" icon="🎯" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        {/* Live Prices */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <h3 style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
              📊 Live Prices
            </h3>
            <span className="badge badge-green">Live</span>
          </div>
          {COINS.map(c => <CoinRow key={c.sym} {...c} />)}
        </div>

        {/* AI Signals */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <h3 style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
              🤖 AI Signals
            </h3>
            <span className="badge badge-cyan">Quantum AI</span>
          </div>
          {SIGNALS.map(s => (
            <div key={s.coin} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 0', borderBottom: '1px solid var(--border)' }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 13 }}>{s.coin}</div>
                <div style={{ fontSize: 10, color: 'var(--text-muted)' }}>Regime: {s.regime}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: SIGNAL_COLORS[s.signal] }}>{s.signal}</div>
                <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{s.confidence}% conf.</div>
              </div>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: PHASE_COLORS[s.phase], boxShadow: `0 0 6px ${PHASE_COLORS[s.phase]}` }} />
            </div>
          ))}
        </div>
      </div>

      {/* Quantum Research Panel */}
      <div className="card glow-cyan">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <h3 style={{ fontSize: 13, fontWeight: 700, color: 'var(--accent-cyan)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            ⚛️ Quantum Research — TimeCrystal Engine
          </h3>
          <span className="badge badge-cyan">v45 Active</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 12 }}>
              {[
                { l: 'Phase',     v: 'DTC-Ordered',  c: 'var(--accent-cyan)'  },
                { l: 'Ω-Drive',   v: '1.05 π',       c: 'var(--text-primary)' },
                { l: 'W-Strength',v: '0.08',          c: 'var(--text-primary)' },
                { l: 'τ-Decay',   v: '42.3',          c: 'var(--accent-purple)'},
              ].map(x => (
                <div key={x.l} style={{ flex: '1 1 80px' }}>
                  <div style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase' }}>{x.l}</div>
                  <div style={{ fontSize: 14, fontWeight: 700, color: x.c, fontFamily: 'monospace' }}>{x.v}</div>
                </div>
              ))}
            </div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>
              Floquet-Simulation aktiv · PennyLane QML · 87.4% Konfidenz
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 6 }}>Phase Diagram (Ω × W)</div>
            <MiniPhaseDiagram />
          </div>
        </div>
      </div>
    </div>
  );
}
