# MySQL Server database setup for Restaurant POS
# Usage: .\scripts\setup-db.ps1 -Password "your_mysql_root_password" [-Port 3306]

param(
    [string]$Host = "127.0.0.1",
    [int]$Port = 3306,
    [string]$User = "root",
    [string]$Password = ""
)

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root "backend\.env"

if (-not $Password -and (Test-Path $envFile)) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^DB_PASSWORD=(.*)$') { $Password = $matches[1] }
        if ($_ -match '^DB_PORT=(\d+)$') { $Port = [int]$matches[1] }
    }
}

if (-not $Password) {
    Write-Host "MySQL Server setup requires a password." -ForegroundColor Yellow
    Write-Host "Run: .\scripts\first-run.ps1" -ForegroundColor Cyan
    Write-Host "Or:  .\scripts\setup-db.ps1 -Password 'your_password' -Port 3306" -ForegroundColor Cyan
    exit 1
}

Write-Host "Connecting to MySQL Server at ${Host}:${Port}..." -ForegroundColor Cyan
$test = & mysql -h $Host -P $Port -u $User "-p$Password" -e "SELECT VERSION() AS version;" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "MySQL Server connection failed:" -ForegroundColor Red
    Write-Host $test
    Write-Host "`nEnsure MySQL80 service is running and credentials are correct." -ForegroundColor Yellow
    exit 1
}
Write-Host "MySQL Server connected." -ForegroundColor Green

$mysqlArgs = @("-h", $Host, "-P", $Port, "-u", $User, "-p$Password")
$schema = Join-Path $root "database\01_schema.sql"
$seed = Join-Path $root "database\02_seed_data.sql"

Write-Host "Creating database and tables..."
Get-Content $schema -Raw | & mysql @mysqlArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Seeding data..."
Get-Content $seed -Raw | & mysql @mysqlArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Sync .env
if (Test-Path $envFile) {
    $content = Get-Content $envFile -Raw
    $content = $content -replace 'DB_PASSWORD=.*', "DB_PASSWORD=$Password"
    $content = $content -replace 'DB_PORT=\d+', "DB_PORT=$Port"
    Set-Content -Path $envFile -Value $content.TrimEnd()
}

Write-Host "`nMySQL Server database 'pos_system' is ready." -ForegroundColor Green
Write-Host "Login: admin@system.com / admin123" -ForegroundColor Cyan
