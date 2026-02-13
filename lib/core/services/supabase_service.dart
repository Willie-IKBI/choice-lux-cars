import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for Supabase initialization and session management
///
/// This service focuses only on:
/// - Initialization and configuration
/// - Session management and authentication
/// - Profile management for current user
///
/// All data access is now handled by feature-specific repositories.
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  /// Get the current Supabase client instance
  SupabaseClient get supabase => Supabase.instance.client;

  /// Get the current authenticated user
  User? get currentUser => supabase.auth.currentUser;

  /// Get the current session
  Session? get currentSession => supabase.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      Log.d('Signing out user: ${currentUser?.id}');
      await supabase.auth.signOut();
      Log.d('User signed out successfully');
    } catch (error) {
      Log.e('Error signing out: $error');
      rethrow;
    }
  }

  /// Get user profile from profiles table
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      Log.d('Getting profile for user: $userId');

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        Log.d('Profile found for user: $userId');
        return response;
      } else {
        Log.d('No profile found for user: $userId');
        return null;
      }
    } catch (error) {
      Log.e('Error getting profile: $error');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      Log.d('Updating profile for user: $userId');

      // Whitelist allowed profile fields and filter out null/empty values.
      // Prevents 400s from immutable/unknown columns (e.g., id, email).
      const allowedKeys = {
        'display_name',
        'role',
        'status',
        'branch_id',
        'profile_image',
        'fcm_token',
        'fcm_token_web',
      };

      final cleanData = <String, dynamic>{};
      data.forEach((key, value) {
        if (value == null) return;
        if (value is String && value.isEmpty) return;
        if (allowedKeys.contains(key)) {
          cleanData[key] = value;
        }
      });

      // No-op if nothing valid to update
      if (cleanData.isEmpty) {
        Log.d('No valid profile fields to update for user: $userId');
        return;
      }
      
      Log.d('Updating profile with data: $cleanData');

      await supabase.from('profiles').update(cleanData).eq('id', userId);

      Log.d('Profile updated successfully for user: $userId');
    } catch (error) {
      Log.e('Error updating profile: $error');
      // Enhanced error logging for debugging
      if (error is PostgrestException) {
        Log.e('Error updating profile (PostgrestException): ${error.message}');
        Log.e('Error details: ${error.details}');
        Log.e('Error hint: ${error.hint}');
        Log.e('Error code: ${error.code}');
      }
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Listen to user changes
  Stream<User?> get userChanges =>
      supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  /// Get user by ID from auth (if they exist in auth)
  Future<User?> getUserById(String userId) async {
    try {
      Log.d('Getting user by ID from auth: $userId');

      // Note: This is limited to auth users only
      // For full user profiles, use the UsersRepository
      if (currentUser?.id == userId) {
        return currentUser;
      }

      Log.d('User not found in current auth session: $userId');
      return null;
    } catch (error) {
      Log.e('Error getting user by ID: $error');
      return null;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      Log.d('Signing in user: $email');
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      Log.d('User signed in successfully: ${response.user?.id}');
      return response;
    } catch (error) {
      Log.e('Error signing in: $error');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      Log.d('Signing up user: $email');
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      Log.d('User signed up successfully: ${response.user?.id}');
      return response;
    } catch (error) {
      Log.e('Error signing up: $error');
      rethrow;
    }
  }

  /// Reset password
  /// For mobile: Uses OTP-based flow (no redirectTo)
  /// For web: Uses link-based flow (with redirectTo)
  Future<void> resetPassword({required String email}) async {
    try {
      Log.d('Resetting password for: $email');
      
      if (kIsWeb) {
        // For web, use link-based flow with redirect URL
        final uri = Uri.base;
        final redirectTo = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/reset-password';
        Log.d('Using web redirect URL: $redirectTo');
        
        await supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: redirectTo,
        );
        Log.d('Password reset email sent successfully with redirect: $redirectTo');
      } else {
        // For mobile (Android/iOS), use OTP-based flow (no redirectTo)
        // This will send an email with a 6-digit code instead of a link
        // The email template must be configured to show {{ .Token }} instead of {{ .ConfirmationURL }}
        await supabase.auth.resetPasswordForEmail(
          email,
          // No redirectTo for mobile - OTP will be sent instead
        );
        Log.d('Password reset OTP email sent successfully (mobile)');
      }
    } catch (error) {
      Log.e('Error resetting password: $error');
      rethrow;
    }
  }

  /// Verify OTP for password reset
  /// This creates a recovery session that allows the user to reset their password
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      Log.d('Verifying password reset OTP for: $email');
      
      // Use verifyOTP method (capital letters) for Supabase Flutter SDK
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      
      if (response.session != null) {
        Log.d('Password reset OTP verified successfully - recovery session created');
      } else {
        throw Exception('Failed to create recovery session');
      }
    } catch (error) {
      Log.e('Error verifying password reset OTP: $error');
      rethrow;
    }
  }

  /// Update password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      Log.d('Updating password for user: ${currentUser?.id}');
      
      // Check if we're in a recovery session
      final session = supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session found');
      }
      
      // For recovery sessions, we need to use updateUser with the recovery session
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      Log.d('Password updated successfully');
    } catch (error) {
      Log.e('Error updating password: $error');
      rethrow;
    }
  }

  // ===== BACKWARDS-COMPAT SHIMS =====
  // These methods provide compatibility with existing code while we transition to repositories
  // They are best-effort queries; adjust table/column names if needed

  /// Get jobs by client (compat shim)
  Future<List<Map<String, dynamic>>> getJobsByClient(String clientId) async {
    final c = Supabase.instance.client;
    return await c.from('jobs').select().eq('client_id', clientId);
  }

  /// Get completed jobs by client (compat shim)
  Future<List<Map<String, dynamic>>> getCompletedJobsByClient(
    String clientId,
  ) async {
    final c = Supabase.instance.client;
    return await c
        .from('jobs')
        .select()
        .eq('client_id', clientId)
        .eq('job_status', 'completed');
  }

  /// Get quotes by client (compat shim)
  Future<List<Map<String, dynamic>>> getQuotesByClient(String clientId) async {
    final c = Supabase.instance.client;
    return await c.from('quotes').select().eq('client_id', clientId);
  }

  /// Get completed jobs revenue by client (compat shim)
  Future<double> getCompletedJobsRevenueByClient(String clientId) async {
    final c = Supabase.instance.client;
    final rows = await c
        .from('jobs')
        .select('amount, job_status')
        .eq('client_id', clientId)
        .eq('job_status', 'completed');
    return rows.fold<double>(
      0.0,
      (sum, r) => sum + ((r['amount'] ?? 0) as num).toDouble(),
    );
  }

  /// Get client by ID (compat shim)
  Future<Map<String, dynamic>?> getClient(String clientId) async {
    final c = Supabase.instance.client;
    final rows = await c.from('clients').select().eq('id', clientId).limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Get agent by ID (compat shim)
  Future<Map<String, dynamic>?> getAgent(String agentId) async {
    final c = Supabase.instance.client;
    final rows = await c.from('agents').select().eq('id', agentId).limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Get vehicle by ID (compat shim)
  Future<Map<String, dynamic>?> getVehicle(String vehicleId) async {
    final c = Supabase.instance.client;
    final rows = await c.from('vehicles').select().eq('id', vehicleId).limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Get user by ID (compat shim)
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final c = Supabase.instance.client;
    final rows = await c.from('profiles').select().eq('id', userId).limit(1);
    return rows.isEmpty ? null : rows.first;
  }
}
