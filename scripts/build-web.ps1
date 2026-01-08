# Build script for Flutter web with Firebase config injection
# Usage: .\scripts\build-web.ps1

Write-Host "🔧 Injecting Firebase config into service worker..." -ForegroundColor Cyan
node scripts/inject-firebase-config.js

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to inject Firebase config" -ForegroundColor Red
    exit 1
}

Write-Host "🏗️  Building Flutter web app..." -ForegroundColor Cyan

# Build with dart-define flags if environment variables are set
$buildArgs = @("build", "web")

if ($env:FIREBASE_API_KEY) {
    $buildArgs += "--dart-define=FIREBASE_API_KEY=$env:FIREBASE_API_KEY"
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

& flutter $buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter build failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green
