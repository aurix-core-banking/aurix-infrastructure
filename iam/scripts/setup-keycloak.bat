@echo off
REM Script de configuração do Keycloak para AUREUS Core Banking
REM Este script configura o Keycloak com realm, clientes, usuários e permissões

echo =============================================
echo AUREUS Core Banking - Configuração Keycloak
echo =============================================

REM Variáveis de configuração
set KEYCLOAK_URL=http://localhost:8080
set ADMIN_USER=admin
set ADMIN_PASSWORD=admin123
set REALM_NAME=aurix

REM Aguardar o Keycloak estar disponível
echo Aguardando Keycloak estar disponível...
:wait_keycloak
curl -f -s "%KEYCLOAK_URL%/health/ready" >nul 2>&1
if %errorlevel% neq 0 (
    echo Aguardando Keycloak...
    timeout /t 5 /nobreak >nul
    goto wait_keycloak
)

echo Keycloak está disponível!

REM Obter token de acesso do admin
echo Obtendo token de acesso do administrador...
for /f "tokens=*" %%i in ('curl -s -X POST "%KEYCLOAK_URL%/realms/master/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=%ADMIN_USER%" -d "password=%ADMIN_PASSWORD%" -d "grant_type=password" -d "client_id=admin-cli" ^| jq -r ".access_token"') do set ADMIN_TOKEN=%%i

if "%ADMIN_TOKEN%"=="null" (
    echo Erro: Não foi possível obter token de acesso do administrador
    exit /b 1
)

echo Token de acesso obtido com sucesso!

REM Verificar se o realm já existe
echo Verificando se o realm '%REALM_NAME%' já existe...
curl -s -X GET "%KEYCLOAK_URL%/admin/realms/%REALM_NAME%" -H "Authorization: Bearer %ADMIN_TOKEN%" -w "%%{http_code}" -o nul > temp_response.txt
set /p REALM_EXISTS=<temp_response.txt
del temp_response.txt

if "%REALM_EXISTS%"=="200" (
    echo Realm '%REALM_NAME%' já existe. Removendo...
    curl -s -X DELETE "%KEYCLOAK_URL%/admin/realms/%REALM_NAME%" -H "Authorization: Bearer %ADMIN_TOKEN%"
    echo Realm removido!
)

REM Criar realm
echo Criando realm '%REALM_NAME%'...
curl -s -X POST "%KEYCLOAK_URL%/admin/realms" -H "Authorization: Bearer %ADMIN_TOKEN%" -H "Content-Type: application/json" -d @/opt/keycloak/data/import/aurix-realm.json

echo Realm criado com sucesso!

REM Aguardar um momento para o realm ser processado
timeout /t 5 /nobreak >nul

echo =============================================
echo Configuração do Keycloak concluída!
echo =============================================
echo Realm: %REALM_NAME%
echo URL: %KEYCLOAK_URL%/realms/%REALM_NAME%
echo Admin Console: %KEYCLOAK_URL%/admin
echo =============================================
echo Usuários criados:
echo - admin / admin123 (Administrador)
echo - gerente / gerente123 (Gerente)
echo - operador / operador123 (Operador)
echo - cliente.teste / cliente123 (Cliente)
echo =============================================

pause
