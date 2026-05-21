@echo off
REM Convert existing USD-scale prices to Philippine pesos (PHP)
REM Usage: migrate-prices-to-php.cmd [mysql_root_password]

setlocal
set "ROOT=%~dp0.."
set "HOST=127.0.0.1"
set "PORT=3306"
set "USER=root"

if exist "%ROOT%\backend\.env" (
  for /f "usebackq tokens=1,2 delims==" %%a in ("%ROOT%\backend\.env") do (
    if /i "%%a"=="DB_PORT" set "PORT=%%b"
    if /i "%%a"=="DB_HOST" set "HOST=%%b"
    if /i "%%a"=="DB_USER" set "USER=%%b"
    if /i "%%a"=="DB_PASSWORD" set "MYSQL_PWD=%%b"
  )
)

if "%~1"=="" (
  if not defined MYSQL_PWD set /p MYSQL_PWD=Enter MySQL root password: 
) else (
  set "MYSQL_PWD=%~1"
)

where mysql >nul 2>&1
if errorlevel 1 (
  echo ERROR: mysql.exe not found in PATH.
  exit /b 1
)

echo.
echo Converting prices to PHP on %HOST%:%PORT% ...
mysql -h %HOST% -P %PORT% -u %USER% -p%MYSQL_PWD% < "%~dp004_convert_prices_to_php.sql"
if errorlevel 1 (
  echo ERROR: Migration failed.
  exit /b 1
)

echo.
echo Done. Hot restart Flutter app to see peso prices.
endlocal
