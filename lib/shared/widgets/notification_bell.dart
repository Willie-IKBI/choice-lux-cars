import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/features/notifications/screens/notification_list_screen.dart';
import 'package:choice_lux_cars/features/notifications/screens/notification_preferences_screen.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class NotificationBell extends StatefulWidget {
  final Color? iconColor;
  final double size;
  final VoidCallback? onTap;
  final bool showCount;
  final bool showMenu;

  const NotificationBell({
    super.key,
    this.iconColor,
    this.size = 24.0,
    this.onTap,
    this.showCount = true,
    this.showMenu = true,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.showMenu) {
      _showNotificationMenu();
    } else {
      _showNotificationList();
    }
  }

  void _showNotificationMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'notifications',
          child: Row(
            children: [
              const Icon(Icons.notifications, size: 20),
              const SizedBox(width: 8),
              const Text('Notifications'),
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref
                      .watch(notificationProvider)
                      .unreadCount;
                  if (unreadCount > 0) {
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
        // Only show settings option for super_admin
        if (userRole == 'super_admin')
          const PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings, size: 20),
                SizedBox(width: 8),
                Text('Notification Settings'),
              ],
            ),
          ),
      ],
    ).then((value) {
      switch (value) {
        case 'notifications':
          _showNotificationList();
          break;
        case 'settings':
          _showNotificationSettings();
          break;
      }
    });
  }

  void _showNotificationList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationListScreen()),
    );
  }

  void _showNotificationSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesScreen(),
      ),
    );
  }

  void _triggerNewNotificationAnimation() {
    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.reverse();
      }
    });
    _shakeController.forward().then((_) {
      if (mounted) {
        _shakeController.reset();
      }
    });
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notificationState = ref.watch(notificationProvider);
        final unreadCount = notificationState.unreadCount;

        // Use the same logic as notifications screen - only count active, unread notifications
        final activeUnreadCount = notificationState.notifications
            .where((n) => !n.isHidden && !n.isRead)
            .length;
        final displayCount = unreadCount > 0 ? unreadCount : activeUnreadCount;

        final hasHighPriority = notificationState.notifications.any(
          (n) => n.isHighPriority && !n.isRead,
        );
        final hasUrgent = notificationState.notifications.any(
          (n) => n.isUrgent && !n.isRead,
        );

        final shouldShowBadge = displayCount > 0;

        // Animate when count changes from 0 to > 0
        if (unreadCount > 0 && !_animationController.isAnimating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _triggerNewNotificationAnimation();
            }
          });
        } else if (unreadCount == 0) {
          // Stop pulsing when no unread notifications
          _pulseController.stop();
        }

        // Wrap in IconButton for proper 48x48px tap target
        return IconButton(
          onPressed: _handleTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bell icon with shake animation
              AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleAnimation,
                  _shakeAnimation,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle:
                          _shakeAnimation.value * 0.1 * (hasUrgent ? 2 : 1),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: _getIconColor(hasUrgent, hasHighPriority),
                        size: widget.size,
                      ),
                    ),
                  );
                },
              ),

              // Badge - Show for recent notifications (read or unread)
              if (shouldShowBadge && widget.showCount)
                Positioned(
                  right: -2,
                  top: -2,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: displayCount == 1 ? 8 : null,
                          height: displayCount == 1 ? 8 : 16,
                          padding: displayCount == 1
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                          decoration: BoxDecoration(
                            color: _getBadgeColor(hasUrgent, hasHighPriority),
                            shape: displayCount == 1
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            borderRadius: displayCount == 1
                                ? null
                                : BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getBadgeColor(
                                  hasUrgent,
                                  hasHighPriority,
                                ).withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: displayCount == 1
                              ? null // Just show the dot
                              : Text(
                                  displayCount > 99
                                      ? '99+'
                                      : displayCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          style: IconButton.styleFrom(
            // Ensure 48x48px minimum tap target
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero, // Remove default padding for icon-only
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
    );
  }

  Color _getIconColor(bool hasUrgent, bool hasHighPriority) {
    if (hasUrgent) {
      return Colors.red;
    } else if (hasHighPriority) {
      return Colors.orange;
    }
    return widget.iconColor ?? Theme.of(context).iconTheme.color!;
  }

  Color _getBadgeColor(bool hasUrgent, bool hasHighPriority) {
    if (hasUrgent) {
      return Colors.red;
    } else if (hasHighPriority) {
      return Colors.orange;
    }
    return const Color(0xFFD32F2F); // Default dark red
  }
}
