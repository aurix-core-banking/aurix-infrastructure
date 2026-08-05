#!/bin/bash

# 🏛️ AUREUS - Script para iniciar o sistema (arquitetura atual: svc-*)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$(cd "$INFRA_DIR/../aurix-backend" 2>/dev/null && pwd)"

echo "🏛️ AUREUS Core Banking - Iniciando sistema..."
echo

# Verificar se Docker está rodando
echo "🔍 Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instale o Docker primeiro."
    exit 1
fi

# Validar paths da arquitetura atual
echo "🔍 Validando estrutura de diretórios..."
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Diretório do backend não encontrado em: $INFRA_DIR/../aurix-backend"
    exit 1
fi

if [ ! -f "$INFRA_DIR/docker-compose.v2.yml" ]; then
    echo "❌ docker-compose.v2.yml não encontrado em: $INFRA_DIR"
    exit 1
fi

echo "✅ Pré-requisitos verificados"
echo

# Subir stack completa (infra + serviços svc-*)
echo "🚀 Subindo stack completa (infra + serviços svc-*)..."
docker compose -f "$INFRA_DIR/docker-compose.v2.yml" up -d --build

echo "⏳ Aguardando serviços subirem..."
sleep 30

# Verificar se PostgreSQL está rodando
echo "🔍 Verificando PostgreSQL..."
until docker exec aurix-postgres pg_isready -U aurix_user -d aurix_db; do
    echo "⚠️  PostgreSQL ainda não está pronto. Aguardando..."
    sleep 5
done

# Verificar se Redis está rodando
echo "🔍 Verificando Redis..."
until docker exec aurix-redis redis-cli ping; do
    echo "⚠️  Redis ainda não está pronto. Aguardando..."
    sleep 2
done

echo "✅ Stack iniciada"
echo

echo "🎉 AUREUS Core Banking iniciado com sucesso!"
echo
echo "📊 Serviços disponíveis:"
echo "  🌐 Gateway (aurix-gateway):      http://localhost:8080"
echo "  🏛️ svc-banking:                   http://localhost:8200"
echo "  💳 svc-payments (PIX):            http://localhost:8201"
echo "  💰 svc-credit:                    http://localhost:8082"
echo "  👤 svc-customer:                  http://localhost:8083"
echo "  📦 svc-products:                  http://localhost:8084"
echo "  🛡️ svc-fraud:                     http://localhost:8207"
echo "  📋 svc-compliance:                http://localhost:8205"
echo "  🧾 svc-finance-mgmt:              http://localhost:8089"
echo "  ⚙️ svc-platform:                  http://localhost:8092"
echo "  🤖 svc-intelligence:              http://localhost:8091"
echo "  🔐 Keycloak Admin:                http://localhost:8443/admin (admin / admin)"
echo "  🗄️ PostgreSQL:                    localhost:5432 (aurix_user / aurix_db)"
echo "  🔴 Redis:                         localhost:6379"
echo "  📨 Kafka:                         localhost:9092"
echo
echo "🔍 Health Checks:"
echo "  - svc-banking:       http://localhost:8200/actuator/health"
echo "  - svc-payments:      http://localhost:8201/actuator/health"
echo "  - svc-credit:        http://localhost:8082/actuator/health"
echo "  - svc-customer:      http://localhost:8083/actuator/health"
echo "  - svc-products:      http://localhost:8084/actuator/health"
echo "  - svc-fraud:         http://localhost:8207/actuator/health"
echo "  - svc-compliance:    http://localhost:8205/actuator/health"
echo "  - svc-finance-mgmt:  http://localhost:8089/actuator/health"
echo "  - svc-platform:      http://localhost:8092/actuator/health"
echo "  - svc-intelligence:  http://localhost:8091/actuator/health"
echo
echo "📚 Documentação: docs/README.md"
echo
