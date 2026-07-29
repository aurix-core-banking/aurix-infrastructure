@echo off
REM AUREUS Core Banking - Script de inicialização com IAM
REM Este script inicia todos os serviços incluindo Keycloak IAM

echo =============================================
echo AUREUS Core Banking - Inicialização Completa
echo =============================================
echo Incluindo sistema IAM (Keycloak)
echo =============================================

REM Verificar se Docker está rodando
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: Docker não está rodando ou não está instalado
    echo Por favor, inicie o Docker Desktop e tente novamente
    pause
    exit /b 1
)

echo Docker está rodando...

REM Parar containers existentes
echo Parando containers existentes...
docker-compose down

REM Remover volumes órfãos (opcional)
echo Removendo volumes órfãos...
docker volume prune -f

REM Iniciar serviços
echo Iniciando serviços do AUREUS...
docker-compose up -d

REM Aguardar serviços estarem prontos
echo Aguardando serviços estarem prontos...
timeout /t 30 /nobreak >nul

REM Verificar status dos serviços
echo Verificando status dos serviços...

REM PostgreSQL
echo Verificando PostgreSQL...
docker exec aurix-postgres pg_isready -U aurix -d aurix
if %errorlevel% equ 0 (
    echo ✓ PostgreSQL está rodando
) else (
    echo ✗ PostgreSQL não está respondendo
)

REM Redis
echo Verificando Redis...
docker exec aurix-redis redis-cli ping
if %errorlevel% equ 0 (
    echo ✓ Redis está rodando
) else (
    echo ✗ Redis não está respondendo
)

REM Keycloak
echo Verificando Keycloak...
curl -f http://localhost:8080/health/ready >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Keycloak está rodando
) else (
    echo ✗ Keycloak não está respondendo
)

REM Prometheus
echo Verificando Prometheus...
curl -f http://localhost:9090/-/healthy >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Prometheus está rodando
) else (
    echo ✗ Prometheus não está respondendo
)

REM Grafana
echo Verificando Grafana...
curl -f http://localhost:3000/api/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Grafana está rodando
) else (
    echo ✗ Grafana não está respondendo
)

echo =============================================
echo Serviços AUREUS iniciados!
echo =============================================
echo URLs de acesso:
echo.
echo AUREUS Core Banking:
echo - API Gateway: http://localhost:8080
echo - AUREUS Core: http://localhost:8081
echo - AUREUS PIX: http://localhost:8082
echo - AUREUS Credit: http://localhost:8083
echo - AUREUS Treasury: http://localhost:8084
echo - AUREUS Security: http://localhost:8085
echo - AUREUS Compliance: http://localhost:8086
echo - AUREUS Analytics: http://localhost:8101
echo - AUREUS Audit: http://localhost:8088
echo - AUREUS Organization: http://localhost:8100
echo.
echo Sistema IAM (Keycloak):
echo - Keycloak Admin: http://localhost:8080/admin
echo - Usuário: admin
echo - Senha: admin123
echo - Realm: aurix
echo.
echo Monitoramento:
echo - Prometheus: http://localhost:9090
echo - Grafana: http://localhost:3000
echo - Usuário: admin
echo - Senha: admin123
echo.
echo Banco de Dados:
echo - PostgreSQL: localhost:5432
echo - Usuário: aurix
echo - Senha: aurix123
echo - Banco: aurix
echo.
echo Cache:
echo - Redis: localhost:6379
echo.
echo =============================================
echo Configurando Keycloak...
echo =============================================

REM Aguardar Keycloak estar totalmente pronto
echo Aguardando Keycloak estar totalmente pronto...
timeout /t 60 /nobreak >nul

REM Executar configuração do Keycloak
echo Executando configuração do Keycloak...
call iam\scripts\setup-keycloak.bat

echo =============================================
echo AUREUS Core Banking está pronto!
echo =============================================
echo.
echo Para parar os serviços:
echo docker-compose down
echo.
echo Para visualizar logs:
echo docker-compose logs -f
echo.
echo Para acessar o banco de dados:
echo docker exec -it aurix-postgres psql -U aurix -d aurix
echo.
echo =============================================

pause
