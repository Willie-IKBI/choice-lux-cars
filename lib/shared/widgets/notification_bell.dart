import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../features/notifications/screens/notification_list_screen.dart';

class NotificationBell extends StatefulWidget {
  final Color? iconColor;
  final double size;
  final VoidCallback? onTap;
  final bool showCount; // Option to show count or just a dot

  const NotificationBell({
    super.key,
    this.iconColor,
    this.size = 24.0,
    this.onTap,
    this.showCount = true,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

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

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));



    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      _showNotificationList();
    }
  }

  void _showNotificationList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notificationState = ref.watch(notificationProvider);
        final unreadCount = notificationState.unreadCount;
        

        
        // Animate when count changes from 0 to > 0
        if (unreadCount > 0 && !_animationController.isAnimating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _animationController.forward().then((_) {
                if (mounted) {
                  _animationController.reverse();
                }
              });
              // Start pulsing animation for new notifications
              _pulseController.repeat(reverse: true);
            }
          });
        } else if (unreadCount == 0) {
          // Stop pulsing when no notifications
          _pulseController.stop();
        }

        return GestureDetector(
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Stack(
            children: [
              // Bell icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: widget.iconColor ?? Theme.of(context).iconTheme.color,
                      size: widget.size,
                    ),
                  );
                },
              ),
              
              // Badge - Show with better positioning and styling
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: unreadCount == 1 ? 8 : null,
                          height: unreadCount == 1 ? 8 : 16,
                          padding: unreadCount == 1 
                              ? EdgeInsets.zero 
                              : EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F), // Dark red that fits the theme
                            shape: unreadCount == 1 ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius: unreadCount == 1 ? null : BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: unreadCount == 1
                              ? null // Just show the dot
                              : Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
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
          ),
        );
      },
    );
  }
} 