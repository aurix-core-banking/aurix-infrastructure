@echo off
echo =============================================
echo AUREUS CORE BANKING - EXECUTANDO TESTES
echo =============================================

echo.
echo 1. Executando testes unitários...
mvn test -Dtest=SistemaRemuneracaoServiceTest

echo.
echo 2. Executando testes de integração...
mvn test -Dtest=GestaoRiscoServiceTest

echo.
echo 3. Executando todos os testes...
mvn test

echo.
echo 4. Gerando relatório de cobertura...
mvn jacoco:report

echo.
echo =============================================
echo TESTES CONCLUÍDOS!
echo =============================================
echo.
echo Relatórios disponíveis em:
echo - target/site/jacoco/index.html
echo.
pause
