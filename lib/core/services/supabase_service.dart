import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

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
      
      await supabase
          .from('profiles')
          .update(data)
          .eq('id', userId);

      Log.d('Profile updated successfully for user: $userId');
    } catch (error) {
      Log.e('Error updating profile: $error');
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Listen to user changes
  Stream<User?> get userChanges => supabase.auth.onUserChange;

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
} 