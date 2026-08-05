@echo off
setlocal
set SCRIPT_DIR=%~dp0
set INFRA_DIR=%SCRIPT_DIR%..

echo =============================================
echo AUREUS CORE BANKING - AMBIENTE DE DESENVOLVIMENTO
echo =============================================

echo.
echo Iniciando infraestrutura de desenvolvimento...
echo.

echo 1. Parando containers existentes...
docker compose -f "%INFRA_DIR%\docker-compose.dev.yml" down

echo.
echo 2. Removendo volumes antigos (opcional)...
set /p choice="Deseja remover volumes antigos? (s/n): "
if /i "%choice%"=="s" (
    docker compose -f "%INFRA_DIR%\docker-compose.dev.yml" down -v
    docker volume prune -f
)

echo.
echo 3. Iniciando serviços de infraestrutura...
docker compose -f "%INFRA_DIR%\docker-compose.dev.yml" up -d

echo.
echo 4. Aguardando serviços iniciarem...
timeout /t 20 /nobreak >nul

echo.
echo 5. Verificando status dos serviços...
docker compose -f "%INFRA_DIR%\docker-compose.dev.yml" ps

echo.
echo =============================================
echo INFRAESTRUTURA INICIADA COM SUCESSO!
echo =============================================
echo.
echo Serviços de infraestrutura:
echo - PostgreSQL: localhost:5432 (aurix_user / aurix_db)
echo - Redis:      localhost:6379
echo - Kafka:      localhost:9092
echo - Keycloak:   http://localhost:8443/admin (admin / admin)
echo.
echo Para iniciar os serviços svc-* (backend):
echo   docker compose -f docker-compose.v2.yml up -d --build
echo.
echo Ou execute os serviços pela IDE (Spring Boot) usando esta infraestrutura.
echo.
echo Para parar o ambiente:
echo   docker compose -f "%INFRA_DIR%\docker-compose.dev.yml" down
echo.
echo Para ver logs:
echo   docker compose -f "%INFRA_DIR%\docker-compose.dev.yml" logs -f
echo.
pause
