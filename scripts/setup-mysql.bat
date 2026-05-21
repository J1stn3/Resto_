@echo off
cd /d "%~dp0..\backend"
echo.
echo Restaurant POS - MySQL Server Setup
echo.
set /p MYSQLPWD=Enter MySQL root password: 
node scripts/setup-mysql.js %MYSQLPWD%
pause
