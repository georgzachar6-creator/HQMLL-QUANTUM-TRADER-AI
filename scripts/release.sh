#!/bin/bash
# HQMLL Quantum Trader — Full Release Script
# Automatisiert: analyze → build web → build APK → git commit → git push
# Usage: ./scripts/release.sh "v42.0 - My Feature"
# Grigori Saks · 2025

set -euo pipefail

COMMIT_MSG="${1:-Auto-release $(date +%Y-%m-%d)}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

cd "$PROJECT_DIR"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   HQMLL QUANTUM TRADER — FULL RELEASE   ║"
echo "╚══════════════════════════════════════════╝"
echo "  Commit: $COMMIT_MSG"
echo "  Time:   $TIMESTAMP"
echo ""

# ── 1. Flutter Pub Get ────────────────────────────────────
echo "[1/6] Getting dependencies..."
flutter pub get
echo "✅ Dependencies OK"

# ── 2. Flutter Analyze ────────────────────────────────────
echo ""
echo "[2/6] Analyzing code..."
flutter analyze --no-fatal-infos
echo "✅ 0 errors"

# ── 3. Build Web ──────────────────────────────────────────
echo ""
echo "[3/6] Building Flutter Web..."
flutter build web --release \
  --dart-define=flutter.inspector.structuredErrors=false
WEB_SIZE=$(du -sh build/web/ | cut -f1)
echo "✅ Web built — $WEB_SIZE"

# ── 4. Build APK ──────────────────────────────────────────
echo ""
echo "[4/6] Building Android APK..."
flutter build apk --release
APK_SIZE=$(du -sh build/app/outputs/flutter-apk/app-release.apk | cut -f1)
echo "✅ APK built — $APK_SIZE"

# ── 5. Git Commit ─────────────────────────────────────────
echo ""
echo "[5/6] Committing to git..."
git add -A
git status --short
git commit -m "$COMMIT_MSG

Build: web=$WEB_SIZE, apk=$APK_SIZE
Date: $TIMESTAMP
flutter analyze: 0 errors"
echo "✅ Committed"

# ── 6. Git Push ───────────────────────────────────────────
echo ""
echo "[6/6] Pushing to GitHub..."
if git push origin main 2>/dev/null; then
  echo "✅ Pushed to GitHub"
else
  echo "⚠️  Push failed (auth issue) — commits are local"
  echo "    Run: git push origin main  after GitHub auth"
fi

# ── Summary ───────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║              ✅ COMPLETE                 ║"
echo "╚══════════════════════════════════════════╝"
echo "  Web Build:  $WEB_SIZE"
echo "  APK Build:  $APK_SIZE"
echo "  Commit:     $COMMIT_MSG"
git log --oneline -1
echo ""
