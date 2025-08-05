import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';

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

  String get displayNameOrEmail => displayName?.isNotEmpty == true 
      ? displayName! 
      : 'User';
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
      _supabaseService.authStateChanges.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        print('Auth state change: $event');
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          state = AsyncValue.data(session.user);
          // Handle FCM token update for newly signed in user
          _handleFCMTokenUpdate(session.user.id);
        } else if (event == AuthChangeEvent.signedOut) {
          state = const AsyncValue.data(null);
        }
      }, onError: (error) {
        print('Auth state change error: $error');
        // Set to not authenticated instead of error to allow app to continue
        state = const AsyncValue.data(null);
      });
    } catch (error) {
      print('Error initializing auth: $error');
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
      print('Error handling FCM token update: $error');
      // Don't fail authentication if FCM token update fails
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Validate inputs first
      if (email.isEmpty || password.isEmpty) {
        state = AsyncValue.error(
          'Please enter both email and password.',
          StackTrace.current,
        );
        return;
      }
      
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        state = AsyncValue.data(response.user);
        // Handle FCM token update after successful sign in
        _handleFCMTokenUpdate(response.user!.id);
      } else {
        state = AsyncValue.error(
          'Login failed. Please check your credentials.',
          StackTrace.current,
        );
      }
    } catch (error) {
      print('Sign in error: $error');
      print('Error type: ${error.runtimeType}');
      print('Error string: ${error.toString()}');
      
      // Provide user-friendly error messages
      String errorMessage = 'An error occurred during login. Please try again.';
      
      final errorString = error.toString().toLowerCase();
      
      if (errorString.contains('invalid login credentials') || 
          errorString.contains('invalid email or password')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      } else if (errorString.contains('email not confirmed')) {
        errorMessage = 'Please check your email and confirm your account before signing in.';
      } else if (errorString.contains('too many requests') || 
                 errorString.contains('rate limit')) {
        errorMessage = 'Too many login attempts. Please wait a moment before trying again.';
      } else if (errorString.contains('user not found')) {
        errorMessage = 'No account found with this email address. Please check your email or sign up.';
      } else if (errorString.contains('network') || 
                 errorString.contains('connection') ||
                 errorString.contains('timeout')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorString.contains('server error') ||
                 errorString.contains('internal server error')) {
        errorMessage = 'Server error. Please try again later.';
      }
      
      print('Setting error state with message: $errorMessage');
      state = AsyncValue.error(errorMessage, StackTrace.current);
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
        state = AsyncValue.error(
          'Registration failed. Please try again.',
          StackTrace.current,
        );
      }
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
      state = const AsyncValue.data(null);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  void clearError() {
    // If there's an error, reset to the current user state
    final currentUser = _supabaseService.currentUser;
    state = AsyncValue.data(currentUser);
  }

  User? get currentUser => state.value;
  bool get isAuthenticated => currentUser != null;
  bool get isLoading => state.isLoading;
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
      print('Error loading profile: $error');
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
      print('Error updating profile: $error');
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  UserProfile? get currentProfile => state.value;
  bool get isLoading => state.isLoading;
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);

// User Profile provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
  (ref) => UserProfileNotifier(ref.read(authProvider.notifier)),
);

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value != null;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value;
});

final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final profileState = ref.watch(userProfileProvider);
  return profileState.value;
}); 