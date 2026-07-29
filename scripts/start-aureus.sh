#!/bin/bash

# 🏛️ AUREUS - Script para iniciar o sistema

echo "🏛️ AUREUS Core Banking - Iniciando sistema..."
echo

# Verificar se Docker está rodando
echo "🔍 Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instale o Docker primeiro."
    exit 1
fi

# Verificar se Java está instalado
echo "🔍 Verificando Java..."
if ! command -v java &> /dev/null; then
    echo "❌ Java não encontrado. Instale o Java 17+ primeiro."
    exit 1
fi

# Verificar se Maven está instalado
echo "🔍 Verificando Maven..."
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven não encontrado. Instale o Maven 3.8+ primeiro."
    exit 1
fi

echo "✅ Pré-requisitos verificados"
echo

# Subir infraestrutura
echo "🚀 Subindo infraestrutura..."
docker-compose up -d

# Aguardar serviços subirem
echo "⏳ Aguardando serviços subirem..."
sleep 30

# Verificar se PostgreSQL está rodando
echo "🔍 Verificando PostgreSQL..."
until docker exec aurix-postgres pg_isready -U aurix -d aurix; do
    echo "⚠️  PostgreSQL ainda não está pronto. Aguardando..."
    sleep 5
done

# Verificar se Redis está rodando
echo "🔍 Verificando Redis..."
until docker exec aurix-redis redis-cli ping; do
    echo "⚠️  Redis ainda não está pronto. Aguardando..."
    sleep 2
done

echo "✅ Infraestrutura iniciada"
echo

# Compilar projeto
echo "🔨 Compilando projeto..."
mvn clean install -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Erro na compilação. Verifique os logs acima."
    exit 1
fi

echo "✅ Projeto compilado com sucesso"
echo

# Executar AUREUS Core
echo "🏛️ Iniciando AUREUS Core..."
cd aurix-core
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS PIX
echo "💳 Iniciando AUREUS PIX..."
cd ../aurix-pix
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS Credit
echo "💰 Iniciando AUREUS Credit..."
cd ../aurix-credit
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS Treasury
echo "🏦 Iniciando AUREUS Treasury..."
cd ../aurix-treasury
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS Gateway
echo "🌐 Iniciando AUREUS Gateway..."
cd ../aurix-gateway
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS Security
echo "🔐 Iniciando AUREUS Security..."
cd ../aurix-security
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS Compliance
echo "📋 Iniciando AUREUS Compliance..."
cd ../aurix-compliance
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS Analytics
echo "📊 Iniciando AUREUS Analytics..."
cd ../aurix-analytics
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

# Executar AUREUS Audit
echo "🔍 Iniciando AUREUS Audit..."
cd ../aurix-audit
mvn spring-boot:run &

# Aguardar um pouco
sleep 5

echo
echo "🎉 AUREUS Core Banking iniciado com sucesso!"
echo
echo "📊 Serviços disponíveis:"
echo "  🌐 AUREUS Gateway: http://localhost:8080"
echo "  🏛️ AUREUS Core: http://localhost:8081/api/core"
echo "  💳 AUREUS PIX: http://localhost:8082/api/pix"
echo "  💰 AUREUS Credit: http://localhost:8083/api/credit"
echo "  🏦 AUREUS Treasury: http://localhost:8084/api/treasury"
echo "  🔐 AUREUS Security: http://localhost:8085/api/security"
echo "  📋 AUREUS Compliance: http://localhost:8086/api/compliance"
echo "  📊 AUREUS Analytics: http://localhost:8101/api/analytics"
echo "  🔍 AUREUS Audit: http://localhost:8088/api/audit"
echo "  📊 Swagger UI Gateway: http://localhost:8080/swagger-ui.html"
echo "  📊 Swagger UI Core: http://localhost:8081/api/core/swagger-ui.html"
echo "  📊 Swagger UI PIX: http://localhost:8082/api/pix/swagger-ui.html"
echo "  📊 Swagger UI Credit: http://localhost:8083/api/credit/swagger-ui.html"
echo "  📊 Swagger UI Treasury: http://localhost:8084/api/treasury/swagger-ui.html"
echo "  📊 Swagger UI Security: http://localhost:8085/api/security/swagger-ui.html"
echo "  📊 Swagger UI Compliance: http://localhost:8086/api/compliance/swagger-ui.html"
echo "  📊 Swagger UI Analytics: http://localhost:8101/api/analytics/swagger-ui.html"
echo "  📊 Swagger UI Audit: http://localhost:8088/api/audit/swagger-ui.html"
echo "  🔍 Health Check Gateway: http://localhost:8080/health"
echo "  🔍 Health Check Core: http://localhost:8081/api/core/health"
echo "  🔍 Health Check PIX: http://localhost:8082/api/pix/health"
echo "  🔍 Health Check Credit: http://localhost:8083/api/credit/health"
echo "  🔍 Health Check Treasury: http://localhost:8084/api/treasury/health"
echo "  🔍 Health Check Security: http://localhost:8085/api/security/health"
echo "  🔍 Health Check Compliance: http://localhost:8086/api/compliance/health"
echo "  🔍 Health Check Analytics: http://localhost:8101/api/analytics/health"
echo "  🔍 Health Check Audit: http://localhost:8088/api/audit/health"
echo "  🗄️ PostgreSQL: localhost:5432"
echo "  🔴 Redis: localhost:6379"
echo "  📈 Prometheus: http://localhost:9090"
echo "  📊 Grafana: http://localhost:3000"
echo "  🔍 Kibana: http://localhost:5601"
echo
echo "📚 Documentação: docs/README.md"
echo
