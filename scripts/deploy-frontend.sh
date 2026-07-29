#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

FRONTEND_API_URL="${FRONTEND_API_URL:-http://localhost:8080}"
FRONTEND_S3_BUCKET_ADMIN="${FRONTEND_S3_BUCKET_ADMIN:-}"
FRONTEND_S3_BUCKET_WEB="${FRONTEND_S3_BUCKET_WEB:-}"
FRONTEND_UPLOAD="${FRONTEND_UPLOAD:-false}"

echo "AUREUS - Deploy frontend"
echo "  API URL (apontamento): $FRONTEND_API_URL"
echo "  Upload to cloud:      $FRONTEND_UPLOAD"
if [ -n "$FRONTEND_S3_BUCKET_ADMIN" ]; then echo "  S3 bucket (admin):     $FRONTEND_S3_BUCKET_ADMIN"; fi
if [ -n "$FRONTEND_S3_BUCKET_WEB" ]; then echo "  S3 bucket (web):      $FRONTEND_S3_BUCKET_WEB"; fi
echo ""

export FRONTEND_API_URL
"$SCRIPT_DIR/build-frontend.sh"

if [ "$FRONTEND_UPLOAD" != "true" ]; then
  echo "Deploy frontend (build only). Set FRONTEND_UPLOAD=true and S3 buckets to upload."
  exit 0
fi

if [ -z "$FRONTEND_S3_BUCKET_ADMIN" ] && [ -z "$FRONTEND_S3_BUCKET_WEB" ]; then
  echo "FRONTEND_UPLOAD=true but no FRONTEND_S3_BUCKET_ADMIN or FRONTEND_S3_BUCKET_WEB set. Skipping upload."
  exit 0
fi

if command -v aws &>/dev/null; then
  if [ -n "$FRONTEND_S3_BUCKET_ADMIN" ]; then
    echo "Uploading admin to s3://$FRONTEND_S3_BUCKET_ADMIN ..."
    aws s3 sync "$ROOT_DIR/apps/frontend/aurix-admin/build" "s3://$FRONTEND_S3_BUCKET_ADMIN" --delete
  fi
  if [ -n "$FRONTEND_S3_BUCKET_WEB" ]; then
    echo "Uploading web to s3://$FRONTEND_S3_BUCKET_WEB ..."
    aws s3 sync "$ROOT_DIR/apps/frontend/aurix-web/build" "s3://$FRONTEND_S3_BUCKET_WEB" --delete
  fi
  echo "Frontend upload complete."
else
  echo "AWS CLI not found. Install it to upload to S3, or deploy build/ manually."
  exit 1
fi
