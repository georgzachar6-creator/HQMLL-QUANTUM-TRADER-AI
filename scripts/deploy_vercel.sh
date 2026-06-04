#!/bin/bash
# HQMLL Quantum Trader — Automated Vercel Deployment Script
# Usage: ./scripts/deploy_vercel.sh [--prod | --preview]
# Requires: vercel CLI installed globally (npm i -g vercel)
# Grigori Saks · 2025

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"
LOG_FILE="$PROJECT_DIR/deploy.log"
DEPLOY_ENV="${1:---prod}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "========================================"
echo "  HQMLL Quantum Trader — Vercel Deploy"
echo "  Mode: $DEPLOY_ENV"
echo "  Time: $TIMESTAMP"
echo "========================================"

# ── Step 1: Navigate to project ────────────────────────────
cd "$PROJECT_DIR"
echo "→ Project: $PROJECT_DIR"

# ── Step 2: Flutter analyze ────────────────────────────────
echo ""
echo "[1/5] Running flutter analyze..."
flutter analyze --no-fatal-infos
echo "✅ Analyze passed"

# ── Step 3: Build Flutter Web ──────────────────────────────
echo ""
echo "[2/5] Building Flutter Web (release)..."
flutter build web --release \
  --base-href "/" \
  --dart-define=flutter.inspector.structuredErrors=false \
  --dart-define=debugShowCheckedModeBanner=false

BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
echo "✅ Web build complete — Size: $BUILD_SIZE"

# ── Step 4: Copy vercel.json to build dir ─────────────────
echo ""
echo "[3/5] Preparing Vercel config..."
cp "$PROJECT_DIR/vercel.json" "$BUILD_DIR/vercel.json"
echo "✅ vercel.json copied to build/web/"

# ── Step 5: Deploy to Vercel ──────────────────────────────
echo ""
echo "[4/5] Deploying to Vercel ($DEPLOY_ENV)..."

if [ "$DEPLOY_ENV" = "--prod" ]; then
  DEPLOY_URL=$(cd "$BUILD_DIR" && vercel --prod --yes 2>&1 | grep -oE 'https://[^ ]+\.vercel\.app' | tail -1)
else
  DEPLOY_URL=$(cd "$BUILD_DIR" && vercel --yes 2>&1 | grep -oE 'https://[^ ]+\.vercel\.app' | tail -1)
fi

echo "✅ Deployed to: $DEPLOY_URL"

# ── Step 6: Log deployment ────────────────────────────────
echo ""
echo "[5/5] Logging deployment..."
echo "$TIMESTAMP | $DEPLOY_ENV | $DEPLOY_URL | $BUILD_SIZE" >> "$LOG_FILE"
echo "✅ Logged to deploy.log"

# ── Summary ───────────────────────────────────────────────
echo ""
echo "========================================"
echo "  ✅ DEPLOYMENT COMPLETE"
echo "  URL: $DEPLOY_URL"
echo "  Size: $BUILD_SIZE"
echo "  Mode: $DEPLOY_ENV"
echo "========================================"
