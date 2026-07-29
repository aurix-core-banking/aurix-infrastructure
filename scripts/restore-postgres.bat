@echo off
setlocal
if "%~1"=="" (
  echo Uso: %0 ^<caminho-do-arquivo.sql^> [database]
  exit /b 1
)
set CONTAINER=%POSTGRES_CONTAINER%
if "%CONTAINER%"=="" set CONTAINER=aurix-postgres
set BACKUP_FILE=%~1
set DB=%~2
if "%DB%"=="" set DB=aurix
set PGUSER=%POSTGRES_USER%
if "%PGUSER%"=="" set PGUSER=aurix
set PGPASSWORD=%POSTGRES_PASSWORD%
if "%PGPASSWORD%"=="" set PGPASSWORD=aurix123

if not exist "%BACKUP_FILE%" (
  echo Arquivo nao encontrado: %BACKUP_FILE%
  exit /b 1
)

echo Restore: %BACKUP_FILE% -^> %DB%
docker cp "%BACKUP_FILE%" %CONTAINER%:/tmp/restore.sql
docker exec -i %CONTAINER% psql -U %PGUSER% -d %DB% -f /tmp/restore.sql
docker exec %CONTAINER% rm -f /tmp/restore.sql
echo Restore concluido.
endlocal
