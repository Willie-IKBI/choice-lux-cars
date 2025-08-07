import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all notifications for the current user
  Future<List<app_notification.AppNotification>> getNotifications({bool unreadOnly = false}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Fetching notifications for user: ${currentUser.id}');

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUser.id)
          .eq('is_hidden', false); // Filter out hidden notifications
      
      if (unreadOnly) {
        query = query.eq('is_read', false);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      print('Raw notification response: $response');
      
      List<app_notification.AppNotification> notifications = (response as List)
          .map((json) => app_notification.AppNotification.fromJson(json))
          .toList();
      
      print('Parsed notifications: ${notifications.length}');
      
      return notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      print('Getting unread count for user: ${currentUser.id}');

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('is_hidden', false) // Filter out hidden notifications
          .eq('is_read', false);

      print('Unread count response: ${response.length}');
      return response.length;
    } catch (e) {
      print('Error getting unread count: $e');
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Create a new notification
  Future<app_notification.AppNotification> createNotification({
    required String userId,
    required String jobId,
    required String message,
    String notificationType = 'job_assignment',
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'job_id': jobId,
            'body': message, // Use 'body' instead of 'message'
            'notification_type': notificationType,
          })
          .select()
          .single();

      return app_notification.AppNotification.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a specific job
  Future<void> markJobNotificationsAsRead(String jobId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('job_id', jobId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark job notifications as read: $e');
    }
  }

  /// Hide notifications for a specific job (soft delete)
  Future<void> hideJobNotifications(String jobId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_hidden': true})
          .eq('job_id', jobId)
          .eq('is_hidden', false);
    } catch (e) {
      throw Exception('Failed to hide job notifications: $e');
    }
  }

  /// Mark all notifications as read for the current user
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }



  /// Get notifications for a specific job
  Future<List<app_notification.AppNotification>> getJobNotifications(String jobId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => app_notification.AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch job notifications: $e');
    }
  }

  /// Clean up old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', thirtyDaysAgo.toIso8601String());
    } catch (e) {
      throw Exception('Failed to cleanup old notifications: $e');
    }
  }

  /// Test method to create a notification manually
  Future<void> createTestNotification() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Creating test notification for user: ${currentUser.id}');

      await _supabase
          .from('notifications')
          .insert({
            'user_id': currentUser.id,
            'job_id': 1, // Test job ID
            'body': 'Test notification - ${DateTime.now()}', // Use 'body' instead of 'message'
            'notification_type': 'job_assignment',
            'is_read': false,
          });

      print('Test notification created successfully');
    } catch (e) {
      print('Error creating test notification: $e');
      throw Exception('Failed to create test notification: $e');
    }
  }
} 