import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for handling deep links (mobile only)
/// 
/// This service handles deep links for password reset and other auth flows.
/// It only runs on mobile platforms - web uses URL fragments which are handled automatically.
class DeepLinkService {
  /// Handle a deep link URI
  /// 
  /// This method extracts tokens from deep links and verifies them with Supabase.
  /// Only processes deep links on mobile - web is handled automatically by Supabase SDK.
  static Future<void> handleDeepLink(Uri uri) async {
    // Skip on web - Supabase SDK handles URL fragments automatically
    if (kIsWeb) {
      Log.d('Deep link handling skipped on web (handled by Supabase SDK)');
      return;
    }

    try {
      Log.d('Deep link received: $uri');
      Log.d('Deep link scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}');
      Log.d('Deep link fragment: ${uri.fragment}');
      Log.d('Deep link query: ${uri.query}');

      // Check if it's a password reset link
      // Supabase might send the link in different formats:
      // 1. Custom scheme: com.choiceluxcars.app://reset-password#access_token=...&type=recovery
      // 2. Custom scheme with path: com.choiceluxcars.app://reset-password?token_hash=...&type=recovery
      // 3. HTTP redirect: https://... which then redirects to the app
      
      final isPasswordResetLink = 
          (uri.scheme == 'com.choiceluxcars.app' && uri.host == 'reset-password') ||
          (uri.scheme == 'com.choiceluxcars.app' && uri.path.contains('reset-password')) ||
          (uri.fragment.contains('type=recovery') || uri.query.contains('type=recovery'));
      
      if (isPasswordResetLink) {
        Log.d('Password reset deep link detected');
        await _handlePasswordResetLink(uri);
      } else {
        Log.d('Deep link not recognized as password reset: scheme=${uri.scheme}, host=${uri.host}');
      }
    } catch (e) {
      Log.e('Error handling deep link: $e');
    }
  }

  /// Handle password reset deep link
  /// 
  /// Extracts the recovery token from the deep link URL and verifies it with Supabase.
  /// This creates a recovery session which triggers AuthChangeEvent.passwordRecovery.
  /// 
  /// The deep link format from Supabase can be:
  /// - Fragment: com.choiceluxcars.app://reset-password#access_token=...&type=recovery
  /// - Query params: com.choiceluxcars.app://reset-password?token_hash=...&type=recovery
  static Future<void> _handlePasswordResetLink(Uri uri) async {
    try {
      Log.d('Processing password reset deep link: $uri');

      // Check if we already have a recovery session
      final currentSession = SupabaseService.instance.currentSession;
      if (currentSession != null) {
        Log.d('Recovery session already exists, skipping token verification');
        return;
      }

      // Try to extract token from fragment first (implicit flow)
      Map<String, String> params = {};
      String? tokenHash;
      String? type;

      // Check fragment (for implicit flow: #access_token=...&type=recovery)
      if (uri.fragment.isNotEmpty) {
        params = Uri.splitQueryString(uri.fragment);
        tokenHash = params['access_token'];
        type = params['type'];
        Log.d('Found params in fragment: type=$type, hasToken=${tokenHash != null}');
      }

      // Check query parameters (for PKCE flow: ?token_hash=...&type=recovery)
      if (tokenHash == null && uri.queryParameters.isNotEmpty) {
        tokenHash = uri.queryParameters['token_hash'];
        type = uri.queryParameters['type'];
        Log.d('Found params in query: type=$type, hasToken=${tokenHash != null}');
      }

      if (type != 'recovery') {
        Log.e('Invalid password reset link type: $type');
        return;
      }

      if (tokenHash == null || tokenHash.isEmpty) {
        Log.e('No token found in password reset deep link (checked fragment and query)');
        return;
      }

      // For password recovery, Supabase uses PKCE flow with token_hash
      // We need to verify the token hash to create a recovery session
      Log.d('Verifying password reset token with Supabase...');
      
      // For password recovery deep links, Supabase sends a token_hash in the URL
      // We need to verify this token with Supabase to create a recovery session.
      // 
      // The Supabase Flutter SDK doesn't have a direct verifyOtp method with tokenHash,
      // so we'll make a direct HTTP request to Supabase's auth verify endpoint.
      
      Log.d('Password reset token extracted from deep link');
      Log.d('Token type: recovery, Token length: ${tokenHash.length}');
      
      // Check if Supabase automatically created a session from the deep link
      // Wait a moment for async processing
      await Future.delayed(const Duration(milliseconds: 500));
      
      final sessionAfterDelay = SupabaseService.instance.currentSession;
      if (sessionAfterDelay != null) {
        Log.d('Recovery session created automatically by Supabase SDK');
        return;
      }
      
      // If no session was created, manually verify the token via HTTP
      Log.d('No session created automatically, attempting manual verification...');
      
      try {
        // Get Supabase URL and key from constants
        final supabaseUrl = AppConstants.supabaseUrl;
        final anonKey = AppConstants.supabaseAnonKey;
        
        // Make HTTP request to Supabase's verify endpoint
        final verifyUrl = Uri.parse('$supabaseUrl/auth/v1/verify');
        final response = await http.post(
          verifyUrl,
          headers: {
            'Content-Type': 'application/json',
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
          },
          body: jsonEncode({
            'token_hash': tokenHash,
            'type': 'recovery',
          }),
        );
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final accessToken = responseData['access_token'] as String?;
          final refreshToken = responseData['refresh_token'] as String?;
          final userData = responseData['user'] as Map<String, dynamic>?;
          
          if (accessToken != null && refreshToken != null && userData != null) {
            Log.d('Recovery token verified successfully via HTTP');
            
            // Set the session in Supabase client using the refresh token
            // This will trigger AuthChangeEvent.passwordRecovery
            try {
              final supabase = SupabaseService.instance.supabase;
              
              // Use setSession with refresh token - this will create the session
              // and trigger the auth state change event
              final response = await supabase.auth.setSession(refreshToken);
              
              if (response.session != null) {
                Log.d('Recovery session created and set successfully');
                // AuthChangeEvent.passwordRecovery will fire automatically
                // Router guard will handle navigation to /reset-password
              } else {
                Log.e('setSession succeeded but no session in response');
              }
            } catch (sessionError) {
              Log.e('Error setting session from verification response: $sessionError');
            }
          } else {
            Log.e('Token verification succeeded but missing required fields in response');
            Log.e('Response data: $responseData');
          }
        } else {
          Log.e('Token verification failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        Log.e('Error verifying recovery token via HTTP: $e');
      }
    } catch (e, stackTrace) {
      Log.e('Error handling password reset deep link: $e');
      Log.e('Stack trace: $stackTrace');
    }
  }
}
