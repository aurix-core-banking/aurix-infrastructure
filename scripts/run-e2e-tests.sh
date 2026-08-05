#!/usr/bin/env bash
set -e

echo "============================================="
echo "AUREUS CORE BANKING - TESTES E2E"
echo "============================================="
echo ""

echo "Verificando se Docker esta rodando..."
if ! docker ps >/dev/null 2>&1; then
  echo "ERRO: Docker nao esta rodando!"
  echo "Inicie o Docker e tente novamente."
  exit 1
fi
echo "Docker esta rodando. Continuando..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
ROOT_DIR="$(cd .. && pwd)"

echo "Iniciando infraestrutura e servicos com Docker Compose..."
docker compose -f docker-compose.yml up -d --build
echo ""
echo "Aguardando estabilizacao dos servicos (90s)..."
sleep 90

cd "$ROOT_DIR"
echo ""
echo "Executando testes E2E com pytest..."
pytest -q aurix-tests/e2e
EXITCODE=$?

echo ""
echo "Encerrando containers Docker..."
cd "$SCRIPT_DIR/.."
docker compose -f docker-compose.yml down -v

echo ""
echo "Testes E2E finalizados com codigo $EXITCODE."
exit $EXITCODE
