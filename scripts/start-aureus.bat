@echo off
REM 🏛️ AUREUS - Script para iniciar o sistema

echo 🏛️ AUREUS Core Banking - Iniciando sistema...
echo.

REM Verificar se Docker está rodando
echo 🔍 Verificando Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker não encontrado. Instale o Docker Desktop primeiro.
    pause
    exit /b 1
)

REM Verificar se Java está instalado
echo 🔍 Verificando Java...
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Java não encontrado. Instale o Java 17+ primeiro.
    pause
    exit /b 1
)

REM Verificar se Maven está instalado
echo 🔍 Verificando Maven...
mvn --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Maven não encontrado. Instale o Maven 3.8+ primeiro.
    pause
    exit /b 1
)

echo ✅ Pré-requisitos verificados
echo.

REM Subir infraestrutura
echo 🚀 Subindo infraestrutura...
docker-compose up -d

REM Aguardar serviços subirem
echo ⏳ Aguardando serviços subirem...
timeout /t 30 /nobreak >nul

REM Verificar se PostgreSQL está rodando
echo 🔍 Verificando PostgreSQL...
docker exec aurix-postgres pg_isready -U aurix -d aurix >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  PostgreSQL ainda não está pronto. Aguardando...
    timeout /t 10 /nobreak >nul
)

REM Verificar se Redis está rodando
echo 🔍 Verificando Redis...
docker exec aurix-redis redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Redis ainda não está pronto. Aguardando...
    timeout /t 5 /nobreak >nul
)

echo ✅ Infraestrutura iniciada
echo.

REM Compilar projeto
echo 🔨 Compilando projeto...
mvn clean install -DskipTests

if %errorlevel% neq 0 (
    echo ❌ Erro na compilação. Verifique os logs acima.
    pause
    exit /b 1
)

echo ✅ Projeto compilado com sucesso
echo.

REM Executar AUREUS Core
echo 🏛️ Iniciando AUREUS Core...
start "AUREUS Core" cmd /k "cd aurix-core && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS PIX
echo 💳 Iniciando AUREUS PIX...
start "AUREUS PIX" cmd /k "cd aurix-pix && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS Credit
echo 💰 Iniciando AUREUS Credit...
start "AUREUS Credit" cmd /k "cd aurix-credit && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS Treasury
echo 🏦 Iniciando AUREUS Treasury...
start "AUREUS Treasury" cmd /k "cd aurix-treasury && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS Gateway
echo 🌐 Iniciando AUREUS Gateway...
start "AUREUS Gateway" cmd /k "cd aurix-gateway && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS Security
echo 🔐 Iniciando AUREUS Security...
start "AUREUS Security" cmd /k "cd aurix-security && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS Compliance
echo 📋 Iniciando AUREUS Compliance...
start "AUREUS Compliance" cmd /k "cd aurix-compliance && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS Analytics
echo 📊 Iniciando AUREUS Analytics...
start "AUREUS Analytics" cmd /k "cd aurix-analytics && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

REM Executar AUREUS Audit
echo 🔍 Iniciando AUREUS Audit...
start "AUREUS Audit" cmd /k "cd aurix-audit && mvn spring-boot:run"

REM Aguardar um pouco
timeout /t 5 /nobreak >nul

echo.
echo 🎉 AUREUS Core Banking iniciado com sucesso!
echo.
echo 📊 Serviços disponíveis:
echo   🌐 AUREUS Gateway: http://localhost:8080
echo   🏛️ AUREUS Core: http://localhost:8081/api/core
echo   💳 AUREUS PIX: http://localhost:8082/api/pix
echo   💰 AUREUS Credit: http://localhost:8083/api/credit
echo   🏦 AUREUS Treasury: http://localhost:8084/api/treasury
echo   🔐 AUREUS Security: http://localhost:8085/api/security
echo   📋 AUREUS Compliance: http://localhost:8086/api/compliance
echo   📊 AUREUS Analytics: http://localhost:8101/api/analytics
echo   🔍 AUREUS Audit: http://localhost:8088/api/audit
echo   📊 Swagger UI Gateway: http://localhost:8080/swagger-ui.html
echo   📊 Swagger UI Core: http://localhost:8081/api/core/swagger-ui.html
echo   📊 Swagger UI PIX: http://localhost:8082/api/pix/swagger-ui.html
echo   📊 Swagger UI Credit: http://localhost:8083/api/credit/swagger-ui.html
echo   📊 Swagger UI Treasury: http://localhost:8084/api/treasury/swagger-ui.html
echo   📊 Swagger UI Security: http://localhost:8085/api/security/swagger-ui.html
echo   📊 Swagger UI Compliance: http://localhost:8086/api/compliance/swagger-ui.html
echo   📊 Swagger UI Analytics: http://localhost:8101/api/analytics/swagger-ui.html
echo   📊 Swagger UI Audit: http://localhost:8088/api/audit/swagger-ui.html
echo   🔍 Health Check Gateway: http://localhost:8080/health
echo   🔍 Health Check Core: http://localhost:8081/api/core/health
echo   🔍 Health Check PIX: http://localhost:8082/api/pix/health
echo   🔍 Health Check Credit: http://localhost:8083/api/credit/health
echo   🔍 Health Check Treasury: http://localhost:8084/api/treasury/health
echo   🔍 Health Check Security: http://localhost:8085/api/security/health
echo   🔍 Health Check Compliance: http://localhost:8086/api/compliance/health
echo   🔍 Health Check Analytics: http://localhost:8101/api/analytics/health
echo   🔍 Health Check Audit: http://localhost:8088/api/audit/health
echo   🗄️ PostgreSQL: localhost:5432
echo   🔴 Redis: localhost:6379
echo   📈 Prometheus: http://localhost:9090
echo   📊 Grafana: http://localhost:3000
echo   🔍 Kibana: http://localhost:5601
echo.
echo 📚 Documentação: docs/README.md
echo.
pause
