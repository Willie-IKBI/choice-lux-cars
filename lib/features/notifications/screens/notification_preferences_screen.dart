import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  // Notification type preferences
  bool _jobAssignments = true;
  bool _jobReassignments = true;
  bool _jobStatusChanges = true;
  bool _jobCancellations = true;
  bool _paymentReminders = true;
  bool _systemAlerts = true;

  // Notification delivery preferences
  bool _pushNotifications = true;
  bool _inAppNotifications = true;
  bool _emailNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Priority preferences
  bool _highPriorityOnly = false;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Notification Settings',
        showBackButton: true,
        showLogo: false,
        actions: [
          TextButton(onPressed: _savePreferences, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Types Section
            _buildSectionHeader('Notification Types', Icons.category),
            const SizedBox(height: 16),

            _buildSwitchTile(
              'Job Assignments',
              'Get notified when new jobs are assigned to you',
              Icons.work,
              _jobAssignments,
              (value) => setState(() => _jobAssignments = value),
            ),

            _buildSwitchTile(
              'Job Reassignments',
              'Get notified when jobs are reassigned to you',
              Icons.swap_horiz,
              _jobReassignments,
              (value) => setState(() => _jobReassignments = value),
            ),

            _buildSwitchTile(
              'Job Status Changes',
              'Get notified when job status is updated',
              Icons.update,
              _jobStatusChanges,
              (value) => setState(() => _jobStatusChanges = value),
            ),

            _buildSwitchTile(
              'Job Cancellations',
              'Get notified when jobs are cancelled',
              Icons.cancel,
              _jobCancellations,
              (value) => setState(() => _jobCancellations = value),
            ),

            _buildSwitchTile(
              'Payment Reminders',
              'Get notified about payment reminders',
              Icons.payment,
              _paymentReminders,
              (value) => setState(() => _paymentReminders = value),
            ),

            _buildSwitchTile(
              'System Alerts',
              'Get notified about system maintenance and updates',
              Icons.warning,
              _systemAlerts,
              (value) => setState(() => _systemAlerts = value),
            ),

            const SizedBox(height: 32),

            // Delivery Methods Section
            _buildSectionHeader('Delivery Methods', Icons.notifications),
            const SizedBox(height: 16),

            _buildSwitchTile(
              'Push Notifications',
              'Receive notifications on your device',
              Icons.phone_android,
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),

            _buildSwitchTile(
              'In-App Notifications',
              'Show notifications within the app',
              Icons.notifications_active,
              _inAppNotifications,
              (value) => setState(() => _inAppNotifications = value),
            ),

            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              Icons.email,
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),

            const SizedBox(height: 32),

            // Sound & Vibration Section
            _buildSectionHeader('Sound & Vibration', Icons.volume_up),
            const SizedBox(height: 16),

            _buildSwitchTile(
              'Sound',
              'Play sound for notifications',
              Icons.volume_up,
              _soundEnabled,
              (value) => setState(() => _soundEnabled = value),
            ),

            _buildSwitchTile(
              'Vibration',
              'Vibrate for notifications',
              Icons.vibration,
              _vibrationEnabled,
              (value) => setState(() => _vibrationEnabled = value),
            ),

            const SizedBox(height: 32),

            // Priority Settings Section
            _buildSectionHeader('Priority Settings', Icons.priority_high),
            const SizedBox(height: 16),

            _buildSwitchTile(
              'High Priority Only',
              'Only show high priority notifications',
              Icons.priority_high,
              _highPriorityOnly,
              (value) => setState(() => _highPriorityOnly = value),
            ),

            const SizedBox(height: 32),

            // Quiet Hours Section
            _buildSectionHeader('Quiet Hours', Icons.bedtime),
            const SizedBox(height: 16),

            _buildSwitchTile(
              'Enable Quiet Hours',
              'Mute notifications during specified hours',
              Icons.bedtime,
              _quietHoursEnabled,
              (value) => setState(() => _quietHoursEnabled = value),
            ),

            if (_quietHoursEnabled) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTimeTile(
                      'Start Time',
                      _quietHoursStart,
                      (time) => setState(() => _quietHoursStart = time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeTile(
                      'End Time',
                      _quietHoursEnd,
                      (time) => setState(() => _quietHoursEnd = time),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Actions Section
            _buildSectionHeader('Actions', Icons.settings),
            const SizedBox(height: 16),

            _buildActionTile(
              'Test Notification',
              'Send a test notification to verify settings',
              Icons.send,
              () => _sendTestNotification(),
            ),

            _buildActionTile(
              'Clear All Notifications',
              'Delete all notifications from your device',
              Icons.clear_all,
              () => _clearAllNotifications(),
            ),

            _buildActionTile(
              'Reset to Defaults',
              'Restore default notification settings',
              Icons.restore,
              () => _resetToDefaults(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildTimeTile(
    String title,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.access_time, color: Colors.grey[600]),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          time.format(context),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        onTap: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) {
            onChanged(newTime);
          }
        },
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  void _savePreferences() {
    // TODO: Implement saving preferences to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification preferences saved')),
    );
  }

  void _sendTestNotification() {
    // TODO: Implement test notification
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test notification sent')));
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Clear all notifications using the provider
                await ref.read(notificationProvider.notifier).clearAllNotifications();
                
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications cleared')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error clearing notifications: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all notification settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _jobAssignments = true;
                _jobReassignments = true;
                _jobStatusChanges = true;
                _jobCancellations = true;
                _paymentReminders = true;
                _systemAlerts = true;
                _pushNotifications = true;
                _inAppNotifications = true;
                _emailNotifications = false;
                _soundEnabled = true;
                _vibrationEnabled = true;
                _highPriorityOnly = false;
                _quietHoursEnabled = false;
                _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
                _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
