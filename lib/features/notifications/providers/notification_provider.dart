import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

// Notification State
class NotificationState {
  final List<app_notification.AppNotification> notifications;
  final int unreadCount;
  final int totalCount;
  final int highPriorityCount;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? stats;

  const NotificationState({
    required this.notifications,
    required this.unreadCount,
    required this.totalCount,
    required this.highPriorityCount,
    required this.isLoading,
    this.error,
    this.stats,
  });

  factory NotificationState.initial() => const NotificationState(
    notifications: [],
    unreadCount: 0,
    totalCount: 0,
    highPriorityCount: 0,
    isLoading: false,
  );

  NotificationState copyWith({
    List<app_notification.AppNotification>? notifications,
    int? unreadCount,
    int? totalCount,
    int? highPriorityCount,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      totalCount: totalCount ?? this.totalCount,
      highPriorityCount: highPriorityCount ?? this.highPriorityCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

// Notification Notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List<app_notification.AppNotification>>? _subscription;

  NotificationNotifier() : super(NotificationState.initial());

  /// Load notifications
  Future<void> loadNotifications({
    bool unreadOnly = false,
    String? notificationType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final notifications = await _notificationService.getNotifications(
        unreadOnly: unreadOnly,
        notificationType: notificationType,
        limit: limit,
        offset: offset,
      );

      // Calculate stats from active notifications only
      final activeNotifications = notifications.where((n) => !n.isHidden).toList();
      final unreadCount = activeNotifications.where((n) => !n.isRead).length;
      final totalCount = activeNotifications.length;
      final highPriorityCount = activeNotifications.where((n) => n.isHighPriority).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        totalCount: totalCount,
        highPriorityCount: highPriorityCount,
        isLoading: false,
      );

      Log.d('Loaded ${notifications.length} notifications, ${unreadCount} unread');
      Log.d('Active notifications - Total: $totalCount, Unread: $unreadCount, High Priority: $highPriorityCount');
      
      // Also update stats based on loaded notifications
      await _updateStatsFromNotifications(notifications);
    } catch (e) {
      Log.e('Error loading notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update stats based on loaded notifications
  Future<void> _updateStatsFromNotifications(List<app_notification.AppNotification> notifications) async {
    try {
      // Calculate stats from active notifications only (not hidden)
      final activeNotifications = notifications.where((n) => !n.isHidden).toList();
      final totalCount = activeNotifications.length;
      final unreadCount = activeNotifications.where((n) => !n.isRead).length;
      final readCount = activeNotifications.where((n) => n.isRead).length;
      final dismissedCount = notifications.where((n) => n.isDismissed).length;
      final highPriorityCount = activeNotifications.where((n) => n.isHighPriority).length;
      
      // Group by type
      final byType = <String, int>{};
      for (final notification in activeNotifications) {
        byType[notification.notificationType] = (byType[notification.notificationType] ?? 0) + 1;
      }

      final stats = {
        'total_count': totalCount,
        'unread_count': unreadCount,
        'read_count': readCount,
        'dismissed_count': dismissedCount,
        'high_priority_count': highPriorityCount,
        'by_type': byType,
      };

      state = state.copyWith(
        stats: stats,
        totalCount: totalCount,
        unreadCount: unreadCount,
        highPriorityCount: highPriorityCount,
      );
      
      Log.d('Updated stats from notifications: $stats');
      Log.d('Updated state counts - Total: $totalCount, Unread: $unreadCount, High Priority: $highPriorityCount');
    } catch (e) {
      Log.e('Error updating stats from notifications: $e');
    }
  }

  /// Load notification statistics
  Future<void> loadStats() async {
    try {
      final stats = await _notificationService.getNotificationStats();
      
      // Extract counts from stats and update state
      final totalCount = stats['total_count'] ?? 0;
      final unreadCount = stats['unread_count'] ?? 0;
      final highPriorityCount = stats['high_priority_count'] ?? 0;
      
      state = state.copyWith(
        stats: stats,
        totalCount: totalCount,
        unreadCount: unreadCount,
        highPriorityCount: highPriorityCount,
      );
      
      Log.d('Loaded notification stats: $stats');
      Log.d('Updated state counts - Total: $totalCount, Unread: $unreadCount, High Priority: $highPriorityCount');
    } catch (e) {
      Log.e('Error loading notification stats: $e');
      // Fallback: calculate stats from current notifications
      await _updateStatsFromNotifications(state.notifications);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();

      // Calculate new stats from active notifications only
      final activeNotifications = updatedNotifications.where((n) => !n.isHidden).toList();
      final unreadCount = activeNotifications.where((n) => !n.isRead).length;
      final totalCount = activeNotifications.length;
      final highPriorityCount = activeNotifications.where((n) => n.isHighPriority).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        totalCount: totalCount,
        highPriorityCount: highPriorityCount,
      );

      Log.d('Marked notification $notificationId as read');
      Log.d('Updated stats - Total: $totalCount, Unread: $unreadCount, High Priority: $highPriorityCount');
    } catch (e) {
      Log.e('Error marking notification as read: $e');
    }
  }

  /// Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      await _notificationService.markMultipleAsRead(notificationIds);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notificationIds.contains(notification.id)) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );

      Log.d('Marked ${notificationIds.length} notifications as read');
    } catch (e) {
      Log.e('Error marking multiple notifications as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }).toList();

      // Calculate new stats from active notifications only
      final activeNotifications = updatedNotifications.where((n) => !n.isHidden).toList();
      final totalCount = activeNotifications.length;
      final highPriorityCount = activeNotifications.where((n) => n.isHighPriority).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
        totalCount: totalCount,
        highPriorityCount: highPriorityCount,
      );

      Log.d('Marked all notifications as read');
      Log.d('Updated stats - Total: $totalCount, Unread: 0, High Priority: $highPriorityCount');
    } catch (e) {
      Log.e('Error marking all notifications as read: $e');
    }
  }

  /// Dismiss notification
  Future<void> dismissNotification(String notificationId) async {
    try {
      await _notificationService.dismissNotification(notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(
            isHidden: true,
            dismissedAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();

      // Calculate new stats from active notifications only
      final activeNotifications = updatedNotifications.where((n) => !n.isHidden).toList();
      final unreadCount = activeNotifications.where((n) => !n.isRead).length;
      final totalCount = activeNotifications.length;
      final highPriorityCount = activeNotifications.where((n) => n.isHighPriority).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        totalCount: totalCount,
        highPriorityCount: highPriorityCount,
      );

      Log.d('Dismissed notification $notificationId');
      Log.d('Updated stats - Total: $totalCount, Unread: $unreadCount, High Priority: $highPriorityCount');
    } catch (e) {
      Log.e('Error dismissing notification: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      final updatedNotifications = state.notifications
        .where((notification) => notification.id != notificationId)
        .toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );

      Log.d('Deleted notification $notificationId');
    } catch (e) {
      Log.e('Error deleting notification: $e');
    }
  }

  /// Add notification to state (for real-time updates)
  void addNotification(app_notification.AppNotification notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    Log.d('Added new notification: ${notification.id}');
  }

  /// Update notification in state (for real-time updates)
  void updateNotification(app_notification.AppNotification notification) {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == notification.id) {
        return notification;
      }
      return n;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    Log.d('Updated notification: ${notification.id}');
  }

  /// Remove notification from state (for real-time updates)
  void removeNotification(String notificationId) {
    final updatedNotifications = state.notifications
      .where((n) => n.id != notificationId)
      .toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    Log.d('Removed notification: $notificationId');
  }

  /// Update unread count (for FCM updates)
  void updateUnreadCount() {
    final unreadCount = state.notifications.where((n) => !n.isRead).length;
    state = state.copyWith(unreadCount: unreadCount);
  }

  /// Start real-time subscription
  void startRealtimeSubscription() {
    try {
      _subscription?.cancel();
      
      _subscription = _notificationService.getNotificationsStream().listen(
        (notifications) {
          final unreadCount = notifications.where((n) => !n.isRead).length;
          state = state.copyWith(
            notifications: notifications,
            unreadCount: unreadCount,
          );
          Log.d('Real-time update: ${notifications.length} notifications');
        },
        onError: (error) {
          Log.e('Real-time subscription error: $error');
          state = state.copyWith(error: error.toString());
        },
      );

      Log.d('Started real-time notification subscription');
    } catch (e) {
      Log.e('Error starting real-time subscription: $e');
    }
  }

  /// Stop real-time subscription
  void stopRealtimeSubscription() {
    _subscription?.cancel();
    _subscription = null;
    Log.d('Stopped real-time notification subscription');
  }

  /// Dispose the provider and clean up resources
  @override
  void dispose() {
    stopRealtimeSubscription();
    super.dispose();
  }

  /// Send job assignment notification
  Future<void> sendJobAssignmentNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
    bool isReassignment = false,
  }) async {
    try {
      await _notificationService.sendJobAssignmentNotification(
        userId: userId,
        jobId: jobId,
        jobNumber: jobNumber,
        isReassignment: isReassignment,
      );
      Log.d('Job assignment notification sent');
    } catch (e) {
      Log.e('Error sending job assignment notification: $e');
      rethrow;
    }
  }

  /// Send job cancellation notification
  Future<void> sendJobCancellationNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
  }) async {
    try {
      await _notificationService.sendJobCancellationNotification(
        userId: userId,
        jobId: jobId,
        jobNumber: jobNumber,
      );
      Log.d('Job cancellation notification sent');
    } catch (e) {
      Log.e('Error sending job cancellation notification: $e');
      rethrow;
    }
  }

  /// Send job status change notification
  Future<void> sendJobStatusChangeNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      await _notificationService.sendJobStatusChangeNotification(
        userId: userId,
        jobId: jobId,
        jobNumber: jobNumber,
        oldStatus: oldStatus,
        newStatus: newStatus,
      );
      Log.d('Job status change notification sent');
    } catch (e) {
      Log.e('Error sending job status change notification: $e');
      rethrow;
    }
  }

  /// Send payment reminder notification
  Future<void> sendPaymentReminderNotification({
    required String userId,
    required String jobId,
    required String jobNumber,
    required String amount,
  }) async {
    try {
      await _notificationService.sendPaymentReminderNotification(
        userId: userId,
        jobId: jobId,
        jobNumber: jobNumber,
        amount: amount,
      );
      Log.d('Payment reminder notification sent');
    } catch (e) {
      Log.e('Error sending payment reminder notification: $e');
      rethrow;
    }
  }

  /// Send system alert notification
  Future<void> sendSystemAlertNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'normal',
    Map<String, dynamic>? actionData,
  }) async {
    try {
      await _notificationService.sendSystemAlertNotification(
        userId: userId,
        title: title,
        message: message,
        priority: priority,
        actionData: actionData,
      );
      Log.d('System alert notification sent');
    } catch (e) {
      Log.e('Error sending system alert notification: $e');
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Initialize the notification provider
  Future<void> initialize() async {
    try {
      Log.d('Initializing notification provider...');
      
      // Load initial notifications
      await loadNotifications();
      
      // Set up real-time subscription
      startRealtimeSubscription();
      
      // Load notification stats
      await loadStats();
      
      Log.d('Notification provider initialized successfully');
    } catch (e) {
      Log.e('Error initializing notification provider: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Hide notifications for a specific job
  Future<void> hideJobNotifications(String jobId) async {
    try {
      Log.d('Hiding notifications for job: $jobId');
      
      // Mark all notifications for this job as dismissed
      await _notificationService.dismissJobNotifications(jobId);
      
      // Reload notifications to reflect changes
      await loadNotifications();
      
      Log.d('Job notifications hidden successfully');
    } catch (e) {
      Log.e('Error hiding job notifications: $e');
      state = state.copyWith(error: e.toString());
    }
  }
}

// Providers
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
}); 