import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPreferencesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's notification preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
        .from('user_notification_preferences')
        .select()
        .eq('user_id', currentUser.id)
        .single();

      return response ?? _getDefaultPreferences();
    } catch (e) {
      print('Error fetching notification preferences: $e');
      return _getDefaultPreferences();
    }
  }

  /// Save user's notification preferences
  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
        .from('user_notification_preferences')
        .upsert({
          'user_id': currentUser.id,
          ...preferences,
          'updated_at': DateTime.now().toIso8601String(),
        });

      print('Notification preferences saved successfully');
    } catch (e) {
      print('Error saving notification preferences: $e');
      rethrow;
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create a test notification
      await _supabase
        .from('notifications')
        .insert({
          'user_id': currentUser.id,
          'message': 'This is a test notification to verify your settings.',
          'notification_type': 'system_alert',
          'priority': 'normal',
          'action_data': {
            'action': 'test_notification',
            'message': 'Test notification sent successfully',
          },
        });

      print('Test notification sent successfully');
    } catch (e) {
      print('Error sending test notification: $e');
      rethrow;
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
        .from('notifications')
        .delete()
        .eq('user_id', currentUser.id);

      print('All notifications cleared successfully');
    } catch (e) {
      print('Error clearing notifications: $e');
      rethrow;
    }
  }

  /// Get default notification preferences
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'job_assignments': true,
      'job_reassignments': true,
      'job_status_changes': true,
      'job_cancellations': true,
      'payment_reminders': true,
      'system_alerts': true,
      'push_notifications': true,
      'in_app_notifications': true,
      'email_notifications': false,
      'sound_enabled': true,
      'vibration_enabled': true,
      'high_priority_only': false,
      'quiet_hours_enabled': false,
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '07:00',
    };
  }
}
