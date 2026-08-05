#!/bin/bash

# AUREUS Core Banking - Ambiente de desenvolvimento (somente infraestrutura)
# Sobe apenas PostgreSQL, Redis, Kafka e Keycloak via docker-compose.dev.yml
# Os serviços svc-* devem ser iniciados pela IDE ou via docker-compose.v2.yml

echo "============================================="
echo "AUREUS CORE BANKING - AMBIENTE DE DESENVOLVIMENTO"
echo "============================================="

echo ""
echo "Iniciando infraestrutura de desenvolvimento..."
echo ""

echo "1. Parando containers existentes..."
docker compose -f docker-compose.dev.yml down

echo ""
echo "2. Removendo volumes antigos (opcional)..."
read -p "Deseja remover volumes antigos? (s/n): " choice
if [[ $choice == "s" || $choice == "S" ]]; then
    docker compose -f docker-compose.dev.yml down -v
    docker volume prune -f
fi

echo ""
echo "3. Iniciando serviços de infraestrutura..."
docker compose -f docker-compose.dev.yml up -d

echo ""
echo "4. Aguardando serviços iniciarem..."
sleep 20

echo ""
echo "5. Verificando status dos serviços..."
docker compose -f docker-compose.dev.yml ps

echo ""
echo "============================================="
echo "INFRAESTRUTURA INICIADA COM SUCESSO!"
echo "============================================="
echo ""
echo "Serviços de infraestrutura:"
echo "- PostgreSQL: localhost:5432 (aurix_user / aurix_db)"
echo "- Redis:      localhost:6379"
echo "- Kafka:      localhost:9092"
echo "- Keycloak:   http://localhost:8443/admin (admin / admin)"
echo ""
echo "Para iniciar os serviços svc-* (backend):"
echo "  docker compose -f docker-compose.v2.yml up -d --build"
echo ""
echo "Ou execute os serviços pela IDE (Spring Boot) usando esta infraestrutura."
echo ""
echo "Para parar o ambiente:"
echo "  docker compose -f docker-compose.dev.yml down"
echo ""
echo "Para ver logs:"
echo "  docker compose -f docker-compose.dev.yml logs -f"
echo ""
