@echo off
set MC_HOST=%1
if "%MC_HOST%"=="" set MC_HOST=http://localhost:9000
set MC_USER=%MINIO_ROOT_USER%
if "%MC_USER%"=="" set MC_USER=aurix_admin
set MC_PASS=%MINIO_ROOT_PASSWORD%
if "%MC_PASS%"=="" set MC_PASS=aurix_secure_password
echo Create buckets manually in MinIO Console http://localhost:9001: aurix-bronze, aurix-silver, aurix-gold
echo Or install mc and run: mc alias set aurix %MC_HOST% %MC_USER% %MC_PASS%
echo   mc mb aurix/aurix-bronze && mc mb aurix/aurix-silver && mc mb aurix/aurix-gold
