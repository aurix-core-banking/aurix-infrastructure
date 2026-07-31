@echo off
setlocal
set SCRIPT_DIR=%~dp0
set ROOT_DIR=%SCRIPT_DIR%..\..
set FRONTEND_DIR=%ROOT_DIR%\aurix-frontend
set ADMIN_DIR=%FRONTEND_DIR%\aurix-admin
set WEB_DIR=%FRONTEND_DIR%\aurix-web
set FRONTEND_API_URL=%FRONTEND_API_URL%
if "%FRONTEND_API_URL%"=="" set FRONTEND_API_URL=http://localhost:8080

echo AUREUS - Build frontend (admin + web)
echo   API URL: %FRONTEND_API_URL%
echo   Root:    %ROOT_DIR%
echo.

if not exist "%ADMIN_DIR%" (
  echo ERRO: diretorio nao encontrado: %ADMIN_DIR%
  exit /b 1
)
if not exist "%WEB_DIR%" (
  echo ERRO: diretorio nao encontrado: %WEB_DIR%
  exit /b 1
)

set REACT_APP_API_URL=%FRONTEND_API_URL%

cd /d "%ADMIN_DIR%"
echo [1/2] Building aurix-admin...
call npm ci --omit=optional 2>nul || call npm install --no-optional
call npm run build
if errorlevel 1 exit /b 1
echo   OK: build/

cd /d "%WEB_DIR%"
echo [2/2] Building aurix-web...
call npm ci --omit=optional 2>nul || call npm install --no-optional
call npm run build
if errorlevel 1 exit /b 1
echo   OK: build/

echo.
echo Frontend build complete. Outputs:
echo   %ADMIN_DIR%\build
echo   %WEB_DIR%\build
endlocal
