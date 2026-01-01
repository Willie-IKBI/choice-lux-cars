import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/constants/notification_constants.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  // Local state for preferences (will be synced with provider)
  Map<String, bool> _preferences = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);

    // Check if user is super_admin first (before loading preferences)
    final isSuperAdmin = userProfile != null && 
        userProfile.role != null && 
        userProfile.role!.toLowerCase() == 'super_admin';
    
    if (!isSuperAdmin) {
      return SystemSafeScaffold(
        appBar: const LuxuryAppBar(
          title: 'Notification Settings',
          showBackButton: true,
          showLogo: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: ChoiceLuxTheme.richGold,
                ),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only Super Administrators can manage notification preferences.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Only watch preferences provider if user is super_admin
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return SystemSafeScaffold(
      appBar: const LuxuryAppBar(
        title: 'Notification Settings',
        showBackButton: true,
        showLogo: false,
      ),
      body: preferencesAsync.when(
        data: (prefs) {
          // Sync local state with provider data
          if (_preferences.isEmpty || _preferences != prefs) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _preferences = Map<String, bool>.from(prefs);
                });
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: ChoiceLuxTheme.richGold,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'These settings control push notifications only. In-app notifications will still appear in your notification list.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ChoiceLuxTheme.platinumSilver,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Job Lifecycle Section
                _buildSectionHeader(
                  'Job Lifecycle',
                  Icons.work_outline,
                ),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  NotificationConstants.jobAssignment,
                  context,
                ),
                _buildNotificationToggle(
                  NotificationConstants.jobReassignment,
                  context,
                ),
                _buildNotificationToggle(
                  NotificationConstants.jobConfirmation,
                  context,
                ),
                _buildNotificationToggle(
                  NotificationConstants.jobCancelled,
                  context,
                ),
                _buildNotificationToggle(
                  NotificationConstants.jobStatusChange,
                  context,
                ),

                const SizedBox(height: 32),

                // Driver Updates Section
                _buildSectionHeader(
                  'Driver Updates',
                  Icons.directions_car_outlined,
                ),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  NotificationConstants.jobStart,
                  context,
                ),
                _buildNotificationToggle(
                  NotificationConstants.stepCompletion,
                  context,
                ),
                _buildNotificationToggle(
                  NotificationConstants.jobCompletion,
                  context,
                ),

                const SizedBox(height: 32),

                // Deadline Warnings Section
                _buildSectionHeader(
                  'Deadline Warnings',
                  Icons.schedule_outlined,
                ),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  NotificationConstants.jobStartDeadlineWarning90min,
                  context,
                ),
                _buildNotificationToggle(
                  NotificationConstants.jobStartDeadlineWarning30min,
                  context,
                ),

                const SizedBox(height: 32),

                // Finance Section
                _buildSectionHeader(
                  'Finance',
                  Icons.payment_outlined,
                ),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  NotificationConstants.paymentReminder,
                  context,
                ),

                const SizedBox(height: 32),

                // System Section
                _buildSectionHeader(
                  'System',
                  Icons.settings_outlined,
                ),
                const SizedBox(height: 12),
                _buildNotificationToggle(
                  NotificationConstants.systemAlert,
                  context,
                ),

                const SizedBox(height: 32),

                // Actions Section
                _buildSectionHeader(
                  'Actions',
                  Icons.more_vert,
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  'Send Test Notification',
                  'Send a test notification to verify your settings',
                  Icons.send_outlined,
                  () => _sendTestNotification(),
                ),
                _buildActionTile(
                  'Reset to Defaults',
                  'Restore all notification preferences to default (all enabled)',
                  Icons.restore_outlined,
                  () => _resetToDefaults(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: ChoiceLuxTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(notificationPreferencesProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: ChoiceLuxTheme.richGold,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(String notificationType, BuildContext context) {
    final isEnabled = _preferences[notificationType] ?? true;
    final displayName =
        NotificationConstants.getNotificationTypeDisplayName(notificationType);
    final description =
        NotificationConstants.getNotificationTypeDescription(notificationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          displayName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ChoiceLuxTheme.platinumSilver,
                ),
          ),
        ),
        value: isEnabled,
        onChanged: (value) async {
          setState(() {
            _preferences[notificationType] = value;
          });

          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref
                .read(notificationPreferencesProvider.notifier)
                .updatePreference(notificationType, value);

            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? '$displayName notifications enabled'
                      : '$displayName notifications disabled',
                ),
                backgroundColor: ChoiceLuxTheme.charcoalGray,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            Log.e('Error updating notification preference: $e');
            // Revert on error
            setState(() {
              _preferences[notificationType] = !value;
            });

            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error updating preference: $e'),
                backgroundColor: ChoiceLuxTheme.errorColor,
              ),
            );
          }
        },
        activeThumbColor: ChoiceLuxTheme.richGold,
        inactiveThumbColor: ChoiceLuxTheme.platinumSilver,
        inactiveTrackColor: ChoiceLuxTheme.charcoalGray,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: ChoiceLuxTheme.richGold,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ChoiceLuxTheme.platinumSilver,
                ),
          ),
        ),
        onTap: onTap,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: ChoiceLuxTheme.platinumSilver,
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final prefsService = ref.read(notificationPreferencesServiceProvider);
      await prefsService.sendTestNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent successfully'),
            backgroundColor: ChoiceLuxTheme.charcoalGray,
          ),
        );
      }
    } catch (e) {
      Log.e('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.restore_outlined,
              color: ChoiceLuxTheme.richGold,
            ),
            const SizedBox(width: 12),
            Text(
              'Reset to Defaults',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ChoiceLuxTheme.softWhite,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all notification preferences to their default values? All notifications will be enabled.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ChoiceLuxTheme.platinumSilver,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: ChoiceLuxTheme.jetBlack,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      try {
        await ref.read(notificationPreferencesProvider.notifier).resetToDefaults();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences reset to defaults'),
              backgroundColor: ChoiceLuxTheme.charcoalGray,
            ),
          );
        }
      } catch (e) {
        Log.e('Error resetting preferences: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting preferences: $e'),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
