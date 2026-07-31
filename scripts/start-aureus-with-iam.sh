#!/bin/bash

# AUREUS Core Banking - Script de inicialização com IAM (Keycloak)
# Inicia a stack completa via docker-compose.v2.yml (que já inclui Keycloak)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================="
echo "AUREUS Core Banking - Inicialização Completa"
echo "Incluindo sistema IAM (Keycloak)"
echo "============================================="
echo

# Verificar se Docker está rodando
if ! docker version >/dev/null 2>&1; then
    echo "ERRO: Docker não está rodando ou não está instalado"
    echo "Por favor, inicie o Docker e tente novamente"
    exit 1
fi

echo "Docker está rodando..."
echo

# Validar arquivo da stack
if [ ! -f "$INFRA_DIR/docker-compose.v2.yml" ]; then
    echo "ERRO: docker-compose.v2.yml não encontrado em: $INFRA_DIR"
    exit 1
fi

# Parar containers existentes
echo "Parando containers existentes..."
docker compose -f "$INFRA_DIR/docker-compose.v2.yml" down

# Iniciar stack completa (infra + serviços + Keycloak)
echo "Iniciando serviços do AUREUS (incluindo Keycloak)..."
docker compose -f "$INFRA_DIR/docker-compose.v2.yml" up -d --build

# Aguardar serviços estarem prontos
echo "Aguardando serviços estarem prontos..."
sleep 30

# Verificar status dos serviços
echo "Verificando status dos serviços..."

# PostgreSQL
echo "Verificando PostgreSQL..."
if docker exec aurix-postgres pg_isready -U aurix_user -d aurix_db >/dev/null 2>&1; then
    echo "✓ PostgreSQL está rodando"
else
    echo "✗ PostgreSQL não está respondendo"
fi

# Redis
echo "Verificando Redis..."
if docker exec aurix-redis redis-cli ping >/dev/null 2>&1; then
    echo "✓ Redis está rodando"
else
    echo "✗ Redis não está respondendo"
fi

# Keycloak
echo "Verificando Keycloak..."
if curl -sf http://localhost:8443 >/dev/null 2>&1; then
    echo "✓ Keycloak está rodando"
else
    echo "✗ Keycloak ainda não está respondendo (pode levar mais tempo)"
fi

echo "============================================="
echo "Serviços AUREUS iniciados!"
echo "============================================="
echo "URLs de acesso:"
echo ""
echo "AUREUS Core Banking:"
echo "- Gateway (aurix-gateway): http://localhost:8080"
echo "- svc-banking:             http://localhost:8200"
echo "- svc-payments (PIX):      http://localhost:8201"
echo "- svc-credit:              http://localhost:8082"
echo "- svc-customer:            http://localhost:8083"
echo "- svc-products:            http://localhost:8084"
echo "- svc-fraud:               http://localhost:8207"
echo "- svc-compliance:          http://localhost:8205"
echo "- svc-finance-mgmt:        http://localhost:8089"
echo "- svc-platform:            http://localhost:8092"
echo "- svc-intelligence:        http://localhost:8091"
echo ""
echo "Sistema IAM (Keycloak):"
echo "- Keycloak Admin: http://localhost:8443/admin"
echo "- Usuário: admin"
echo "- Senha: admin"
echo "- Realm: aurix"
echo ""
echo "Banco de Dados:"
echo "- PostgreSQL: localhost:5432"
echo "- Usuário: aurix_user"
echo "- Banco: aurix_db"
echo ""
echo "Cache:"
echo "- Redis: localhost:6379"
echo ""
echo "Mensageria:"
echo "- Kafka: localhost:9092"
echo ""
echo "============================================="
