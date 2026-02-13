# Add Deep Link to Supabase - Management API Method

## Option 1: Using Supabase Dashboard (Easiest)

1. Go to: https://supabase.com/dashboard/project/hgqrbekphumdlsifuamq/auth/url-configuration
2. In "Additional Redirect URLs", add:
   ```
   com.choiceluxcars.app://reset-password
   ```
3. Click "Save"

## Option 2: Using Management API (Programmatic)

If you want to use the Management API, you'll need:

1. **Get your access token:**
   - Go to: https://supabase.com/dashboard/account/tokens
   - Create a new access token if you don't have one

2. **Get current auth config:**
   ```bash
   curl -X GET "https://api.supabase.com/v1/projects/hgqrbekphumdlsifuamq/config/auth" \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
   ```

3. **Update with deep link:**
   ```bash
   curl -X PATCH "https://api.supabase.com/v1/projects/hgqrbekphumdlsifuamq/config/auth" \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "additional_redirect_urls": [
         "com.choiceluxcars.app://reset-password"
       ]
     }'
   ```

**Note:** The Management API may require you to include ALL existing redirect URLs in the array, not just add one. Check the current config first.

## Platform-Specific Notes

### Android ✅ (Already Configured)
- Deep link intent filter is in `AndroidManifest.xml`
- Scheme: `com.choiceluxcars.app`
- Host: `reset-password`

### iOS (If you build for iOS)
You'll need to add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.choiceluxcars.app</string>
    </array>
  </dict>
</array>
```

## After Adding the Deep Link

1. Request a password reset from the Android app
2. Check the email - the link should be: `com.choiceluxcars.app://reset-password#access_token=...&type=recovery`
3. Clicking it should open the app (not browser)
4. App processes the token and navigates to reset password screen
