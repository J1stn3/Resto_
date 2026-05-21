# Start backend API (run from project root)
$root = Split-Path $PSScriptRoot -Parent
Set-Location (Join-Path $root "backend")

if (-not (Test-Path "node_modules")) {
    Write-Host "Installing backend dependencies..."
    npm install
}

Write-Host "Starting API on http://localhost:8080/api/v1"
npm run dev
