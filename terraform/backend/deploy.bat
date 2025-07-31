@echo off
setlocal enabledelayedexpansion

REM Configuration
set PROJECT_NAME=terraform-backend
set ENVIRONMENT=dev
set STACK_NAME=%PROJECT_NAME%

echo.
echo 🔧 Terraform Backend Deployment Script
echo =======================================
echo.

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS CLI is not installed. Please install it first.
    echo Download from: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Check if AWS CLI is configured
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS CLI is not configured. Please run 'aws configure' first.
    pause
    exit /b 1
)

echo ✅ AWS CLI is configured

REM Deploy CloudFormation stack
echo.
echo ℹ️  Deploying Terraform Backend infrastructure...

aws cloudformation deploy ^
    --stack-name %STACK_NAME% ^
    --template-file backend.yaml ^
    --parameter-overrides ^
        ProjectName=%PROJECT_NAME% ^
        Environment=%ENVIRONMENT% ^
    --capabilities CAPABILITY_IAM ^
    --tags ^
        Project=%PROJECT_NAME% ^
        Environment=%ENVIRONMENT% ^
        ManagedBy=CloudFormation

if errorlevel 1 (
    echo ❌ Failed to deploy CloudFormation stack
    pause
    exit /b 1
)

echo ✅ CloudFormation stack deployed successfully

REM Get stack outputs
echo.
echo ℹ️  Retrieving stack outputs...

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --output text --query "Stacks[*].Outputs[?OutputKey=='S3Bucket'].OutputValue" 2^>nul') do set S3_BUCKET=%%i
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --output text --query "Stacks[*].Outputs[?OutputKey=='DynamoDBTable'].OutputValue" 2^>nul') do set DYNAMODB_TABLE=%%i
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --output text --query "Stacks[*].Outputs[?OutputKey=='KMSKeyId'].OutputValue" 2^>nul') do set KMS_KEY=%%i
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name %STACK_NAME% --output text --query "Stacks[*].Outputs[?OutputKey=='Region'].OutputValue" 2^>nul') do set REGION=%%i

if "%S3_BUCKET%"=="" (
    echo ❌ Failed to retrieve S3 bucket name
    pause
    exit /b 1
)

if "%DYNAMODB_TABLE%"=="" (
    echo ❌ Failed to retrieve DynamoDB table name
    pause
    exit /b 1
)

echo ✅ Stack outputs retrieved successfully

REM Auto-update providers.tf if it exists
if exist "..\providers.tf" (
    echo.
    echo ℹ️  Updating ..\providers.tf backend configuration...
    
    REM Create backup
    copy "..\providers.tf" "..\providers.tf.backup" >nul
    
    REM Update backend configuration using PowerShell
    powershell -Command ^
        "$content = Get-Content '..\providers.tf' -Raw; " ^
        "$content = $content -replace 'bucket\s*=\s*\"[^\"]*\"', 'bucket         = \"%S3_BUCKET%\"'; " ^
        "$content = $content -replace 'region\s*=\s*\"[^\"]*\"', 'region         = \"%REGION%\"'; " ^
        "$content = $content -replace 'dynamodb_table\s*=\s*\"[^\"]*\"', 'dynamodb_table = \"%DYNAMODB_TABLE%\"'; " ^
        "Set-Content '..\providers.tf' $content"
    
    echo ✅ providers.tf updated automatically
)

REM Display summary
echo.
echo ==========================================
echo 🚀 TERRAFORM BACKEND DEPLOYMENT COMPLETE
echo ==========================================
echo.
echo ℹ️  📦 S3 Bucket: %S3_BUCKET%
echo ℹ️  🔒 DynamoDB Table: %DYNAMODB_TABLE%
echo ℹ️  🔑 KMS Key: %KMS_KEY%
echo ℹ️  🌍 Region: %REGION%
echo.
echo 🔧 Backend configuration in terraform/providers.tf:
echo terraform {
echo   backend "s3" {
echo     bucket         = "%S3_BUCKET%"
echo     key            = "infraiim"
echo     region         = "%REGION%"
echo     dynamodb_table = "%DYNAMODB_TABLE%"
echo     encrypt        = true
echo   }
echo }
echo.
echo ⚠️  Next steps:
echo 1. Add AWS credentials to GitHub Secrets
echo 2. Run 'terraform init' in the terraform directory
echo 3. Commit and push changes to deploy your application
echo.
pause