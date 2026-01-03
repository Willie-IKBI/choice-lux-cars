import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/constants/notification_constants.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/features/notifications/widgets/notification_card.dart';
import 'package:choice_lux_cars/features/notifications/services/notification_service.dart';
import 'package:choice_lux_cars/features/notifications/models/notification.dart' as app_notification;
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  String _selectedFilter = 'all';
  bool _showUnreadOnly = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
      ref.read(notificationProvider.notifier).loadStats();
      ref.read(notificationProvider.notifier).startRealtimeSubscription();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    ref.read(notificationProvider.notifier).stopRealtimeSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: 'Notifications',
        showBackButton: true,
        showLogo: false,
        actions: [
          // Combined Actions Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
            tooltip: 'More actions',
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  ref.read(notificationProvider.notifier).loadNotifications();
                  ref.read(notificationProvider.notifier).loadStats();
                  break;
                case 'mark_all_read':
                  _showMarkAllReadDialog(context);
                  break;
                case 'filter_all':
                  setState(() => _selectedFilter = 'all');
                  _loadFilteredNotifications();
                  break;
                case 'filter_unread':
                  setState(() => _selectedFilter = 'unread');
                  _loadFilteredNotifications();
                  break;
              }
            },
            color: ChoiceLuxTheme.charcoalGray,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: ChoiceLuxTheme.richGold, size: 18),
                    const SizedBox(width: 12),
                    Text('Refresh', style: TextStyle(color: ChoiceLuxTheme.softWhite)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filter_all',
                child: Row(
                  children: [
                    Icon(Icons.all_inbox, color: ChoiceLuxTheme.richGold, size: 18),
                    const SizedBox(width: 12),
                    Text('All Notifications', style: TextStyle(color: ChoiceLuxTheme.softWhite)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filter_unread',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread, color: ChoiceLuxTheme.richGold, size: 18),
                    const SizedBox(width: 12),
                    Text('Unread Only', style: TextStyle(color: ChoiceLuxTheme.softWhite)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: ChoiceLuxTheme.successColor, size: 18),
                    const SizedBox(width: 12),
                    Text('Mark All Read', style: TextStyle(color: ChoiceLuxTheme.softWhite)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Layer 1: Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: ChoiceLuxTheme.backgroundGradient,
            ),
          ),
          // Layer 2: Background pattern
          const Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatterns.dashboard,
            ),
          ),
          // Layer 3: Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Filter and Stats Section
                _buildFilterSection(),

                // Notifications List
                SizedBox(
                  height: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight - 
                          200, // Approximate height for filter section
                  child: Consumer(
                  builder: (context, ref, child) {
                    final notificationState = ref.watch(notificationProvider);

                    if (notificationState.isLoading) {
                      return _buildLoadingState();
                    }

                    if (notificationState.error != null) {
                      return _buildErrorState(notificationState.error!);
                    }

                    if (notificationState.notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(notificationProvider.notifier)
                            .loadNotifications();
                      },
                      color: ChoiceLuxTheme.richGold,
                      backgroundColor: ChoiceLuxTheme.charcoalGray,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _getFilteredNotifications(
                          notificationState.notifications,
                        ).length,
                        itemBuilder: (context, index) {
                          final filteredNotifications = _getFilteredNotifications(
                            notificationState.notifications,
                          );
                          final notification = filteredNotifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NotificationCard(
                              notification: notification,
                              onTap: () => _handleNotificationTap(notification),
                              onDismiss: () =>
                                  _handleNotificationDismiss(notification),
                              onMarkRead: () => _handleMarkAsRead(notification),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  PopupMenuItem<String> _buildFilterMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: ChoiceLuxTheme.richGold, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Consumer(
      builder: (context, ref, child) {
        final notificationState = ref.watch(notificationProvider);

        // Use the provider's calculated stats instead of recalculating locally
        final totalCount = notificationState.totalCount;
        final unreadCount = notificationState.unreadCount;
        final highPriorityCount = notificationState.highPriorityCount;

        // Fallback calculation if provider stats are 0 but we have notifications
        final fallbackTotalCount = totalCount > 0
            ? totalCount
            : notificationState.notifications.where((n) => !n.isHidden).length;
        final fallbackUnreadCount = unreadCount > 0
            ? unreadCount
            : notificationState.notifications
                  .where((n) => !n.isHidden && !n.isRead)
                  .length;
        final fallbackHighPriorityCount = highPriorityCount > 0
            ? highPriorityCount
            : notificationState.notifications
                  .where((n) => !n.isHidden && n.isHighPriority)
                  .length;

        // Debug logging to help identify the issue
        Log.d(
          'Notification stats - Total: $totalCount, Unread: $unreadCount, High Priority: $highPriorityCount',
        );
        Log.d(
          'Fallback stats - Total: $fallbackTotalCount, Unread: $fallbackUnreadCount, High Priority: $fallbackHighPriorityCount',
        );
        Log.d(
          'Total notifications in list: ${notificationState.notifications.length}',
        );
        Log.d(
          'Active notifications: ${notificationState.notifications.where((n) => !n.isHidden).length}',
        );

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: ChoiceLuxTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Summary Card with clickable filter numbers
              _buildSummaryCard(
                fallbackTotalCount,
                fallbackUnreadCount,
                fallbackHighPriorityCount,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : ChoiceLuxTheme.softWhite,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: ChoiceLuxTheme.charcoalGray,
      selectedColor: ChoiceLuxTheme.richGold,
      checkmarkColor: Colors.black,
      side: BorderSide(
        color: selected
            ? ChoiceLuxTheme.richGold
            : ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ChoiceLuxTheme.richGold,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ChoiceLuxTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).loadNotifications();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: ChoiceLuxTheme.richGold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications',
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _loadFilteredNotifications() {
    ref
        .read(notificationProvider.notifier)
        .loadNotifications(
          unreadOnly: _showUnreadOnly,
          notificationType: _selectedFilter == 'all' ? null : _selectedFilter,
        );
  }

  void _handleNotificationTap(notification) {
    // Mark as read if unread
    if (!notification.isRead) {
      _handleMarkAsRead(notification);
    }

    // Handle navigation based on notification type and action data
    if (notification.actionData != null) {
      final route = notification.actionRoute;
      if (route != null) {
        context.go(route);
        return;
      }
    }

    // Fallback navigation based on notification type
    switch (notification.notificationType) {
      case NotificationConstants.jobAssignment:
      case NotificationConstants.jobReassignment:
      case NotificationConstants.jobConfirmation:
      case NotificationConstants.jobStatusChange:
      case NotificationConstants.jobCancelled:
      case NotificationConstants.jobStart:
      case NotificationConstants.jobCompletion:
      case NotificationConstants.stepCompletion:
      case NotificationConstants.jobStartDeadlineWarning90min:
      case NotificationConstants.jobStartDeadlineWarning60min:
        if (notification.jobId != null &&
            notification.jobId.toString().isNotEmpty) {
          // Handle both integer and string job IDs
          String jobIdToUse = notification.jobId.toString();

          // If it's a job number (like "2025-002"), try to find the actual job ID
          if (jobIdToUse.contains('-')) {
            // This is a job number, we need to find the actual job ID
            Log.d(
              'Warning: ${NotificationConstants.errorInvalidJobId}: $jobIdToUse',
            );
            SnackBarUtils.showWarning(
              context,
              'Job number detected, navigating to jobs list',
            );
            // For now, navigate to jobs list and let user find the job
            context.go('/jobs');
            return;
          }

          // Use the job ID directly (should be integer now)
          try {
            context.go(
              NotificationConstants.getJobSummaryRoute(int.parse(jobIdToUse)),
            );
          } catch (e) {
            Log.e('Error navigating to job: $e');
            SnackBarUtils.showError(
              context,
              'Failed to navigate to job details',
            );
            // Fallback to jobs list
            context.go('/jobs');
          }
        }
        break;
      case NotificationConstants.paymentReminder:
        if (notification.jobId != null &&
            notification.jobId.toString().isNotEmpty) {
          // Handle both integer and string job IDs
          String jobIdToUse = notification.jobId.toString();

          // If it's a job number (like "2025-002"), try to find the actual job ID
          if (jobIdToUse.contains('-')) {
            // This is a job number, we need to find the actual job ID
            Log.d(
              'Warning: ${NotificationConstants.errorInvalidJobId}: $jobIdToUse',
            );
            SnackBarUtils.showWarning(
              context,
              'Job number detected, navigating to jobs list',
            );
            // For now, navigate to jobs list and let user find the job
            context.go('/jobs');
            return;
          }

          // Use the job ID directly (should be integer now)
          try {
            context.go(
              NotificationConstants.getJobPaymentRoute(int.parse(jobIdToUse)),
            );
          } catch (e) {
            Log.e('Error navigating to job payment: $e');
            SnackBarUtils.showError(
              context,
              'Failed to navigate to job payment',
            );
            // Fallback to jobs list
            context.go('/jobs');
          }
        }
        break;
      case NotificationConstants.systemAlert:
        // Stay on notifications screen for system alerts
        break;
      default:
        // Stay on notifications screen for unknown types
        SnackBarUtils.showInfo(
          context,
          'Unknown notification type: ${notification.notificationType}',
        );
        break;
    }
  }

  void _handleNotificationDismiss(notification) {
    ref
        .read(notificationProvider.notifier)
        .dismissNotification(notification.id);
  }

  void _handleMarkAsRead(notification) {
    ref.read(notificationProvider.notifier).markAsRead(notification.id);
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<app_notification.AppNotification> _getFilteredNotifications(
    List<app_notification.AppNotification> notifications,
  ) {
    // First filter out dismissed notifications
    final activeNotifications = notifications
        .where((n) => !n.isHidden)
        .toList();

    // Then apply the selected filter
    switch (_selectedFilter) {
      case 'unread':
        return activeNotifications.where((n) => !n.isRead).toList();
      case 'priority':
        return activeNotifications
            .where((n) => n.isHighPriority || n.isUrgent)
            .toList();
      case 'all':
      default:
        return activeNotifications;
    }
  }


  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 100, // Fixed height for consistency
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    int totalCount,
    int unreadCount,
    int highPriorityCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
            ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notification Summary',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Statistics in a clean format - clickable
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total',
                totalCount.toString(),
                Icons.all_inbox,
                ChoiceLuxTheme.richGold,
                'all',
              ),
              Container(
                height: 30,
                width: 1,
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
              ),
              _buildSummaryItem(
                'Unread',
                unreadCount.toString(),
                Icons.mark_email_unread,
                ChoiceLuxTheme.orange,
                'unread',
              ),
              Container(
                height: 30,
                width: 1,
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
              ),
              _buildSummaryItem(
                'Priority',
                highPriorityCount.toString(),
                Icons.priority_high,
                ChoiceLuxTheme.errorColor,
                'priority',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
    String filterValue,
  ) {
    final isActive = _selectedFilter == filterValue;
    
    return GestureDetector(
      onTap: () => _setFilter(filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? color.withValues(alpha: 0.9)
                    : ChoiceLuxTheme.platinumSilver,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkAllReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: Text(
          'Mark All as Read',
          style: TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to mark all notifications as read?',
          style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
    );
  }
}
