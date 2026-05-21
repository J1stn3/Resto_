# One-command launcher (after DB is configured)
param([string]$Password = "")

$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if ($Password) {
    $envPath = Join-Path $root "backend\.env"
    (Get-Content $envPath) -replace '^DB_PASSWORD=.*', "DB_PASSWORD=$Password" | Set-Content $envPath
    & "$PSScriptRoot\setup-db.ps1" -Password $Password
}

Write-Host "`n=== Restaurant POS ===" -ForegroundColor Cyan
Write-Host "1. Backend:  http://localhost:8080/api/v1"
Write-Host "2. Flutter:  http://localhost:5173 (Chrome)`n"

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$root\backend'; npm run dev"
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$root'; flutter run -d chrome --web-port=5173"
