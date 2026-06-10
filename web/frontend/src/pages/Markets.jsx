import React, { useState, useEffect } from 'react';

const BASE_COINS = [
  { sym: 'BTC',  name: 'Bitcoin',       price: 67420,  cap: '1.32T', vol: '28.4B', change24h: +2.34, change7d: +8.12,  icon: '₿', rank: 1  },
  { sym: 'ETH',  name: 'Ethereum',      price: 3890,   cap: '468B',  vol: '14.2B', change24h: +1.87, change7d: +5.43,  icon: 'Ξ', rank: 2  },
  { sym: 'BNB',  name: 'BNB',           price: 612,    cap: '92B',   vol: '2.1B',  change24h: +0.45, change7d: +3.21,  icon: '⬡', rank: 3  },
  { sym: 'SOL',  name: 'Solana',        price: 178.5,  cap: '82B',   vol: '5.6B',  change24h: -0.92, change7d: -2.14,  icon: '◎', rank: 4  },
  { sym: 'XRP',  name: 'XRP',           price: 0.62,   cap: '34B',   vol: '1.8B',  change24h: +1.10, change7d: +4.56,  icon: '✕', rank: 5  },
  { sym: 'ADA',  name: 'Cardano',       price: 0.48,   cap: '17B',   vol: '0.9B',  change24h: -1.23, change7d: -3.45,  icon: '₳', rank: 6  },
  { sym: 'AVAX', name: 'Avalanche',     price: 38.2,   cap: '15B',   vol: '0.7B',  change24h: +2.78, change7d: +9.23,  icon: '⬟', rank: 7  },
  { sym: 'DOT',  name: 'Polkadot',      price: 8.90,   cap: '12B',   vol: '0.4B',  change24h: +0.33, change7d: +1.87,  icon: '⬤', rank: 8  },
  { sym: 'DOGE', name: 'Dogecoin',      price: 0.168,  cap: '24B',   vol: '1.2B',  change24h: +3.45, change7d: +12.3,  icon: 'Ð', rank: 9  },
  { sym: 'LINK', name: 'Chainlink',     price: 14.20,  cap: '8.5B',  vol: '0.6B',  change24h: +1.56, change7d: +6.78,  icon: '⬡', rank: 10 },
  { sym: 'UNI',  name: 'Uniswap',       price: 11.40,  cap: '7.2B',  vol: '0.3B',  change24h: -0.67, change7d: -1.23,  icon: '🦄', rank: 11 },
  { sym: 'ATOM', name: 'Cosmos',        price: 9.80,   cap: '3.8B',  vol: '0.2B',  change24h: +0.89, change7d: +2.34,  icon: '⚛',  rank: 12 },
];

function SparkLine({ change }) {
  const up = change >= 0;
  const pts = Array.from({ length: 12 }, (_, i) => {
    const trend = (i / 11) * Math.abs(change) * (up ? 1 : -1);
    return 20 - (trend + (Math.random() - 0.5) * 3) * 0.6;
  });
  const d = pts.map((y, i) => `${i === 0 ? 'M' : 'L'}${i * 10},${Math.max(2, Math.min(38, y))}`).join(' ');
  return (
    <svg width="110" height="40" viewBox="0 110 40" style={{ opacity: 0.8 }}>
      <path d={d} fill="none" stroke={up ? '#10b981' : '#ef4444'} strokeWidth="1.5"/>
    </svg>
  );
}

export default function Markets() {
  const [coins, setCoins] = useState(BASE_COINS);
  const [sort, setSort] = useState({ key: 'rank', dir: 1 });
  const [search, setSearch] = useState('');

  useEffect(() => {
    const t = setInterval(() => {
      setCoins(prev => prev.map(c => ({
        ...c,
        price: +(c.price * (1 + (Math.random() - 0.5) * 0.002)).toFixed(c.price > 100 ? 2 : 4),
        change24h: +(c.change24h + (Math.random() - 0.5) * 0.1).toFixed(2),
      })));
    }, 2500);
    return () => clearInterval(t);
  }, []);

  function toggleSort(key) {
    setSort(s => ({ key, dir: s.key === key ? -s.dir : 1 }));
  }

  const filtered = coins
    .filter(c => !search || c.sym.toLowerCase().includes(search.toLowerCase()) || c.name.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => {
      const av = sort.key === 'price' ? a.price : sort.key === 'change24h' ? a.change24h : a.rank;
      const bv = sort.key === 'price' ? b.price : sort.key === 'change24h' ? b.change24h : b.rank;
      return (av - bv) * sort.dir;
    });

  function Th({ label, sortKey }) {
    const active = sort.key === sortKey;
    return (
      <th onClick={() => toggleSort(sortKey)} style={{
        padding: '8px 12px', textAlign: 'right', cursor: 'pointer',
        color: active ? 'var(--accent-cyan)' : 'var(--text-muted)',
        fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px',
        userSelect: 'none', whiteSpace: 'nowrap',
      }}>
        {label} {active ? (sort.dir > 0 ? '↑' : '↓') : ''}
      </th>
    );
  }

  return (
    <div className="animate-fadein" style={{ maxWidth: 1000, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 800 }}>📈 Live Markets</h2>
          <p style={{ color: 'var(--text-muted)', fontSize: 12, marginTop: 2 }}>
            {filtered.length} Assets · Preise aktualisieren live
          </p>
        </div>
        <input
          type="text"
          placeholder="🔍 Suchen..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          style={{
            background: 'var(--bg-card)', border: '1px solid var(--border)',
            borderRadius: 8, padding: '8px 14px', color: 'var(--text-primary)',
            fontSize: 13, outline: 'none', width: 200,
          }}
        />
      </div>

      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--border)', background: 'var(--bg-surface)' }}>
              <Th label="#"          sortKey="rank"     />
              <th style={{ padding: '8px 12px', textAlign: 'left',  fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Asset</th>
              <Th label="Price"      sortKey="price"    />
              <Th label="24h %"      sortKey="change24h"/>
              <th style={{ padding: '8px 12px', textAlign: 'right', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>7d Chart</th>
              <th style={{ padding: '8px 12px', textAlign: 'right', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Mkt Cap</th>
              <th style={{ padding: '8px 12px', textAlign: 'right', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Vol 24h</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((c, idx) => {
              const up = c.change24h >= 0;
              return (
                <tr key={c.sym} style={{
                  borderBottom: '1px solid var(--border)',
                  background: idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.01)',
                  transition: 'background 0.15s',
                  cursor: 'pointer',
                }}
                  onMouseEnter={e => e.currentTarget.style.background = 'rgba(0,212,255,0.04)'}
                  onMouseLeave={e => e.currentTarget.style.background = idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.01)'}
                >
                  <td style={{ padding: '10px 12px', textAlign: 'right', color: 'var(--text-muted)', fontSize: 12 }}>{c.rank}</td>
                  <td style={{ padding: '10px 12px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div style={{
                        width: 32, height: 32, borderRadius: 8,
                        background: 'var(--bg-surface)', border: '1px solid var(--border)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 16, flexShrink: 0,
                      }}>{c.icon}</div>
                      <div>
                        <div style={{ fontWeight: 700, fontSize: 13 }}>{c.sym}</div>
                        <div style={{ fontSize: 10, color: 'var(--text-muted)' }}>{c.name}</div>
                      </div>
                    </div>
                  </td>
                  <td style={{ padding: '10px 12px', textAlign: 'right', fontFamily: 'monospace', fontWeight: 700, fontSize: 13 }}>
                    ${c.price < 1 ? c.price.toFixed(4) : c.price.toLocaleString()}
                  </td>
                  <td style={{ padding: '10px 12px', textAlign: 'right', fontWeight: 700, fontSize: 13, color: up ? 'var(--accent-green)' : 'var(--accent-red)' }}>
                    {up ? '+' : ''}{c.change24h.toFixed(2)}%
                  </td>
                  <td style={{ padding: '4px 12px', textAlign: 'right' }}>
                    <SparkLine change={c.change7d} />
                  </td>
                  <td style={{ padding: '10px 12px', textAlign: 'right', fontSize: 12, color: 'var(--text-secondary)' }}>{c.cap}</td>
                  <td style={{ padding: '10px 12px', textAlign: 'right', fontSize: 12, color: 'var(--text-muted)' }}>{c.vol}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
