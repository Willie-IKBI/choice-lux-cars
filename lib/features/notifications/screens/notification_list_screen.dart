import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/constants/notification_constants.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as app_notification;
import 'package:choice_lux_cars/core/logging/log.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen> {
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),
            
            // Filter and Stats Section
            _buildFilterSection(),
            
            // Notifications List
            Expanded(
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
                      await ref.read(notificationProvider.notifier).loadNotifications();
                    },
                    color: ChoiceLuxTheme.richGold,
                    backgroundColor: ChoiceLuxTheme.charcoalGray,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _getFilteredNotifications(notificationState.notifications).length,
                      itemBuilder: (context, index) {
                        final filteredNotifications = _getFilteredNotifications(notificationState.notifications);
                        final notification = filteredNotifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onDismiss: () => _handleNotificationDismiss(notification),
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
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.jetBlack.withValues(alpha: 0.95),
            ChoiceLuxTheme.jetBlack.withValues(alpha: 0.90),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: ChoiceLuxTheme.richGold,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(40, 40),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Title
              Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ChoiceLuxTheme.softWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              // Filter Button
              Container(
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.filter_list,
                    color: ChoiceLuxTheme.richGold,
                    size: 20,
                  ),
                  tooltip: 'Filter notifications',
                  onSelected: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    _loadFilteredNotifications();
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
                    _buildFilterMenuItem('all', 'All', Icons.all_inbox),
                    _buildFilterMenuItem(NotificationConstants.jobAssignment, 'Job Assignments', Icons.work),
                    _buildFilterMenuItem(NotificationConstants.jobStatusChange, 'Status Updates', Icons.update),
                    _buildFilterMenuItem(NotificationConstants.paymentReminder, 'Payment Reminders', Icons.payment),
                    _buildFilterMenuItem(NotificationConstants.systemAlert, 'System Alerts', Icons.warning),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Mark All Read Button
              Consumer(
                builder: (context, ref, child) {
                  final notificationState = ref.watch(notificationProvider);
                  final unreadCount = notificationState.unreadCount;
                  
                  if (unreadCount > 0) {
                    return Container(
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ChoiceLuxTheme.successColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _showMarkAllReadDialog(context),
                        icon: Icon(
                          Icons.done_all,
                          color: ChoiceLuxTheme.successColor,
                          size: 20,
                        ),
                        tooltip: 'Mark all as read',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: ChoiceLuxTheme.richGold,
            size: 18,
          ),
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
            : notificationState.notifications.where((n) => !n.isHidden && !n.isRead).length;
        final fallbackHighPriorityCount = highPriorityCount > 0 
            ? highPriorityCount 
            : notificationState.notifications.where((n) => !n.isHidden && n.isHighPriority).length;
        
        // Debug logging to help identify the issue
        Log.d('Notification stats - Total: $totalCount, Unread: $unreadCount, High Priority: $highPriorityCount');
        Log.d('Fallback stats - Total: $fallbackTotalCount, Unread: $fallbackUnreadCount, High Priority: $fallbackHighPriorityCount');
        Log.d('Total notifications in list: ${notificationState.notifications.length}');
        Log.d('Active notifications: ${notificationState.notifications.where((n) => !n.isHidden).length}');
        
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
              // Filter buttons
              Row(
                children: [
                  Expanded(
                    child: _buildFilterButton(
                      'All',
                      _selectedFilter == 'all',
                      () => _setFilter('all'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterButton(
                      'Unread',
                      _selectedFilter == 'unread',
                      () => _setFilter('unread'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      fallbackTotalCount.toString(),
                      Icons.all_inbox,
                      ChoiceLuxTheme.richGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Unread',
                      fallbackUnreadCount.toString(),
                      Icons.mark_email_unread,
                      ChoiceLuxTheme.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'High Priority',
                      fallbackHighPriorityCount.toString(),
                      Icons.priority_high,
                      ChoiceLuxTheme.errorColor,
                    ),
                  ),
                ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: ChoiceLuxTheme.errorColor,
          ),
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
    ref.read(notificationProvider.notifier).loadNotifications(
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
      case NotificationConstants.jobStatusChange:
      case NotificationConstants.jobCancellation:
        if (notification.jobId != null && notification.jobId.toString().isNotEmpty) {
          // Handle both integer and string job IDs
          String jobIdToUse = notification.jobId.toString();
          
          // If it's a job number (like "2025-002"), try to find the actual job ID
          if (jobIdToUse.contains('-')) {
            // This is a job number, we need to find the actual job ID
            Log.d('Warning: ${NotificationConstants.errorInvalidJobId}: $jobIdToUse');
            SnackBarUtils.showWarning(context, 'Job number detected, navigating to jobs list');
            // For now, navigate to jobs list and let user find the job
            context.go('/jobs');
            return;
          }
          
          // Use the job ID directly (should be integer now)
          try {
            context.go(NotificationConstants.getJobSummaryRoute(int.parse(jobIdToUse)));
          } catch (e) {
            Log.e('Error navigating to job: $e');
            SnackBarUtils.showError(context, 'Failed to navigate to job details');
            // Fallback to jobs list
            context.go('/jobs');
          }
        }
        break;
      case NotificationConstants.paymentReminder:
        if (notification.jobId != null && notification.jobId.toString().isNotEmpty) {
          // Handle both integer and string job IDs
          String jobIdToUse = notification.jobId.toString();
          
          // If it's a job number (like "2025-002"), try to find the actual job ID
          if (jobIdToUse.contains('-')) {
            // This is a job number, we need to find the actual job ID
            Log.d('Warning: ${NotificationConstants.errorInvalidJobId}: $jobIdToUse');
            SnackBarUtils.showWarning(context, 'Job number detected, navigating to jobs list');
            // For now, navigate to jobs list and let user find the job
            context.go('/jobs');
            return;
          }
          
          // Use the job ID directly (should be integer now)
          try {
            context.go(NotificationConstants.getJobPaymentRoute(int.parse(jobIdToUse)));
          } catch (e) {
            Log.e('Error navigating to job payment: $e');
            SnackBarUtils.showError(context, 'Failed to navigate to job payment');
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
        SnackBarUtils.showInfo(context, 'Unknown notification type: ${notification.notificationType}');
        break;
    }
  }

  void _handleNotificationDismiss(notification) {
    ref.read(notificationProvider.notifier).dismissNotification(notification.id);
  }

  void _handleMarkAsRead(notification) {
    ref.read(notificationProvider.notifier).markAsRead(notification.id);
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<app_notification.AppNotification> _getFilteredNotifications(List<app_notification.AppNotification> notifications) {
    // First filter out dismissed notifications
    final activeNotifications = notifications.where((n) => !n.isHidden).toList();
    
    // Then apply the selected filter
    switch (_selectedFilter) {
      case 'unread':
        return activeNotifications.where((n) => !n.isRead).toList();
      case 'all':
      default:
        return activeNotifications;
    }
  }

  Widget _buildFilterButton(String label, bool isSelected, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    ChoiceLuxTheme.richGold,
                    ChoiceLuxTheme.richGold.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected ? null : ChoiceLuxTheme.charcoalGray.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? ChoiceLuxTheme.richGold
                : ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check,
                color: Colors.black,
                size: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : ChoiceLuxTheme.softWhite,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
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
          ),
        ],
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
          style: TextStyle(
            color: ChoiceLuxTheme.platinumSilver,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
              ),
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