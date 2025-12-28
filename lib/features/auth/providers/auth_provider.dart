import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';
import 'package:choice_lux_cars/core/services/preferences_service.dart';
import 'package:choice_lux_cars/core/services/job_deadline_check_service.dart';
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
  final int? branchId; // Branch allocation: NULL = Admin/National (can see all branches), non-null = specific branch assignment

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
    this.branchId,
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
      branchId: map['branch_id'] != null ? int.tryParse(map['branch_id'].toString()) : null,
    );
  }

  String get displayNameOrEmail =>
      displayName?.isNotEmpty == true ? displayName! : 'User';

  /// Check if user is an administrator (includes both administrator and super_admin)
  bool get isAdmin {
    final roleLower = role?.toLowerCase();
    return roleLower == 'administrator' || roleLower == 'super_admin';
  }

  /// Check if user is a super administrator
  bool get isSuperAdmin {
    return role?.toLowerCase() == 'super_admin';
  }

  /// Check if user is a manager
  bool get isManager {
    return role?.toLowerCase() == 'manager';
  }

  /// Check if user is a driver manager
  bool get isDriverManager {
    return role?.toLowerCase() == 'driver_manager';
  }

  /// Check if user is a driver
  bool get isDriver {
    return role?.toLowerCase() == 'driver';
  }

  /// Check if user has national access (admin or super_admin with no branch assignment)
  bool get hasNationalAccess {
    return isAdmin && branchId == null;
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  final SupabaseService _supabaseService = SupabaseService.instance;
  final PreferencesService _preferencesService = PreferencesService.instance;
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
          } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
            // Handle token refresh - keep user logged in
            Log.d('Token refreshed successfully, maintaining session');
            state = AsyncValue.data(session.user);
          } else if (event == AuthChangeEvent.userUpdated && session != null) {
            // Handle user update - keep user logged in
            Log.d('User updated, maintaining session');
            state = AsyncValue.data(session.user);
          } else if (event == AuthChangeEvent.signedOut) {
            Log.d('User signed out');
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
          } else if (session == null && state.value != null) {
            // Session lost but we had a user - try to recover
            Log.d('Session lost but user was logged in, attempting recovery...');
            _attemptSessionRecovery();
          }
        },
        onError: (error) {
          Log.e('Auth state change error: $error');
          // Don't immediately log out on error - try to recover session first
          final currentSession = _supabaseService.currentSession;
          if (currentSession != null) {
            Log.d('Error occurred but session still exists, maintaining state');
            state = AsyncValue.data(currentSession.user);
          } else {
            Log.d('Error occurred and no session, attempting recovery...');
            _attemptSessionRecovery();
          }
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
      Log.d('AuthProvider: Handling FCM token update for user: $userId');
      
      // Try to get Firebase service instance
      _firebaseService ??= FirebaseService.instance;

      // Request notification permissions
      final permissionGranted = await _firebaseService!.requestNotificationPermissions();
      Log.d('AuthProvider: Notification permissions granted: $permissionGranted');

      // Always try to get and save the token after login (web may need explicit fetch)
      // Get token directly and save it
      final token = await _firebaseService!.getFCMToken();
      if (token != null) {
        Log.d('AuthProvider: FCM token obtained, updating profile...');
        await _firebaseService!.updateFCMTokenInProfile(userId);
        Log.d('AuthProvider: FCM token updated successfully');
      } else {
        Log.d('AuthProvider: No FCM token available yet (may need permissions or VAPID key)');
        
        // For web, token might not be available immediately after permission request
        // Try again after a short delay
        if (kIsWeb) {
          Log.d('AuthProvider: Web platform - retrying token fetch after delay...');
          await Future.delayed(const Duration(seconds: 2));
          final retryToken = await _firebaseService!.getFCMToken();
          if (retryToken != null) {
            Log.d('AuthProvider: FCM token obtained on retry, updating profile...');
            await _firebaseService!.updateFCMTokenInProfile(userId);
          }
        }
      }
    } catch (error) {
      Log.e('Error handling FCM token update: $error');
      // Don't fail authentication if FCM token update fails
    }
  }

  // Handle remember me functionality
  Future<void> _handleRememberMe(bool rememberMe, String email, String password) async {
    try {
      // Save remember me preference
      await _preferencesService.setRememberMe(rememberMe);
      
      if (rememberMe) {
        // Save credentials for auto-login
        await _preferencesService.saveCredentials(email, password);
        Log.d('Credentials saved for remember me');
      } else {
        // Clear saved credentials if remember me is disabled
        await _preferencesService.clearSavedCredentials();
        Log.d('Saved credentials cleared');
      }
    } catch (error) {
      Log.e('Error handling remember me: $error');
      // Don't fail authentication if remember me handling fails
    }
  }

  // Attempt to recover session when it's lost unexpectedly
  Future<void> _attemptSessionRecovery() async {
    try {
      Log.d('Attempting session recovery...');
      
      // First, check if there's a valid session that just needs refresh
      final currentSession = _supabaseService.currentSession;
      if (currentSession != null) {
        Log.d('Session found, restoring user state');
        state = AsyncValue.data(currentSession.user);
        return;
      }

      // Try to refresh the session
      try {
        final refreshedSession = await _supabaseService.supabase.auth.refreshSession();
        if (refreshedSession.session != null) {
          Log.d('Session refreshed successfully');
          state = AsyncValue.data(refreshedSession.session!.user);
          return;
        }
      } catch (refreshError) {
        Log.d('Session refresh failed: $refreshError');
      }

      // If refresh failed, try remember me auto-login
      final rememberMe = await _preferencesService.getRememberMe();
      if (rememberMe) {
        final credentials = await _preferencesService.getSavedCredentials();
        final email = credentials['email'];
        final password = credentials['password'];
        
        if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
          Log.d('Attempting auto-login with saved credentials...');
          try {
            await signIn(email: email, password: password, rememberMe: true);
            Log.d('Auto-login successful');
            return;
          } catch (autoLoginError) {
            Log.e('Auto-login failed: $autoLoginError');
          }
        }
      }

      // If all recovery attempts failed, set to not authenticated
      Log.d('Session recovery failed, user must log in again');
      state = const AsyncValue.data(null);
    } catch (error) {
      Log.e('Error during session recovery: $error');
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn({
    required String email, 
    required String password,
    bool rememberMe = false,
  }) async {
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
        
        // Handle remember me functionality
        await _handleRememberMe(rememberMe, email, password);
        
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
      // Stop the deadline check service before signing out
      JobDeadlineCheckService.instance.stop();
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
    Log.d('Auth Provider - Setting password recovery state: $isRecovery');
    _isPasswordRecovery = isRecovery;
  }

  // Load saved credentials for remember me
  Future<Map<String, String?>> loadSavedCredentials() async {
    try {
      final rememberMe = await _preferencesService.getRememberMe();
      if (rememberMe) {
        return await _preferencesService.getSavedCredentials();
      }
      return {'email': null, 'password': null};
    } catch (error) {
      Log.e('Error loading saved credentials: $error');
      return {'email': null, 'password': null};
    }
  }

  // Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      return await _preferencesService.getRememberMe();
    } catch (error) {
      Log.e('Error checking remember me status: $error');
      return false;
    }
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
