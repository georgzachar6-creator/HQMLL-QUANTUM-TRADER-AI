import React, { useState, useEffect, useRef } from 'react';

const TABS = ['DATA LAB', 'MODEL TRAINER', 'SYMBOLIC AI', 'EXP. DESIGNER', 'TRADING BRIDGE'];

const MODELS = [
  { id: 'cnn',      label: 'CNN',         icon: '🔷', desc: 'Convolutional Neural Network',     acc: 84.2, trained: true  },
  { id: 'lstm',     label: 'LSTM',        icon: '🔄', desc: 'Long Short-Term Memory',           acc: 87.5, trained: true  },
  { id: 'svm',      label: 'SVM',         icon: '📐', desc: 'Support Vector Machine',          acc: 79.1, trained: true  },
  { id: 'rf',       label: 'Random Forest',icon: '🌲',desc: 'Ensemble Decision Trees',         acc: 82.3, trained: true  },
  { id: 'pennylane',label: 'PennyLane',   icon: '⚛️', desc: 'Quantum ML Circuit (VQC)',         acc: 91.2, trained: false },
  { id: 'tfq',      label: 'TFQ',         icon: '🌀', desc: 'TensorFlow Quantum',               acc: 88.9, trained: false },
];

const PLATFORMS = [
  { id: 'bec',            label: 'BEC',             icon: '❄️' },
  { id: 'ionTrap',        label: 'Ion Trap',        icon: '⚡' },
  { id: 'nvCenter',       label: 'NV-Center',       icon: '💎' },
  { id: 'superconducting',label: 'Superconducting', icon: '🔵' },
];

const HYPOTHESES = [
  'Floquet-Syste folgen ∂²ψ/∂t² + Ω²ψ = W·cos(Ωt)·ψ',
  'DTC-Ordnungsparameter Φ = |⟨σˣ(nT)⟩| > 0.5',
  'Sub-harmonische Oszillation bei ω = Ω/2 ± δ',
  'Phasengrenze bei W_c ≈ 0.12 für Ω ∈ [π·0.9, π·1.1]',
];

const RL_SUGGESTIONS = [
  { title: 'Ω-Sweep-Experiment',   desc: 'Variiere Ω von 0.8π bis 1.2π in 50 Schritten',   priority: 'HIGH',   reward: 0.87 },
  { title: 'W-Stärken-Analyse',    desc: 'Erhöhe W schrittweise 0.01 → 0.20',              priority: 'HIGH',   reward: 0.82 },
  { title: 'Dekohärenz-Studie',    desc: 'Messe τ-Abhängigkeit bei T∈[0.5K, 4K]',          priority: 'MEDIUM', reward: 0.71 },
  { title: 'Platform-Vergleich',   desc: 'BEC vs Ion-Trap DTC-Stabilität',                  priority: 'LOW',    reward: 0.64 },
];

function PhaseDiagramSVG({ omega = 1.05, w = 0.08 }) {
  const ox = Math.round(((omega - 0.8) / 0.4) * 180 + 10);
  const oy = Math.round((1 - w / 0.2) * 60 + 10);

  return (
    <svg width="100%" height="100" viewBox="0 0 200 90" style={{ borderRadius: 8, background: '#111827' }}>
      {/* Zones */}
      <rect x="0"   y="0"  width="100" height="45" fill="rgba(0,212,255,0.12)" rx="4"/>
      <rect x="100" y="0"  width="100" height="45" fill="rgba(139,92,246,0.12)" rx="4"/>
      <rect x="0"   y="45" width="100" height="45" fill="rgba(16,185,129,0.10)" rx="4"/>
      <rect x="100" y="45" width="100" height="45" fill="rgba(239,68,68,0.10)" rx="4"/>
      {/* Zone labels */}
      <text x="50"  y="24" textAnchor="middle" fill="#00d4ff" fontSize="9" fontWeight="bold">DTC-ORDERED</text>
      <text x="150" y="24" textAnchor="middle" fill="#8b5cf6" fontSize="9" fontWeight="bold">MBL</text>
      <text x="50"  y="67" textAnchor="middle" fill="#10b981" fontSize="9" fontWeight="bold">TRIVIAL</text>
      <text x="150" y="67" textAnchor="middle" fill="#ef4444" fontSize="9" fontWeight="bold">CHAOTIC</text>
      {/* Axes */}
      <line x1="10" y1="80" x2="190" y2="80" stroke="#334155" strokeWidth="1"/>
      <line x1="10" y1="10" x2="10"  y2="80" stroke="#334155" strokeWidth="1"/>
      <text x="100" y="88" textAnchor="middle" fill="#64748b" fontSize="7">Ω →</text>
      <text x="5"   y="45" textAnchor="middle" fill="#64748b" fontSize="7" transform="rotate(-90,5,45)">W ↑</text>
      {/* Current point */}
      <circle cx={ox} cy={oy} r="5" fill="#00d4ff" opacity="0.9">
        <animate attributeName="opacity" values="1;0.4;1" dur="1.5s" repeatCount="indefinite"/>
      </circle>
      <circle cx={ox} cy={oy} r="9" fill="none" stroke="#00d4ff" strokeWidth="1" opacity="0.5"/>
    </svg>
  );
}

function TimeSeriesSVG({ phase }) {
  const pts = Array.from({ length: 40 }, (_, i) => {
    const base = Math.cos(Math.PI * i) * Math.exp(-i / (phase === 'dtcOrdered' ? 30 : 8));
    return base + (Math.random() - 0.5) * 0.1;
  });
  const min = Math.min(...pts); const max = Math.max(...pts);
  const norm = pts.map(v => 40 - ((v - min) / (max - min || 1)) * 36 + 2);
  const pathD = norm.map((y, i) => `${i === 0 ? 'M' : 'L'}${i * 5},${y}`).join(' ');
  const color = phase === 'dtcOrdered' ? '#00d4ff' : phase === 'chaotic' ? '#ef4444' : '#10b981';

  return (
    <svg width="100%" height="45" viewBox="0 200 42" style={{ background: 'transparent' }}>
      <path d={pathD} fill="none" stroke={color} strokeWidth="1.5" opacity="0.8"/>
    </svg>
  );
}

export default function QmlLab() {
  const [tab, setTab] = useState(0);
  const [platform, setPlatform] = useState('bec');
  const [omega, setOmega] = useState(1.05);
  const [wStrength, setWStrength] = useState(0.08);
  const [training, setTraining] = useState(null);
  const [progress, setProgress] = useState(0);
  const [hypothesis, setHypothesis] = useState('');
  const [hypotheses, setHypotheses] = useState(HYPOTHESES);
  const timerRef = useRef(null);

  const phase = omega > 0.9 && omega < 1.1 && wStrength < 0.12 ? 'dtcOrdered'
    : wStrength > 0.15 ? 'chaotic'
    : omega < 0.85 ? 'trivial'
    : 'mbl';

  const phaseColor = {
    dtcOrdered: 'var(--accent-cyan)',
    trivial:    'var(--accent-green)',
    chaotic:    'var(--accent-red)',
    mbl:        'var(--accent-purple)',
  }[phase];
  const phaseLabel = { dtcOrdered: 'DTC-Ordered', trivial: 'Trivial', chaotic: 'Chaotic', mbl: 'MBL' }[phase];

  function startTraining(modelId) {
    setTraining(modelId);
    setProgress(0);
    clearInterval(timerRef.current);
    timerRef.current = setInterval(() => {
      setProgress(p => {
        if (p >= 100) { clearInterval(timerRef.current); setTraining(null); return 100; }
        return p + Math.random() * 8;
      });
    }, 200);
  }

  return (
    <div className="animate-fadein" style={{ maxWidth: 900, margin: '0 auto' }}>
      <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 800 }}>⚛️ QML Research Lab</h2>
          <p style={{ color: 'var(--text-muted)', fontSize: 12, marginTop: 2 }}>
            TimeCrystal Deep Reasoning · Floquet Engine · PennyLane/TFQ
          </p>
        </div>
        <span className="badge badge-cyan">v45 Active</span>
      </div>

      {/* Tab Bar */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 16, flexWrap: 'wrap' }}>
        {TABS.map((t, i) => (
          <button key={t} onClick={() => setTab(i)} style={{
            padding: '6px 14px', borderRadius: 8, border: 'none',
            background: tab === i ? 'var(--accent-cyan)' : 'var(--bg-card)',
            color: tab === i ? '#0a0e1a' : 'var(--text-secondary)',
            fontWeight: 700, fontSize: 11, cursor: 'pointer', letterSpacing: '0.5px',
            transition: 'all 0.15s',
          }}>{t}</button>
        ))}
      </div>

      {/* TAB 0: DATA LAB */}
      {tab === 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {/* Platform selector */}
          <div className="card">
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Platform</div>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {PLATFORMS.map(p => (
                <button key={p.id} onClick={() => setPlatform(p.id)} style={{
                  padding: '7px 14px', borderRadius: 8, border: `1px solid ${platform === p.id ? 'var(--accent-cyan)' : 'var(--border)'}`,
                  background: platform === p.id ? 'rgba(0,212,255,0.1)' : 'var(--bg-surface)',
                  color: platform === p.id ? 'var(--accent-cyan)' : 'var(--text-secondary)',
                  fontSize: 12, fontWeight: 600, cursor: 'pointer',
                  display: 'flex', alignItems: 'center', gap: 5,
                }}>{p.icon} {p.label}</button>
              ))}
            </div>
          </div>

          {/* Parameters */}
          <div className="card">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--text-muted)', marginBottom: 6 }}>
                  <span>Ω Drive Frequency</span>
                  <span style={{ color: 'var(--accent-cyan)', fontFamily: 'monospace', fontWeight: 700 }}>{omega.toFixed(2)}π</span>
                </div>
                <input type="range" min="0.8" max="1.2" step="0.01" value={omega}
                  onChange={e => setOmega(+e.target.value)}
                  style={{ width: '100%', accentColor: 'var(--accent-cyan)' }} />
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 9, color: 'var(--text-muted)', marginTop: 2 }}>
                  <span>0.8π</span><span>1.2π</span>
                </div>
              </div>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--text-muted)', marginBottom: 6 }}>
                  <span>W Drive Strength</span>
                  <span style={{ color: 'var(--accent-purple)', fontFamily: 'monospace', fontWeight: 700 }}>{wStrength.toFixed(3)}</span>
                </div>
                <input type="range" min="0.01" max="0.25" step="0.005" value={wStrength}
                  onChange={e => setWStrength(+e.target.value)}
                  style={{ width: '100%', accentColor: 'var(--accent-purple)' }} />
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 9, color: 'var(--text-muted)', marginTop: 2 }}>
                  <span>0.01</span><span>0.25</span>
                </div>
              </div>
            </div>
          </div>

          {/* Phase Badge + Diagram */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
            <div className="card" style={{ borderColor: `${phaseColor}30` }}>
              <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8 }}>PREDICTED PHASE</div>
              <div style={{ fontSize: 24, fontWeight: 900, color: phaseColor, fontFamily: 'monospace' }}>{phaseLabel}</div>
              <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>Ω={omega.toFixed(2)}π · W={wStrength.toFixed(3)}</div>
              <TimeSeriesSVG phase={phase} />
            </div>
            <div className="card">
              <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8 }}>PHASE DIAGRAM (Ω × W)</div>
              <PhaseDiagramSVG omega={omega} w={wStrength} />
            </div>
          </div>
        </div>
      )}

      {/* TAB 1: MODEL TRAINER */}
      {tab === 1 && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: 12 }}>
          {MODELS.map(m => (
            <div key={m.id} className="card" style={{ borderColor: m.trained ? 'var(--border)' : 'rgba(139,92,246,0.2)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                <span style={{ fontSize: 22 }}>{m.icon}</span>
                <div>
                  <div style={{ fontWeight: 700 }}>{m.label}</div>
                  <div style={{ fontSize: 10, color: 'var(--text-muted)' }}>{m.desc}</div>
                </div>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                <span className={`badge ${m.trained ? 'badge-green' : 'badge-purple'}`}>
                  {m.trained ? '✓ Trained' : '◎ Quantum'}
                </span>
                <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--accent-cyan)', fontFamily: 'monospace' }}>{m.acc}%</span>
              </div>
              {/* Progress bar */}
              <div style={{ background: 'var(--bg-deep)', borderRadius: 4, height: 4, marginBottom: 10 }}>
                <div style={{
                  width: training === m.id ? `${Math.min(progress, 100)}%` : m.trained ? '100%' : '0%',
                  height: '100%', borderRadius: 4,
                  background: m.trained ? 'var(--accent-green)' : 'var(--accent-purple)',
                  transition: 'width 0.2s',
                }} />
              </div>
              <button
                className="btn btn-secondary"
                style={{ width: '100%', justifyContent: 'center', opacity: training && training !== m.id ? 0.5 : 1 }}
                disabled={!!training}
                onClick={() => startTraining(m.id)}
              >
                {training === m.id ? `⏳ ${Math.min(Math.round(progress), 100)}%` : '▶ Train'}
              </button>
            </div>
          ))}
        </div>
      )}

      {/* TAB 2: SYMBOLIC AI */}
      {tab === 2 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div className="card">
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 10, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
              Entdeckte Gleichungen & Hypothesen
            </div>
            {hypotheses.map((h, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ fontSize: 16 }}>⚛️</span>
                <code style={{ flex: 1, fontSize: 12, color: 'var(--accent-cyan)', background: 'var(--bg-deep)', padding: '4px 8px', borderRadius: 6 }}>{h}</code>
                <button
                  style={{ background: 'none', border: 'none', color: 'var(--accent-red)', cursor: 'pointer', fontSize: 14 }}
                  onClick={() => setHypotheses(hs => hs.filter((_, j) => j !== i))}
                >✕</button>
              </div>
            ))}
          </div>
          <div className="card">
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8 }}>Neue Hypothese hinzufügen</div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input
                type="text"
                value={hypothesis}
                onChange={e => setHypothesis(e.target.value)}
                placeholder="z.B. ψ(t) = A·cos(Ωt/2)·e^(-γt)"
                style={{
                  flex: 1, background: 'var(--bg-deep)', border: '1px solid var(--border)',
                  borderRadius: 8, padding: '8px 12px', color: 'var(--text-primary)',
                  fontSize: 13, outline: 'none', fontFamily: 'monospace',
                }}
              />
              <button className="btn btn-primary" onClick={() => { if (hypothesis.trim()) { setHypotheses(h => [...h, hypothesis]); setHypothesis(''); } }}>
                + Hinzufügen
              </button>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: EXP. DESIGNER */}
      {tab === 3 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div className="card" style={{ background: 'rgba(139,92,246,0.05)', borderColor: 'rgba(139,92,246,0.2)' }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--accent-purple)', marginBottom: 4 }}>
              🤖 RL-basierter Experiment-Designer
            </div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>
              AI analysiert bisherige Experimente und schlägt optimale nächste Schritte vor
            </div>
          </div>
          {RL_SUGGESTIONS.map((s, i) => (
            <div key={i} className="card" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--bg-deep)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, color: 'var(--accent-cyan)', flexShrink: 0 }}>
                {i + 1}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 13, display: 'flex', alignItems: 'center', gap: 8 }}>
                  {s.title}
                  <span className={`badge ${s.priority === 'HIGH' ? 'badge-red' : s.priority === 'MEDIUM' ? 'badge-yellow' : 'badge-cyan'}`}>{s.priority}</span>
                </div>
                <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>{s.desc}</div>
              </div>
              <div style={{ textAlign: 'right', flexShrink: 0 }}>
                <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Reward</div>
                <div style={{ fontFamily: 'monospace', fontWeight: 800, color: 'var(--accent-green)' }}>{s.reward}</div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* TAB 4: TRADING BRIDGE */}
      {tab === 4 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div className="card glow-cyan">
            <div style={{ fontWeight: 700, color: 'var(--accent-cyan)', marginBottom: 12 }}>🌉 TimeCrystal → Trading Bridge</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
              {[
                { regime: 'DTC-Ordered', strategy: 'Trend Following',     risk: 'LOW',    color: '#00d4ff' },
                { regime: 'MBL',        strategy: 'Mean Reversion',       risk: 'MEDIUM', color: '#8b5cf6' },
                { regime: 'Trivial',    strategy: 'Range Trading',        risk: 'LOW',    color: '#10b981' },
                { regime: 'Chaotic',    strategy: 'Volatility Arbitrage', risk: 'HIGH',   color: '#ef4444' },
              ].map(r => (
                <div key={r.regime} className="card" style={{ borderColor: `${r.color}30`, padding: 12 }}>
                  <div style={{ fontSize: 12, fontWeight: 700, color: r.color }}>{r.regime}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 4 }}>{r.strategy}</div>
                  <div style={{ marginTop: 6 }}>
                    <span className={`badge ${r.risk === 'HIGH' ? 'badge-red' : r.risk === 'MEDIUM' ? 'badge-yellow' : 'badge-green'}`}>
                      Risk: {r.risk}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="card">
            <div style={{ fontWeight: 700, marginBottom: 10, fontSize: 13 }}>🔮 Emmy-GS Oracle Integration</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {['BTC/USDT: DTC-Ordered → STRONG BUY (conf: 91.2%)',
                'ETH/USDT: Trivial → BUY (conf: 74.5%)',
                'SOL/USDT: Chaotic → WAIT (conf: 58.3%)'].map((s, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', background: 'var(--bg-deep)', borderRadius: 8 }}>
                  <span style={{ fontSize: 14 }}>🔮</span>
                  <code style={{ fontSize: 12, color: 'var(--accent-cyan)' }}>{s}</code>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
