#!/usr/bin/env bash
set -e

CONTAINER="${POSTGRES_CONTAINER:-aurix-postgres}"
BACKUP_FILE="${1:?Uso: $0 <caminho-do-arquivo.sql> [database]}"
DB="${2:-aurix_db}"
PGUSER="${POSTGRES_USER:-aurix_user}"
PGPASSWORD="${POSTGRES_PASSWORD:-aurix_dev_password}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Arquivo nao encontrado: $BACKUP_FILE"
  exit 1
fi

echo "Restore: $BACKUP_FILE -> $DB (container $CONTAINER)"
export PGPASSWORD
docker cp "$BACKUP_FILE" "${CONTAINER}:/tmp/restore.sql"
docker exec -i "$CONTAINER" psql -U "$PGUSER" -d "$DB" -f /tmp/restore.sql
docker exec "$CONTAINER" rm -f /tmp/restore.sql
echo "Restore concluido. Validar dados e reiniciar servicos se necessario."
