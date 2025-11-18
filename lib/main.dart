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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Log.d('Initializing Choice Lux Cars app...');

    // Initialize Supabase
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    Log.d('Supabase initialized successfully');

    // Initialize Firebase (optional, won't crash if fails)
    try {
      await FirebaseService.initialize();
      Log.d('Firebase initialized successfully');
      
      // Set up FCM background message handler (must be top-level)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Note: FCM initialization (permissions, token, channel creation) is handled by 
      // FCMService.initialize() which is called in app.dart after the widget tree is built
      // This ensures proper context and avoids duplicate initialization
      
    } catch (error) {
      Log.e('Firebase initialization failed: $error');
      Log.d('Continuing without Firebase...');
    }

    Log.d('App initialization completed successfully');

    runApp(const ProviderScope(child: ChoiceLuxCarsApp()));
  } catch (error) {
    Log.e('Failed to initialize app: $error');
    // Show error screen or fallback
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to initialize app: $error')),
        ),
      ),
    );
  }
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

// Note: FCM token setup and permission requests are now handled by FCMService.initialize()
// which is called in app.dart. This avoids duplicate initialization and ensures proper context.
