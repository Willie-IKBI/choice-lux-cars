import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get notifications for the current user
  static Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc('get_user_notifications', params: {
        'user_uuid': _supabase.auth.currentUser!.id,
        'limit_count': limit,
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  /// Get unread notifications
  static Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    try {
      final response = await _supabase
          .from('unread_notifications')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get unread notifications: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase.rpc('mark_notification_read', params: {
        'notification_id_param': notificationId,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Dismiss notification
  static Future<void> dismissNotification(String notificationId) async {
    try {
      await _supabase.rpc('dismiss_notification', params: {
        'notification_id_param': notificationId,
      });
    } catch (e) {
      throw Exception('Failed to dismiss notification: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _supabase.auth.currentUser!.id);
      
      // Filter in memory for now
      final unreadCount = response.where((notification) => 
        notification['read_at'] == null && notification['dismissed_at'] == null
      ).length;
      
      return unreadCount;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }

  /// Get notifications by type
  static Future<List<Map<String, dynamic>>> getNotificationsByType(String type) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('notification_type', type)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get notifications by type: $e');
    }
  }

  /// Get job-related notifications
  static Future<List<Map<String, dynamic>>> getJobNotifications(int jobId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get job notifications: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      // Get all unread notifications first
      final unreadNotifications = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _supabase.auth.currentUser!.id);
      
      // Update each one individually
      for (final notification in unreadNotifications) {
        if (notification['read_at'] == null) {
          await _supabase
              .from('notifications')
              .update({
                'read_at': DateTime.now().toIso8601String(),
              })
              .eq('id', notification['id']);
        }
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete old notifications (cleanup)
  static Future<void> deleteOldNotifications(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .lt('created_at', cutoffDate.toIso8601String());
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }

  /// Subscribe to real-time notifications
  static RealtimeChannel subscribeToNotifications({
    required Function(Map<String, dynamic>) onNotification,
  }) {
    return _supabase
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _supabase.auth.currentUser!.id,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from real-time notifications
  static void unsubscribeFromNotifications(RealtimeChannel channel) {
    channel.unsubscribe();
  }
}
