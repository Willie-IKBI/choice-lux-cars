import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';
import 'package:choice_lux_cars/core/utils/auth_error_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

// User Profile Model
class UserProfile {
  final String id;
  final String? displayName;
  final String? role;
  final String? address;
  final String? number;
  final String? kin;
  final String? kinNumber;
  final String? profileImage;
  final String? status;

  UserProfile({
    required this.id,
    this.displayName,
    this.role,
    this.address,
    this.number,
    this.kin,
    this.kinNumber,
    this.profileImage,
    this.status,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      displayName: map['display_name'],
      role: map['role'],
      address: map['address'],
      number: map['number'],
      kin: map['kin'],
      kinNumber: map['kin_number'],
      profileImage: map['profile_image'],
      status: map['status'],
    );
  }

  String get displayNameOrEmail =>
      displayName?.isNotEmpty == true ? displayName! : 'User';
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  final SupabaseService _supabaseService = SupabaseService.instance;
  FirebaseService? _firebaseService;

  void _initializeAuth() {
    try {
      // Set initial state based on current session
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        state = AsyncValue.data(currentUser);
        // Check and update FCM token for existing user
        _handleFCMTokenUpdate(currentUser.id);
      } else {
        state = const AsyncValue.data(null);
      }

      // Listen to auth state changes
      _supabaseService.authStateChanges.listen(
        (data) {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          Log.d('Auth state change: $event');

          if (event == AuthChangeEvent.signedIn && session != null) {
            state = AsyncValue.data(session.user);

            // Handle FCM token update for newly signed in user
            _handleFCMTokenUpdate(session.user.id);
          } else if (event == AuthChangeEvent.signedOut) {
            state = const AsyncValue.data(null);
          } else if (event == AuthChangeEvent.passwordRecovery) {
            // Handle password recovery event - user clicked reset link
            Log.d(
              'Password recovery event detected - user should be redirected to reset password screen',
            );
            // The user is now authenticated with a recovery session
            if (session != null) {
              state = AsyncValue.data(session.user);
              // Set password recovery state
              setPasswordRecovery(true);
            }
          }
        },
        onError: (error) {
          Log.e('Auth state change error: $error');
          // Set to not authenticated instead of error to allow app to continue
          state = const AsyncValue.data(null);
        },
      );
    } catch (error) {
      Log.e('Error initializing auth: $error');
      // Set to not authenticated instead of error to allow app to continue
      state = const AsyncValue.data(null);
    }
  }

  // Handle FCM token update
  Future<void> _handleFCMTokenUpdate(String userId) async {
    try {
      // Try to get Firebase service instance
      _firebaseService ??= FirebaseService.instance;

      // Request notification permissions
      await _firebaseService!.requestNotificationPermissions();

      // Check if FCM token needs updating
      bool shouldUpdate = await _firebaseService!.shouldUpdateFCMToken(userId);
      if (shouldUpdate) {
        await _firebaseService!.updateFCMTokenInProfile(userId);
      }
    } catch (error) {
      Log.e('Error handling FCM token update: $error');
      // Don't fail authentication if FCM token update fails
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      _setErrorState('Please enter both email and password.');
      return;
    }

    state = const AsyncValue.loading();

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AsyncValue.data(response.user);
        // Handle FCM token update after successful sign in
        _handleFCMTokenUpdate(response.user!.id);
      } else {
        _setErrorState('Login failed. Please check your credentials.');
      }
    } catch (error) {
      Log.e('Supabase signIn error: $error');
      Log.d('Error type: ${error.runtimeType}');
      Log.d('Error string: ${error.toString()}');

      // Use centralized error handling utility to convert to safe AuthError
      final authError = AuthErrorUtils.toAuthError(error);
      Log.d('Setting error state with message: ${authError.message}');
      _setErrorState(authError.message);
    }
  }

  // Helper method to set error state safely
  void _setErrorState(String errorMessage) {
    try {
      // Create a safe error object
      final error = Exception(errorMessage);
      state = AsyncValue.error(error, StackTrace.empty);
    } catch (e) {
      Log.e('Error setting error state: $e');
      // Fallback to data state with null user
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      state = const AsyncValue.loading();
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        userData: {
          'display_name': displayName,
          'role': 'unassigned', // New users are unassigned by default
        },
      );

      if (response.user != null) {
        // Create profile record
        await _supabaseService.updateProfile(
          userId: response.user!.id,
          data: {
            'id': response.user!.id,
            'display_name': displayName,
            'role': 'unassigned', // New users are unassigned by default
            'status': 'unassigned',
          },
        );

        state = AsyncValue.data(response.user);
        // Handle FCM token update after successful sign up
        _handleFCMTokenUpdate(response.user!.id);
      } else {
        _setErrorState('Registration failed. Please try again.');
      }
    } catch (error) {
      // Use centralized error handling utility to convert to safe AuthError
      final authError = AuthErrorUtils.toAuthError(error);
      _setErrorState(authError.message);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
      state = const AsyncValue.data(null);
    } catch (error) {
      // Use centralized error handling utility to convert to safe AuthError
      final authError = AuthErrorUtils.toAuthError(error);
      _setErrorState(authError.message);
    }
  }

  void clearError() {
    // If there's an error, reset to the current user state
    final currentUser = _supabaseService.currentUser;
    state = AsyncValue.data(currentUser);
  }

  // Forgot password methods
  Future<bool> resetPassword({required String email}) async {
    try {
      await _supabaseService.resetPassword(email: email);
      // Set password recovery flag when reset is requested
      setPasswordRecovery(true);
      Log.d('Password recovery requested for: $email');
      return true;
    } catch (error) {
      Log.e('Reset password error: $error');
      final authError = AuthErrorUtils.toAuthError(error);
      _setErrorState(authError.message);
      return false;
    }
  }

  Future<bool> updatePassword({required String newPassword}) async {
    try {
      await _supabaseService.updatePassword(newPassword: newPassword);
      return true;
    } catch (error) {
      Log.e('Update password error: $error');
      final authError = AuthErrorUtils.toAuthError(error);
      _setErrorState(authError.message);
      return false;
    }
  }

  User? get currentUser => state.value;
  bool get isAuthenticated => currentUser != null;
  bool get isLoading => state.isLoading;

  // Track password recovery state
  bool _isPasswordRecovery = false;
  bool get isPasswordRecovery => _isPasswordRecovery;

  // Set password recovery state
  void setPasswordRecovery(bool isRecovery) {
    _isPasswordRecovery = isRecovery;
  }
}

// User Profile Notifier
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  UserProfileNotifier(this._authNotifier) : super(const AsyncValue.loading()) {
    _initializeProfile();
  }

  final AuthNotifier _authNotifier;
  final SupabaseService _supabaseService = SupabaseService.instance;

  void _initializeProfile() {
    // Listen to auth state changes and update profile accordingly
    _authNotifier.addListener((authState) {
      final user = authState.value;
      if (user != null) {
        _loadProfile(user.id);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      state = const AsyncValue.loading();
      final profileData = await _supabaseService.getProfile(userId);

      if (profileData != null) {
        final profile = UserProfile.fromMap(profileData);
        state = AsyncValue.data(profile);
      } else {
        // If no profile exists, create a default one
        final defaultProfile = UserProfile(
          id: userId,
          displayName: null,
          role: null,
        );
        state = AsyncValue.data(defaultProfile);
      }
    } catch (error) {
      Log.e('Error loading profile: $error');
      // Create a default profile on error
      final defaultProfile = UserProfile(
        id: userId,
        displayName: null,
        role: null,
      );
      state = AsyncValue.data(defaultProfile);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final currentProfile = state.value;
      if (currentProfile == null) return;

      await _supabaseService.updateProfile(
        userId: currentProfile.id,
        data: data,
      );

      // Reload profile after update
      await _loadProfile(currentProfile.id);
    } catch (error) {
      Log.e('Error updating profile: $error');
      // Use centralized error handling utility to convert to safe AuthError
      final authError = AuthErrorUtils.toAuthError(error);
      _setErrorState(authError.message);
    }
  }

  UserProfile? get currentProfile => state.value;
  bool get isLoading => state.isLoading;

  // Helper method to set error state safely
  void _setErrorState(String errorMessage) {
    try {
      // Create a safe error object
      final error = Exception(errorMessage);
      state = AsyncValue.error(error, StackTrace.empty);
    } catch (e) {
      Log.e('Error setting error state: $e');
      // Fallback to data state with null profile
      state = const AsyncValue.data(null);
    }
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);

// User Profile provider
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
      (ref) => UserProfileNotifier(ref.read(authProvider.notifier)),
    );

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  try {
    final authState = ref.watch(authProvider);
    return authState.value != null;
  } catch (e) {
    Log.e('Error in isAuthenticatedProvider: $e');
    return false;
  }
});

final currentUserProvider = Provider<User?>((ref) {
  try {
    final authState = ref.watch(authProvider);
    return authState.value;
  } catch (e) {
    Log.e('Error in currentUserProvider: $e');
    return null;
  }
});

final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  try {
    final profileState = ref.watch(userProfileProvider);
    return profileState.value;
  } catch (e) {
    Log.e('Error in currentUserProfileProvider: $e');
    return null;
  }
});
