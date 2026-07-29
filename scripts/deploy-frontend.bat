@echo off
setlocal
set SCRIPT_DIR=%~dp0
set ROOT_DIR=%SCRIPT_DIR%..\..

set FRONTEND_API_URL=%FRONTEND_API_URL%
if "%FRONTEND_API_URL%"=="" set FRONTEND_API_URL=http://localhost:8080
set FRONTEND_S3_BUCKET_ADMIN=%FRONTEND_S3_BUCKET_ADMIN%
set FRONTEND_S3_BUCKET_WEB=%FRONTEND_S3_BUCKET_WEB%
set FRONTEND_UPLOAD=%FRONTEND_UPLOAD%
if "%FRONTEND_UPLOAD%"=="" set FRONTEND_UPLOAD=false

echo AUREUS - Deploy frontend
echo   API URL (apontamento): %FRONTEND_API_URL%
echo   Upload to cloud:      %FRONTEND_UPLOAD%
if not "%FRONTEND_S3_BUCKET_ADMIN%"=="" echo   S3 bucket (admin):     %FRONTEND_S3_BUCKET_ADMIN%
if not "%FRONTEND_S3_BUCKET_WEB%"=="" echo   S3 bucket (web):      %FRONTEND_S3_BUCKET_WEB%
echo.

set FRONTEND_API_URL=%FRONTEND_API_URL%
call "%SCRIPT_DIR%build-frontend.bat"
if errorlevel 1 exit /b 1

if not "%FRONTEND_UPLOAD%"=="true" (
  echo Deploy frontend (build only). Set FRONTEND_UPLOAD=true and S3 buckets to upload.
  exit /b 0
)

if "%FRONTEND_S3_BUCKET_ADMIN%"=="" if "%FRONTEND_S3_BUCKET_WEB%"=="" (
  echo FRONTEND_UPLOAD=true but no FRONTEND_S3_BUCKET_ADMIN or FRONTEND_S3_BUCKET_WEB set. Skipping upload.
  exit /b 0
)

where aws >nul 2>nul
if errorlevel 1 (
  echo AWS CLI not found. Install it to upload to S3, or deploy build/ manually.
  exit /b 1
)
if not "%FRONTEND_S3_BUCKET_ADMIN%"=="" (
  echo Uploading admin to s3://%FRONTEND_S3_BUCKET_ADMIN% ...
  aws s3 sync "%ROOT_DIR%\frontend\aurix-admin\build" "s3://%FRONTEND_S3_BUCKET_ADMIN%" --delete
)
if not "%FRONTEND_S3_BUCKET_WEB%"=="" (
  echo Uploading web to s3://%FRONTEND_S3_BUCKET_WEB% ...
  aws s3 sync "%ROOT_DIR%\frontend\aurix-web\build" "s3://%FRONTEND_S3_BUCKET_WEB%" --delete
)
echo Frontend upload complete.
endlocal
