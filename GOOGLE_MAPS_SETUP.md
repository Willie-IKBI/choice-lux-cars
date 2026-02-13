# Google Maps API Key Setup

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

Add your key to `android/local.properties` (gitignored, never committed):

```properties
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

The key is injected at build time via Gradle `manifestPlaceholders`. Never commit the key to version control.

### Web

Edit `web/index.html` and replace `YOUR_GOOGLE_MAPS_API_KEY` in the script URL:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY"></script>
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
