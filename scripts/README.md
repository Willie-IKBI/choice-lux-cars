# Build Scripts

## Firebase Config Injection

The `inject-firebase-config.js` script replaces placeholders in `web/firebase-messaging-sw.js` with actual Firebase configuration values at build time. This prevents hardcoding secrets in the repository.

### Usage

**Automatic (recommended):**
```bash
# Windows PowerShell
.\scripts\build-web.ps1

# Linux/Mac
./scripts/build-web.sh

# Or via npm (runs automatically before build)
npm run prebuild:web
flutter build web
```

**Manual:**
```bash
node scripts/inject-firebase-config.js
```

### Environment Variables

The script reads from environment variables (with fallback defaults):

- `FIREBASE_API_KEY` - Firebase API key
- `FIREBASE_AUTH_DOMAIN` - Firebase auth domain
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_STORAGE_BUCKET` - Firebase storage bucket
- `FIREBASE_SENDER_ID` or `FIREBASE_MESSAGING_SENDER_ID` - Firebase messaging sender ID
- `FIREBASE_APP_ID` - Firebase app ID

### CI/CD Setup

For CI/CD pipelines, set these as environment variables/secrets:

```yaml
# Example GitHub Actions
env:
  FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
  FIREBASE_AUTH_DOMAIN: ${{ secrets.FIREBASE_AUTH_DOMAIN }}
  FIREBASE_PROJECT_ID: ${{ secrets.FIREBASE_PROJECT_ID }}
  FIREBASE_STORAGE_BUCKET: ${{ secrets.FIREBASE_STORAGE_BUCKET }}
  FIREBASE_SENDER_ID: ${{ secrets.FIREBASE_SENDER_ID }}
  FIREBASE_APP_ID: ${{ secrets.FIREBASE_APP_ID }}
```

Then run:
```bash
npm run prebuild:web
flutter build web
```
