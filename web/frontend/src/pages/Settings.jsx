import React, { useState } from 'react';

const VERSION_INFO = {
  app: 'v46.0.0',
  flutter: '3.35.4',
  dart: '3.9.2',
  build: new Date().toISOString().split('T')[0],
  commit: 'bbb32a6',
  features: ['TimeCrystal Deep Reasoning', 'QML Lab (5 Tabs)', 'PhaseDiagram CustomPainter', 'Enterprise Web v1', 'PWA Support'],
};

const SECRETS_REQUIRED = [
  { key: 'VERCEL_TOKEN',       desc: 'Vercel Deployment Token',           link: 'https://vercel.com/account/tokens',     required: true  },
  { key: 'VERCEL_ORG_ID',      desc: 'Vercel Organisation ID',            link: 'https://vercel.com/account',            required: true  },
  { key: 'VERCEL_PROJECT_ID',  desc: 'Vercel Projekt ID',                  link: 'https://vercel.com/dashboard',          required: true  },
  { key: 'NETLIFY_AUTH_TOKEN', desc: 'Netlify Auth Token',                 link: 'https://app.netlify.com/user/applications', required: false },
  { key: 'NETLIFY_SITE_ID',    desc: 'Netlify Site ID',                    link: 'https://app.netlify.com',              required: false },
  { key: 'FIREBASE_TOKEN',     desc: 'Firebase CI Token',                  link: 'https://console.firebase.google.com',   required: false },
  { key: 'VITE_SUPABASE_URL',  desc: 'Supabase Projekt-URL',               link: 'https://supabase.com/dashboard',        required: false },
  { key: 'VITE_SUPABASE_ANON_KEY', desc: 'Supabase Anonymous Key',         link: 'https://supabase.com/dashboard',        required: false },
  { key: 'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON', desc: 'Google Play Service Account', link: 'https://console.cloud.google.com', required: false },
];

function Section({ title, icon, children }) {
  return (
    <div className="card" style={{ marginBottom: 16 }}>
      <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--text-primary)', marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
        <span>{icon}</span> {title}
      </div>
      {children}
    </div>
  );
}

export default function Settings() {
  const [copied, setCopied] = useState(null);

  function copy(text, key) {
    navigator.clipboard?.writeText(text).then(() => {
      setCopied(key);
      setTimeout(() => setCopied(null), 2000);
    });
  }

  return (
    <div className="animate-fadein" style={{ maxWidth: 800, margin: '0 auto' }}>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 20, fontWeight: 800 }}>⚙️ Settings & Konfiguration</h2>
        <p style={{ color: 'var(--text-muted)', fontSize: 12, marginTop: 4 }}>App-Info · CI/CD Secrets · GitHub Setup</p>
      </div>

      {/* Version Info */}
      <Section title="App-Version & Build-Info" icon="📦">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: 10, marginBottom: 12 }}>
          {[
            { l: 'App Version', v: VERSION_INFO.app,     c: 'var(--accent-cyan)'   },
            { l: 'Flutter',     v: VERSION_INFO.flutter,  c: 'var(--text-primary)'  },
            { l: 'Dart',        v: VERSION_INFO.dart,     c: 'var(--text-primary)'  },
            { l: 'Build Date',  v: VERSION_INFO.build,    c: 'var(--text-secondary)'},
            { l: 'Commit',      v: VERSION_INFO.commit,   c: 'var(--accent-purple)' },
          ].map(x => (
            <div key={x.l} style={{ background: 'var(--bg-deep)', borderRadius: 8, padding: '8px 12px' }}>
              <div style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase' }}>{x.l}</div>
              <div style={{ fontFamily: 'monospace', fontWeight: 700, color: x.c, marginTop: 2 }}>{x.v}</div>
            </div>
          ))}
        </div>
        <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 6 }}>Features in v46:</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {VERSION_INFO.features.map(f => (
            <span key={f} className="badge badge-cyan" style={{ fontSize: 10 }}>{f}</span>
          ))}
        </div>
      </Section>

      {/* GitHub Secrets */}
      <Section title="GitHub Secrets für CI/CD" icon="🔐">
        <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 12 }}>
          Gehe zu{' '}
          <a href="https://github.com/GrischaS/HQMLL-QUANTUM-TRADER-AI/settings/secrets/actions" target="_blank" rel="noreferrer" style={{ color: 'var(--accent-cyan)' }}>
            GitHub → Settings → Secrets and variables → Actions
          </a>{' '}
          und füge folgende Secrets hinzu:
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {SECRETS_REQUIRED.map(s => (
            <div key={s.key} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px 12px', background: 'var(--bg-deep)', borderRadius: 8,
              border: `1px solid ${s.required ? 'rgba(239,68,68,0.2)' : 'var(--border)'}`,
            }}>
              {s.required && <span style={{ color: 'var(--accent-red)', fontSize: 12 }}>*</span>}
              <code style={{ flex: 1, fontSize: 12, color: s.required ? 'var(--text-primary)' : 'var(--text-muted)', fontFamily: 'monospace' }}>
                {s.key}
              </code>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', flex: 2 }}>{s.desc}</span>
              <a href={s.link} target="_blank" rel="noreferrer" style={{ fontSize: 10, color: 'var(--accent-cyan)', whiteSpace: 'nowrap' }}>
                Holen →
              </a>
              <button
                onClick={() => copy(s.key, s.key)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: copied === s.key ? 'var(--accent-green)' : 'var(--text-muted)', fontSize: 12 }}
              >{copied === s.key ? '✓' : '⧉'}</button>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 8, fontSize: 10, color: 'var(--text-muted)' }}>* Pflichtfelder für Deployment-Workflows</div>
      </Section>

      {/* GitHub Push Guide */}
      <Section title="GitHub Push (PAT erforderlich)" icon="🚀">
        <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 10 }}>
          46 lokale Commits warten auf den Push. Setup eines Personal Access Tokens:
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { step: '1', text: 'Gehe zu github.com/settings/tokens/new', link: 'https://github.com/settings/tokens/new' },
            { step: '2', text: 'Note: "HQMLL Push" · Scopes: ✅ repo (vollständig)' },
            { step: '3', text: 'Token kopieren: ghp_xxxxx...' },
            { step: '4', text: 'Im Terminal ausführen:' },
          ].map(x => (
            <div key={x.step} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
              <div style={{
                width: 22, height: 22, borderRadius: '50%',
                background: 'var(--accent-cyan)', color: '#0a0e1a',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, fontWeight: 800, flexShrink: 0, marginTop: 1,
              }}>{x.step}</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', paddingTop: 2 }}>
                {x.text}
                {x.link && <> — <a href={x.link} target="_blank" rel="noreferrer">öffnen →</a></>}
              </div>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 10, background: 'var(--bg-deep)', borderRadius: 8, padding: '10px 14px', border: '1px solid var(--border)' }}>
          <code style={{ fontSize: 12, color: 'var(--accent-cyan)', display: 'block', lineHeight: 1.8 }}>
            export GH_PAT=ghp_DeinToken<br/>
            bash /home/user/flutter_app/scripts/github_push.sh
          </code>
        </div>
      </Section>

      {/* Branches */}
      <Section title="Branch-Übersicht" icon="🌿">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            { branch: 'main (remote)',               desc: 'v33.0 — zuletzt gepusht',                    status: 'old',     commits: 21  },
            { branch: 'feat/enterprise-setup-v1',     desc: 'Copilot: React Web + CI/CD + Docker + PWA',  status: 'new',     commits: 10  },
            { branch: 'main (lokal)',                 desc: 'v45.0 — TimeCrystal + QML Lab + Phase Diag', status: 'current', commits: 46  },
          ].map(b => (
            <div key={b.branch} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', background: 'var(--bg-deep)', borderRadius: 8 }}>
              <span style={{ fontSize: 14 }}>🌿</span>
              <code style={{ flex: 1, fontSize: 12, color: 'var(--text-primary)' }}>{b.branch}</code>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', flex: 2 }}>{b.desc}</span>
              <span className={`badge ${b.status === 'current' ? 'badge-cyan' : b.status === 'new' ? 'badge-purple' : 'badge-yellow'}`}>
                {b.status === 'current' ? 'ACTIVE' : b.status === 'new' ? 'COPILOT' : 'OUTDATED'}
              </span>
              <span style={{ fontSize: 11, color: 'var(--text-muted)', fontFamily: 'monospace', whiteSpace: 'nowrap' }}>{b.commits} commits</span>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 10, fontSize: 11, color: 'var(--text-muted)' }}>
          💡 Nach dem Push werden alle lokalen Commits + die integrierten Copilot-Features zusammengeführt.
        </div>
      </Section>
    </div>
  );
}
