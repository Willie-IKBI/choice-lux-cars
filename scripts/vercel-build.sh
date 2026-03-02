#!/bin/bash
# Vercel build script for Flutter web
# Runs flutter build with --dart-define from env, then injects config into build/web
# Required Vercel env vars: FIREBASE_API_KEY, FIREBASE_VAPID_KEY, GOOGLE_MAPS_API_KEY
# Optional: SUPABASE_URL, SUPABASE_ANON_KEY, FIREBASE_* (see docs/VERCEL_DEPLOYMENT.md)

set -e

FLUTTER_CMD="${FLUTTER_CMD:-flutter/bin/flutter}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)""$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_OUT="$PROJECT_ROOT/build/web"

cd "$PROJECT_ROOT"

echo "Building Flutter web app with dart-define-from-file..."

# Generate dart_defines.json from env (avoids shell parsing issues with special chars in anon key)
node scripts/generate-dart-defines.js

"$FLUTTER_CMD" build web --release --dart-define-from-file=dart_defines.json

echo "Injecting Firebase and Maps config into build output..."
INJECT_TARGET_DIR="$BUILD_OUT" node scripts/inject-firebase-config.js

echo "Build completed successfully."
