#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/aurix-frontend"
ADMIN_DIR="$FRONTEND_DIR/aurix-admin"
WEB_DIR="$FRONTEND_DIR/aurix-web"
FRONTEND_API_URL="${FRONTEND_API_URL:-http://localhost:8080}"

echo "AUREUS - Build frontend (admin + web)"
echo "  API URL: $FRONTEND_API_URL"
echo "  Root:    $ROOT_DIR"
echo ""

for dir in "$FRONTEND_DIR" "$ADMIN_DIR" "$WEB_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "ERRO: diretório não encontrado: $dir"
    exit 1
  fi
done

export REACT_APP_API_URL="$FRONTEND_API_URL"

cd "$ADMIN_DIR"
echo "[1/2] Building aurix-admin..."
npm ci --omit=optional 2>/dev/null || npm install --no-optional
npm run build
echo "  OK: build/"

cd "$WEB_DIR"
echo "[2/2] Building aurix-web..."
npm ci --omit=optional 2>/dev/null || npm install --no-optional
npm run build
echo "  OK: build/"

echo ""
echo "Frontend build complete. Outputs:"
echo "  - $ADMIN_DIR/build"
echo "  - $WEB_DIR/build"
