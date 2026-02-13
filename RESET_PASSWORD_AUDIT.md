# Reset Password Flow Audit Report

## Executive Summary
The reset password flow has a critical issue: **users clicking the reset password email link are redirected to the sign-in page instead of the reset password page**. This audit identifies the root causes and provides recommendations for both web and mobile (Android) implementations.

---

## Current Flow Analysis

### 1. Forgot Password Request (`forgot_password_screen.dart`)
✅ **Status: Working**
- User enters email
- Calls `authProvider.resetPassword(email)`
- Email is sent successfully

### 2. Email Link Click (`supabase_service.dart`)
❌ **Status: BROKEN**
- **Problem**: `resetPasswordForEmail()` is called WITHOUT a `redirectTo` parameter
- **Current Code**:
  ```dart
  await supabase.auth.resetPasswordForEmail(email);
  ```
- **Impact**: Supabase uses the default Site URL (likely pointing to `/login` or root), so users land on sign-in page instead of `/reset-password`

### 3. Reset Password Screen (`reset_password_screen.dart`)
✅ **Status: Partially Working**
- Screen exists at `/reset-password` route
- Validates session on load
- Updates password correctly
- **Issue**: Users never reach this screen because they're redirected to login

### 4. Router Guard (`guards.dart`)
⚠️ **Status: Has Logic But May Not Trigger**
- Has password recovery detection logic
- Redirects to `/reset-password` if in password recovery mode
- **Issue**: Relies on `AuthChangeEvent.passwordRecovery` event, which may not fire if user lands on wrong page first

---

## Root Causes

### Primary Issue: Missing `redirectTo` Parameter
**Location**: `lib/core/services/supabase_service.dart:192`

**Problem**: 
- No `redirectTo` is specified when calling `resetPasswordForEmail()`
- Supabase defaults to the Site URL configured in dashboard
- Site URL likely points to login page or root

**Fix Required**:
```dart
await supabase.auth.resetPasswordForEmail(
  email,
  redirectTo: 'https://your-domain.com/reset-password', // Web
  // OR for mobile:
  // redirectTo: 'com.yourapp://reset-password', // Android deep link
);
```

### Secondary Issue: Supabase Site URL Configuration
**Location**: Supabase Dashboard → Authentication → URL Configuration

**Problem**:
- Site URL may be set to login page or root
- Should point to reset password page for password recovery flows

**Fix Required**:
- Set Site URL to your production domain (e.g., `https://choice-lux-cars-app.vercel.app`)
- Add `/reset-password` to allowed redirect URLs

### Tertiary Issue: Web URL Handling
**Location**: App initialization / URL handling

**Problem**:
- Web app may not properly handle URL fragments/query params from email links
- No explicit handling of `#access_token=...&type=recovery` in URL

**Fix Required**:
- Handle URL fragments when app loads
- Extract token and verify it
- Redirect to `/reset-password` if valid recovery token

---

## Detailed Issues

### Issue 1: Missing redirectTo in resetPasswordForEmail
**File**: `lib/core/services/supabase_service.dart`
**Line**: 192
**Severity**: 🔴 **CRITICAL**

**Current Code**:
```dart
Future<void> resetPassword({required String email}) async {
  try {
    Log.d('Resetting password for: $email');
    await supabase.auth.resetPasswordForEmail(email);
    Log.d('Password reset email sent successfully');
  } catch (error) {
    Log.e('Error resetting password: $error');
    rethrow;
  }
}
```

**Required Fix**:
```dart
Future<void> resetPassword({required String email}) async {
  try {
    Log.d('Resetting password for: $email');
    
    // Determine redirect URL based on platform
    String redirectTo;
    if (kIsWeb) {
      // For web, use the full URL to reset password page
      redirectTo = '${Uri.base.origin}/reset-password';
    } else {
      // For mobile, use deep link
      redirectTo = 'com.choice.lux.cars://reset-password';
    }
    
    await supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
    Log.d('Password reset email sent successfully with redirect: $redirectTo');
  } catch (error) {
    Log.e('Error resetting password: $error');
    rethrow;
  }
}
```

---

### Issue 2: Supabase Dashboard Configuration
**Location**: Supabase Dashboard
**Severity**: 🔴 **CRITICAL**

**Required Actions**:
1. Go to: **Authentication → URL Configuration**
2. Set **Site URL** to: `https://choice-lux-cars-app.vercel.app` (or your production URL)
3. Add to **Redirect URLs**:
   - `https://choice-lux-cars-app.vercel.app/reset-password`
   - `https://choice-lux-cars-app.vercel.app/**` (wildcard for all paths)
   - For local dev: `http://localhost:*/reset-password`

**Note**: The Site URL is the **default redirect** when no `redirectTo` is specified. Since we're fixing Issue 1, this becomes less critical but should still be configured correctly.

---

### Issue 3: Web URL Fragment Handling
**Location**: App initialization / main.dart
**Severity**: 🟡 **MEDIUM**

**Problem**: 
- When user clicks email link, Supabase redirects to: `https://your-domain.com/reset-password#access_token=...&type=recovery`
- The app may not be extracting and handling this token automatically
- Supabase Flutter SDK should handle this, but we need to ensure it's working

**Check Required**:
- Verify that `Supabase.instance.client.auth.onAuthStateChange` is properly listening
- Ensure `AuthChangeEvent.passwordRecovery` is being triggered
- Verify router guard is redirecting correctly when event fires

**Current Implementation** (`auth_provider.dart:98-108`):
```dart
else if (event == AuthChangeEvent.passwordRecovery) {
  Log.d('Password recovery event detected - user should be redirected to reset password screen');
  if (session != null) {
    state = AsyncValue.data(session.user);
    setPasswordRecovery(true);
  }
}
```

This looks correct, but the event may not fire if the URL isn't handled properly.

---

### Issue 4: Android Deep Linking (For Mobile App)
**Location**: Android configuration
**Severity**: 🟡 **MEDIUM** (for mobile users)

**Current Status**: Not configured

**Required Actions**:
1. **AndroidManifest.xml**: Add intent filter for deep links
2. **Supabase Configuration**: Add deep link URL to allowed redirects
3. **App Code**: Handle deep link when app opens

**Android Deep Link Format**:
```
com.choice.lux.cars://reset-password
```

**Benefits**:
- Better UX: Opens app directly instead of browser
- More secure: Token handled in-app
- Native experience

---

## Recommended Fix Priority

### Phase 1: Immediate Fix (Web)
1. ✅ Add `redirectTo` parameter to `resetPasswordForEmail()` call
2. ✅ Configure Supabase Site URL and redirect URLs
3. ✅ Test the flow end-to-end

### Phase 2: Enhanced Web Handling
1. ✅ Add explicit URL fragment handling on app load
2. ✅ Verify auth state change events are firing
3. ✅ Add logging to track the flow

### Phase 3: Mobile Enhancement (Android)
1. ✅ Configure Android deep linking
2. ✅ Update `resetPassword()` to use deep link for mobile
3. ✅ Handle deep link in app initialization
4. ✅ Test on Android device

---

## Testing Checklist

### Web Testing
- [ ] Request password reset
- [ ] Check email for reset link
- [ ] Click link in email
- [ ] Verify redirects to `/reset-password` (not `/login`)
- [ ] Verify session is valid
- [ ] Enter new password
- [ ] Verify password updates successfully
- [ ] Verify redirects to login after success

### Mobile Testing (Android)
- [ ] Request password reset
- [ ] Check email for reset link
- [ ] Click link in email
- [ ] Verify app opens (not browser)
- [ ] Verify navigates to reset password screen
- [ ] Enter new password
- [ ] Verify password updates successfully

---

## Code Changes Required

### 1. Update `supabase_service.dart`
- Add `redirectTo` parameter based on platform
- Use web URL for web, deep link for mobile

### 2. Update Supabase Dashboard
- Set Site URL correctly
- Add redirect URLs to allowlist

### 3. (Optional) Add URL handling in app initialization
- Extract fragments from URL on web
- Handle deep links on mobile

### 4. (Optional) Android Deep Linking
- Update AndroidManifest.xml
- Add deep link handler in app

---

## Questions for Clarification

1. **What is your production web URL?**
   - Current: `https://choice-lux-cars-app.vercel.app`?
   - Should we use this or a custom domain?

2. **Do you have a mobile app (Android/iOS)?**
   - If yes, what's the app package name?
   - Do you want deep linking for mobile?

3. **What's the current Supabase Site URL?**
   - Check in Dashboard → Authentication → URL Configuration
   - This affects the default redirect behavior

---

## Next Steps

1. **Immediate**: Fix `redirectTo` parameter in `resetPasswordForEmail()`
2. **Immediate**: Configure Supabase redirect URLs
3. **Test**: Verify web flow works end-to-end
4. **Enhance**: Add mobile deep linking if applicable
5. **Document**: Update any user-facing documentation

---

## References

- [Supabase Password Reset Docs](https://supabase.com/docs/guides/auth/passwords#resetting-a-password)
- [Supabase Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
- [Flutter Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)
