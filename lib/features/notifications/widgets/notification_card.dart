import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/notification.dart' as app_notification;
import '../providers/notification_provider.dart';
import '../../../app/theme.dart';

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
    final isUnread = notification.isUnread;
    final isHighPriority = notification.isHighPriority;
    final isUrgent = notification.isUrgent;
    final isExpired = notification.isExpired;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (onDismiss != null) {
          onDismiss!();
        } else {
          ref.read(notificationProvider.notifier).dismissNotification(notification.id);
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              ChoiceLuxTheme.errorColor.withValues(alpha: 0.1),
              ChoiceLuxTheme.errorColor,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete,
          color: ChoiceLuxTheme.softWhite,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        decoration: BoxDecoration(
          gradient: ChoiceLuxTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getCardBorderColor(isUnread, isHighPriority, isUrgent),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _handleTap(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon, priority, and actions
                Row(
                  children: [
                    // Notification icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getIconBackgroundColor(isUnread, isHighPriority, isUrgent),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _getIconBorderColor(isUnread, isHighPriority, isUrgent),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getNotificationIcon(),
                        color: ChoiceLuxTheme.softWhite,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getNotificationTitle(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                    color: ChoiceLuxTheme.softWhite,
                                  ),
                                ),
                              ),
                              
                              // Priority indicator
                              if (isHighPriority) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isUrgent 
                                        ? ChoiceLuxTheme.errorColor.withValues(alpha: 0.2)
                                        : ChoiceLuxTheme.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isUrgent 
                                          ? ChoiceLuxTheme.errorColor.withValues(alpha: 0.5)
                                          : ChoiceLuxTheme.orange.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isUrgent ? 'URGENT' : 'HIGH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isUrgent 
                                          ? ChoiceLuxTheme.errorColor
                                          : ChoiceLuxTheme.orange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              
                              // Action buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!notification.isRead)
                                    IconButton(
                                      onPressed: () => _handleMarkAsRead(context, ref),
                                      icon: Icon(
                                        Icons.check_circle_outline,
                                        color: ChoiceLuxTheme.successColor,
                                        size: 20,
                                      ),
                                      tooltip: 'Mark as read',
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(4),
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: () => _handleDismiss(context, ref),
                                    icon: Icon(
                                      Icons.close,
                                      color: ChoiceLuxTheme.platinumSilver,
                                      size: 20,
                                    ),
                                    tooltip: 'Dismiss',
                                    style: IconButton.styleFrom(
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(32, 32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
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
                          
                          const SizedBox(height: 12),
                          
                          // Footer row with timestamp and action
                          Row(
                            children: [
                              // Timestamp
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeAgo(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                                ),
                              ),
                              
                              const Spacer(),
                              
                              // Action button
                              if (notification.actionData != null && notification.actionRoute != null)
                                GestureDetector(
                                  onTap: () => _handleActionButtonTap(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getActionButtonText(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ChoiceLuxTheme.richGold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCardBorderColor(bool isUnread, bool isHighPriority, bool isUrgent) {
    if (notification.isExpired) {
      return ChoiceLuxTheme.grey.withValues(alpha: 0.3);
    }
    if (isUrgent) {
      return ChoiceLuxTheme.errorColor.withValues(alpha: 0.5);
    }
    if (isHighPriority) {
      return ChoiceLuxTheme.orange.withValues(alpha: 0.5);
    }
    if (isUnread) {
      return ChoiceLuxTheme.richGold.withValues(alpha: 0.5);
    }
    return ChoiceLuxTheme.richGold.withValues(alpha: 0.2);
  }

  Color _getIconBackgroundColor(bool isUnread, bool isHighPriority, bool isUrgent) {
    if (notification.isExpired) {
      return ChoiceLuxTheme.grey;
    }
    if (isUrgent) {
      return ChoiceLuxTheme.errorColor;
    }
    if (isHighPriority) {
      return ChoiceLuxTheme.orange;
    }
    if (isUnread) {
      return ChoiceLuxTheme.richGold;
    }
    return ChoiceLuxTheme.infoColor;
  }

  Color _getIconBorderColor(bool isUnread, bool isHighPriority, bool isUrgent) {
    if (notification.isExpired) {
      return ChoiceLuxTheme.grey.withValues(alpha: 0.5);
    }
    if (isUrgent) {
      return ChoiceLuxTheme.errorColor.withValues(alpha: 0.8);
    }
    if (isHighPriority) {
      return ChoiceLuxTheme.orange.withValues(alpha: 0.8);
    }
    if (isUnread) {
      return ChoiceLuxTheme.richGold.withValues(alpha: 0.8);
    }
    return ChoiceLuxTheme.infoColor.withValues(alpha: 0.8);
  }

  IconData _getNotificationIcon() {
    switch (notification.notificationType) {
      case 'job_assignment':
      case 'job_reassignment':
        return Icons.work;
      case 'job_status_change':
        return Icons.update;
      case 'job_cancellation':
        return Icons.cancel;
      case 'payment_reminder':
        return Icons.payment;
      case 'system_alert':
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
      case 'job_status_change':
        return 'Job Status Updated';
      case 'job_cancellation':
        return 'Job Cancelled';
      case 'payment_reminder':
        return 'Payment Reminder';
      case 'system_alert':
        return 'System Alert';
      default:
        return 'Notification';
    }
  }

  String _getActionButtonText() {
    switch (notification.actionType) {
      case 'view_job':
        return 'View Job';
      case 'start_job':
        return 'Start Job';
      case 'complete_job':
        return 'Complete Job';
      default:
        return 'View';
    }
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
        } else if (notification.actionType == 'view_job' && notification.jobId.isNotEmpty) {
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
      ref.read(notificationProvider.notifier).dismissNotification(notification.id);
    }
  }

  void _handleActionButtonTap(BuildContext context) {
    if (notification.actionData != null) {
      final route = notification.actionRoute;
      if (route != null) {
        context.go(route);
      } else if (notification.actionType == 'view_job' && notification.jobId.isNotEmpty) {
        context.go('/jobs/${notification.jobId}/summary');
      }
    }
  }
} 