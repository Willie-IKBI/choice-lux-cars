import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get notifications
  Future<List<app_notification.AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
    String? notificationType,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('=== DEBUG: Fetching notifications for user: ${currentUser.id} ===');

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

      print('Fetched ${response.length} notifications for user ${currentUser.id}');
      if (response.isNotEmpty) {
        print('Sample notification: ${response.first}');
      }

      return response.map((json) => app_notification.AppNotification.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
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

      final response = await _supabase
        .rpc('get_notification_stats', params: {'user_uuid': currentUser.id});

      if (response == null) {
        // Fallback to manual calculation if RPC function doesn't exist
        return await _calculateNotificationStatsManually();
      }

      return response;
    } catch (e) {
      print('Error fetching notification stats: $e');
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

      final notifications = await getNotifications(limit: 1000); // Get all notifications
      
      final totalCount = notifications.length;
      final unreadCount = notifications.where((n) => n.isUnread).length;
      final readCount = notifications.where((n) => n.isRead).length;
      final dismissedCount = notifications.where((n) => n.isDismissed).length;
      
      // Group by type
      final byType = <String, int>{};
      for (final notification in notifications) {
        byType[notification.notificationType] = (byType[notification.notificationType] ?? 0) + 1;
      }

      return {
        'total_count': totalCount,
        'unread_count': unreadCount,
        'read_count': readCount,
        'dismissed_count': dismissedCount,
        'by_type': byType,
      };
    } catch (e) {
      print('Error calculating notification stats manually: $e');
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
          'read_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);

      print('Marked notification $notificationId as read');
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      await _supabase
        .rpc('mark_notifications_as_read', params: {'notification_ids': notificationIds});

      print('Marked ${notificationIds.length} notifications as read');
    } catch (e) {
      print('Error marking multiple notifications as read: $e');
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
          'read_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', currentUser.id)
        .eq('is_read', false);

      print('Marked all notifications as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
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
          'dismissed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);

      print('Dismissed notification $notificationId');
    } catch (e) {
      print('Error dismissing notification: $e');
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

      print('Deleted notification $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
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

      print('Created notification: ${response['id']}');
      return app_notification.AppNotification.fromJson(response);
    } catch (e) {
      print('Error creating notification: $e');
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
      final response = await _supabase.functions.invoke(
        'send-push-notification',
        body: {
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

      print('Push notification sent successfully: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error sending push notification: $e');
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
      final notification = await createNotification(
        userId: userId,
        jobId: jobId,
        message: isReassignment 
          ? 'Job #$jobNumber has been reassigned to you. Please confirm your assignment.'
          : 'New job #$jobNumber has been assigned to you. Please confirm your assignment.',
        notificationType: isReassignment ? 'job_reassignment' : 'job_assignment',
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
          'notification_type': isReassignment ? 'job_reassignment' : 'job_assignment',
          'job_id': jobId,
          'job_number': jobNumber,
          'route': '/jobs/$jobId/summary',
        },
        priority: 'high',
        sound: true,
      );

      print('Job assignment notification sent successfully');
    } catch (e) {
      print('Error sending job assignment notification: $e');
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
      final notification = await createNotification(
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

      print('Job cancellation notification sent successfully');
    } catch (e) {
      print('Error sending job cancellation notification: $e');
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
      final notification = await createNotification(
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

      print('Job status change notification sent successfully');
    } catch (e) {
      print('Error sending job status change notification: $e');
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
      final notification = await createNotification(
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

      print('Payment reminder notification sent successfully');
    } catch (e) {
      print('Error sending payment reminder notification: $e');
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
      final notification = await createNotification(
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

      print('System alert notification sent successfully');
    } catch (e) {
      print('Error sending system alert notification: $e');
      rethrow;
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
        var notifications = list.map((json) => app_notification.AppNotification.fromJson(json)).toList();
        
        // Apply filters in Dart code
        if (unreadOnly) {
          notifications = notifications.where((n) => !n.isRead).toList();
        }
        
        if (notificationType != null) {
          notifications = notifications.where((n) => n.notificationType == notificationType).toList();
        }
        
        return notifications;
      });
    } catch (e) {
      print('Error setting up notifications stream: $e');
      rethrow;
    }
  }

  /// Clean up expired notifications
  Future<void> cleanupExpiredNotifications() async {
    try {
      await _supabase.rpc('cleanup_expired_notifications');
      print('Cleaned up expired notifications');
    } catch (e) {
      print('Error cleaning up expired notifications: $e');
      rethrow;
    }
  }

  /// Dismiss all notifications for a specific job
  Future<void> dismissJobNotifications(String jobId) async {
    try {
      await _supabase
        .from('app_notifications')
        .update({
          'dismissed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('job_id', jobId);

      print('Dismissed notifications for job: $jobId');
    } catch (e) {
      print('Error dismissing job notifications: $e');
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
      print('Error finding job ID for job number $jobNumber: $e');
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
        if (jobId != null && (jobId.contains('-') || jobId.startsWith('JOB-'))) {
          // This is a job number, try to find the actual job ID
          final actualJobId = await getJobIdByJobNumber(jobId);
          
          if (actualJobId != null) {
            // Update the notification with the correct job ID
            await supabase
                .from('app_notifications')
                .update({
                  'job_id': actualJobId,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', notification['id']);
            
            print('Fixed notification ${notification['id']}: $jobId -> $actualJobId');
          } else {
            // Couldn't find the job, mark it as problematic
            await supabase
                .from('app_notifications')
                .update({
                  'job_id': null,
                  'action_data': {
                    ...notification['action_data'] ?? {},
                    'error': 'Job number not found: $jobId'
                  },
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', notification['id']);
            
            print('Could not find job for notification ${notification['id']}: $jobId');
          }
        }
      }
    } catch (e) {
      print('Error fixing notification job IDs: $e');
    }
  }
} 