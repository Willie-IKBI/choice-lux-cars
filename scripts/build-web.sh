#!/bin/bash
# Build script for Flutter web with Firebase and Maps config injection
# Usage: ./scripts/build-web.sh
# Required env vars: FIREBASE_API_KEY, FIREBASE_VAPID_KEY, GOOGLE_MAPS_API_KEY (see scripts/README.md)

set -e

echo "🏗️  Building Flutter web app..."

# Build with dart-define flags if environment variables are set
DART_DEFINES=()

if [ -n "$FIREBASE_API_KEY" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY")
fi
if [ -n "$FIREBASE_VAPID_KEY" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_VAPID_KEY=$FIREBASE_VAPID_KEY")
fi
if [ -n "$FIREBASE_AUTH_DOMAIN" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN")
fi
if [ -n "$FIREBASE_PROJECT_ID" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID")
fi
if [ -n "$FIREBASE_STORAGE_BUCKET" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET")
fi
if [ -n "$FIREBASE_SENDER_ID" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_SENDER_ID=$FIREBASE_SENDER_ID")
fi
if [ -n "$FIREBASE_APP_ID" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID")
fi
if [ -n "$SUPABASE_URL" ]; then
    DART_DEFINES+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
fi
if [ -n "$SUPABASE_ANON_KEY" ]; then
    DART_DEFINES+=("--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")
fi

flutter build web "${DART_DEFINES[@]}"

echo "🔧 Injecting config into build output (keeps source clean)..."
INJECT_TARGET_DIR="$(cd "$(dirname "$0")/.." && pwd)/build/web" node scripts/inject-firebase-config.js

echo "✅ Build completed successfully!"
