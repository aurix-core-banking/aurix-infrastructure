@echo off
setlocal
set SCRIPT_DIR=%~dp0
set ROOT_DIR=%SCRIPT_DIR%..\..
set FRONTEND_API_URL=%FRONTEND_API_URL%
if "%FRONTEND_API_URL%"=="" set FRONTEND_API_URL=http://localhost:8080

echo AUREUS - Build frontend (admin + web)
echo   API URL: %FRONTEND_API_URL%
echo   Root:    %ROOT_DIR%
echo.

set REACT_APP_API_URL=%FRONTEND_API_URL%

cd /d "%ROOT_DIR%\frontend\aurix-admin"
echo [1/2] Building aurix-admin...
call npm ci --omit=optional 2>nul || call npm install --no-optional
call npm run build
if errorlevel 1 exit /b 1
echo   OK: build/

cd /d "%ROOT_DIR%\frontend\aurix-web"
echo [2/2] Building aurix-web...
call npm ci --omit=optional 2>nul || call npm install --no-optional
call npm run build
if errorlevel 1 exit /b 1
echo   OK: build/

echo.
echo Frontend build complete. Outputs:
echo   %ROOT_DIR%\frontend\aurix-admin\build
echo   %ROOT_DIR%\frontend\aurix-web\build
endlocal
