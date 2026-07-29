@echo off
set SCRIPT_DIR=%~dp0
set INFRA_DIR=%SCRIPT_DIR%..
cd /d "%INFRA_DIR%"
echo AUREUS Core Banking - Encerrando servicos...
docker-compose down
echo AUREUS Core Banking encerrado.
pause
