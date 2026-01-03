import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Router guards for authentication and authorization
///
/// This class provides centralized logic for route protection and access control.
/// It handles:
/// - Authentication checks
/// - Email verification requirements
/// - Role-based access control
/// - Password recovery flows
///
/// Usage:
/// ```dart
/// // In your GoRouter configuration:
/// redirect: (context, state) => RouterGuards.guardRoute(
///   user: authState.value,
///   currentRoute: state.matchedLocation,
///   isLoading: authState.isLoading,
///   hasError: authState.hasError,
///   isPasswordRecovery: authNotifier.isPasswordRecovery,
///   userRole: userProfile?.role,
/// ),
///
/// // For specific route protection:
/// if (!RouterGuards.isAuthenticated(user)) {
///   return '/login';
/// }
/// ```
class RouterGuards {
  /// Check if user is authenticated
  static bool isAuthenticated(User? user) {
    return user != null;
  }

  /// Check if user's email is verified
  /// Note: Supabase handles email verification automatically
  /// This method checks if the user has confirmed their email
  static bool isEmailVerified(User? user) {
    if (user == null) return false;

    // Check if email is confirmed (Supabase sets this after email verification)
    return user.emailConfirmedAt != null;
  }

  /// Check if user has an assigned role (not 'unassigned')
  static bool hasAssignedRole(String? role) {
    return role != null && role != 'unassigned';
  }

  /// Handle login-required routes
  static String? requireAuth(User? user, String currentRoute) {
    if (!isAuthenticated(user)) {
      Log.d('Router Guard - Authentication required, redirecting to login');
      return '/login';
    }
    return null;
  }

  /// Handle email verification required routes
  static String? requireEmailVerification(User? user, String currentRoute) {
    if (!isAuthenticated(user)) {
      Log.d('Router Guard - Authentication required, redirecting to login');
      return '/login';
    }

    if (!isEmailVerified(user)) {
      Log.d(
        'Router Guard - Email verification required, redirecting to pending approval',
      );
      return '/pending-approval';
    }

    return null;
  }

  /// Handle role-based access control
  static String? requireAssignedRole(User? user, String currentRoute) {
    if (!isAuthenticated(user)) {
      Log.d('Router Guard - Authentication required, redirecting to login');
      return '/login';
    }

    // For now, we'll assume users need an assigned role to access the app
    // This can be enhanced later with more granular role checking
    return null;
  }

  /// Check if user has specific role
  static bool hasRole(User? user, String role) {
    if (user == null) return false;
    // This would need to be enhanced based on your user model structure
    // For now, we'll assume role checking is done elsewhere
    return true;
  }

  /// Check if user can access admin routes
  static bool canAccessAdmin(User? user) {
    if (user == null) return false;
    // Add your admin role logic here
    return false;
  }

  /// Handle password recovery deep links
  static String? handlePasswordRecovery(
    User? user,
    bool isPasswordRecovery,
    String currentRoute,
  ) {
    // If user is in password recovery mode, they should stay on reset-password
    if (isPasswordRecovery && currentRoute == '/reset-password') {
      return null; // Allow them to stay on reset password screen
    }

    // If user is in password recovery mode but on wrong route, redirect to reset-password
    if (isPasswordRecovery && currentRoute != '/reset-password') {
      Log.d(
        'Router Guard - Password recovery mode, redirecting to reset password',
      );
      return '/reset-password';
    }

    return null;
  }

  /// Handle deep link routing
  static String? handleDeepLink(String? deepLink, User? user) {
    if (deepLink == null) return null;

    // Handle password recovery deep links
    if (deepLink.contains('recovery_token') ||
        deepLink.contains('reset-password')) {
      if (isAuthenticated(user)) {
        return '/reset-password';
      } else {
        // User needs to authenticate first, then will be redirected
        return '/login';
      }
    }

    // Handle other deep link types here
    // Example: email verification, invite links, etc.

    return null;
  }

  /// Main router guard that combines all checks
  static String? guardRoute({
    required User? user,
    required String currentRoute,
    required bool isLoading,
    required bool hasError,
    required bool isPasswordRecovery,
    required String? userRole,
  }) {
    Log.d('Router Guard - Checking route: $currentRoute, user: ${user?.id}, isPasswordRecovery: $isPasswordRecovery, isLoading: $isLoading, hasError: $hasError');
    
    // Don't redirect while loading
    if (isLoading) {
      Log.d('Router Guard - Loading, no redirect');
      return null;
    }

    // Don't redirect on error, let the UI handle it
    if (hasError) {
      Log.d('Router Guard - Has error, no redirect');
      return null;
    }

    // Handle password recovery first - this takes absolute priority
    if (isPasswordRecovery) {
      Log.d('Router Guard - Password recovery mode active');
      final recoveryRedirect = handlePasswordRecovery(
        user,
        isPasswordRecovery,
        currentRoute,
      );
      if (recoveryRedirect != null) {
        Log.d('Router Guard - Password recovery redirect: $recoveryRedirect');
        return recoveryRedirect;
      }
      // If no redirect needed, allow the user to stay where they are
      Log.d('Router Guard - Password recovery mode, no redirect needed');
      return null;
    }

    // Define public routes that don't require authentication
    final publicRoutes = [
      '/login',
      '/signup',
      '/forgot-password',
      '/reset-password',
    ];

    // If not authenticated, only allow access to public routes
    if (!isAuthenticated(user)) {
      if (publicRoutes.contains(currentRoute)) {
        Log.d('Router Guard - Not authenticated, but on public route: $currentRoute');
        return null; // Allow access to public routes
      }
      Log.d('Router Guard - Not authenticated, redirecting to login');
      return '/login';
    }

    // User is authenticated, check role assignment
    if (userRole == null || userRole == 'unassigned') {
      if (currentRoute == '/pending-approval') {
        Log.d('Router Guard - User not assigned, but on pending approval route');
        return null; // Allow access to pending approval route
      }
      Log.d(
        'Router Guard - User not assigned, redirecting to pending approval',
      );
      return '/pending-approval';
    }

    // If user is assigned but on auth routes, redirect to dashboard
    if (publicRoutes.contains(currentRoute) ||
        currentRoute == '/pending-approval') {
      Log.d(
        'Router Guard - Authenticated user on auth route, redirecting to dashboard',
      );
      return '/';
    }

    // Check for super_admin-only routes
    if (currentRoute == '/settings') {
      if (userRole != 'super_admin') {
        Log.d('Router Guard - Settings route requires super_admin, redirecting to dashboard');
        return '/';
      }
    }

    // Allow access to protected routes
    Log.d('Router Guard - Allowing access to protected route: $currentRoute');
    return null;
  }
}
