import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:choice_lux_cars/core/constants.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
          apiKey: 'AIzaSyDYZG-hSZIbfhktZmErbpIXWqNrFC_lLyY',
          appId: '1:522491134348:android:3035a4d8b64c22d4b7d6a9',
          messagingSenderId: '522491134348',
          projectId: 'choice-lux-cars-8d510',
          storageBucket: 'choice-lux-cars-8d510.firebasestorage.app',
        );
      }

      await Firebase.initializeApp(options: options);
      print('Firebase initialized successfully for ${kIsWeb ? 'Web' : 'Mobile'}');
    } catch (error) {
      print('Failed to initialize Firebase: $error');
      // Don't rethrow Firebase initialization errors to prevent app crashes
      print('Continuing without Firebase...');
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      // Skip FCM on web during development
      if (kIsWeb) {
        print('Skipping FCM permissions on web');
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

      print('User granted permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (error) {
      print('Error requesting notification permissions: $error');
      return false;
    }
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      // Skip FCM on web during development
      if (kIsWeb) {
        print('Skipping FCM token on web');
        return null;
      }

      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (error) {
      print('Error getting FCM token: $error');
      return null;
    }
  }

  // Update FCM token in Supabase profile
  Future<void> updateFCMTokenInProfile(String userId) async {
    try {
      // Skip FCM on web during development
      if (kIsWeb) {
        print('Skipping FCM token update on web');
        return;
      }

      String? token = await getFCMToken();
      if (token != null) {
        await _supabaseService.updateProfile(
          userId: userId,
          data: {
            'fcm_token': token,
          },
        );
        print('FCM token updated in profile for user: $userId');
      }
    } catch (error) {
      print('Error updating FCM token in profile: $error');
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
      print('Error checking FCM token: $error');
      return false;
    }
  }

  // Setup FCM token refresh listener
  void setupTokenRefreshListener() {
    // Skip FCM on web during development
    if (kIsWeb) {
      print('Skipping FCM token refresh listener on web');
      return;
    }

    _messaging.onTokenRefresh.listen((token) {
      print('FCM token refreshed: $token');
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
      print('Skipping FCM foreground message handler on web');
      return;
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  // Setup background message handler
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
  }
} 