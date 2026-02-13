# OTP-Based Password Reset Setup Guide

## Overview
The app now uses an **OTP-based password reset flow for mobile** (Android/iOS) and a **link-based flow for web**. This eliminates deep link issues on mobile devices.

## How It Works

### Mobile Flow (Android/iOS):
1. User requests password reset from app
2. App sends email with **6-digit OTP code** (not a link)
3. User enters code in the app
4. App verifies code with Supabase
5. User can then set new password

### Web Flow:
1. User requests password reset from web app
2. Email contains a **link** (existing flow)
3. User clicks link → Opens reset password page
4. User sets new password

## Required Supabase Configuration

### Step 1: Update Email Template for Mobile OTP

You need to modify the **Password Reset** email template in Supabase Dashboard to show the OTP code for mobile requests.

1. Go to Supabase Dashboard → **Authentication** → **Email Templates**
2. Select **"Reset Password"** template
3. Update the template to include the OTP code:

**Current template likely shows:**
```
Click here to reset your password: {{ .ConfirmationURL }}
```

**Update to show OTP code:**
```
Your password reset code is: {{ .Token }}

This code is valid for 1 hour.

If you didn't request this, please ignore this email.
```

**OR** use a conditional template that shows both:
```
{{ if .Token }}
Your password reset code is: {{ .Token }}

Enter this 6-digit code in the app to reset your password.
{{ else }}
Click here to reset your password: {{ .ConfirmationURL }}
{{ end }}
```

### Step 2: Verify Email Template Variables

Supabase provides these variables in email templates:
- `{{ .Token }}` - The 6-digit OTP code (when no redirectTo is provided)
- `{{ .ConfirmationURL }}` - The reset link (when redirectTo is provided)
- `{{ .Email }}` - User's email address
- `{{ .SiteURL }}` - Your site URL

### Step 3: Test the Flow

1. **Mobile Test:**
   - Open Android app
   - Go to "Forgot Password"
   - Enter email
   - Check email for 6-digit code
   - Enter code in app
   - Set new password

2. **Web Test:**
   - Open web app
   - Go to "Forgot Password"
   - Enter email
   - Check email for link
   - Click link
   - Set new password

## Code Changes Made

### Files Modified:
1. `lib/core/services/supabase_service.dart`
   - Updated `resetPassword()` to not use `redirectTo` for mobile
   - Added `verifyPasswordResetOtp()` method

2. `lib/features/auth/providers/auth_provider.dart`
   - Added `verifyPasswordResetOtp()` method

3. `lib/features/auth/forgot_password/forgot_password_screen.dart`
   - Updated to navigate to OTP screen for mobile after email sent

4. `lib/features/auth/verify_otp/verify_otp_screen.dart` (NEW)
   - New screen for entering 6-digit OTP code
   - Auto-submits when all 6 digits entered
   - Resend code functionality

5. `lib/features/auth/reset_password/reset_password_screen.dart`
   - Updated comments to reflect OTP flow for mobile

6. `lib/app/app.dart`
   - Added `/verify-otp` route

## Important Notes

1. **Email Template**: The email template MUST be updated in Supabase Dashboard. Without this, mobile users won't receive the OTP code.

2. **Backward Compatibility**: Web flow continues to use link-based reset (no changes needed).

3. **Session Management**: After OTP verification, a recovery session is created, allowing the user to reset their password.

4. **Error Handling**: If OTP verification fails, users can request a new code.

## Troubleshooting

### Issue: Mobile users receive email with link instead of code
**Solution**: Check that `redirectTo` is NOT being passed for mobile in `supabase_service.dart`. The code should check `kIsWeb` and only pass `redirectTo` for web.

### Issue: OTP code not appearing in email
**Solution**: Verify the email template uses `{{ .Token }}` variable. This is only available when `redirectTo` is not provided.

### Issue: "Invalid OTP" error
**Solution**: 
- Verify the code is entered correctly (6 digits)
- Check that the code hasn't expired (usually 1 hour)
- Request a new code if needed

## Next Steps

1. ✅ Code implementation complete
2. ⚠️ **REQUIRED**: Update Supabase email template (see Step 1 above)
3. Test on Android device
4. Test on web browser
5. Deploy updated APK
