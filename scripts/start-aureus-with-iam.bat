@echo off
REM AUREUS Core Banking - Script de inicialização com IAM (Keycloak)
REM Inicia a stack completa via docker-compose.v2.yml (que já inclui Keycloak)

set SCRIPT_DIR=%~dp0
set INFRA_DIR=%SCRIPT_DIR%..

echo =============================================
echo AUREUS Core Banking - Inicialização Completa
echo Incluindo sistema IAM (Keycloak)
echo =============================================
echo.

REM Verificar se Docker está rodando
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: Docker não está rodando ou não está instalado
    echo Por favor, inicie o Docker Desktop e tente novamente
    pause
    exit /b 1
)

echo Docker está rodando...
echo.

REM Validar arquivo da stack
if not exist "%INFRA_DIR%\docker-compose.v2.yml" (
    echo ERRO: docker-compose.v2.yml não encontrado em: %INFRA_DIR%
    pause
    exit /b 1
)

REM Parar containers existentes
echo Parando containers existentes...
docker compose -f "%INFRA_DIR%\docker-compose.v2.yml" down

REM Iniciar stack completa (infra + serviços + Keycloak)
echo Iniciando serviços do AUREUS (incluindo Keycloak)...
docker compose -f "%INFRA_DIR%\docker-compose.v2.yml" up -d --build

REM Aguardar serviços estarem prontos
echo Aguardando serviços estarem prontos...
timeout /t 30 /nobreak >nul

REM Verificar status dos serviços
echo Verificando status dos serviços...

REM PostgreSQL
echo Verificando PostgreSQL...
docker exec aurix-postgres pg_isready -U aurix_user -d aurix_db >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PostgreSQL está rodando
) else (
    echo ✗ PostgreSQL não está respondendo
)

REM Redis
echo Verificando Redis...
docker exec aurix-redis redis-cli ping >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Redis está rodando
) else (
    echo ✗ Redis não está respondendo
)

REM Keycloak
echo Verificando Keycloak...
curl -sf http://localhost:8443 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Keycloak está rodando
) else (
    echo ✗ Keycloak ainda não está respondendo (pode levar mais tempo)
)

echo =============================================
echo Serviços AUREUS iniciados!
echo =============================================
echo URLs de acesso:
echo.
echo AUREUS Core Banking:
echo - Gateway (aurix-gateway): http://localhost:8080
echo - svc-banking:             http://localhost:8200
echo - svc-payments (PIX):      http://localhost:8201
echo - svc-credit:              http://localhost:8082
echo - svc-customer:            http://localhost:8083
echo - svc-products:            http://localhost:8084
echo - svc-fraud:               http://localhost:8207
echo - svc-compliance:          http://localhost:8205
echo - svc-finance-mgmt:        http://localhost:8089
echo - svc-platform:            http://localhost:8092
echo - svc-intelligence:        http://localhost:8091
echo.
echo Sistema IAM (Keycloak):
echo - Keycloak Admin: http://localhost:8443/admin
echo - Usuário: admin
echo - Senha: admin
echo - Realm: aurix
echo.
echo Banco de Dados:
echo - PostgreSQL: localhost:5432
echo - Usuário: aurix_user
echo - Banco: aurix_db
echo.
echo Cache:
echo - Redis: localhost:6379
echo.
echo Mensageria:
echo - Kafka: localhost:9092
echo.
echo =============================================
echo.
echo Para parar os serviços:
echo docker compose -f "%INFRA_DIR%\docker-compose.v2.yml" down
echo.
echo Para visualizar logs:
echo docker compose -f "%INFRA_DIR%\docker-compose.v2.yml" logs -f
echo.
pause
