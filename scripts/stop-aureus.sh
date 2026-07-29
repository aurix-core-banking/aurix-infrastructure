#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$INFRA_DIR"

echo "AUREUS Core Banking - Encerrando servicos..."
docker-compose down

echo "AUREUS Core Banking encerrado."
