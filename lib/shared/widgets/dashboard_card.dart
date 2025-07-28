import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

class DashboardCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? badge;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.badge,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? ChoiceLuxTheme.richGold;
    final backgroundColor = widget.backgroundColor ?? ChoiceLuxTheme.charcoalGray;
    
    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    
    // Debug: Print card sizing info
    print('DashboardCard - Screen width: $screenWidth, isMobile: $isMobile, isSmallMobile: $isSmallMobile');
    
    // Mobile-optimized sizing with better touch targets
    final iconSize = isSmallMobile ? 24.0 : isMobile ? 28.0 : 36.0;
    final iconContainerPadding = isSmallMobile ? 8.0 : isMobile ? 10.0 : 16.0;
    final cardPadding = isSmallMobile 
        ? const EdgeInsets.all(12.0)
        : isMobile 
            ? const EdgeInsets.all(16.0)
            : const EdgeInsets.all(24.0);
    final titleSpacing = isSmallMobile ? 8.0 : isMobile ? 10.0 : 16.0;
    final borderRadius = isMobile ? 12.0 : 20.0;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor,
                    backgroundColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                  if (_isHovered)
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                ],
                border: Border.all(
                  color: _isHovered 
                      ? iconColor.withOpacity(0.3) 
                      : Colors.white.withOpacity(0.1),
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Container(
                    padding: cardPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Container with better touch target
                        Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.all(iconContainerPadding),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(borderRadius * 0.8),
                                border: Border.all(
                                  color: iconColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                widget.icon,
                                size: iconSize,
                                color: iconColor,
                              ),
                            ),
                            // Badge
                            if (widget.badge != null)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    widget.badge!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: titleSpacing),
                        
                        // Title - simplified for mobile
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ChoiceLuxTheme.softWhite,
                            fontSize: isSmallMobile ? 14 : isMobile ? 16 : 18,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Subtitle - only show on larger screens for cleaner mobile experience
                        if (widget.subtitle != null && !isMobile) ...[
                          SizedBox(height: 6),
                          Text(
                            widget.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ChoiceLuxTheme.platinumSilver,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 