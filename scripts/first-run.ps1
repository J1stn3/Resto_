# First-time MySQL Server setup for Restaurant POS
# Run: .\scripts\first-run.ps1

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root "backend\.env"

Write-Host "`n=== Restaurant POS - MySQL Server Setup ===" -ForegroundColor Cyan
Write-Host "This project uses MySQL Server only (install from dev.mysql.com).`n"

# Detect port from .env or default
$port = 3306
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^DB_PORT=(\d+)$') { $port = [int]$matches[1] }
    }
}

$portInput = Read-Host "MySQL Server port [$port]"
if ($portInput) { $port = [int]$portInput }

$secure = Read-Host "MySQL root password" -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

if (-not $password) {
    Write-Host "Password cannot be empty." -ForegroundColor Red
    exit 1
}

Write-Host "Testing MySQL Server on port $port..."
$test = & mysql -h 127.0.0.1 -P $port -u root "-p$password" -e "SELECT VERSION();" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Connection failed: $test" -ForegroundColor Red
    Write-Host "Start MySQL80 service:  Start-Service MySQL80" -ForegroundColor Yellow
    exit 1
}
Write-Host "MySQL Server OK." -ForegroundColor Green

# Update .env
$envTemplate = @"
DB_HOST=127.0.0.1
DB_PORT=$port
DB_USER=root
DB_PASSWORD=$password
DB_NAME=pos_system
PORT=8080
NODE_ENV=development
JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=24h
TAX_RATE=0.10
"@
Set-Content -Path $envFile -Value $envTemplate
Write-Host "Updated backend\.env" -ForegroundColor Green

& "$PSScriptRoot\setup-db.ps1" -Password $password -Port $port
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== Next steps ===" -ForegroundColor Cyan
Write-Host "1. Backend:  cd backend; npm run dev"
Write-Host "2. Flutter:  press R to hot restart"
Write-Host "3. Login:    admin@system.com / admin123`n"
