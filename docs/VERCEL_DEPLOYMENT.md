# Vercel Deployment Guide

The web app is deployed to Vercel. This guide covers required environment variables and build configuration.

## Build Process

The build uses `scripts/vercel-build.sh` which:

1. Runs `flutter build web --release` with `--dart-define` flags from environment variables
2. Runs `inject-firebase-config.js` to inject Firebase and Google Maps config into `build/web/`

## Required Environment Variables

Set these in Vercel Project Settings → Environment Variables (for Production, Preview, and optionally Development):

| Variable | Alternative (also supported) | Purpose | Required |
|----------|------------------------------|---------|----------|
| `FIREBASE_API_KEY` | `NEXT_PUBLIC_FIREBASE_API_KEY` | Firebase client init + service worker | Yes (web push) |
| `FIREBASE_VAPID_KEY` | — | Web FCM token (Firebase Console → Cloud Messaging → Web push certificates) | Yes (web push) |
| `GOOGLE_MAPS_API_KEY` | — | Google Maps in index.html | Yes (maps on web) |
| `SUPABASE_URL` | `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_ANON_KEY` | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon/public key | Yes |

### Optional (have defaults in inject script)

| Variable | Purpose |
|----------|---------|
| `FIREBASE_AUTH_DOMAIN` | Firebase auth domain |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_STORAGE_BUCKET` | Firebase storage bucket |
| `FIREBASE_SENDER_ID` | Firebase messaging sender ID |
| `FIREBASE_APP_ID` | Firebase web app ID |

## Test Locally Before Deploy

Build and serve the production web app locally (same output as Vercel) to test before pushing:

```powershell
# Set env vars (same as run_production.ps1)
$env:SUPABASE_URL = "https://xxx.supabase.co"
$env:SUPABASE_ANON_KEY = "your_key"
$env:FIREBASE_API_KEY = "your_firebase_key"
$env:FIREBASE_VAPID_KEY = "your_vapid_key"
$env:GOOGLE_MAPS_API_KEY = "your_maps_key"

# Build and serve at http://localhost:3000
.\scripts\preview-web.ps1
# or: npm run preview
```

Open `http://localhost:3000` in your browser to verify the production build before deploying.

## Pre-Deployment Checklist

1. **Vercel**: Project → Settings → Environment Variables
   - Confirm all required variables are set
   - Ensure `FIREBASE_VAPID_KEY` is present (web push will not work without it)

2. **Firebase Console**: Project settings → Cloud Messaging
   - Generate Web push certificates if not done
   - Copy the VAPID key to `FIREBASE_VAPID_KEY` in Vercel

3. **Supabase**: Auth → URL Configuration
   - Site URL: `https://your-vercel-domain.vercel.app`
   - Redirect URLs: add your Vercel domain and `/reset-password`

4. **Supabase Edge Functions**: `push-notifications` and `push-notifications-poller`
   - Confirm `FIREBASE_SERVICE_ACCOUNT_KEY` secret is set (required for FCM delivery)

## vercel.json

```json
{
  "buildCommand": "bash scripts/vercel-build.sh",
  "outputDirectory": "build/web",
  "installCommand": "...",
  "rewrites": [{"source": "/(.*)", "destination": "/index.html"}]
}
```

## Troubleshooting

### Web push not working
- Verify `FIREBASE_VAPID_KEY` is set in Vercel
- Verify `FIREBASE_API_KEY` is set
- Check browser console for FCM token errors

### Maps not loading
- Verify `GOOGLE_MAPS_API_KEY` is set
- Ensure Maps JavaScript API is enabled in Google Cloud Console

### Build fails
- Ensure all required env vars are set
- Check Vercel build logs for missing `--dart-define` values
