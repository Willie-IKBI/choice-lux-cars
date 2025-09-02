import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:choice_lux_cars/core/constants.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:choice_lux_cars/core/logging/log.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      FirebaseOptions options;

      if (kIsWeb) {
        // Web configuration
        options = const FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          authDomain: AppConstants.firebaseAuthDomain,
          projectId: AppConstants.firebaseProjectId,
          storageBucket: AppConstants.firebaseStorageBucket,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          appId: AppConstants.firebaseAppId,
        );
      } else {
        // Mobile configuration (Android/iOS)
        options = const FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          appId: AppConstants.firebaseAppId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          projectId: AppConstants.firebaseProjectId,
          storageBucket: AppConstants.firebaseStorageBucket,
        );
      }

      await Firebase.initializeApp(options: options);
      Log.d(
        'Firebase initialized successfully for ${kIsWeb ? 'Web' : 'Mobile'}',
      );
    } catch (error) {
      Log.e('Failed to initialize Firebase: $error');
      // Don't rethrow Firebase initialization errors to prevent app crashes
      Log.d('Continuing without Firebase...');
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      // Skip FCM on web during development
      if (kIsWeb) {
        Log.d('Skipping FCM permissions on web');
        return false;
      }

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Log.d('User granted permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (error) {
      Log.e('Error requesting notification permissions: $error');
      return false;
    }
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      // Skip FCM on web during development
      if (kIsWeb) {
        Log.d('Skipping FCM token on web');
        return null;
      }

      String? token = await _messaging.getToken();
      Log.d('FCM Token: $token');
      return token;
    } catch (error) {
      Log.e('Error getting FCM token: $error');
      return null;
    }
  }

  // Update FCM token in Supabase profile
  Future<void> updateFCMTokenInProfile(String userId) async {
    try {
      // Skip FCM on web during development
      if (kIsWeb) {
        Log.d('Skipping FCM token update on web');
        return;
      }

      String? token = await getFCMToken();
      if (token != null) {
        await _supabaseService.updateProfile(
          userId: userId,
          data: {'fcm_token': token},
        );
        Log.d('FCM token updated in profile for user: $userId');
      }
    } catch (error) {
      Log.e('Error updating FCM token in profile: $error');
    }
  }

  // Check if FCM token needs updating
  Future<bool> shouldUpdateFCMToken(String userId) async {
    try {
      // Skip FCM on web during development
      if (kIsWeb) {
        return false;
      }

      // Get current token
      String? currentToken = await getFCMToken();
      if (currentToken == null) return false;

      // Get profile from Supabase
      final profile = await _supabaseService.getProfile(userId);
      if (profile == null) return true;

      // Check if token is different or missing
      String? storedToken = profile['fcm_token'];
      return storedToken != currentToken;
    } catch (error) {
      Log.e('Error checking FCM token: $error');
      return false;
    }
  }

  // Setup FCM token refresh listener
  void setupTokenRefreshListener() {
    // Skip FCM on web during development
    if (kIsWeb) {
      Log.d('Skipping FCM token refresh listener on web');
      return;
    }

    _messaging.onTokenRefresh.listen((token) {
      Log.d('FCM token refreshed: $token');
      // Update token in profile if user is authenticated
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        updateFCMTokenInProfile(currentUser.id);
      }
    });
  }

  // Setup foreground message handler
  void setupForegroundMessageHandler() {
    // Skip FCM on web during development
    if (kIsWeb) {
      Log.d('Skipping FCM foreground message handler on web');
      return;
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Log.d('Got a message whilst in the foreground!');
      Log.d('Message data: ${message.data}');

      if (message.notification != null) {
        Log.d('Message also contained a notification: ${message.notification}');
      }
    });
  }

  // Setup background message handler
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    Log.d('Handling a background message: ${message.messageId}');
  }
}
