import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';

// Notification State
class NotificationState {
  final List<app_notification.AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    required this.notifications,
    required this.unreadCount,
    required this.isLoading,
    this.error,
  });

  factory NotificationState.initial() => const NotificationState(
    notifications: [],
    unreadCount: 0,
    isLoading: false,
  );

  NotificationState copyWith({
    List<app_notification.AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<app_notification.AppNotification> get unreadNotifications => 
      notifications.where((n) => !n.isRead).toList();
}

// Notification Provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService = NotificationService();
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _notificationChannel;
  bool _isInitialized = false;

  NotificationNotifier() : super(NotificationState.initial());

  /// Initialize the notification provider
  Future<void> initialize() async {
    if (_isInitialized) {
      print('NotificationProvider: Already initialized, skipping');
      return;
    }
    
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      print('NotificationProvider: No current user, skipping initialization');
      return;
    }
    
    print('NotificationProvider: Initializing for user: ${currentUser.id}');
    _isInitialized = true; // Set this early to prevent multiple calls
    
    try {
      await fetchNotifications();
      await updateUnreadCount();
      _setupRealtimeSubscriptions();
      print('NotificationProvider: Initialization complete');
    } catch (e) {
      print('NotificationProvider: Initialization failed: $e');
      _isInitialized = false; // Reset on failure
    }
  }

  /// Auto-initialize when provider is accessed
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      print('NotificationProvider: Auto-initializing...');
      await initialize();
      print('NotificationProvider: Auto-initialization complete');
    }
  }

  /// Set up real-time subscriptions for notifications
  void _setupRealtimeSubscriptions() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    // Cancel existing subscriptions
    _notificationChannel?.unsubscribe();

    // Subscribe to notifications for the current user
    _notificationChannel = _supabase
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser.id,
          ),
          callback: (payload) {
            final notification = app_notification.AppNotification.fromJson(payload.newRecord);
            addNotification(notification);
            updateUnreadCount();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser.id,
          ),
          callback: (payload) {
            final notification = app_notification.AppNotification.fromJson(payload.newRecord);
            updateNotification(notification);
            updateUnreadCount();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser.id,
          ),
          callback: (payload) {
            final notificationId = payload.oldRecord['id'] as String;
            removeNotification(notificationId);
            updateUnreadCount();
          },
        )
        .subscribe();
  }

  /// Fetch all notifications for the current user
  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      print('NotificationProvider: Fetching notifications...');
      final notifications = await _notificationService.getNotifications(
        unreadOnly: unreadOnly,
      );
      print('NotificationProvider: Fetched ${notifications.length} notifications');
      
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (e) {
      print('NotificationProvider: Error fetching notifications: $e');
      state = state.copyWith(
        error: 'Failed to fetch notifications: $e',
        isLoading: false,
      );
    }
  }

  /// Update the unread count
  Future<void> updateUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update unread count: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local state
      final index = state.notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotifications = List<app_notification.AppNotification>.from(state.notifications);
        updatedNotifications[index] = updatedNotifications[index].copyWith(isRead: true);
        
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Update local state
      final updatedNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all notifications as read: $e');
    }
  }

  /// Mark all notifications for a specific job as read
  Future<void> markJobNotificationsAsRead(String jobId) async {
    try {
      await _notificationService.markJobNotificationsAsRead(jobId);
      
      // Update local state
      int updatedCount = 0;
      final updatedNotifications = state.notifications.map((n) {
        if (n.jobId == jobId && !n.isRead) {
          updatedCount++;
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > updatedCount ? state.unreadCount - updatedCount : 0,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark job notifications as read: $e');
    }
  }

  /// Hide notifications for a specific job (soft delete)
  Future<void> hideJobNotifications(String jobId) async {
    try {
      await _notificationService.hideJobNotifications(jobId);
      
      // Update local state - remove hidden notifications
      final updatedNotifications = state.notifications.where((n) => n.jobId != jobId).toList();
      final hiddenCount = state.notifications.length - updatedNotifications.length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > hiddenCount ? state.unreadCount - hiddenCount : 0,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to hide job notifications: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Update local state
      final notification = state.notifications.firstWhere((n) => n.id == notificationId);
      final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: !notification.isRead && state.unreadCount > 0 ? state.unreadCount - 1 : state.unreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete notification: $e');
    }
  }

  /// Add a new notification to the list
  void addNotification(app_notification.AppNotification notification) {
    final updatedNotifications = [notification, ...state.notifications];
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: !notification.isRead ? state.unreadCount + 1 : state.unreadCount,
    );
  }

  /// Update an existing notification
  void updateNotification(app_notification.AppNotification notification) {
    final index = state.notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      final oldNotification = state.notifications[index];
      final updatedNotifications = List<app_notification.AppNotification>.from(state.notifications);
      updatedNotifications[index] = notification;
      
      // Update unread count if read status changed
      int newUnreadCount = state.unreadCount;
      if (oldNotification.isRead != notification.isRead) {
        if (notification.isRead) {
          newUnreadCount = newUnreadCount > 0 ? newUnreadCount - 1 : 0;
        } else {
          newUnreadCount++;
        }
      }
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    }
  }

  /// Remove a notification from the list
  void removeNotification(String notificationId) {
    final notification = state.notifications.firstWhere((n) => n.id == notificationId);
    final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
    
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: !notification.isRead && state.unreadCount > 0 ? state.unreadCount - 1 : state.unreadCount,
    );
  }





  /// Clear all notifications (for testing or cleanup)
  void clearAll() {
    state = state.copyWith(
      notifications: [],
      unreadCount: 0,
    );
  }

  /// Refresh subscriptions (call when user changes)
  void refreshSubscriptions() {
    _setupRealtimeSubscriptions();
  }

  /// Dispose resources
  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    super.dispose();
  }
} 