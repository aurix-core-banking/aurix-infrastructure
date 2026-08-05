@echo off
setlocal

echo =============================================
echo AUREUS CORE BANKING - TESTES E2E
echo =============================================
echo.

echo Verificando se Docker esta rodando...
timeout /t 5 /nobreak >nul
docker ps >nul 2>&1
if errorlevel 1 (
  echo ERRO: Docker Desktop nao esta rodando ou nao responde!
  echo Por favor, inicie o Docker Desktop e tente novamente.
  exit /b 1
)
echo Docker esta rodando. Continuando...
echo.

cd /d "%~dp0"
cd ..

echo Iniciando infraestrutura e servicos com Docker Compose...
docker compose -f docker-compose.yml up -d --build
if errorlevel 1 (
  echo Falha ao iniciar os containers Docker.
  exit /b 1
)

echo.
echo Aguardando estabilizacao dos servicos (90s)...
timeout /t 90 /nobreak >nul

cd ..

echo.
echo Executando testes E2E com pytest...
pytest -q aurix-tests\e2e
set EXITCODE=%ERRORLEVEL%

echo.
echo Encerrando containers Docker...
cd infrastructure
docker compose -f docker-compose.yml down -v

echo.
echo Testes E2E finalizados com codigo %EXITCODE%.
exit /b %EXITCODE%

