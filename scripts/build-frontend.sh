#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_API_URL="${FRONTEND_API_URL:-http://localhost:8080}"

echo "AUREUS - Build frontend (admin + web)"
echo "  API URL: $FRONTEND_API_URL"
echo "  Root:    $ROOT_DIR"
echo ""

export REACT_APP_API_URL="$FRONTEND_API_URL"

cd "$ROOT_DIR/apps/frontend/aurix-admin"
echo "[1/2] Building aurix-admin..."
npm ci --omit=optional 2>/dev/null || npm install --no-optional
npm run build
echo "  OK: build/"

cd "$ROOT_DIR/apps/frontend/aurix-web"
echo "[2/2] Building aurix-web..."
npm ci --omit=optional 2>/dev/null || npm install --no-optional
npm run build
echo "  OK: build/"

echo ""
echo "Frontend build complete. Outputs:"
echo "  - $ROOT_DIR/apps/frontend/aurix-admin/build"
echo "  - $ROOT_DIR/apps/frontend/aurix-web/build"
