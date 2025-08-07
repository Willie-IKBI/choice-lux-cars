import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize(WidgetRef ref) async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token and save to user profile
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen(_saveFCMToken);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message, ref);
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message, ref);
      });
    }
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      // Get current user ID
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        print('No current user found for FCM token save');
        return;
      }
      
      // Save token to user profile in Supabase
      await SupabaseService.instance.updateProfile(
        userId: currentUser.id,
        data: {
          'fcm_token': token,
        },
      );
      print('FCM token saved successfully');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message, WidgetRef ref) {
    if (message.data['action'] == 'new_job_assigned') {
      // Show in-app notification
      _showJobAssignmentNotification(message.data['job_id'], ref);
    }
  }

  static void _handleNotificationTap(RemoteMessage message, WidgetRef ref) {
    if (message.data['action'] == 'new_job_assigned') {
      // Navigate to job detail
      _navigateToJobDetail(message.data['job_id'], ref);
    }
  }

  static void _showJobAssignmentNotification(String jobId, WidgetRef ref) {
    // Show snackbar or custom notification
    final context = ref.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚗 New job assigned! Tap to view details.'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _navigateToJobDetail(jobId, ref),
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }
  }

  static void _navigateToJobDetail(String jobId, WidgetRef ref) {
    // Navigate to job summary screen
    final context = ref.context;
    if (context != null) {
      context.go('/jobs/$jobId/summary');
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  if (message.data['action'] == 'new_job_assigned') {
    // Could show local notification here
    print('Background message received: ${message.data}');
  }
} 