# FCM Multi-Device Token Support

## Overview

The app now supports separate FCM tokens for web and mobile platforms, allowing users to receive push notifications on both devices simultaneously.

## Implementation

### Database Schema

**Added Column:**
- `profiles.fcm_token_web` - Stores FCM token for web platform
- `profiles.fcm_token` - Stores FCM token for mobile/Android platform (existing)

**Migration:**
- File: `supabase/migrations/20250111_add_fcm_token_web.sql`
- Run this SQL script in Supabase SQL Editor to add the column

### Code Changes

**Flutter App:**
1. **`lib/main.dart`** - Updated `_saveFCMTokenToProfile()` to save to platform-specific column
2. **`lib/core/services/firebase_service.dart`** - Updated `updateFCMTokenInProfile()` 
3. **`lib/core/services/fcm_service.dart`** - Updated `_saveFCMToken()`

**Edge Function:**
- **`supabase/functions/push-notifications/index.ts`** - Updated to:
  - Fetch both `fcm_token` and `fcm_token_web` from profiles
  - Send notifications to all available tokens
  - Log delivery for each token separately

## Behavior

### Token Saving
- **Web app**: Token saved to `fcm_token_web` column
- **Android app**: Token saved to `fcm_token` column
- **Both tokens preserved**: Signing in on one platform doesn't overwrite the other

### Notification Delivery
- When a notification is created, the Edge Function:
  1. Fetches both tokens from the user's profile
  2. Sends notification to all available tokens
  3. Logs success/failure for each token
  4. Returns summary of results

### Token Refresh
- Each platform handles its own token refresh
- Web tokens refresh independently of mobile tokens
- Both tokens are saved to their respective columns

## Testing

### Test Web Token Saving
1. Sign in to web app
2. Check Supabase: `SELECT id, fcm_token_web, fcm_token FROM profiles WHERE id = 'your-user-id'`
3. Verify `fcm_token_web` is populated

### Test Android Token Saving
1. Sign in to Android app
2. Check Supabase: `SELECT id, fcm_token_web, fcm_token FROM profiles WHERE id = 'your-user-id'`
3. Verify `fcm_token` is populated

### Test Multi-Device Notifications
1. Sign in on both web and Android with same user
2. Trigger a notification (e.g., job assignment)
3. Verify notification appears on both devices
4. Check Edge Function logs for delivery confirmation

## Migration Notes

- **Backward Compatible**: Existing `fcm_token` column still works for Android
- **No Breaking Changes**: Old tokens continue to work
- **Gradual Migration**: Users will get web tokens as they use the web app

## Troubleshooting

### No notifications on web
- Check `fcm_token_web` column is populated
- Verify web app has notification permissions
- Check VAPID key is configured correctly

### No notifications on Android
- Check `fcm_token` column is populated
- Verify Android app has notification permissions
- Check FCM service account key is configured

### Notifications on only one device
- Verify both tokens are saved in profile
- Check Edge Function logs for delivery status
- Ensure both platforms have valid tokens




