import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/constants/notification_constants.dart';

class NotificationPreferencesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's notification preferences from profiles.notification_prefs JSONB column
  Future<Map<String, bool>> getPreferences({String? userId}) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('profiles')
          .select('notification_prefs')
          .eq('id', targetUserId)
          .single();

      final prefs = response['notification_prefs'] as Map<String, dynamic>?;
      
      if (prefs == null || prefs.isEmpty) {
        return _getDefaultPreferences();
      }

      // Convert to Map<String, bool> and merge with defaults
      final result = <String, bool>{};
      final defaults = _getDefaultPreferences();
      
      // Start with defaults
      result.addAll(defaults);
      
      // Override with user preferences
      for (final entry in prefs.entries) {
        if (entry.value is bool) {
          result[entry.key] = entry.value as bool;
        }
      }

      return result;
    } catch (e) {
      Log.e('Error fetching notification preferences: $e');
      return _getDefaultPreferences();
    }
  }

  /// Get preference for a specific notification type
  Future<bool> getPreference(String notificationType, {String? userId}) async {
    try {
      final prefs = await getPreferences(userId: userId);
      return prefs[notificationType] ?? true; // Default to enabled
    } catch (e) {
      Log.e('Error fetching notification preference: $e');
      return true; // Default to enabled on error
    }
  }

  /// Save user's notification preferences to profiles.notification_prefs JSONB column
  Future<void> savePreferences(Map<String, bool> preferences, {String? userId}) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      // Validate that all keys are valid notification types
      const validTypes = NotificationConstants.allNotificationTypes;
      for (final key in preferences.keys) {
        if (!validTypes.contains(key)) {
          Log.d('Invalid notification type in preferences: $key');
        }
      }

      // Update the JSONB column
      await _supabase
          .from('profiles')
          .update({
            'notification_prefs': preferences,
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('id', targetUserId);

      Log.d('Notification preferences saved successfully');
    } catch (e) {
      Log.e('Error saving notification preferences: $e');
      rethrow;
    }
  }

  /// Update a single notification preference
  Future<void> updatePreference(
    String notificationType,
    bool enabled, {
    String? userId,
  }) async {
    try {
      final currentPrefs = await getPreferences(userId: userId);
      currentPrefs[notificationType] = enabled;
      await savePreferences(currentPrefs, userId: userId);
    } catch (e) {
      Log.e('Error updating notification preference: $e');
      rethrow;
    }
  }

  /// Reset preferences to defaults
  Future<void> resetToDefaults({String? userId}) async {
    try {
      await savePreferences(_getDefaultPreferences(), userId: userId);
    } catch (e) {
      Log.e('Error resetting notification preferences: $e');
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
          .from('app_notifications') // FIXED: Use correct table name
          .delete()
          .eq('user_id', currentUser.id);

      Log.d('All notifications cleared successfully');
    } catch (e) {
      Log.e('Error clearing notifications: $e');
      rethrow;
    }
  }

  /// Get default notification preferences (all enabled)
  Map<String, bool> _getDefaultPreferences() {
    // Return all notification types enabled by default
    final defaults = <String, bool>{};
    for (final type in NotificationConstants.allNotificationTypes) {
      defaults[type] = true;
    }
    return defaults;
  }
}
