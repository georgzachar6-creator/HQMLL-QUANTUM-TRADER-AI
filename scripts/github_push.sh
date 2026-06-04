#!/bin/bash
# ============================================================
# HQMLL Quantum Trader — GitHub Push Script v43.0
# Usage: GH_PAT=ghp_xxxxx bash scripts/github_push.sh
# ============================================================
set -e

REPO="https://github.com/GrischaS/HQMLL-QUANTUM-TRADER-AI.git"
BRANCH="main"

if [ -z "$GH_PAT" ]; then
  echo "❌ ERROR: GH_PAT environment variable not set"
  echo ""
  echo "Usage:"
  echo "  export GH_PAT=ghp_YourPersonalAccessTokenHere"
  echo "  bash scripts/github_push.sh"
  echo ""
  echo "Generate token at: https://github.com/settings/tokens"
  echo "Required scopes: repo (full)"
  exit 1
fi

echo "🔑 Configuring GitHub credentials..."
git config --global user.name "Grischa-Saks"
git config --global user.email "genspark_flutter_dev@genspark.ai"
git config --global credential.helper store

# Write credentials
echo "https://GrischaS:${GH_PAT}@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials

echo "📊 Current git status:"
cd /home/user/flutter_app
git log --oneline -5
echo ""
git log --oneline origin/main..HEAD 2>/dev/null | wc -l | xargs -I{} echo "{} commits to push"

echo ""
echo "🚀 Pushing to GitHub..."
git push origin $BRANCH 2>&1

echo ""
echo "✅ Push complete! GitHub Actions CI/CD will now trigger automatically."
echo "   → https://github.com/GrischaS/HQMLL-QUANTUM-TRADER-AI/actions"
