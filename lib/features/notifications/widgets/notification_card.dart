import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/notifications/models/notification.dart' as app_notification;
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';

class NotificationCard extends ConsumerWidget {
  final app_notification.AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onMarkRead;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighPriority = notification.isHighPriority;
    final isUrgent = notification.isUrgent;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (onDismiss != null) {
          onDismiss!();
        } else {
          ref
              .read(notificationProvider.notifier)
              .dismissNotification(notification.id);
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: ChoiceLuxTheme.softWhite, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleTap(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Square icon on left
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getNotificationIcon(),
                          color: _getIconColor(),
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Content in middle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              _getNotificationTitle(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Message
                            Text(
                              notification.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: ChoiceLuxTheme.platinumSilver,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Timestamp
                            Text(
                              _getTimeAgo(),
                              style: TextStyle(
                                fontSize: 12,
                                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Actions on right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Priority badge
                          if (isHighPriority)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ChoiceLuxTheme.richGold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'HIGH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // View Details button
                          if (notification.actionData != null &&
                              notification.actionRoute != null)
                            GestureDetector(
                              onTap: () => _handleActionButtonTap(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ChoiceLuxTheme.charcoalGray,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: ChoiceLuxTheme.softWhite,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: ChoiceLuxTheme.softWhite,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // X icon in top right corner
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleDismiss(context, ref),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: ChoiceLuxTheme.platinumSilver,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconBackgroundColor() {
    // Based on reference: gold briefcase for job confirmed, blue checkmark for step completed
    if (notification.notificationType == 'job_confirmation' ||
        notification.notificationType == 'job_assignment' ||
        notification.notificationType == 'job_reassignment') {
      return ChoiceLuxTheme.richGold.withOpacity(0.2);
    }
    if (notification.notificationType == 'step_completion' ||
        notification.notificationType == 'job_completion') {
      return ChoiceLuxTheme.infoColor.withOpacity(0.2);
    }
    return ChoiceLuxTheme.charcoalGray;
  }

  Color _getIconColor() {
    // Based on reference: gold for job confirmed, blue for step completed
    if (notification.notificationType == 'job_confirmation' ||
        notification.notificationType == 'job_assignment' ||
        notification.notificationType == 'job_reassignment') {
      return ChoiceLuxTheme.richGold;
    }
    if (notification.notificationType == 'step_completion' ||
        notification.notificationType == 'job_completion') {
      return ChoiceLuxTheme.infoColor;
    }
    return ChoiceLuxTheme.softWhite;
  }

  IconData _getNotificationIcon() {
    switch (notification.notificationType) {
      case 'job_assignment':
      case 'job_reassignment':
      case 'job_confirmation':
        return Icons.business_center; // Briefcase icon for job confirmed
      case 'job_status_change':
        return Icons.update;
      case 'job_cancelled':
        return Icons.cancel;
      case 'job_start':
      case 'job_completion':
        return Icons.check_circle;
      case 'step_completion':
        return Icons.check_circle; // Checkmark for step completed
      case 'payment_reminder':
        return Icons.payment;
      case 'system_alert':
      case 'job_start_deadline_warning_90min':
      case 'job_start_deadline_warning_60min':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle() {
    switch (notification.notificationType) {
      case 'job_assignment':
        return 'New Job Assignment';
      case 'job_reassignment':
        return 'Job Reassigned';
      case 'job_confirmation':
        return 'Job Confirmed';
      case 'job_status_change':
        return 'Job Status Updated';
      case 'job_cancelled':
        return 'Job Cancelled';
      case 'job_start':
        return 'Job Started';
      case 'job_completion':
        return 'Job Completed';
      case 'step_completion':
        return 'Step Completed';
      case 'payment_reminder':
        return 'Payment Reminder';
      case 'system_alert':
        return 'System Alert';
      case 'job_start_deadline_warning_90min':
        return 'Job Start Deadline Warning (90 min)';
      case 'job_start_deadline_warning_60min':
        return 'Job Start Deadline Warning (60 min)';
      default:
        return 'Notification';
    }
  }

  String _getActionButtonText() {
    // Always return "View Details" to match reference
    return 'View Details';
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(notification.createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (onTap != null) {
      onTap!();
    } else {
      // Default navigation logic
      if (notification.actionData != null) {
        final route = notification.actionRoute;
        if (route != null) {
          context.go(route);
        } else if (notification.actionType == 'view_job' &&
            notification.jobId.isNotEmpty) {
          context.go('/jobs/${notification.jobId}/summary');
        }
      }
    }
  }

  void _handleMarkAsRead(BuildContext context, WidgetRef ref) {
    if (onMarkRead != null) {
      onMarkRead!();
    } else {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }
  }

  void _handleDismiss(BuildContext context, WidgetRef ref) {
    if (onDismiss != null) {
      onDismiss!();
    } else {
      ref
          .read(notificationProvider.notifier)
          .dismissNotification(notification.id);
    }
  }

  void _handleActionButtonTap(BuildContext context) {
    if (notification.actionData != null) {
      final route = notification.actionRoute;
      if (route != null) {
        context.go(route);
      } else if (notification.actionType == 'view_job' &&
          notification.jobId.isNotEmpty) {
        context.go('/jobs/${notification.jobId}/summary');
      }
    }
  }
}
