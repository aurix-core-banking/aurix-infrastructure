@echo off
setlocal
set CONTAINER=%POSTGRES_CONTAINER%
if "%CONTAINER%"=="" set CONTAINER=aurix-postgres
set BACKUP_DIR=%BACKUP_DIR%
if "%BACKUP_DIR%"=="" set BACKUP_DIR=.\backups
set RETENTION_DAYS=%RETENTION_DAYS%
if "%RETENTION_DAYS%"=="" set RETENTION_DAYS=30
set PGUSER=%POSTGRES_USER%
if "%PGUSER%"=="" set PGUSER=aurix_user
set PGPASSWORD=%POSTGRES_PASSWORD%
if "%PGPASSWORD%"=="" set PGPASSWORD=aurix_dev_password
set AURIX_DB=%POSTGRES_DB%
if "%AURIX_DB%"=="" set AURIX_DB=aurix_db

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set STAMP=%%I
set STAMP=%STAMP:~0,8%_%STAMP:~8,6%

echo Backup PostgreSQL: %AURIX_DB% e keycloak
docker exec %CONTAINER% pg_dump -U %PGUSER% -d %AURIX_DB% --no-owner --no-acl -F p -f /tmp/aurix_dump.sql
docker cp %CONTAINER%:/tmp/aurix_dump.sql "%BACKUP_DIR%\aurix_%STAMP%.sql"
docker exec %CONTAINER% rm -f /tmp/aurix_dump.sql

docker exec %CONTAINER% pg_dump -U %PGUSER% -d keycloak --no-owner --no-acl -F p -f /tmp/keycloak_dump.sql 2>nul
docker cp %CONTAINER%:/tmp/keycloak_dump.sql "%BACKUP_DIR%\keycloak_%STAMP%.sql" 2>nul
docker exec %CONTAINER% rm -f /tmp/keycloak_dump.sql 2>nul

echo Backup concluido. Arquivos em %BACKUP_DIR%
endlocal
