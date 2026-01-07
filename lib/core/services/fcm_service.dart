import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _currentToken;
  static bool _isInitialized = false;

  /// Initialize FCM service
  static Future<bool> initialize(WidgetRef ref) async {
    if (_isInitialized) {
      Log.d('FCMService: Already initialized');
      return true;
    }

    try {
      Log.d('FCMService: Initializing...');

      // Initialize local notifications for Android (if not web)
      if (!kIsWeb) {
        try {
          const AndroidInitializationSettings initializationSettingsAndroid =
              AndroidInitializationSettings('@mipmap/ic_launcher');

          const InitializationSettings initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid,
          );

          await _localNotifications.initialize(initializationSettings);
          Log.d('FCMService: Local notifications initialized');
        } catch (e) {
          Log.e('FCMService: Error initializing local notifications: $e');
          // Continue anyway - notifications may still work
        }

        // Create Android notification channel (must exist before FCM shows notifications)
        try {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'choice_lux_cars_channel', // MUST match channelId used in FCM payload
            'Choice Lux Cars Notifications',
            description:
                'Notifications for job updates, assignments, and system alerts',
            importance: Importance.high,
            playSound: true,
          );

          final androidPlugin = _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

          await androidPlugin?.createNotificationChannel(channel);
          Log.d('FCMService: Android notification channel created');
        } catch (e) {
          Log.e('FCMService: Error creating notification channel: $e');
        }
      }

      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
        announcement: true,
      );

      Log.d('FCMService: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token (do not persist here; centralized writer handles saving)
        _currentToken = await _messaging.getToken();
        if (_currentToken != null) {
          Log.d(
            'FCMService: Token obtained: ${_currentToken!.substring(0, 20)}...',
          );
        }

        // Handle token refresh (do not persist here; centralized writer handles saving)
        _messaging.onTokenRefresh.listen((token) async {
          _currentToken = token;
          Log.d('FCMService: Token refreshed: ${token.substring(0, 20)}...');
        });

        // Set up message handlers
        _setupMessageHandlers(ref);

        _isInitialized = true;
        Log.d('FCMService: Initialization complete');
        return true;
      } else {
        Log.d('FCMService: Permission denied');
        return false;
      }
    } catch (e) {
      Log.e('FCMService: Initialization failed: $e');
      return false;
    }
  }

  /// Set up message handlers
  static void _setupMessageHandlers(WidgetRef ref) {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _handleForegroundMessage(message, ref);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message, ref);
    });

    // Handle initial notification when app is opened from terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message, ref);
      }
    });
  }

  /// Save FCM token to user profile (unused - centralized writer handles saving)
  static Future<void> _saveFCMToken(String token) async {
    try {
      // Get current user ID
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        Log.d('FCMService: No current user found for FCM token save');
        return;
      }

      // Save token to user profile in Supabase (platform-specific)
      final updateData = <String, dynamic>{};
      
      if (kIsWeb) {
        updateData['fcm_token_web'] = token;
      } else {
        updateData['fcm_token'] = token;
      }
      
      await SupabaseService.instance.updateProfile(
        userId: currentUser.id,
        data: updateData,
      );
      Log.d('FCMService: FCM token saved successfully (platform: ${kIsWeb ? "web" : "mobile"})');
    } catch (e) {
      Log.e('FCMService: Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message, WidgetRef ref) async {
    Log.d('FCMService: Foreground message received: ${message.data}');

    final action = message.data['action'];
    final jobId = message.data['job_id'];
    final title = message.notification?.title ?? 'Choice Lux Cars';
    final messageText =
        message.notification?.body ?? 'New notification received';

    // Update notification count and refresh notification list
    ref.read(notificationProvider.notifier).updateUnreadCount();
    // Reload notifications to ensure new notification appears in-app immediately
    ref.read(notificationProvider.notifier).loadNotifications();

    // Show system notification (required for foreground messages on Android)
    if (!kIsWeb) {
      await _showSystemNotification(
        title: title,
        body: messageText,
        data: message.data,
      );
    } else {
      // Web: Use browser Notification API for foreground messages
      await _showWebNotification(
        title: title,
        body: messageText,
        data: message.data,
      );
    }

    // Show in-app notification based on type
    switch (action) {
      case 'new_job_assigned':
      case 'job_reassigned':
        _showJobNotification(messageText, jobId, ref, 'View Job');
        break;
      case 'job_cancelled':
        _showJobNotification(messageText, jobId, ref, 'View Details');
        break;
      case 'job_status_changed':
        _showJobNotification(messageText, jobId, ref, 'View Job');
        break;
      case 'payment_reminder':
        _showPaymentNotification(messageText, jobId, ref);
        break;
      case 'system_alert':
        _showSystemAlert(messageText, ref);
        break;
      default:
        _showGenericNotification(messageText, ref);
    }
  }

  /// Show system notification using flutter_local_notifications
  static Future<void> _showSystemNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
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

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data), // Use JSON string instead of toString()
      );

      Log.d('FCMService: System notification shown');
    } catch (e) {
      Log.e('FCMService: Error showing system notification: $e');
    }
  }

  /// Show web notification using browser Notification API
  static Future<void> _showWebNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Check if browser supports notifications
      if (kIsWeb) {
        // Request permission if not granted
        final permission = await _requestWebNotificationPermission();
        if (permission != 'granted') {
          Log.d('FCMService: Web notification permission not granted');
          return;
        }

        // Show notification using browser API
        // Note: This requires dart:html, but we'll use a platform channel approach
        // For now, web notifications are handled by the service worker
        // This function is a placeholder for future enhancement
        Log.d('FCMService: Web notification would be shown (handled by service worker)');
      }
    } catch (e) {
      Log.e('FCMService: Error showing web notification: $e');
    }
  }

  /// Request web notification permission
  static Future<String> _requestWebNotificationPermission() async {
    // Web notifications are handled by service worker
    // Permission is requested when getting FCM token
    return 'granted'; // Assume granted if FCM token was obtained
  }

  /// Handle notification taps
  static void _handleNotificationTap(RemoteMessage message, WidgetRef ref) {
    Log.d('FCMService: Notification tapped: ${message.data}');

    final action = message.data['action'];
    final jobId = message.data['job_id'];
    final route = message.data['route'];

    // Navigate based on action data
    if (route != null) {
      _navigateToRoute(route, ref);
    } else if (action == 'view_job' && jobId != null) {
      _navigateToJobDetail(jobId, ref);
    } else if (action == 'confirm_job' && jobId != null) {
      _navigateToJobDetail(jobId, ref);
    } else {
      // Default navigation to notifications screen
      _navigateToNotifications(ref);
    }
  }

  /// Show job-related notification
  static void _showJobNotification(
    String message,
    String? jobId,
    WidgetRef ref,
    String actionText,
  ) {
    final context = ref.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.work, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        action: SnackBarAction(
          label: actionText,
          onPressed: () => jobId != null
              ? _navigateToJobDetail(jobId, ref)
              : _navigateToNotifications(ref),
        ),
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show payment notification
  static void _showPaymentNotification(
    String message,
    String? jobId,
    WidgetRef ref,
  ) {
    final context = ref.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.payment, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        action: SnackBarAction(
          label: 'View Payment',
          onPressed: () => jobId != null
              ? _navigateToJobDetail(jobId, ref)
              : _navigateToNotifications(ref),
        ),
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show system alert
  static void _showSystemAlert(String message, WidgetRef ref) {
    final context = ref.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show generic notification
  static void _showGenericNotification(String message, WidgetRef ref) {
    final context = ref.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateToNotifications(ref),
        ),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Navigate to specific route
  static void _navigateToRoute(String route, WidgetRef ref) {
    final context = ref.context;
    if (context == null) return;

    try {
      context.go(route);
      Log.d('FCMService: Navigated to route: $route');
    } catch (e) {
      Log.e('FCMService: Navigation error: $e');
      // Fallback to notifications screen
      _navigateToNotifications(ref);
    }
  }

  /// Navigate to job detail
  static void _navigateToJobDetail(String jobId, WidgetRef ref) {
    final context = ref.context;
    if (context == null) return;

    try {
      context.go('/jobs/$jobId/summary');
      Log.d('FCMService: Navigated to job: $jobId');
    } catch (e) {
      Log.e('FCMService: Job navigation error: $e');
      _navigateToNotifications(ref);
    }
  }

  /// Navigate to notifications screen
  static void _navigateToNotifications(WidgetRef ref) {
    final context = ref.context;
    if (context == null) return;

    try {
      context.go('/notifications');
      Log.d('FCMService: Navigated to notifications');
    } catch (e) {
      Log.e('FCMService: Notifications navigation error: $e');
    }
  }

  /// Get current FCM token
  static String? get currentToken => _currentToken;

  /// Check if FCM is initialized
  static bool get isInitialized => _isInitialized;

  /// Refresh FCM token
  static Future<String?> refreshToken() async {
    try {
      _currentToken = await _messaging.getToken();
      return _currentToken;
    } catch (e) {
      Log.e('FCMService: Error refreshing token: $e');
      return null;
    }
  }

  /// Delete FCM token (for logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      Log.d('FCMService: Token deleted');
    } catch (e) {
      Log.e('FCMService: Error deleting token: $e');
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      Log.d('FCMService: Subscribed to topic: $topic');
    } catch (e) {
      Log.e('FCMService: Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      Log.d('FCMService: Unsubscribed from topic: $topic');
    } catch (e) {
      Log.e('FCMService: Error unsubscribing from topic: $e');
    }
  }
}

