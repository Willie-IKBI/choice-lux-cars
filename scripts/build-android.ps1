# Build Android APK with Supabase and Maps config from .env
# Required: SUPABASE_URL, SUPABASE_ANON_KEY, ANDROID_GOOGLE_MAPS_API_KEY (or NEXT_PUBLIC_* variants)
# Usage: .\scripts\build-android.ps1

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $ProjectRoot ".env"
$localProps = Join-Path $ProjectRoot "android\local.properties"

# Load .env
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            if ($key -and $val) { Set-Item -Path "env:$key" -Value $val }
        }
    }
}

# Supabase config (required for auth)
$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { $env:NEXT_PUBLIC_SUPABASE_URL }
$supabaseAnonKey = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { $env:NEXT_PUBLIC_SUPABASE_ANON_KEY }
if (-not $supabaseUrl -or -not $supabaseAnonKey) {
    Write-Host "ERROR: Supabase config missing. Add to .env (gitignored):" -ForegroundColor Red
    Write-Host "  SUPABASE_URL=https://YOUR_PROJECT.supabase.co" -ForegroundColor Yellow
    Write-Host "  SUPABASE_ANON_KEY=your_anon_key" -ForegroundColor Yellow
    exit 1
}

$androidKey = $env:ANDROID_GOOGLE_MAPS_API_KEY
if (-not $androidKey) {
    Write-Host "ERROR: ANDROID_GOOGLE_MAPS_API_KEY not set. Add to .env (gitignored):" -ForegroundColor Red
    Write-Host "  ANDROID_GOOGLE_MAPS_API_KEY=your_android_maps_key" -ForegroundColor Yellow
    Write-Host "Use a key restricted to Android apps (package + SHA-1) in Google Cloud Console." -ForegroundColor Gray
    exit 1
}

# Sync key to local.properties (gitignored)
$keyLine = "GOOGLE_MAPS_API_KEY=$androidKey"
$lines = @()
if (Test-Path $localProps) {
    $lines = Get-Content $localProps
}
$found = $false
$newLines = foreach ($line in $lines) {
    if ($line -match '^GOOGLE_MAPS_API_KEY=') {
        $found = $true
        $keyLine
    } else {
        $line
    }
}
if (-not $found) { $newLines += $keyLine }
Set-Content -Path $localProps -Value $newLines

Write-Host "Building Android APK..." -ForegroundColor Cyan
$buildArgs = @("build", "apk", "--release")
$buildArgs += "--dart-define=SUPABASE_URL=$supabaseUrl"
$buildArgs += "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"

Push-Location $ProjectRoot
try {
    flutter @buildArgs
    if ($LASTEXITCODE -ne 0) { exit 1 }
    Write-Host "APK: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
} finally {
    Pop-Location
}
