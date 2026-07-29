#!/usr/bin/env sh
set -e
MC_HOST="${MC_HOST:-http://localhost:9000}"
MC_USER="${MINIO_ROOT_USER:-aurix_admin}"
MC_PASS="${MINIO_ROOT_PASSWORD:-aurix_secure_password}"
if command -v mc >/dev/null 2>&1; then
  mc alias set aurix "$MC_HOST" "$MC_USER" "$MC_PASS"
  mc mb aurix/aurix-bronze --ignore-existing
  mc mb aurix/aurix-silver --ignore-existing
  mc mb aurix/aurix-gold --ignore-existing
  echo "Buckets aurix-bronze, aurix-silver, aurix-gold created."
else
  echo "Install mc (minio client) or run from container: docker run --rm --network host minio/mc alias set aurix $MC_HOST $MC_USER $MC_PASS && docker run --rm --network host minio/mc mb aurix/aurix-bronze --ignore-existing && ..."
fi
