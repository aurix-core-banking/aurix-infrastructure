#!/usr/bin/env bash
set -e

CONTAINER="${POSTGRES_CONTAINER:-aurix-postgres}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
PGUSER="${POSTGRES_USER:-aurix}"
PGPASSWORD="${POSTGRES_PASSWORD:-aurix123}"

mkdir -p "$BACKUP_DIR"
STAMP=$(date +%Y%m%d_%H%M%S)
AUREUS_FILE="${BACKUP_DIR}/aurix_${STAMP}.sql"
KEYCLOAK_FILE="${BACKUP_DIR}/keycloak_${STAMP}.sql"

echo "Backup PostgreSQL: aurix e keycloak -> $BACKUP_DIR"
export PGPASSWORD
docker exec "$CONTAINER" pg_dump -U "$PGUSER" -d aurix --no-owner --no-acl -F p -f /tmp/aurix_dump.sql
docker cp "${CONTAINER}:/tmp/aurix_dump.sql" "$AUREUS_FILE"
docker exec "$CONTAINER" rm -f /tmp/aurix_dump.sql

docker exec "$CONTAINER" pg_dump -U "$PGUSER" -d keycloak --no-owner --no-acl -F p -f /tmp/keycloak_dump.sql 2>/dev/null || true
docker cp "${CONTAINER}:/tmp/keycloak_dump.sql" "$KEYCLOAK_FILE" 2>/dev/null || true
docker exec "$CONTAINER" rm -f /tmp/keycloak_dump.sql 2>/dev/null || true

echo "Criado: $AUREUS_FILE"
[ -f "$KEYCLOAK_FILE" ] && echo "Criado: $KEYCLOAK_FILE"

echo "Retencao: removendo backups com mais de ${RETENTION_DAYS} dias"
find "$BACKUP_DIR" -name 'aurix_*.sql' -mtime +${RETENTION_DAYS} -delete
find "$BACKUP_DIR" -name 'keycloak_*.sql' -mtime +${RETENTION_DAYS} -delete
echo "Backup concluido."
