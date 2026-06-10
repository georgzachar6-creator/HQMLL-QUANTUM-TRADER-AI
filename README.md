# HQMLL Quantum Trader AI System

**Enterprise AI Trading Platform** — Flutter Mobile + Enterprise Web Frontend

[![Flutter CI/CD](https://github.com/GrischaS/HQMLL-QUANTUM-TRADER-AI/actions/workflows/ci_cd.yml/badge.svg)](https://github.com/GrischaS/HQMLL-QUANTUM-TRADER-AI/actions/workflows/ci_cd.yml)
[![Enterprise Web](https://github.com/GrischaS/HQMLL-QUANTUM-TRADER-AI/actions/workflows/enterprise-deploy.yml/badge.svg)](https://github.com/GrischaS/HQMLL-QUANTUM-TRADER-AI/actions/workflows/enterprise-deploy.yml)

---

## 🏗️ Architektur

```
HQMLL-QUANTUM-TRADER-AI/
├── lib/                          # Flutter App (Dart)
│   ├── screens/                  # 46+ Screens
│   │   ├── dashboard_screen.dart # Quantum Research Panel
│   │   ├── qml_research_screen.dart  # 5-Tab QML Lab (v44+)
│   │   └── ...
│   ├── services/                 # Business Logic
│   │   ├── time_crystal_service.dart  # ⚛️ TimeCrystal Engine (v44)
│   │   ├── auto_save_service.dart
│   │   └── ...
│   └── main.dart
├── web/frontend/                 # Enterprise Web (React + Vite)
│   ├── src/
│   │   ├── pages/               # Dashboard, Markets, QML Lab, Connections, Settings
│   │   ├── api/                 # store-connection.js (Supabase)
│   │   └── App.jsx
│   ├── manifest.webmanifest     # PWA Manifest
│   └── sw.js                    # Service Worker
├── docker/                       # Docker Setup
│   ├── Dockerfile               # Multi-stage (node:18 + nginx)
│   └── nginx.conf
├── .github/workflows/            # CI/CD Pipelines
│   ├── ci_cd.yml                # Flutter + React + Docker Build
│   └── enterprise-deploy.yml    # Vercel + Netlify + Firebase Deploy
├── scripts/
│   ├── github_push.sh           # GitHub Push Helper (PAT)
│   └── ...
└── pubspec.yaml                  # Flutter v46.0.0+460
```

---

## 🚀 Features

### Flutter Mobile App (v46.0)
- **Dashboard** — Live Preise, AI-Signale, Quantum Research Panel, P&L
- **QML Research Lab** — 5 Tabs: Data Lab / Model Trainer / Symbolic AI / Exp. Designer / Trading Bridge
- **TimeCrystal Engine** — Floquet-Simulation, DTC-Ordnungsparameter, PennyLane/TFQ
- **Phase Diagram** — CustomPainter 2D-Phasenraum (Ω × W)
- **46+ Screens** — vollständige Trading-Plattform
- **AutoSave** — persistente Datenhaltung (SharedPreferences + Hive)

### Enterprise Web (v46.0)
- **React + Vite** — modernes SPA mit React Router v6
- **Dashboard** — Live-Preise, AI-Signale, Quantum Research Panel (mirrored)
- **Markets** — Sortierbare Coin-Tabelle mit Live-Updates + Sparklines
- **QML Lab** — Interaktives Phase Diagram, Model Trainer, Symbolic AI
- **Connections** — Exchange-Verbindungen (Binance/Bybit/OKX/Alpaca/...) mit Supabase
- **Settings** — GitHub Secrets Guide, Version-Info, Branch-Übersicht
- **PWA** — Offline-Support, Installierbar, Service Worker
- **Dark Theme** — Quantum Design System

---

## 🛠️ Lokale Entwicklung

### Flutter Mobile
```bash
flutter pub get
flutter run                  # Device/Emulator
flutter build web --release  # Web Build
flutter build apk --release  # Android APK
```

### Enterprise Web
```bash
cd web/frontend
npm install
npm run dev     # → http://localhost:3000
npm run build   # → dist/
```

### Docker
```bash
# Build
docker build -f docker/Dockerfile -t hqmll-web .

# Run
docker run -p 8080:80 hqmll-web
# → http://localhost:8080
```

---

## ⚙️ GitHub Secrets (CI/CD)

Konfiguriere in **Settings → Secrets and variables → Actions**:

| Secret | Pflicht | Beschreibung |
|--------|---------|--------------|
| `VERCEL_TOKEN` | ✅ | [vercel.com/account/tokens](https://vercel.com/account/tokens) |
| `VERCEL_ORG_ID` | ✅ | Vercel Team/Org ID |
| `VERCEL_PROJECT_ID` | ✅ | Vercel Projekt ID |
| `NETLIFY_AUTH_TOKEN` | ⬜ | Netlify Deploy Token |
| `NETLIFY_SITE_ID` | ⬜ | Netlify Site ID |
| `FIREBASE_TOKEN` | ⬜ | Firebase CI Token |
| `VITE_SUPABASE_URL` | ⬜ | Supabase Projekt URL |
| `VITE_SUPABASE_ANON_KEY` | ⬜ | Supabase Anonymous Key |

---

## 🔀 GitHub Push (PAT)

```bash
# PAT erstellen: github.com/settings/tokens/new
# Scope: repo (vollständig)

export GH_PAT=ghp_DeinPersonalAccessToken
bash scripts/github_push.sh
```

---

## 📊 Build Status

| Platform | Status |
|----------|--------|
| Flutter Web | ✅ v46.0 (`build/web/`) |
| Android APK | ✅ 91.3MB (`build/app/outputs/flutter-apk/`) |
| Enterprise Web | ✅ React+Vite (`web/frontend/dist/`) |
| Docker Image | ✅ Multi-stage |

---

## 🔬 TimeCrystal Engine

Das Herzstück der AI-Analyse:

```dart
// Phase prediction
final phase = timeCrystalService.currentPhase; // dtcOrdered / trivial / chaotic / mbl

// Trading insights
final insights = timeCrystalService.getTradingInsights();
// → { regime, orderParameter, confidence, strategy }

// Run Floquet experiment
final exp = await timeCrystalService.runExperiment(
  omega: 1.05 * pi,
  wStrength: 0.08,
  platform: TCPlatform.bec,
);
```

---

*HQMLL Quantum Trader AI — Enterprise Platform v46.0*
