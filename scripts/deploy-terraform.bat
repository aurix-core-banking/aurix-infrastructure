@echo off
setlocal enabledelayedexpansion
set SCRIPT_DIR=%~dp0
set INFRA_DIR=%SCRIPT_DIR%..
set ENVIRONMENT=dev
set CLOUD_PROVIDER=all
set DEPLOY_K8S=false
set DEPLOY_FRONTEND=false
set DEPLOY_FRONTEND_ONLY=false
set FRONTEND_UPLOAD=false

:parse
if "%~1"=="" goto check_frontend_only
if /i "%~1"=="--environment" (set ENVIRONMENT=%~2 & shift & shift & goto parse)
if /i "%~1"=="--cloud-provider" (set CLOUD_PROVIDER=%~2 & shift & shift & goto parse)
if /i "%~1"=="--deploy-k8s" (set DEPLOY_K8S=true & shift & goto parse)
if /i "%~1"=="--deploy-frontend" (set DEPLOY_FRONTEND=true & shift & goto parse)
if /i "%~1"=="--deploy-frontend-only" (set DEPLOY_FRONTEND_ONLY=true & shift & goto parse)
if /i "%~1"=="--frontend-api-url" (set FRONTEND_API_URL=%~2 & shift & shift & goto parse)
if /i "%~1"=="--frontend-upload" (set FRONTEND_UPLOAD=true & shift & goto parse)
if /i "%~1"=="--help" (
  echo Usage: %~n0.bat [OPTIONS]
  echo   --environment ENV        dev, staging, prod
  echo   --cloud-provider CP      aws, azure, gcp, all
  echo   --deploy-k8s             Deploy Kubernetes manifests
  echo   --deploy-frontend        Build frontend with backend (same cloud)
  echo   --frontend-api-url URL   API URL for frontend (apontamento)
  echo   --frontend-upload        Upload frontend to S3 after build
  echo   --deploy-frontend-only   Deploy only frontend; set FRONTEND_API_URL or use --frontend-api-url
  echo   --help                  This message
  exit /b 0
)
shift
goto parse

:check_frontend_only
if "%DEPLOY_FRONTEND_ONLY%"=="true" (
  if "%FRONTEND_API_URL%"=="" set FRONTEND_API_URL=http://localhost:8080
  echo AUREUS - Deploy frontend only (apontamento: %FRONTEND_API_URL%)
  call "%SCRIPT_DIR%deploy-frontend.bat"
  exit /b 0
)

echo AUREUS Platform - Terraform Deployment
cd /d "%INFRA_DIR%\terraform"
call terraform init -upgrade
if errorlevel 1 exit /b 1

if "%CLOUD_PROVIDER%"=="aws" (
  set "TF_VARS=-var=environment=%ENVIRONMENT% -var=db_password=%DB_PASSWORD%"
  if defined AWS_REGION set TF_VARS=!TF_VARS! -var=aws_region=%AWS_REGION%
  call terraform apply -target=module.aws_vpc -target=module.aws_eks -target=module.aws_rds -target=module.aws_redis -target=module.aws_alb -target=module.aws_cloudfront -target=module.aws_s3 -target=module.aws_cloudwatch -target=module.aws_iam -target=module.aws_security !TF_VARS! -auto-approve
) else if "%CLOUD_PROVIDER%"=="azure" (
  set "TF_VARS=-var=environment=%ENVIRONMENT% -var=db_password=%DB_PASSWORD%"
  if defined AZURE_LOCATION set TF_VARS=!TF_VARS! -var=azure_location=%AZURE_LOCATION%
  call terraform apply -target=module.azure_resource_group -target=module.azure_aks -target=module.azure_postgresql -target=module.azure_redis !TF_VARS! -auto-approve
) else if "%CLOUD_PROVIDER%"=="gcp" (
  set "TF_VARS=-var=environment=%ENVIRONMENT% -var=db_password=%DB_PASSWORD% -var=gcp_project_id=%GCP_PROJECT_ID%"
  if defined GCP_REGION set TF_VARS=!TF_VARS! -var=gcp_region=%GCP_REGION%
  call terraform apply -target=module.gcp_vpc -target=module.gcp_gke -target=module.gcp_cloud_sql -target=module.gcp_memorystore !TF_VARS! -auto-approve
) else (
  call terraform plan -var="environment=%ENVIRONMENT%" -var="db_password=%DB_PASSWORD%" -out=aurix-platform.tfplan
  if errorlevel 1 exit /b 1
  call terraform apply aurix-platform.tfplan
)
if errorlevel 1 exit /b 1

if "%DEPLOY_K8S%"=="true" (
  if "%CLOUD_PROVIDER%"=="aws" aws eks update-kubeconfig --region %AWS_REGION% --name aurix-eks
  if "%CLOUD_PROVIDER%"=="azure" az aks get-credentials --resource-group aurix-platform-%ENVIRONMENT% --name aurix-aks
  if "%CLOUD_PROVIDER%"=="gcp" gcloud container clusters get-credentials aurix-gke --region %GCP_REGION%
  kubectl apply -f "%INFRA_DIR%\kubernetes\namespace.yaml"
  kubectl apply -f "%INFRA_DIR%\kubernetes\aurix-core-deployment.yaml"
)

if "%DEPLOY_FRONTEND%"=="true" (
  if "%FRONTEND_API_URL%"=="" set FRONTEND_API_URL=http://localhost:8080
  set FRONTEND_API_URL=%FRONTEND_API_URL%
  if "%FRONTEND_UPLOAD%"=="true" (
    set FRONTEND_UPLOAD=true
    call "%SCRIPT_DIR%deploy-frontend.bat"
  ) else (
    call "%SCRIPT_DIR%build-frontend.bat"
  )
)

call terraform output
echo AUREUS Platform deployment completed.
endlocal
