# Google Maps and Firebase Setup

## Firebase (FCM + google-services.json)

For push notifications on Android, you need `android/app/google-services.json` from the Firebase Console. This file is gitignored and must not be committed.

1. Go to [Firebase Console](https://console.firebase.google.com/) → your project → Project settings
2. Under "Your apps", add an Android app with package name `com.choiceluxcars.app` if not already added
3. Download `google-services.json` and place it at `android/app/google-services.json`
4. Or copy from template: `cp android/app/google-services.json.example android/app/google-services.json` and fill in your values

If a previous `google-services.json` was committed with real API keys:
1. Rotate those keys in Firebase Console
2. Run `git rm --cached android/app/google-services.json` to stop tracking (file stays locally, gitignored)
3. Commit the change

---

## Google Maps API Key Setup

The Job Summaries feature includes a map that displays GPS coordinates for all stops (pickup and dropoff locations) from completed driver trips. To enable the map, you need to add your Google Maps API key.

## 1. Get an API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Maps SDK for Android**, **Maps SDK for iOS**, and **Maps JavaScript API** (for web)
4. Go to **APIs & Services > Credentials**
5. Create an API key and **restrict it**:
   - **Application restriction**: Android apps, add your package name `com.choiceluxcars.app` and SHA-1
   - **API restriction**: restrict to Maps SDK for Android / iOS / JavaScript API only
6. If a key was ever committed to git, **rotate it** in the console and use the new key

## 2. Configure the API Key

### Android (no hardcoded secrets)

Use a key restricted to Android apps (package name + SHA-1) in Google Cloud Console. Store it in `.env` (gitignored):

```properties
ANDROID_GOOGLE_MAPS_API_KEY=your_android_maps_key_here
```

Then build with the provided script, which syncs the key to `android/local.properties` (also gitignored) at build time:

```powershell
.\scripts\build-android.ps1
```

The key is injected at build time via Gradle `manifestPlaceholders`. Never commit `.env` or `local.properties`.

### Web

Set `GOOGLE_MAPS_API_KEY` as an environment variable before building. The key is injected at build time via `scripts/inject-firebase-config.js`:

```powershell
$env:GOOGLE_MAPS_API_KEY = "your_actual_api_key_here"
.\scripts\build-web.ps1
```

Or on Linux/macOS:

```bash
GOOGLE_MAPS_API_KEY=your_actual_api_key_here ./scripts/build-web.sh
```

### iOS (if building for iOS)

Add to `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

// In application:didFinishLaunchingWithOptions:
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
```

## 3. Map Behavior

- The map shows GPS coordinates from the `trip_progress` table
- Coordinates are captured when the driver arrives at pickup and dropoff locations
- If no GPS data exists (e.g. job not yet driven), the map shows "No GPS coordinates recorded"
- Green markers = pickup locations
- Orange markers = dropoff locations
