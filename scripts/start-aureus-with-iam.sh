#!/bin/bash

# AUREUS Core Banking - Script de inicialização com IAM
# Este script inicia todos os serviços incluindo Keycloak IAM

set -e

echo "============================================="
echo "AUREUS Core Banking - Inicialização Completa"
echo "============================================="
echo "Incluindo sistema IAM (Keycloak)"
echo "============================================="

# Verificar se Docker está rodando
if ! docker version >/dev/null 2>&1; then
    echo "ERRO: Docker não está rodando ou não está instalado"
    echo "Por favor, inicie o Docker e tente novamente"
    exit 1
fi

echo "Docker está rodando..."

# Parar containers existentes
echo "Parando containers existentes..."
docker-compose down

# Remover volumes órfãos (opcional)
echo "Removendo volumes órfãos..."
docker volume prune -f

# Iniciar serviços
echo "Iniciando serviços do AUREUS..."
docker-compose up -d

# Aguardar serviços estarem prontos
echo "Aguardando serviços estarem prontos..."
sleep 30

# Verificar status dos serviços
echo "Verificando status dos serviços..."

# PostgreSQL
echo "Verificando PostgreSQL..."
if docker exec aurix-postgres pg_isready -U aurix -d aurix >/dev/null 2>&1; then
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
if curl -f http://localhost:8080/health/ready >/dev/null 2>&1; then
    echo "✓ Keycloak está rodando"
else
    echo "✗ Keycloak não está respondendo"
fi

# Prometheus
echo "Verificando Prometheus..."
if curl -f http://localhost:9090/-/healthy >/dev/null 2>&1; then
    echo "✓ Prometheus está rodando"
else
    echo "✗ Prometheus não está respondendo"
fi

# Grafana
echo "Verificando Grafana..."
if curl -f http://localhost:3000/api/health >/dev/null 2>&1; then
    echo "✓ Grafana está rodando"
else
    echo "✗ Grafana não está respondendo"
fi

echo "============================================="
echo "Serviços AUREUS iniciados!"
echo "============================================="
echo "URLs de acesso:"
echo ""
echo "AUREUS Core Banking:"
echo "- API Gateway: http://localhost:8080"
echo "- AUREUS Core: http://localhost:8081"
echo "- AUREUS PIX: http://localhost:8082"
echo "- AUREUS Credit: http://localhost:8083"
echo "- AUREUS Treasury: http://localhost:8084"
echo "- AUREUS Security: http://localhost:8085"
echo "- AUREUS Compliance: http://localhost:8086"
echo "- AUREUS Analytics: http://localhost:8101"
echo "- AUREUS Audit: http://localhost:8088"
echo "- AUREUS Organization: http://localhost:8100"
echo ""
echo "Sistema IAM (Keycloak):"
echo "- Keycloak Admin: http://localhost:8080/admin"
echo "- Usuário: admin"
echo "- Senha: admin123"
echo "- Realm: aurix"
echo ""
echo "Monitoramento:"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3000"
echo "- Usuário: admin"
echo "- Senha: admin123"
echo ""
echo "Banco de Dados:"
echo "- PostgreSQL: localhost:5432"
echo "- Usuário: aurix"
echo "- Senha: aurix123"
echo "- Banco: aurix"
echo ""
echo "Cache:"
echo "- Redis: localhost:6379"
echo ""
echo "============================================="
echo "Configurando Keycloak..."
echo "============================================="

# Aguardar Keycloak estar totalmente pronto
echo "Aguardando Keycloak estar totalmente pronto..."
sleep 60

# Executar configuração do Keycloak
echo "Executando configuração do Keycloak..."
if [ -f "iam/scripts/setup-keycloak.sh" ]; then
    chmod +x iam/scripts/setup-keycloak.sh
    ./iam/scripts/setup-keycloak.sh
else
    echo "Script de configuração do Keycloak não encontrado"
    echo "Configure manualmente via Admin Console: http://localhost:8080/admin"
fi

echo "============================================="
echo "AUREUS Core Banking está pronto!"
echo "============================================="
echo ""
echo "Para parar os serviços:"
echo "docker-compose down"
echo ""
echo "Para visualizar logs:"
echo "docker-compose logs -f"
echo ""
echo "Para acessar o banco de dados:"
echo "docker exec -it aurix-postgres psql -U aurix -d aurix"
echo ""
echo "============================================="
