@echo off
set SCRIPT_DIR=%~dp0
set INFRA_DIR=%SCRIPT_DIR%..
cd /d "%INFRA_DIR%"
echo AUREUS Core Banking - Encerrando servicos...
docker compose -f docker-compose.v2.yml down
docker compose -f docker-compose.dev.yml down
echo AUREUS Core Banking encerrado.
pause
