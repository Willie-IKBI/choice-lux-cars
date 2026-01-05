import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/features/notifications/services/notification_preferences_service.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  // Notification type preferences (using singular names matching database keys)
  bool _jobAssignment = true;
  bool _jobReassignment = true;
  bool _jobStatusChange = true;
  bool _jobCancelled = true; // Fixed: was _jobCancellations
  bool _jobConfirmation = true;
  bool _jobStart = true;
  bool _jobCompletion = true;
  bool _stepCompletion = true;
  bool _jobStartDeadlineWarning90min = true;
  bool _jobStartDeadlineWarning60min = true;
  bool _systemAlert = true;

  // Note: Delivery methods, sound, vibration, priority, and quiet hours settings
  // have been removed as they are not currently enforced by the notification system.

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    
    final userProfile = ref.watch(currentUserProfileProvider);
    final userRole = userProfile?.role?.toLowerCase();
    final isSuperAdmin = userRole == 'super_admin';
    final isManager = userRole == 'manager';
    final isAdmin = userRole == 'administrator' || userRole == 'super_admin';

    // Restrict access to super_admin only
    if (!isSuperAdmin) {
      return SystemSafeScaffold(
        appBar: LuxuryAppBar(
          title: 'Notification Settings',
          showBackButton: true,
          showLogo: false,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(padding * 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: ResponsiveTokens.getIconSize(screenWidth) * 2.5, color: ChoiceLuxTheme.orange),
                SizedBox(height: spacing * 2),
                Text(
                  'Access Restricted',
                  style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 18), color: ChoiceLuxTheme.orange, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: spacing),
                Text(
                  'Only Super Administrators can configure notification settings.',
                  style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 14), color: ChoiceLuxTheme.platinumSilver),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing * 3),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: 'Notification Settings',
        showBackButton: true,
        showLogo: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: ResponsiveTokens.getIconSize(screenWidth) * 2.5, color: ChoiceLuxTheme.errorColor),
                      SizedBox(height: spacing * 2),
                      Text(
                        'Error loading preferences',
                        style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 18), color: ChoiceLuxTheme.errorColor),
                      ),
                      SizedBox(height: spacing),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 14), color: ChoiceLuxTheme.platinumSilver),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing * 3),
                      ElevatedButton(
                        onPressed: _loadPreferences,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
            // Notification Types Section
            _buildSectionHeader('Notification Types', Icons.category),
            SizedBox(height: spacing * 2),

            _buildSwitchTile(
              'Job Assignments',
              'Get notified when new jobs are assigned to you',
              Icons.work,
              _jobAssignment,
              (value) {
                setState(() => _jobAssignment = value);
                _savePreferences();
              },
            ),

            _buildSwitchTile(
              'Job Reassignments',
              'Get notified when jobs are reassigned to you',
              Icons.swap_horiz,
              _jobReassignment,
              (value) {
                setState(() => _jobReassignment = value);
                _savePreferences();
              },
            ),

            _buildSwitchTile(
              'Job Confirmation',
              'Get notified when drivers confirm job assignments',
              Icons.check_circle,
              _jobConfirmation,
              (value) {
                setState(() => _jobConfirmation = value);
                _savePreferences();
              },
            ),

            _buildSwitchTile(
              'Job Status Changes',
              'Get notified when job status is updated',
              Icons.update,
              _jobStatusChange,
              (value) {
                setState(() => _jobStatusChange = value);
                _savePreferences();
              },
            ),

            _buildSwitchTile(
              'Job Cancellations',
              'Get notified when jobs are cancelled',
              Icons.cancel,
              _jobCancelled,
              (value) {
                setState(() => _jobCancelled = value);
                _savePreferences();
              },
            ),

            _buildSwitchTile(
              'Job Start',
              'Get notified when drivers start jobs',
              Icons.play_arrow,
              _jobStart,
              (value) {
                setState(() => _jobStart = value);
                _savePreferences();
              },
            ),

            _buildSwitchTile(
              'Job Completion',
              'Get notified when jobs are completed',
              Icons.check_circle_outline,
              _jobCompletion,
              (value) {
                setState(() => _jobCompletion = value);
                _savePreferences();
              },
            ),

            _buildSwitchTile(
              'Step Completion',
              'Get notified when drivers complete job steps',
              Icons.done_all,
              _stepCompletion,
              (value) {
                setState(() => _stepCompletion = value);
                _savePreferences();
              },
            ),

            // Role-based deadline warnings
            if (isManager)
              _buildSwitchTile(
                'Job Start Deadline Warning (90 min)',
                'Get notified when jobs are not started 90 minutes before pickup',
                Icons.warning_amber,
                _jobStartDeadlineWarning90min,
                (value) {
                  setState(() => _jobStartDeadlineWarning90min = value);
                  _savePreferences();
                },
              ),

            if (isAdmin)
              _buildSwitchTile(
                'Job Start Deadline Warning (60 min)',
                'Get notified when jobs are not started 60 minutes before pickup',
                Icons.warning_amber,
                _jobStartDeadlineWarning60min,
                (value) {
                  setState(() => _jobStartDeadlineWarning60min = value);
                  _savePreferences();
                },
              ),

            _buildSwitchTile(
              'System Alerts',
              'Get notified about system maintenance and updates',
              Icons.warning,
              _systemAlert,
              (value) {
                setState(() => _systemAlert = value);
                _savePreferences();
              },
            ),

            SizedBox(height: spacing * 4),

            // Actions Section
            _buildSectionHeader('Actions', Icons.settings),
            SizedBox(height: spacing * 2),

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

            SizedBox(height: spacing * 4),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    return Row(
      children: [
        Icon(icon, color: ChoiceLuxTheme.infoColor, size: ResponsiveTokens.getIconSize(screenWidth)),
        SizedBox(width: spacing),
        Text(
          title,
          style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 18), fontWeight: FontWeight.w600),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    return Card(
      margin: EdgeInsets.only(bottom: spacing),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: ResponsiveTokens.getIconSize(screenWidth), color: ChoiceLuxTheme.platinumSilver),
            SizedBox(width: spacing * 1.5),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(left: padding * 2),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 14), color: ChoiceLuxTheme.platinumSilver),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: ChoiceLuxTheme.infoColor,
        activeTrackColor: ChoiceLuxTheme.infoColor.withOpacity(0.5),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    return Card(
      margin: EdgeInsets.only(bottom: spacing),
      child: ListTile(
        leading: Icon(icon, color: ChoiceLuxTheme.platinumSilver, size: ResponsiveTokens.getIconSize(screenWidth)),
        title: Text(
          title,
          style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 16), fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 14), color: ChoiceLuxTheme.platinumSilver),
        ),
        onTap: onTap,
        trailing: Icon(Icons.arrow_forward_ios, size: ResponsiveTokens.getIconSize(screenWidth) * 0.7),
      ),
    );
  }

  /// Load preferences from database
  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await _preferencesService.getPreferences();

      setState(() {
        // Map preferences to state variables
        // Support both singular (new) and plural (old) keys for backward compatibility
        _jobAssignment = prefs['job_assignment'] ?? prefs['job_assignments'] ?? true;
        _jobReassignment = prefs['job_reassignment'] ?? prefs['job_reassignments'] ?? true;
        _jobConfirmation = prefs['job_confirmation'] ?? true;
        _jobStatusChange = prefs['job_status_change'] ?? prefs['job_status_changes'] ?? true;
        _jobCancelled = prefs['job_cancelled'] ?? prefs['job_cancellations'] ?? prefs['job_cancellation'] ?? true;
        _jobStart = prefs['job_start'] ?? true;
        _jobCompletion = prefs['job_completion'] ?? true;
        _stepCompletion = prefs['step_completion'] ?? true;
        _jobStartDeadlineWarning90min = prefs['job_start_deadline_warning_90min'] ?? true;
        _jobStartDeadlineWarning60min = prefs['job_start_deadline_warning_60min'] ?? true;
        _systemAlert = prefs['system_alert'] ?? prefs['system_alerts'] ?? true;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load preferences: ${e.toString()}';
      });
    }
  }

  /// Save preferences to database
  Future<void> _savePreferences() async {
    try {
      // Build preferences map using singular keys (matching notification_type values)
      final prefs = {
        // Notification types (singular keys matching Edge Functions)
        'job_assignment': _jobAssignment,
        'job_reassignment': _jobReassignment,
        'job_confirmation': _jobConfirmation,
        'job_status_change': _jobStatusChange,
        'job_cancelled': _jobCancelled,
        'job_start': _jobStart,
        'job_completion': _jobCompletion,
        'step_completion': _stepCompletion,
        'job_start_deadline_warning_90min': _jobStartDeadlineWarning90min,
        'job_start_deadline_warning_60min': _jobStartDeadlineWarning60min,
        'system_alert': _systemAlert,
      };

      await _preferencesService.savePreferences(prefs);

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Notification preferences saved',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Failed to save preferences: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await _preferencesService.sendTestNotification();
      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Test notification sent',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Failed to send test notification: ${e.toString()}',
        );
      }
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: ChoiceLuxTheme.errorColor),
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
            onPressed: () async {
              setState(() {
                _jobAssignment = true;
                _jobReassignment = true;
                _jobConfirmation = true;
                _jobStatusChange = true;
                _jobCancelled = true;
                _jobStart = true;
                _jobCompletion = true;
                _stepCompletion = true;
                _jobStartDeadlineWarning90min = true;
                _jobStartDeadlineWarning60min = true;
                _systemAlert = true;
              });
              Navigator.of(context).pop();
              await _savePreferences();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
