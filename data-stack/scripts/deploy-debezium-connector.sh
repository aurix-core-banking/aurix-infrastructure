#!/usr/bin/env sh
# Deploy do conector Debezium (PostgreSQL CDC) no Kafka Connect.
# Uso:
#   ./deploy-debezium-connector.sh
#   CONNECT_URL=http://localhost:8083 ./deploy-debezium-connector.sh
set -e

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"
CONNECTOR_JSON="${CONNECTOR_JSON:-../../data-platform/kafka/connect-debezium-postgres.json}"
CONNECTOR_NAME="${CONNECTOR_NAME:-aurix-postgres-cdc}"

if [ ! -f "$CONNECTOR_JSON" ]; then
  echo "Conector JSON não encontrado: $CONNECTOR_JSON" >&2
  echo "Aponte CONNECTOR_JSON ou execute a partir de aurix-infrastructure/data-stack/" >&2
  exit 1
fi

echo "Aguardando Kafka Connect em $CONNECT_URL ..."
until curl -sf "$CONNECT_URL/connectors" >/dev/null; do
  sleep 2
done
echo "Kafka Connect disponível."

if curl -sf "$CONNECT_URL/connectors/$CONNECTOR_NAME" >/dev/null; then
  echo "Conector '$CONNECTOR_NAME' já existe — atualizando..."
  curl -sf -X PUT -H "Content-Type: application/json" \
    --data @"$CONNECTOR_JSON" \
    "$CONNECT_URL/connectors/$CONNECTOR_NAME/config" >/dev/null
else
  echo "Criando conector '$CONNECTOR_NAME'..."
  curl -sf -X POST -H "Content-Type: application/json" \
    --data @"$CONNECTOR_JSON" \
    "$CONNECT_URL/connectors" >/dev/null
fi

echo "Conector '$CONNECTOR_NAME' deployado com sucesso."
curl -sf "$CONNECT_URL/connectors/$CONNECTOR_NAME/status"
echo
