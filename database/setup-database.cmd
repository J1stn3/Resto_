@echo off
REM Restaurant POS - create database via MySQL CMD client
REM Usage: setup-database.cmd YOUR_MYSQL_ROOT_PASSWORD
REM    or: setup-database.cmd   (will prompt for password)

setlocal
set "ROOT=%~dp0.."
set "HOST=127.0.0.1"
set "PORT=3305"
set "USER=root"
set "DB=pos_system"

if "%~1"=="" (
  set /p MYSQL_PWD=Enter MySQL root password: 
) else (
  set "MYSQL_PWD=%~1"
)

where mysql >nul 2>&1
if errorlevel 1 (
  echo ERROR: mysql.exe not found in PATH.
  echo Add MySQL bin folder, e.g. C:\Program Files\MySQL\MySQL Server 8.0\bin
  exit /b 1
)

echo.
echo Connecting to %HOST%:%PORT% ...
mysql -h %HOST% -P %PORT% -u %USER% -p%MYSQL_PWD% -e "SELECT VERSION() AS mysql_version;" 2>nul
if errorlevel 1 (
  echo ERROR: Could not connect. Check password, port %PORT%, and that MySQL service is running.
  exit /b 1
)

echo Creating tables...
mysql -h %HOST% -P %PORT% -u %USER% -p%MYSQL_PWD% < "%ROOT%\database\01_schema.sql"
if errorlevel 1 (
  echo ERROR: Schema failed. See message above.
  exit /b 1
)

echo Seeding data...
mysql -h %HOST% -P %PORT% -u %USER% -p%MYSQL_PWD% < "%ROOT%\database\02_seed_data.sql"
if errorlevel 1 (
  echo ERROR: Seed failed. If database already has data, drop it first or skip seed.
  exit /b 1
)

echo.
echo Done. Database "%DB%" is ready.
echo Login: admin@system.com / admin123
echo.
echo Update backend\.env with:
echo   DB_PASSWORD=%MYSQL_PWD%
echo Then restart backend: cd backend ^& npm run dev
echo.
endlocal
