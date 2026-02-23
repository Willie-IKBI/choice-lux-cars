# Build and serve production web app locally (test before deploying to Vercel)
# Loads from .env if present (gitignored). Otherwise set env vars in THIS terminal.
# Usage: .\scripts\preview-web.ps1  or  npm run preview

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $ProjectRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            if ($key -and $val) { Set-Item -Path "env:$key" -Value $val }
        }
    }
}

# Support both standard and NEXT_PUBLIC_ prefixed names
$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { $env:NEXT_PUBLIC_SUPABASE_URL }
$supabaseAnonKey = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { $env:NEXT_PUBLIC_SUPABASE_ANON_KEY }

if (-not $supabaseUrl -or -not $supabaseAnonKey) {
    Write-Host "ERROR: Supabase config missing. Set in THIS terminal before running:" -ForegroundColor Red
    Write-Host '  $env:SUPABASE_URL="https://YOUR_PROJECT.supabase.co"' -ForegroundColor Yellow
    Write-Host '  $env:SUPABASE_ANON_KEY="your_anon_key"' -ForegroundColor Yellow
    Write-Host "Or use NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY" -ForegroundColor Yellow
    Write-Host "Get keys from: Supabase Dashboard -> Settings -> API" -ForegroundColor Gray
    exit 1
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $ProjectRoot

try {
    Write-Host "Building production web app..." -ForegroundColor Cyan
    & "$PSScriptRoot\build-web.ps1"
    if ($LASTEXITCODE -ne 0) { exit 1 }

    Write-Host ""
    Write-Host "Serving at http://localhost:3000 (Ctrl+C to stop)" -ForegroundColor Green
    Write-Host "Open in browser to test production build before deploying to Vercel." -ForegroundColor Gray
    Write-Host ""
    npx serve build/web -l 3000
} finally {
    Pop-Location
}
