@echo off
echo =============================================
echo AUREUS CORE BANKING - AMBIENTE DE DESENVOLVIMENTO
echo =============================================

echo.
echo Iniciando ambiente de desenvolvimento...
echo.

echo 1. Parando containers existentes...
docker-compose -f ../docker-compose.dev.yml down

echo.
echo 2. Removendo volumes antigos (opcional)...
set /p choice="Deseja remover volumes antigos? (s/n): "
if /i "%choice%"=="s" (
    docker-compose -f ../docker-compose.dev.yml down -v
    docker volume prune -f
)

echo.
echo 3. Construindo imagens...
docker-compose -f ../docker-compose.dev.yml build --no-cache

echo.
echo 4. Iniciando serviços...
docker-compose -f ../docker-compose.dev.yml up -d

echo.
echo 5. Aguardando serviços iniciarem...
timeout /t 30 /nobreak

echo.
echo 6. Verificando status dos serviços...
docker-compose -f ../docker-compose.dev.yml ps

echo.
echo =============================================
echo AMBIENTE INICIADO COM SUCESSO!
echo =============================================
echo.
echo Serviços disponíveis:
echo - AUREUS Gateway: http://localhost:8080
echo - AUREUS Core: http://localhost:8081
echo - AUREUS PIX: http://localhost:8082
echo - AUREUS Credit: http://localhost:8083
echo - AUREUS Treasury: http://localhost:8084
echo - AUREUS Security: http://localhost:8085
echo - AUREUS Compliance: http://localhost:8086
echo - AUREUS Analytics: http://localhost:8101
echo - AUREUS Audit: http://localhost:8088
echo - AUREUS Organization: http://localhost:8100
echo - Nginx Load Balancer: http://localhost:80
echo.
echo Documentação API:
echo - Swagger UI: http://localhost:8080/swagger-ui.html
echo.
echo Banco de Dados:
echo - PostgreSQL: localhost:5432
echo - Usuário: aurix
echo - Senha: aurix123
echo - Database: aurix_core_banking
echo.
echo Cache:
echo - Redis: localhost:6379
echo.
echo Para parar o ambiente:
echo docker-compose -f ../docker-compose.dev.yml down
echo.
echo Para ver logs:
echo docker-compose -f ../docker-compose.dev.yml logs -f
echo.
pause
