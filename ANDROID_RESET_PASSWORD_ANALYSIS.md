# Android Reset Password Flow - Issue Analysis & Recommendations

## 🔍 Issue Identified

**Problem**: When users click the password reset link in email on Android:
- ✅ App opens (deep link works)
- ❌ App navigates to sign-in page instead of reset password page
- ❌ Password recovery session is not established

## 🔬 Root Cause Analysis

### Current Flow:
1. User requests password reset → Email sent with deep link: `com.choiceluxcars.app://reset-password#access_token=...&type=recovery`
2. User clicks link → Android opens app via deep link ✅
3. **MISSING**: App doesn't extract token from deep link URL
4. **MISSING**: Token is not passed to Supabase for verification
5. **RESULT**: No recovery session created, `AuthChangeEvent.passwordRecovery` never fires
6. **RESULT**: Router guard sees no session → redirects to `/login`

### Why It Works on Web:
- Web: Supabase SDK automatically processes URL fragments (`#access_token=...`)
- Mobile: Deep links need explicit handling - the token is in the URL but not automatically processed

### Code Gaps:
1. **No deep link listener**: App doesn't use `app_links` package to listen for incoming deep links
2. **No token extraction**: No code to parse the deep link URL and extract the token
3. **No Supabase verification**: Token is not passed to `supabase.auth.verifyOtp()` or similar

---

## ✅ Recommended Solution

### Option 1: Use App Links Package (Recommended)
**Best for**: Native mobile experience, proper deep link handling

**Implementation**:
1. Add `app_links` package listener in app initialization
2. Extract token from deep link URL
3. Verify token with Supabase to create recovery session
4. Navigate to reset password screen

**Pros**:
- Proper deep link handling
- Works for both cold start and warm start
- Handles all deep link scenarios

**Cons**:
- Requires additional code
- Need to handle edge cases

### Option 2: Use Supabase's Built-in Deep Link Handling
**Best for**: Simpler implementation, relies on Supabase SDK

**Implementation**:
1. Configure Supabase to handle deep links automatically
2. Use Supabase's session recovery methods
3. Listen for auth state changes

**Pros**:
- Less code
- Leverages Supabase SDK features

**Cons**:
- May require additional Supabase configuration
- Less control over the flow

### Option 3: Hybrid Approach (Recommended for Production)
**Best for**: Robust solution with fallbacks

**Implementation**:
1. Use `app_links` to capture deep link
2. Extract token and verify with Supabase
3. Handle both PKCE and implicit flows
4. Add proper error handling and logging

---

## 🛠️ Detailed Implementation Plan (Option 1)

### Step 1: Add Deep Link Listener in App Initialization

**File**: `lib/main.dart` or `lib/app/app.dart`

```dart
import 'package:app_links/app_links.dart';

// In app initialization
final appLinks = AppLinks();

// Listen for deep links
appLinks.uriLinkStream.listen((uri) {
  _handleDeepLink(uri);
});

// Also check for initial link (when app opens from terminated state)
final initialLink = await appLinks.getInitialLink();
if (initialLink != null) {
  _handleDeepLink(initialLink);
}
```

### Step 2: Handle Deep Link and Extract Token

**File**: `lib/core/services/deep_link_service.dart` (new file)

```dart
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class DeepLinkService {
  static Future<void> handleDeepLink(Uri uri) async {
    Log.d('Deep link received: $uri');
    
    // Check if it's a password reset link
    if (uri.scheme == 'com.choiceluxcars.app' && 
        uri.host == 'reset-password') {
      await _handlePasswordResetLink(uri);
    }
  }
  
  static Future<void> _handlePasswordResetLink(Uri uri) async {
    try {
      // Extract token from URL fragment
      final fragment = uri.fragment;
      if (fragment.isEmpty) {
        Log.e('No token found in deep link');
        return;
      }
      
      // Parse fragment: access_token=...&type=recovery&...
      final params = Uri.splitQueryString(fragment);
      final accessToken = params['access_token'];
      final type = params['type'];
      
      if (type != 'recovery' || accessToken == null) {
        Log.e('Invalid password reset link: type=$type, token=${accessToken != null}');
        return;
      }
      
      // For PKCE flow, we need to verify the token hash
      // For implicit flow, the token is already in the URL
      // Supabase SDK should handle this, but we may need to explicitly verify
      
      // Check if we have a recovery session
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user != null) {
        // Session already exists, navigate to reset password
        Log.d('Recovery session found, navigating to reset password');
        // Navigation will be handled by router guard
        return;
      }
      
      // If no session, we need to verify the token
      // This depends on whether Supabase uses PKCE or implicit flow
      // For now, let's try to get the session from the URL
      
      Log.d('Processing password reset token...');
      // Supabase SDK should automatically handle this when the app loads
      // But we may need to explicitly trigger it
      
    } catch (e) {
      Log.e('Error handling password reset deep link: $e');
    }
  }
}
```

### Step 3: Update App Initialization

**File**: `lib/app/app.dart`

```dart
import 'package:app_links/app_links.dart';

class _ChoiceLuxCarsAppState extends ConsumerState<ChoiceLuxCarsApp> {
  late AppLinks _appLinks;
  
  @override
  void initState() {
    super.initState();
    // ... existing code ...
    
    // Initialize deep link handling
    _appLinks = AppLinks();
    _setupDeepLinkListener();
  }
  
  void _setupDeepLinkListener() {
    // Listen for deep links when app is running
    _appLinks.uriLinkStream.listen((uri) {
      Log.d('Deep link received: $uri');
      DeepLinkService.handleDeepLink(uri);
    });
    
    // Check for initial link (when app opens from terminated state)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        Log.d('Initial deep link: $uri');
        DeepLinkService.handleDeepLink(uri);
      }
    });
  }
}
```

### Step 4: Alternative - Use Supabase's Session Recovery

**File**: `lib/core/services/supabase_service.dart`

Add method to handle recovery from deep link:

```dart
/// Handle password reset from deep link
Future<void> handlePasswordResetDeepLink(Uri uri) async {
  try {
    Log.d('Handling password reset deep link: $uri');
    
    // Extract token from fragment
    final fragment = uri.fragment;
    if (fragment.isEmpty) {
      throw Exception('No token found in deep link');
    }
    
    final params = Uri.splitQueryString(fragment);
    final tokenHash = params['access_token'];
    final type = params['type'];
    
    if (type != 'recovery' || tokenHash == null) {
      throw Exception('Invalid password reset link');
    }
    
    // Verify the OTP token with Supabase
    // This creates a recovery session
    final response = await supabase.auth.verifyOtp(
      tokenHash: tokenHash,
      type: OtpType.recovery,
    );
    
    if (response.session != null) {
      Log.d('Password reset session created successfully');
      // Auth state change will fire, router guard will handle navigation
    } else {
      throw Exception('Failed to create recovery session');
    }
  } catch (error) {
    Log.e('Error handling password reset deep link: $error');
    rethrow;
  }
}
```

---

## 🎯 Simplified Recommendation (Quick Fix)

### Use Supabase's Built-in Deep Link Handling

The Supabase Flutter SDK should automatically handle deep links, but we need to ensure:

1. **Check if Supabase is processing the deep link automatically**
   - Add logging to see if `AuthChangeEvent.passwordRecovery` fires
   - Check if session is created when app opens

2. **If not working, explicitly verify the token**:

```dart
// In app initialization or deep link handler
final uri = /* deep link URI */;
final fragment = uri.fragment;
final params = Uri.splitQueryString(fragment);

if (params['type'] == 'recovery' && params['access_token'] != null) {
  // Verify with Supabase
  await supabase.auth.verifyOtp(
    tokenHash: params['access_token']!,
    type: OtpType.recovery,
  );
}
```

3. **Ensure router guard checks for recovery session**:

The router guard should check for recovery session and redirect accordingly.

---

## 📋 Testing Checklist

After implementation:
- [ ] Request password reset from Android app
- [ ] Check email for reset link
- [ ] Click link → App opens
- [ ] **Verify**: Token is extracted from URL
- [ ] **Verify**: Recovery session is created
- [ ] **Verify**: `AuthChangeEvent.passwordRecovery` fires
- [ ] **Verify**: App navigates to `/reset-password` (not `/login`)
- [ ] **Verify**: User can enter new password
- [ ] **Verify**: Password updates successfully

---

## 🔧 Immediate Action Items

1. **Add logging** to see what happens when deep link opens:
   - Log the deep link URL
   - Log auth state changes
   - Log router guard decisions

2. **Test current behavior**:
   - Check if Supabase SDK automatically processes the deep link
   - Check if `AuthChangeEvent.passwordRecovery` fires
   - Check if session is created

3. **Implement fix** based on test results:
   - If SDK handles it: Fix router guard logic
   - If SDK doesn't handle it: Add explicit deep link handling

---

## 💡 Alternative: Simpler Web-Based Flow

**Consideration**: Instead of deep links, use web URLs that open in browser, then redirect to app:

1. Email contains web URL: `https://choice-lux-cars-app.vercel.app/reset-password?token=...`
2. User clicks → Opens in browser
3. Browser processes token, creates session
4. App can detect session and navigate accordingly

**Pros**: Simpler, works reliably
**Cons**: Less native experience, requires browser

---

## 📝 Next Steps

1. **Immediate**: Add logging to diagnose current behavior
2. **Short-term**: Implement deep link handling using `app_links`
3. **Long-term**: Consider web-based flow as fallback
