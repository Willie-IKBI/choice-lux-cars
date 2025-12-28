import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/notifications/models/notification.dart' as app_notification;
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get notifications
  Future<List<app_notification.AppNotification>> getNotifications({
    int limit = 1000,  // Increased from 50 to fetch more notifications
    int offset = 0,
    bool unreadOnly = false,
    String? notificationType,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      Log.d(
        '=== DEBUG: Fetching notifications for user: ${currentUser.id} ===',
      );
      Log.d('Limit: $limit, Offset: $offset');
      Log.d('Unread only: $unreadOnly');
      Log.d('Notification type: $notificationType');

      // Build query with all conditions
      var query = _supabase
          .from('app_notifications')
          .select()
          .eq('user_id', currentUser.id)
          .eq('is_hidden', false); // Only show non-hidden notifications

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      if (notificationType != null) {
        query = query.eq('notification_type', notificationType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      Log.d(
        'Fetched ${response.length} notifications for user ${currentUser.id}',
      );
      Log.d('Raw response length: ${response.length}');
      if (response.isNotEmpty) {
        Log.d('Sample notification: ${response.first}');
        Log.d('Sample notification isHidden: ${response.first['is_hidden']}');
        Log.d('Sample notification isRead: ${response.first['is_read']}');
      }

      return response
          .map((json) => app_notification.AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      Log.e('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'get_notification_stats',
        params: {'user_uuid': currentUser.id},
      );

      if (response == null) {
        // Fallback to manual calculation if RPC function doesn't exist
        return await _calculateNotificationStatsManually();
      }

      return response;
    } catch (e) {
      Log.e('Error fetching notification stats: $e');
      // Fallback to manual calculation
      return await _calculateNotificationStatsManually();
    }
  }

  /// Manual calculation of notification statistics (fallback)
  Future<Map<String, dynamic>> _calculateNotificationStatsManually() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final notifications = await getNotifications(
        limit: 1000,
      ); // Get all notifications

      final totalCount = notifications.length;
      final unreadCount = notifications.where((n) => n.isUnread).length;
      final readCount = notifications.where((n) => n.isRead).length;
      final dismissedCount = notifications.where((n) => n.isDismissed).length;

      // Group by type
      final byType = <String, int>{};
      for (final notification in notifications) {
        byType[notification.notificationType] =
            (byType[notification.notificationType] ?? 0) + 1;
      }

      return {
        'total_count': totalCount,
        'unread_count': unreadCount,
        'read_count': readCount,
        'dismissed_count': dismissedCount,
        'by_type': byType,
      };
    } catch (e) {
      Log.e('Error calculating notification stats manually: $e');
      return {
        'total_count': 0,
        'unread_count': 0,
        'read_count': 0,
        'dismissed_count': 0,
        'by_type': {},
      };
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('app_notifications')
          .update({
            'is_read': true,
            'read_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('id', notificationId);

      Log.d('Marked notification $notificationId as read');
    } catch (e) {
      Log.e('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      await _supabase.rpc(
        'mark_notifications_as_read',
        params: {'notification_ids': notificationIds},
      );

      Log.d('Marked ${notificationIds.length} notifications as read');
    } catch (e) {
      Log.e('Error marking multiple notifications as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('app_notifications')
          .update({
            'is_read': true,
            'read_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      Log.d('Marked all notifications as read');
    } catch (e) {
      Log.e('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    try {
      await _supabase
          .from('app_notifications')
          .update({
            'is_hidden': true,
            'dismissed_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('id', notificationId);

      Log.d('Dismissed notification $notificationId');
    } catch (e) {
      Log.e('Error dismissing notification: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('app_notifications')
          .delete()
          .eq('id', notificationId);

      Log.d('Deleted notification $notificationId');
    } catch (e) {
      Log.e('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Create a new notification
  Future<app_notification.AppNotification> createNotification({
    required String userId,
    required String jobId,
    required String message,
    required String notificationType,
    String priority = 'normal',
    Map<String, dynamic>? actionData,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _supabase
          .from('app_notifications')
          .insert({
            'user_id': userId,
            'job_id': jobId,
            'message': message,
            'notification_type': notificationType,
            'priority': priority,
            'action_data': actionData,
            'expires_at': expiresAt?.toIso8601String(),
          })
          .select()
          .single();

      Log.d('Created notification: ${response['id']}');

      // Check user preferences before sending push notification
      final pushEnabled = await isPushNotificationEnabled(
        userId: userId,
        notificationType: notificationType,
      );

      if (pushEnabled) {
        // Call Edge Function directly to send push notification
        try {
          final payload = {
            'type': 'INSERT',
            'table': 'app_notifications',
            'record': response,
            'schema': 'public',
            'old_record': null,
          };
          
          Log.d('Sending payload to Edge Function: $payload');
          
          final result = await _supabase.functions.invoke(
            'push-notifications',
            body: payload,
          );
          
          Log.d('Edge Function response: $result');
          Log.d('Push notification sent via Edge Function');
        } catch (pushError) {
          Log.e('Error sending push notification: $pushError');
          // Don't rethrow - notification was created successfully
        }
      } else {
        Log.d('Push notification skipped - user has disabled $notificationType');
      }

      return app_notification.AppNotification.fromJson(response);
    } catch (e) {
      Log.e('Error creating notification: $e');
      rethrow;
    }
  }

  /// Send push notification via FCM
  Future<Map<String, dynamic>> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'normal',
    bool sound = true,
    int? badge,
  }) async {
    try {
      // Extract notification type from data if available
      final notificationType = data?['notification_type'] as String?;
      
      // Check user preferences if notification type is provided
      if (notificationType != null) {
        final pushEnabled = await isPushNotificationEnabled(
          userId: userId,
          notificationType: notificationType,
        );
        
        if (!pushEnabled) {
          Log.d('Push notification skipped - user has disabled $notificationType');
          return {'skipped': true, 'reason': 'user_preference_disabled'};
        }
      }

      final response = await _supabase.functions.invoke(
        'push-notifications',
        body: {
          'type': 'MANUAL',
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data,
          'priority': priority,
          'sound': sound,
          'badge': badge,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to send push notification: ${response.data}');
      }

      Log.d('Push notification sent successfully: ${response.data}');
      return response.data;
    } catch (e) {
      Log.e('Error sending push notification: $e');
      rethrow;
    }
  }

  /// Send job assignment notification with push
  Future<void> sendJobAssignmentNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
    bool isReassignment = false,
  }) async {
    try {
      // Create in-app notification
      await createNotification(
        userId: userId,
        jobId: jobId,
        message: isReassignment
            ? 'Job #$jobNumber has been reassigned to you. Please confirm your assignment.'
            : 'New job #$jobNumber has been assigned to you. Please confirm your assignment.',
        notificationType: isReassignment
            ? 'job_reassignment'
            : 'job_assignment',
        priority: 'high',
        actionData: {
          'job_id': jobId,
          'job_number': jobNumber,
          'action': 'view_job',
          'route': '/jobs/$jobId/summary',
        },
      );

      // Send push notification
      await sendPushNotification(
        userId: userId,
        title: isReassignment ? 'Job Reassigned' : 'New Job Assignment',
        body: isReassignment
            ? 'Job #$jobNumber has been reassigned to you'
            : 'New job #$jobNumber has been assigned to you',
        data: {
          'action': isReassignment ? 'job_reassigned' : 'new_job_assigned',
          'notification_type': isReassignment
              ? 'job_reassignment'
              : 'job_assignment',
          'job_id': jobId,
          'job_number': jobNumber,
          'route': '/jobs/$jobId/summary',
        },
        priority: 'high',
        sound: true,
      );

      Log.d('Job assignment notification sent successfully');
    } catch (e) {
      Log.e('Error sending job assignment notification: $e');
      rethrow;
    }
  }

  /// Send job cancellation notification with push
  Future<void> sendJobCancellationNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
  }) async {
    try {
      // Create in-app notification
      await createNotification(
        userId: userId,
        jobId: jobId,
        message: 'Job #$jobNumber has been cancelled.',
        notificationType: 'job_cancelled',
        priority: 'high',
        actionData: {
          'job_id': jobId,
          'job_number': jobNumber,
          'action': 'view_job',
          'route': '/jobs/$jobId/summary',
        },
      );

      // Send push notification
      await sendPushNotification(
        userId: userId,
        title: 'Job Cancelled',
        body: 'Job #$jobNumber has been cancelled',
        data: {
          'action': 'job_cancelled',
          'notification_type': 'job_cancelled',
          'job_id': jobId,
          'job_number': jobNumber,
          'route': '/jobs/$jobId/summary',
        },
        priority: 'high',
        sound: true,
      );

      Log.d('Job cancellation notification sent successfully');
    } catch (e) {
      Log.e('Error sending job cancellation notification: $e');
      rethrow;
    }
  }

  /// Send job status change notification with push
  Future<void> sendJobStatusChangeNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      String message;
      String title;

      switch (newStatus) {
        case 'in_progress':
          message = 'Job #$jobNumber has started.';
          title = 'Job Started';
          break;
        case 'completed':
          message = 'Job #$jobNumber has been completed.';
          title = 'Job Completed';
          break;
        default:
          message = 'Job #$jobNumber status updated to $newStatus.';
          title = 'Job Status Updated';
      }

      // Create in-app notification
      await createNotification(
        userId: userId,
        jobId: jobId,
        message: message,
        notificationType: 'job_status_change',
        priority: 'normal',
        actionData: {
          'job_id': jobId,
          'job_number': jobNumber,
          'old_status': oldStatus,
          'new_status': newStatus,
          'action': 'view_job',
          'route': '/jobs/$jobId/summary',
        },
      );

      // Send push notification
      await sendPushNotification(
        userId: userId,
        title: title,
        body: message,
        data: {
          'action': 'job_status_changed',
          'notification_type': 'job_status_change',
          'job_id': jobId,
          'job_number': jobNumber,
          'old_status': oldStatus,
          'new_status': newStatus,
          'route': '/jobs/$jobId/summary',
        },
        priority: 'normal',
        sound: true,
      );

      Log.d('Job status change notification sent successfully');
    } catch (e) {
      Log.e('Error sending job status change notification: $e');
      rethrow;
    }
  }

  /// Send payment reminder notification
  Future<void> sendPaymentReminderNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
    required String amount,
  }) async {
    try {
      final message = 'Payment reminder: Job #$jobNumber - \$$amount due';

      // Create in-app notification
      await createNotification(
        userId: userId,
        jobId: jobId,
        message: message,
        notificationType: 'payment_reminder',
        priority: 'high',
        actionData: {
          'job_id': jobId,
          'job_number': jobNumber,
          'amount': amount,
          'action': 'view_payment',
          'route': '/jobs/$jobId/payment',
        },
      );

      // Send push notification
      await sendPushNotification(
        userId: userId,
        title: 'Payment Reminder',
        body: message,
        data: {
          'action': 'payment_reminder',
          'notification_type': 'payment_reminder',
          'job_id': jobId,
          'job_number': jobNumber,
          'amount': amount,
          'route': '/jobs/$jobId/payment',
        },
        priority: 'high',
        sound: true,
      );

      Log.d('Payment reminder notification sent successfully');
    } catch (e) {
      Log.e('Error sending payment reminder notification: $e');
      rethrow;
    }
  }

  /// Send system alert notification
  Future<void> sendSystemAlertNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'normal',
    Map<String, dynamic>? actionData,
  }) async {
    try {
      // Create in-app notification
      await createNotification(
        userId: userId,
        jobId: '', // System alerts don't have job IDs
        message: message,
        notificationType: 'system_alert',
        priority: priority,
        actionData: actionData,
      );

      // Send push notification
      await sendPushNotification(
        userId: userId,
        title: title,
        body: message,
        data: {
          'action': 'system_alert',
          'notification_type': 'system_alert',
          ...?actionData,
        },
        priority: priority,
        sound: priority == 'high' || priority == 'urgent',
      );

      Log.d('System alert notification sent successfully');
    } catch (e) {
      Log.e('Error sending system alert notification: $e');
      rethrow;
    }
  }

  /// Check if user has push notifications enabled for a specific notification type
  /// Returns true if enabled, false if disabled, defaults to true if preference not set
  Future<bool> isPushNotificationEnabled({
    required String userId,
    required String notificationType,
  }) async {
    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select('notification_prefs')
          .eq('id', userId)
          .single();

      final prefs = profileResponse['notification_prefs'] as Map<String, dynamic>?;
      
      if (prefs == null || prefs.isEmpty) {
        // Default to enabled if preferences not set
        return true;
      }

      // Check if this notification type is explicitly disabled
      final isEnabled = prefs[notificationType] as bool?;
      
      // Default to true if key doesn't exist (backward compatibility)
      return isEnabled ?? true;
    } catch (e) {
      Log.e('Error checking notification preference: $e');
      // Default to enabled on error (fail open)
      return true;
    }
  }

  /// Get real-time notifications stream
  Stream<List<app_notification.AppNotification>> getNotificationsStream({
    bool unreadOnly = false,
    String? notificationType,
  }) {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Use a simpler stream approach
      final stream = _supabase
          .from('app_notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return stream.map((list) {
        var notifications = list
            .map((json) => app_notification.AppNotification.fromJson(json))
            .toList();

        // Apply filters in Dart code
        if (unreadOnly) {
          notifications = notifications.where((n) => !n.isRead).toList();
        }

        if (notificationType != null) {
          notifications = notifications
              .where((n) => n.notificationType == notificationType)
              .toList();
        }

        return notifications;
      });
    } catch (e) {
      Log.e('Error setting up notifications stream: $e');
      rethrow;
    }
  }

  /// Clean up expired notifications
  Future<void> cleanupExpiredNotifications() async {
    try {
      await _supabase.rpc('cleanup_expired_notifications');
      Log.d('Cleaned up expired notifications');
    } catch (e) {
      Log.e('Error cleaning up expired notifications: $e');
      rethrow;
    }
  }

  /// Dismiss all notifications for a specific job
  Future<void> dismissJobNotifications(String jobId) async {
    try {
      await _supabase
          .from('app_notifications')
          .update({
            'dismissed_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId);

      Log.d('Dismissed notifications for job: $jobId');
    } catch (e) {
      Log.e('Error dismissing job notifications: $e');
      rethrow;
    }
  }

  /// Get job ID by job number
  static Future<int?> getJobIdByJobNumber(String jobNumber) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('jobs')
          .select('id')
          .eq('job_number', jobNumber)
          .single();

      return response['id'] as int?;
    } catch (e) {
      Log.e('Error finding job ID for job number $jobNumber: $e');
      return null;
    }
  }

  /// Fix notification job IDs that are job numbers instead of actual job IDs
  static Future<void> fixNotificationJobIds() async {
    try {
      final supabase = Supabase.instance.client;

      // Get notifications with job numbers instead of job IDs
      final response = await supabase
          .from('app_notifications')
          .select('id, job_id, action_data')
          .or('job_id.like.*-*,job_id.like.*JOB-*');

      for (final notification in response) {
        final jobId = notification['job_id']?.toString();
        if (jobId != null &&
            (jobId.contains('-') || jobId.startsWith('JOB-'))) {
          // This is a job number, try to find the actual job ID
          final actualJobId = await getJobIdByJobNumber(jobId);

          if (actualJobId != null) {
            // Update the notification with the correct job ID
            await supabase
                .from('app_notifications')
                .update({
                  'job_id': actualJobId,
                  'updated_at': SATimeUtils.getCurrentSATimeISO(),
                })
                .eq('id', notification['id']);

            Log.d(
              'Fixed notification ${notification['id']}: $jobId -> $actualJobId',
            );
          } else {
            // Couldn't find the job, mark it as problematic
            await supabase
                .from('app_notifications')
                .update({
                  'job_id': null,
                  'action_data': {
                    ...notification['action_data'] ?? {},
                    'error': 'Job number not found: $jobId',
                  },
                  'updated_at': SATimeUtils.getCurrentSATimeISO(),
                })
                .eq('id', notification['id']);

            Log.e(
              'Could not find job for notification ${notification['id']}: $jobId',
            );
          }
        }
      }
    } catch (e) {
      Log.e('Error fixing notification job IDs: $e');
    }
  }

  /// Static helper to check if user has push notifications enabled for a notification type
  static Future<bool> isPushNotificationEnabledStatic({
    required String userId,
    required String notificationType,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final profileResponse = await supabase
          .from('profiles')
          .select('notification_prefs')
          .eq('id', userId)
          .single();

      final prefs = profileResponse['notification_prefs'] as Map<String, dynamic>?;
      
      if (prefs == null || prefs.isEmpty) {
        // Default to enabled if preferences not set
        return true;
      }

      // Check if this notification type is explicitly disabled
      final isEnabled = prefs[notificationType] as bool?;
      
      // Default to true if key doesn't exist (backward compatibility)
      return isEnabled ?? true;
    } catch (e) {
      Log.e('Error checking notification preference: $e');
      // Default to enabled on error (fail open)
      return true;
    }
  }

  /// Send job start notification to administrators, managers, and driver managers
  static Future<void> sendJobStartNotification({
    required int jobId,
    required String driverName,
    required String clientName,
    required String passengerName,
    required String jobNumber,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Get all administrators, super admins, managers, and driver managers
      final usersResponse = await supabase
          .from('profiles')
          .select('id, role')
          .inFilter('role', ['administrator', 'super_admin', 'manager', 'driver_manager'])
          .eq('status', 'active');

      final message =
          'Job Started: $driverName is driving $passengerName ($clientName) - Job #$jobNumber';

      // Create notifications for all target users
      for (final user in usersResponse) {
        final notification = await supabase.from('app_notifications').insert({
          'user_id': user['id'],
          'message': message,
          'notification_type': 'job_start',
          'job_id': jobId,
          'priority': 'high',
          'action_data': {
            'route': '/jobs/$jobId/summary',
            'job_id': jobId,
            'driver_name': driverName,
            'client_name': clientName,
            'passenger_name': passengerName,
            'job_number': jobNumber,
          },
          'created_at': SATimeUtils.getCurrentSATimeISO(),
          'updated_at': SATimeUtils.getCurrentSATimeISO(),
        }).select().single();

        // Check user preferences before sending push notification
        final pushEnabled = await isPushNotificationEnabledStatic(
          userId: user['id'],
          notificationType: 'job_start',
        );

        if (pushEnabled) {
          // Send push notification via Edge Function
          try {
            await supabase.functions.invoke(
              'push-notifications',
              body: {
                'type': 'INSERT',
                'table': 'app_notifications',
                'record': notification,
                'schema': 'public',
                'old_record': null,
              },
            );
          } catch (pushError) {
            Log.e('Error sending push notification for job start: $pushError');
          }
        } else {
          Log.d('Push notification skipped for user ${user['id']} - job_start disabled');
        }
      }

      Log.d('Sent job start notifications to ${usersResponse.length} users');
    } catch (e) {
      Log.e('Error sending job start notification: $e');
    }
  }

  /// Send step completion notification
  static Future<void> sendStepCompletionNotification({
    required int jobId,
    required String stepName,
    required String driverName,
    required String jobNumber,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Get all administrators, super admins, managers, and driver managers
      final usersResponse = await supabase
          .from('profiles')
          .select('id, role')
          .inFilter('role', ['administrator', 'super_admin', 'manager', 'driver_manager'])
          .eq('status', 'active');

      final stepDisplayName = _getStepDisplayName(stepName);
      final message =
          'Driver Update: $driverName completed $stepDisplayName - Job #$jobNumber';

      // Create notifications for all target users
      for (final user in usersResponse) {
        final notification = await supabase.from('app_notifications').insert({
          'user_id': user['id'],
          'message': message,
          'notification_type': 'step_completion',
          'job_id': jobId,
          'priority': 'normal',
          'action_data': {
            'route': '/jobs/$jobId/summary',
            'job_id': jobId,
            'driver_name': driverName,
            'step_name': stepName,
            'step_display_name': stepDisplayName,
            'job_number': jobNumber,
          },
          'created_at': SATimeUtils.getCurrentSATimeISO(),
          'updated_at': SATimeUtils.getCurrentSATimeISO(),
        }).select().single();

        // Check user preferences before sending push notification
        final pushEnabled = await isPushNotificationEnabledStatic(
          userId: user['id'],
          notificationType: 'step_completion',
        );

        if (pushEnabled) {
          // Send push notification via Edge Function
          try {
            await supabase.functions.invoke(
              'push-notifications',
              body: {
                'type': 'INSERT',
                'table': 'app_notifications',
                'record': notification,
                'schema': 'public',
                'old_record': null,
              },
            );
          } catch (pushError) {
            Log.e('Error sending push notification for step completion: $pushError');
          }
        } else {
          Log.d('Push notification skipped for user ${user['id']} - step_completion disabled');
        }
      }

      Log.d(
        'Sent step completion notifications to ${usersResponse.length} users',
      );
    } catch (e) {
      Log.e('Error sending step completion notification: $e');
    }
  }

  /// Send job completion notification
  static Future<void> sendJobCompletionNotification({
    required int jobId,
    required String driverName,
    required String clientName,
    required String passengerName,
    required String jobNumber,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Get all administrators, super admins, managers, and driver managers
      final usersResponse = await supabase
          .from('profiles')
          .select('id, role')
          .inFilter('role', ['administrator', 'super_admin', 'manager', 'driver_manager'])
          .eq('status', 'active');

      final message =
          'Job Completed: $driverName finished job for $passengerName ($clientName) - Job #$jobNumber';

      // Create notifications for all target users
      for (final user in usersResponse) {
        final notification = await supabase.from('app_notifications').insert({
          'user_id': user['id'],
          'message': message,
          'notification_type': 'job_completion',
          'job_id': jobId,
          'priority': 'high',
          'action_data': {
            'route': '/jobs/$jobId/summary',
            'job_id': jobId,
            'driver_name': driverName,
            'client_name': clientName,
            'passenger_name': passengerName,
            'job_number': jobNumber,
          },
          'created_at': SATimeUtils.getCurrentSATimeISO(),
          'updated_at': SATimeUtils.getCurrentSATimeISO(),
        }).select().single();

        // Check user preferences before sending push notification
        final pushEnabled = await isPushNotificationEnabledStatic(
          userId: user['id'],
          notificationType: 'job_completion',
        );

        if (pushEnabled) {
          // Send push notification via Edge Function
          try {
            await supabase.functions.invoke(
              'push-notifications',
              body: {
                'type': 'INSERT',
                'table': 'app_notifications',
                'record': notification,
                'schema': 'public',
                'old_record': null,
              },
            );
          } catch (pushError) {
            Log.e('Error sending push notification for job completion: $pushError');
          }
        } else {
          Log.d('Push notification skipped for user ${user['id']} - job_completion disabled');
        }
      }

      Log.d(
        'Sent job completion notifications to ${usersResponse.length} users',
      );
    } catch (e) {
      Log.e('Error sending job completion notification: $e');
    }
  }

  /// Send job confirmation notification (driver confirmed) to administrators, managers, and driver managers
  static Future<void> sendJobConfirmationNotification({
    required int jobId,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch minimal job info
      final job = await supabase
          .from('jobs')
          .select('job_number, driver_id')
          .eq('id', jobId)
          .single();

      final String jobNumber = job['job_number']?.toString() ?? jobId.toString();
      final String driverId = job['driver_id']?.toString() ?? '';

      // Get driver display name (fallback to Unknown Driver)
      String driverName = 'Unknown Driver';
      if (driverId.isNotEmpty) {
        try {
          final driver = await supabase
              .from('profiles')
              .select('display_name')
              .eq('id', driverId)
              .single();
          driverName = driver['display_name']?.toString() ?? driverName;
        } catch (_) {}
      }

      // Get all administrators, super admins, managers, and driver managers
      final usersResponse = await supabase
          .from('profiles')
          .select('id, role')
          .inFilter('role', ['administrator', 'super_admin', 'manager', 'driver_manager'])
          .eq('status', 'active');

      final message =
          'Job Confirmed: $driverName confirmed job #$jobNumber';

      // Create notifications for all target users
      for (final user in usersResponse) {
        final notification = await supabase.from('app_notifications').insert({
          'user_id': user['id'],
          'message': message,
          'notification_type': 'job_confirmation',
          'job_id': jobId,
          'priority': 'high',
          'action_data': {
            'route': '/jobs/$jobId/summary',
            'job_id': jobId,
            'driver_name': driverName,
            'job_number': jobNumber,
          },
          'created_at': SATimeUtils.getCurrentSATimeISO(),
          'updated_at': SATimeUtils.getCurrentSATimeISO(),
        }).select().single();

        // Check user preferences before sending push notification
        final pushEnabled = await isPushNotificationEnabledStatic(
          userId: user['id'],
          notificationType: 'job_confirmation',
        );

        if (pushEnabled) {
          // Send push notification via Edge Function
          try {
            await supabase.functions.invoke(
              'push-notifications',
              body: {
                'type': 'INSERT',
                'table': 'app_notifications',
                'record': notification,
                'schema': 'public',
                'old_record': null,
              },
            );
          } catch (pushError) {
            Log.e('Error sending push notification for job confirmation: $pushError');
          }
        } else {
          Log.d('Push notification skipped for user ${user['id']} - job_confirmation disabled');
        }
      }

      Log.d('Sent job confirmation notifications to ${usersResponse.length} users');
    } catch (e) {
      Log.e('Error sending job confirmation notification: $e');
    }
  }

  /// Get display name for step
  static String _getStepDisplayName(String stepName) {
    switch (stepName) {
      case 'vehicle_collection':
        return 'Vehicle Collection';
      case 'pickup_arrival':
        return 'Pickup Arrival';
      case 'passenger_onboard':
        return 'Passenger Onboard';
      case 'dropoff_arrival':
        return 'Dropoff Arrival';
      case 'trip_complete':
        return 'Trip Completion';
      case 'vehicle_return':
        return 'Vehicle Return';
      default:
        return stepName;
    }
  }

  /// Clear all notifications for the current user
  Future<void> clearAllNotifications() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('app_notifications')
          .delete()
          .eq('user_id', currentUser.id);

      Log.d('All notifications cleared successfully for user ${currentUser.id}');
    } catch (e) {
      Log.e('Error clearing all notifications: $e');
      rethrow;
    }
  }
}
