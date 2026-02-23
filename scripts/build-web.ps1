# Build script for Flutter web with Firebase and Google Maps config injection
# Usage: .\scripts\build-web.ps1
# Required env vars: SUPABASE_URL, SUPABASE_ANON_KEY, FIREBASE_API_KEY, FIREBASE_VAPID_KEY, GOOGLE_MAPS_API_KEY

# Support both standard and NEXT_PUBLIC_ prefixed names
$supabaseUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { $env:NEXT_PUBLIC_SUPABASE_URL }
$supabaseAnonKey = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { $env:NEXT_PUBLIC_SUPABASE_ANON_KEY }
$firebaseApiKey = if ($env:FIREBASE_API_KEY) { $env:FIREBASE_API_KEY } else { $env:NEXT_PUBLIC_FIREBASE_API_KEY }

if (-not $supabaseUrl -or -not $supabaseAnonKey) {
    Write-Host "ERROR: Supabase config missing. Set SUPABASE_URL and SUPABASE_ANON_KEY (or NEXT_PUBLIC_ variants)" -ForegroundColor Red
    exit 1
}

Write-Host "🏗️  Building Flutter web app..." -ForegroundColor Cyan

# Build with dart-define flags if environment variables are set
$buildArgs = @("build", "web")

if ($firebaseApiKey) {
    $buildArgs += "--dart-define=FIREBASE_API_KEY=$firebaseApiKey"
}
if ($env:FIREBASE_VAPID_KEY) {
    $buildArgs += "--dart-define=FIREBASE_VAPID_KEY=$env:FIREBASE_VAPID_KEY"
}
if ($env:FIREBASE_AUTH_DOMAIN) {
    $buildArgs += "--dart-define=FIREBASE_AUTH_DOMAIN=$env:FIREBASE_AUTH_DOMAIN"
}
if ($env:FIREBASE_PROJECT_ID) {
    $buildArgs += "--dart-define=FIREBASE_PROJECT_ID=$env:FIREBASE_PROJECT_ID"
}
if ($env:FIREBASE_STORAGE_BUCKET) {
    $buildArgs += "--dart-define=FIREBASE_STORAGE_BUCKET=$env:FIREBASE_STORAGE_BUCKET"
}
if ($env:FIREBASE_SENDER_ID) {
    $buildArgs += "--dart-define=FIREBASE_SENDER_ID=$env:FIREBASE_SENDER_ID"
}
if ($env:FIREBASE_APP_ID) {
    $buildArgs += "--dart-define=FIREBASE_APP_ID=$env:FIREBASE_APP_ID"
}
$buildArgs += "--dart-define=SUPABASE_URL=$supabaseUrl"
$buildArgs += "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"

& flutter $buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter build failed" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Injecting config into build output (keeps source clean)..." -ForegroundColor Cyan
$env:INJECT_TARGET_DIR = (Join-Path $PSScriptRoot "..\build\web")
node scripts/inject-firebase-config.js

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to inject config" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green
