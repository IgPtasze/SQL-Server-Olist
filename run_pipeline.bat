@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

REM ===========================================================================
REM Run ID and log configuration
REM ===========================================================================

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "RUN_ID=%%i"

if not defined RUN_ID (
    echo ERROR: Could not generate the run ID.
    exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "START_SECONDS=%%i"

if not defined START_SECONDS (
    echo ERROR: Could not determine the pipeline start time.
    exit /b 1
)

set "LOG_DIR=%~dp0logs"
set "LOG_FILE=%LOG_DIR%\pipeline_%RUN_ID%.log"

if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
    if errorlevel 1 (
        echo ERROR: Could not create the logs directory.
        exit /b 1
    )
)

REM ===========================================================================
REM Pipeline header
REM ===========================================================================

call :logecho ==========================================
call :logecho       OLIST DATA WAREHOUSE PIPELINE
call :logecho ==========================================
call :logecho Run ID: %RUN_ID%
call :logecho Started: %DATE% %TIME%
call :logecho

REM ===========================================================================
REM 1. Check environment
REM ===========================================================================

call :logecho [1/4] Checking environment...

where docker >nul 2>&1
if errorlevel 1 (
    set "FAIL_MESSAGE=Docker is not installed or unavailable in PATH."
    goto :fail
)

docker compose version >>"%LOG_FILE%" 2>&1
if errorlevel 1 (
    set "FAIL_MESSAGE=Docker Compose is unavailable."
    goto :fail
)

if not exist ".env" (
    set "FAIL_MESSAGE=.env file not found."
    goto :fail
)

REM Load MSSQL_SA_PASSWORD from .env so it is available to sqlcmd calls
REM made directly from this script (docker compose only substitutes it
REM internally for the services it starts).
for /f "usebackq tokens=1,2 delims==" %%A in (".env") do (
    if /i "%%A"=="MSSQL_SA_PASSWORD" set "MSSQL_SA_PASSWORD=%%B"
)

if not defined MSSQL_SA_PASSWORD (
    set "FAIL_MESSAGE=MSSQL_SA_PASSWORD not found in .env file."
    goto :fail
)

if not exist "docker-compose.yaml" (
    set "FAIL_MESSAGE=Docker Compose configuration file not found."
    goto :fail
)

if not exist "scripts\run_pipeline.sql" (
    set "FAIL_MESSAGE=scripts\run_pipeline.sql not found."
    goto :fail
)

REM Check whether Docker Engine is reachable.
docker info >>"%LOG_FILE%" 2>&1
if errorlevel 1 (
    set "FAIL_MESSAGE=Docker Engine is not running. Start Docker Desktop and try again."
    goto :fail
)

call :logecho       SUCCESS

REM ===========================================================================
REM 2. Start SQL Server
REM ===========================================================================

call :logecho
call :logecho [2/4] Starting SQL Server...
call :logecho       Waiting for SQL Server readiness - Docker healthcheck...

docker compose up -d --wait sqlserver >>"%LOG_FILE%" 2>&1
if errorlevel 1 (
    call :log SQL Server readiness check failed. Collecting diagnostics...
    docker compose ps >>"%LOG_FILE%" 2>&1
    docker compose logs --tail 100 sqlserver >>"%LOG_FILE%" 2>&1
    set "FAIL_MESSAGE=SQL Server did not become healthy in time. See the log for details."
    goto :fail
)

call :logecho       SUCCESS

REM ===========================================================================
REM 3. Preprocess source data
REM ===========================================================================

call :logecho
call :logecho [3/4] Preprocessing source data...

docker compose run --rm preprocessing >>"%LOG_FILE%" 2>&1
if errorlevel 1 (
    set "FAIL_MESSAGE=Source data preprocessing failed. See the log for details."
    goto :fail
)

call :logecho       SUCCESS

REM ===========================================================================
REM 4. Execute SQL pipeline
REM ===========================================================================

call :logecho
call :logecho [4/4] Executing SQL pipeline...
call :logecho       Bronze, Silver, Gold and validations

docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "%MSSQL_SA_PASSWORD%" -C -b -i /scripts/run_pipeline.sql >>"%LOG_FILE%" 2>&1
if errorlevel 1 (
    set "FAIL_MESSAGE=SQL pipeline execution failed. See the log for details."
    goto :fail
)

call :logecho       SUCCESS
call :logecho
call :logecho       Validation summary:

for /f "usebackq delims=" %%L in (`findstr /C:"Silver Layer Validation:" /C:"Gold Layer Validation:" "%LOG_FILE%"`) do (
    echo       %%L
)

goto :success

REM ===========================================================================
REM Successful completion
REM ===========================================================================

:success
call :get_duration

call :logecho
call :logecho ==========================================
call :logecho PIPELINE EXECUTION COMPLETED
call :logecho ==========================================
call :logecho Duration: !DURATION!
call :log Finished: %DATE% %TIME%
echo Log: logs\pipeline_%RUN_ID%.log

exit /b 0

REM ===========================================================================
REM Failure handling
REM ===========================================================================

:fail
call :get_duration

call :logecho
call :logecho ERROR: !FAIL_MESSAGE!

echo.
echo       Last log lines (see the full log file for complete details):
echo       ------------------------------------------
for /f "usebackq delims=" %%L in (`powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG_FILE%' -Tail 30"`) do (
    echo       %%L
)
echo       ------------------------------------------

call :logecho ==========================================
call :logecho PIPELINE FAILED
call :logecho Duration: !DURATION!
call :log Finished: %DATE% %TIME%
echo Check log: logs\pipeline_%RUN_ID%.log
call :logecho ==========================================

exit /b 1

REM ===========================================================================
REM Calculate elapsed time
REM ===========================================================================

:get_duration
for /f %%i in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "END_SECONDS=%%i"

set /a ELAPSED=END_SECONDS-START_SECONDS
set /a HOURS=ELAPSED/3600
set /a MINUTES=(ELAPSED%%3600)/60
set /a SECONDS=ELAPSED%%60

if !HOURS! LSS 10 set "HOURS=0!HOURS!"
if !MINUTES! LSS 10 set "MINUTES=0!MINUTES!"
if !SECONDS! LSS 10 set "SECONDS=0!SECONDS!"

set "DURATION=!HOURS!:!MINUTES!:!SECONDS!"
exit /b 0

REM ===========================================================================
REM Logging helpers
REM ===========================================================================

:log
REM Writes a line to the log file only.
REM The message is captured into a variable first and read back with
REM delayed expansion (!line!) inside the if/else block below, instead of
REM substituting %* directly into it. Parentheses or other special
REM characters in the message would otherwise be parsed as part of the
REM block's own ( ) structure, breaking the script with
REM "... was unexpected at this time."
set "line=%*"
if not defined line (
    >>"%LOG_FILE%" echo.
) else (
    >>"%LOG_FILE%" echo(!line!
)
exit /b 0

:logecho
REM Writes the same line to both the console and the log file, so the two
REM never have to be kept in sync by hand. See the note in :log above for
REM why the message goes through a variable with delayed expansion.
set "line=%*"
if not defined line (
    echo.
    >>"%LOG_FILE%" echo.
) else (
    echo(!line!
    >>"%LOG_FILE%" echo(!line!
)
exit /b 0