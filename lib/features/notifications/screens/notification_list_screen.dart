import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../widgets/notification_card.dart';
import '../../../shared/widgets/luxury_app_bar.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Notifications',
        showBackButton: true,
        showLogo: false,
        actions: [
          // Test button for creating notifications
          IconButton(
            onPressed: () => _createTestNotification(),
            icon: const Icon(Icons.add),
            tooltip: 'Create Test Notification',
          ),
          Consumer(
            builder: (context, ref, child) {
              final notificationState = ref.watch(notificationProvider);
              final unreadCount = notificationState.unreadCount;
              
              if (unreadCount > 0) {
                return TextButton(
                  onPressed: () => _showMarkAllReadDialog(context),
                  child: const Text('Mark All Read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final notificationState = ref.watch(notificationProvider);
          
          if (notificationState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (notificationState.error != null) {
            return _buildErrorState(notificationState.error!);
          }

          if (notificationState.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(notificationProvider.notifier).fetchNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notificationState.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationState.notifications[index];
                return NotificationCard(
                  notification: notification,
                  onDismiss: () {
                    // Show undo snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notification deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            // Note: In a real app, you'd want to implement undo functionality
                            // For now, we'll just show a message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Undo functionality not implemented'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when you\'re assigned new jobs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
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
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).fetchNotifications();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _createTestNotification() async {
    try {
      final notificationService = NotificationService();
      await notificationService.createJobAssignmentNotification(
        jobId: '1', // Test job ID
        jobNumber: 'TEST-001',
      );
      
      // Refresh notifications
      await ref.read(notificationProvider.notifier).fetchNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job assignment notification created successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating job assignment notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMarkAllReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: const Text(
          'Are you sure you want to mark all notifications as read?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                ),
              );
            },
            child: const Text('Mark All Read'),
          ),
        ],
      ),
    );
  }
} 