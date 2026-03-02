#!/bin/bash
# Vercel build script for Flutter web
# Runs flutter build with --dart-define from env, then injects config into build/web
# Required Vercel env vars: FIREBASE_API_KEY, FIREBASE_VAPID_KEY, GOOGLE_MAPS_API_KEY
# Optional: SUPABASE_URL, SUPABASE_ANON_KEY, FIREBASE_* (see docs/VERCEL_DEPLOYMENT.md)

set -e

FLUTTER_CMD="${FLUTTER_CMD:-flutter/bin/flutter}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_OUT="$PROJECT_ROOT/build/web"

cd "$PROJECT_ROOT"

echo "Building Flutter web app with dart-define from env..."

# Support both standard and NEXT_PUBLIC_ prefixed names (Vercel/Next.js convention)
FIREBASE_API_KEY="${FIREBASE_API_KEY:-$NEXT_PUBLIC_FIREBASE_API_KEY}"
SUPABASE_URL="${SUPABASE_URL:-$NEXT_PUBLIC_SUPABASE_URL}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-$NEXT_PUBLIC_SUPABASE_ANON_KEY}"

# Verify Supabase config (required for auth - 405 error if missing)
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "ERROR: SUPABASE_URL or SUPABASE_ANON_KEY is empty. Auth will fail with 405."
  echo "  Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in Vercel env vars."
  exit 1
fi
echo "Supabase URL configured: ${SUPABASE_URL:0:30}..."

DART_DEFINES=()

# Required for web push
[ -n "$FIREBASE_API_KEY" ] && DART_DEFINES+=("--dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY")
[ -n "$FIREBASE_VAPID_KEY" ] && DART_DEFINES+=("--dart-define=FIREBASE_VAPID_KEY=$FIREBASE_VAPID_KEY")

# Required for Supabase (no defaults in env.dart)
[ -n "$SUPABASE_URL" ] && DART_DEFINES+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
[ -n "$SUPABASE_ANON_KEY" ] && DART_DEFINES+=("--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")

# Firebase optional (have defaults)
[ -n "$FIREBASE_AUTH_DOMAIN" ] && DART_DEFINES+=("--dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN")
[ -n "$FIREBASE_PROJECT_ID" ] && DART_DEFINES+=("--dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID")
[ -n "$FIREBASE_STORAGE_BUCKET" ] && DART_DEFINES+=("--dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET")
[ -n "$FIREBASE_SENDER_ID" ] && DART_DEFINES+=("--dart-define=FIREBASE_SENDER_ID=$FIREBASE_SENDER_ID")
[ -n "$FIREBASE_APP_ID" ] && DART_DEFINES+=("--dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID")

"$FLUTTER_CMD" build web --release "${DART_DEFINES[@]}"

echo "Injecting Firebase and Maps config into build output..."
INJECT_TARGET_DIR="$BUILD_OUT" node scripts/inject-firebase-config.js

echo "Build completed successfully."
