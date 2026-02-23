# Build Scripts

## Firebase and Maps Config Injection

The `inject-firebase-config.js` script replaces placeholders in `web/firebase-messaging-sw.js` and `web/index.html` with actual configuration values at build time. This prevents hardcoding secrets in the repository.

### Usage

**Production build** (injects into `build/web/`, source stays clean):
```bash
# Windows PowerShell - set env vars first (see Environment Variables below)
.\scripts\build-web.ps1

# Linux/Mac
./scripts/build-web.sh
```

**Preview locally** (build + serve at http://localhost:3000 - test before deploying to Vercel):
```bash
.\scripts\preview-web.ps1
# or: npm run preview
```

**Local dev** (`flutter run -d chrome` - injects into `web/`):
```bash
node scripts/inject-firebase-config.js   # run once, then flutter run
flutter run -d chrome
```
If you ran inject for dev, run `git checkout web/` before committing to restore placeholders.

### Environment Variables

Required (no hardcoded fallbacks for secrets):

- `FIREBASE_API_KEY` - Firebase API key (required for web push)
- `FIREBASE_VAPID_KEY` - Web FCM VAPID key (from Firebase Console → Cloud Messaging → Web push certificates; **required for web push**)
- `GOOGLE_MAPS_API_KEY` - Google Maps API key (required for maps on web)
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anon/public key

Optional (non-secret, have defaults):

- `FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_SENDER_ID` or `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_APP_ID`

### Vercel

Vercel uses `scripts/vercel-build.sh`. Set all required env vars in Vercel Project Settings. See [docs/VERCEL_DEPLOYMENT.md](../docs/VERCEL_DEPLOYMENT.md).

### CI/CD Setup

For CI/CD pipelines, set these as secrets and use the build scripts:

```yaml
env:
  FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
  FIREBASE_VAPID_KEY: ${{ secrets.FIREBASE_VAPID_KEY }}
  GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}
  SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
  SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```
