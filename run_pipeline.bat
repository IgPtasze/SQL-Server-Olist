@echo off
setlocal
cd /d "%~dp0"

set "VALIDATION_WARNINGS=0"
set "SQL_LOG=%TEMP%\olist_sql_pipeline.log"

echo ==========================================
echo       OLIST DATA WAREHOUSE PIPELINE
echo ==========================================
echo.

REM 1. Check Docker and environment configuration
echo [1/4] Checking environment...

where docker >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or unavailable in PATH.
    exit /b 1
)

if not exist ".env" (
    echo ERROR: .env file not found.
    exit /b 1
)

if not exist "scripts\run_pipeline.sql" (
    echo ERROR: scripts\run_pipeline.sql not found.
    exit /b 1
)

REM 2. Start SQL Server and wait until it is ready
echo.
echo [2/4] Starting SQL Server...

docker compose up -d sqlserver
if errorlevel 1 goto :error

echo Waiting for SQL Server...

set /a ATTEMPTS=0

:wait_sql
docker compose run --rm sqlcmd -Q "SELECT 1" >nul 2>&1
if not errorlevel 1 goto :sql_ready

set /a ATTEMPTS+=1
if %ATTEMPTS% GEQ 30 (
    echo ERROR: SQL Server did not become ready in time.
    goto :error
)

timeout /t 2 /nobreak >nul
goto :wait_sql

:sql_ready
echo SUCCESS: SQL Server is ready.

REM 3. Preprocess source data
echo.
echo [3/4] Preprocessing source data...

docker compose run --rm preprocessing
if errorlevel 1 goto :error

echo SUCCESS: Source data preprocessing completed.

REM 4. Execute the entire SQL pipeline in one sqlcmd container
echo.
echo [4/4] Executing the SQL pipeline...
echo This includes Bronze, Silver, Gold and all validations.
echo.

docker compose run --rm sqlcmd -i "/scripts/run_pipeline.sql" > "%SQL_LOG%" 2>&1

if errorlevel 1 (
    type "%SQL_LOG%"
    echo.
    echo ERROR: SQL pipeline execution failed.
    goto :error
)

type "%SQL_LOG%"

findstr /C:"FAIL" "%SQL_LOG%" >nul
if not errorlevel 1 (
    set "VALIDATION_WARNINGS=1"
)

echo.
echo ==========================================

if "%VALIDATION_WARNINGS%"=="1" (
    echo PIPELINE COMPLETED WITH WARNINGS
    echo One or more validation checks returned FAIL.
    echo Review the validation results above.
) else (
    echo PIPELINE COMPLETED SUCCESSFULLY
    echo All validation checks passed.
)

echo ==========================================
exit /b 0


:error
echo.
echo ==========================================
echo PIPELINE FAILED
echo An execution error occurred.
echo Check the error messages above.
echo ==========================================
exit /b 1