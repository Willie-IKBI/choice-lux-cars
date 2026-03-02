import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:choice_lux_cars/app/app.dart';
import 'package:choice_lux_cars/core/services/firebase_service.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/constants.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      Log.e('FlutterError: ${details.exceptionAsString()}');
      Log.e('Stack: ${details.stack}');
    };

    try {
      Log.d('Initializing Choice Lux Cars app...');

      try {
        GoogleFonts.config.allowRuntimeFetching = true;
        Log.d('GoogleFonts runtime fetching enabled');
      } catch (e) {
        Log.e('Failed to configure GoogleFonts: $e');
      }

      // Validate Supabase config before init (prevents 405 AuthUnknownException when URL is empty)
      final supabaseUrl = AppConstants.supabaseUrl;
      final supabaseAnonKey = AppConstants.supabaseAnonKey;
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception(
          'Supabase config missing at build time. '
          'Set SUPABASE_URL and SUPABASE_ANON_KEY (or NEXT_PUBLIC_* variants) in Vercel Environment Variables, '
          'then redeploy with "Clear build cache".',
        );
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      Log.d('Supabase initialized successfully');

      try {
        await FirebaseService.initialize();
        Log.d('Firebase initialized successfully');
        
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        await _requestNotificationPermissions();
        await _setupFCMToken();
        
      } catch (error) {
        Log.e('Firebase initialization failed: $error');
        Log.d('Continuing without Firebase...');
      }

      Log.d('App initialization completed successfully');

      runApp(const ProviderScope(child: ChoiceLuxCarsApp()));
    } catch (error) {
      Log.e('Failed to initialize app: $error');
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Failed to initialize app: $error')),
          ),
        ),
      );
    }
  }, (error, stackTrace) {
    Log.e('Unhandled error: $error');
    Log.e('Stack trace: $stackTrace');
  });
}

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Log.d('Handling a background message: ${message.messageId}');
  Log.d('Background message data: ${message.data}');
  Log.d('Background message notification: ${message.notification?.title}');

  // Initialize local notifications for background messages
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create notification channel (required for Android, especially when app is terminated)
  // This ensures the channel exists before showing notifications
  if (!kIsWeb) {
    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'choice_lux_cars_channel', // MUST match channelId used in notification details
          'Choice Lux Cars Notifications',
          description: 'Notifications for job updates, assignments, and system alerts',
          importance: Importance.high,
          playSound: true,
        );

        await androidPlugin.createNotificationChannel(channel);
        Log.d('Background handler: Notification channel created');
      }
    } catch (e) {
      Log.e('Background handler: Error creating notification channel: $e');
      // Continue anyway - channel might already exist
    }
  }

  // Show system notification for background messages
  final title = message.notification?.title ?? 'Choice Lux Cars';
  final body = message.notification?.body ?? 'New notification received';

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'choice_lux_cars_channel',
    'Choice Lux Cars Notifications',
    channelDescription: 'Notifications for job updates, assignments, and system alerts',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    notificationDetails,
    payload: jsonEncode(message.data), // Use JSON string for proper parsing
  );

  Log.d('Background notification shown');
}

// Request notification permissions
Future<void> _requestNotificationPermissions() async {
  try {
    final messaging = FirebaseMessaging.instance;
    
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: true,
    );
    
    Log.d('Notification permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      Log.d('Notification permissions granted');
    } else {
      Log.d('Notification permissions denied');
    }
  } catch (error) {
    Log.e('Error requesting notification permissions: $error');
  }
}

// Setup FCM token
Future<void> _setupFCMToken() async {
  try {
    final messaging = FirebaseMessaging.instance;
    
    Log.d('Setting up FCM token (platform: ${kIsWeb ? "web" : "mobile"})...');
    
    // Get FCM token (web uses VAPID via FirebaseService)
    final token = await FirebaseService.instance.getFCMToken();
    if (token != null) {
      Log.d('FCM Token obtained: ${token.substring(0, 20)}...');
      
    // Centralized writer handles saving (Auth flow)
    Log.d('FCM Token obtained; saving is handled by centralized writer');
    } else {
      Log.d('No FCM token available - may need to grant permissions');
      if (kIsWeb) {
        Log.d('Web: Ensure notification permissions are granted and VAPID key is configured');
      }
    }
    
    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      Log.d('FCM token refreshed: ${newToken.substring(0, 20)}...');
      
    // Centralized writer handles saving (Auth flow)
    });
    
  } catch (error) {
    Log.e('Error setting up FCM token: $error');
    if (kIsWeb) {
      Log.e('Web FCM setup error details: $error');
    }
  }
}

// Save FCM token to user profile (platform-specific)
// Centralized profile save handled via FirebaseService/Auth flow
