# Supabase Deep Link Configuration - REQUIRED FIX

## The Problem
Supabase is sending a **web URL** instead of a **deep link** because the deep link is not in the allowed redirect URLs.

## The Solution
You MUST add the deep link to Supabase Dashboard's allowed redirect URLs.

## Steps to Fix

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **URL Configuration**
   - Or go directly to: `https://supabase.com/dashboard/project/hgqrbekphumdlsifuamq/auth/url-configuration`

2. **Add the Deep Link to "Additional Redirect URLs"**
   - In the "Additional Redirect URLs" field, add:
   ```
   com.choiceluxcars.app://reset-password
   ```
   - Click "Save"

3. **Verify Site URL**
   - Make sure "Site URL" is set to your production web URL:
   ```
   https://choice-lux-cars-app.vercel.app
   ```

4. **Test Again**
   - Request a password reset from the Android app
   - Check the email - the link should now use the deep link format
   - Clicking it should open the app instead of the browser

## Why This Happens

According to Supabase documentation:
- Supabase **CAN** send deep links for mobile apps
- **BUT** the deep link MUST be in the allowed redirect URLs list
- If it's not there, Supabase rejects it and falls back to the Site URL (web URL)
- This is why you're seeing a web URL in the browser instead of the app opening

## Current Code Status

✅ **AndroidManifest.xml** - Deep link intent filter is correctly configured
✅ **supabase_service.dart** - `redirectTo` parameter is correctly set to `com.choiceluxcars.app://reset-password`
❌ **Supabase Dashboard** - Deep link is NOT in allowed redirect URLs (THIS IS THE PROBLEM)

## After Adding the Deep Link

Once you add `com.choiceluxcars.app://reset-password` to Supabase's allowed redirect URLs:
1. Supabase will accept the `redirectTo` parameter
2. The email will contain a deep link instead of a web URL
3. Clicking the link will open the Android app
4. The app will process the recovery token and navigate to the reset password screen
