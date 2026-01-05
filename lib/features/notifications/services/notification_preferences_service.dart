import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

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
          .from('profiles')
          .select('notification_prefs')
          .eq('id', currentUser.id)
          .single();

      // Extract notification_prefs JSONB column
      final prefs = response['notification_prefs'] as Map<String, dynamic>?;
      
      // Merge with defaults to ensure all keys exist
      final defaults = _getDefaultPreferences();
      if (prefs == null || prefs.isEmpty) {
        return defaults;
      }
      
      // Merge user preferences with defaults (user prefs take precedence)
      return {...defaults, ...prefs};
    } catch (e) {
      Log.e('Error fetching notification preferences: $e');
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

      // Update profiles.notification_prefs JSONB column
      await _supabase
          .from('profiles')
          .update({
            'notification_prefs': preferences,
          })
          .eq('id', currentUser.id);

      Log.d('Notification preferences saved successfully');
    } catch (e) {
      Log.e('Error saving notification preferences: $e');
      throw e;
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create a test notification in the canonical table
      final inserted = await _supabase
          .from('app_notifications')
          .insert({
            'user_id': currentUser.id,
            'message': 'This is a test notification to verify your settings.',
            'notification_type': 'system_alert',
            'priority': 'normal',
            'action_data': {
              'action': 'test_notification',
              'message': 'Test notification sent successfully',
              'route': '/',
            },
          })
          .select()
          .single();

      // Trigger push via Edge Function (same path as NotificationService)
      try {
        await _supabase.functions.invoke(
          'push-notifications',
          body: {
            'type': 'INSERT',
            'table': 'app_notifications',
            'record': inserted,
            'schema': 'public',
            'old_record': null,
          },
        );
      } catch (e) {
        Log.e('Error invoking push-notifications function: $e');
      }

      Log.d('Test notification sent successfully');
    } catch (e) {
      Log.e('Error sending test notification: $e');
      throw e;
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
          .from('app_notifications') // FIXED: Use correct table name
          .delete()
          .eq('user_id', currentUser.id);

      Log.d('All notifications cleared successfully');
    } catch (e) {
      Log.e('Error clearing notifications: $e');
      throw e;
    }
  }

  /// Get default notification preferences
  /// Uses singular keys to match Edge Functions and database notification_type values
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      // Notification types (singular keys matching notification_type values)
      'job_assignment': true,
      'job_reassignment': true,
      'job_status_change': true,
      'job_cancelled': true, // Fixed: was 'job_cancellation'
      'job_confirmation': true,
      'job_start': true,
      'job_completion': true,
      'step_completion': true,
      'job_start_deadline_warning_90min': true,
      'job_start_deadline_warning_60min': true,
      'system_alert': true,
      // Note: Delivery methods, sound, vibration, priority, and quiet hours
      // preferences have been removed from defaults as they are not currently
      // enforced by the notification system.
    };
  }
}
