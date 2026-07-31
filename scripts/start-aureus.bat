@echo off
REM 🏛️ AUREUS - Script para iniciar o sistema (arquitetura atual: svc-*)

set SCRIPT_DIR=%~dp0
set INFRA_DIR=%SCRIPT_DIR%..
set BACKEND_DIR=%INFRA_DIR%\..\aurix-backend

echo 🏛️ AUREUS Core Banking - Iniciando sistema...
echo.

REM Verificar se Docker está rodando
echo 🔍 Verificando Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker não encontrado. Instale o Docker Desktop primeiro.
    pause
    exit /b 1
)

REM Validar paths da arquitetura atual
echo 🔍 Validando estrutura de diretórios...
if not exist "%BACKEND_DIR%" (
    echo ❌ Diretório do backend não encontrado em: %BACKEND_DIR%
    pause
    exit /b 1
)
if not exist "%INFRA_DIR%\docker-compose.v2.yml" (
    echo ❌ docker-compose.v2.yml não encontrado em: %INFRA_DIR%
    pause
    exit /b 1
)

echo ✅ Pré-requisitos verificados
echo.

REM Subir stack completa (infra + serviços svc-*)
echo 🚀 Subindo stack completa (infra + serviços svc-*)...
docker compose -f "%INFRA_DIR%\docker-compose.v2.yml" up -d --build

REM Aguardar serviços subirem
echo ⏳ Aguardando serviços subirem...
timeout /t 30 /nobreak >nul

REM Verificar se PostgreSQL está rodando
echo 🔍 Verificando PostgreSQL...
docker exec aurix-postgres pg_isready -U aurix_user -d aurix_db >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  PostgreSQL ainda não está pronto. Aguardando...
    timeout /t 10 /nobreak >nul
)

REM Verificar se Redis está rodando
echo 🔍 Verificando Redis...
docker exec aurix-redis redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Redis ainda não está pronto. Aguardando...
    timeout /t 5 /nobreak >nul
)

echo ✅ Stack iniciada
echo.

echo 🎉 AUREUS Core Banking iniciado com sucesso!
echo.
echo 📊 Serviços disponíveis:
echo   🌐 Gateway (aurix-gateway):      http://localhost:8080
echo   🏛️ svc-banking:                   http://localhost:8200
echo   💳 svc-payments (PIX):            http://localhost:8201
echo   💰 svc-credit:                    http://localhost:8082
echo   👤 svc-customer:                  http://localhost:8083
echo   📦 svc-products:                  http://localhost:8084
echo   🛡️ svc-fraud:                     http://localhost:8207
echo   📋 svc-compliance:                http://localhost:8205
echo   🧾 svc-finance-mgmt:              http://localhost:8089
echo   ⚙️ svc-platform:                  http://localhost:8092
echo   🤖 svc-intelligence:              http://localhost:8091
echo   🔐 Keycloak Admin:                http://localhost:8443/admin (admin / admin)
echo   🗄️ PostgreSQL:                    localhost:5432 (aurix_user / aurix_db)
echo   🔴 Redis:                         localhost:6379
echo   📨 Kafka:                         localhost:9092
echo.
echo 📚 Documentação: docs/README.md
echo.
pause
