#!/bin/bash
# Build script for Flutter web with Firebase config injection
# Usage: ./scripts/build-web.sh

set -e

echo "🔧 Injecting Firebase config into service worker..."
node scripts/inject-firebase-config.js

echo "🏗️  Building Flutter web app..."

# Build with dart-define flags if environment variables are set
DART_DEFINES=()

if [ -n "$FIREBASE_API_KEY" ]; then
    DART_DEFINES+=("--dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY")
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

flutter build web "${DART_DEFINES[@]}"

echo "✅ Build completed successfully!"
