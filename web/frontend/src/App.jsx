import React, { useState, useEffect } from 'react';
import { Outlet, NavLink, useLocation } from 'react-router-dom';

const NAV = [
  { to: '/dashboard',   icon: '📊', label: 'Dashboard' },
  { to: '/markets',     icon: '📈', label: 'Markets'   },
  { to: '/qml-lab',     icon: '🔬', label: 'QML Lab'   },
  { to: '/connections', icon: '🔗', label: 'Connect'   },
  { to: '/settings',    icon: '⚙️',  label: 'Settings'  },
];

function NavItem({ to, icon, label }) {
  return (
    <NavLink
      to={to}
      style={({ isActive }) => ({
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 3,
        padding: '8px 12px',
        borderRadius: 10,
        textDecoration: 'none',
        fontSize: 11,
        fontWeight: 600,
        letterSpacing: '0.5px',
        color: isActive ? 'var(--accent-cyan)' : 'var(--text-muted)',
        background: isActive ? 'rgba(0,212,255,0.08)' : 'transparent',
        transition: 'all 0.15s',
        minWidth: 56,
        textAlign: 'center',
      })}
    >
      <span style={{ fontSize: 20 }}>{icon}</span>
      <span>{label}</span>
    </NavLink>
  );
}

export default function App() {
  const location = useLocation();
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const t = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  const titleMap = {
    '/dashboard':   'Dashboard',
    '/markets':     'Live Markets',
    '/qml-lab':     'QML Research Lab',
    '/connections': 'Exchange Connections',
    '/settings':    'Settings',
  };
  const title = titleMap[location.pathname] || 'HQMLL';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', background: 'var(--bg-deep)' }}>
      {/* Top Header */}
      <header style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '10px 20px',
        background: 'var(--bg-surface)',
        borderBottom: '1px solid var(--border)',
        position: 'sticky', top: 0, zIndex: 100,
        flexShrink: 0,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: 'linear-gradient(135deg, var(--accent-cyan), var(--accent-purple))',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 16, fontWeight: 900, color: '#0a0e1a',
          }}>Q</div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)', lineHeight: 1 }}>
              HQMLL Quantum Trader AI
            </div>
            <div style={{ fontSize: 10, color: 'var(--text-muted)' }}>Enterprise Platform v46.0</div>
          </div>
        </div>

        <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)' }}>
          {title}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {/* Live indicator */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <div style={{
              width: 7, height: 7, borderRadius: '50%',
              background: 'var(--accent-green)',
              boxShadow: '0 0 8px var(--accent-green)',
              animation: 'pulse 2s infinite',
            }} />
            <span style={{ fontSize: 11, color: 'var(--accent-green)', fontWeight: 600 }}>LIVE</span>
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', fontFamily: 'monospace' }}>
            {time.toLocaleTimeString('de-DE')}
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main style={{ flex: 1, overflow: 'auto', padding: '16px' }}>
        <Outlet />
      </main>

      {/* Bottom Navigation */}
      <nav style={{
        display: 'flex', justifyContent: 'center', gap: 4,
        padding: '8px 16px',
        background: 'var(--bg-surface)',
        borderTop: '1px solid var(--border)',
        flexShrink: 0,
      }}>
        {NAV.map((n) => <NavItem key={n.to} {...n} />)}
      </nav>
    </div>
  );
}
