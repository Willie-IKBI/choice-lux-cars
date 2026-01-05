import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/app/theme_helpers.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
    final iconColor = widget.iconColor ?? context.brandGold;
    final backgroundColor =
        widget.backgroundColor ?? ChoiceLuxTheme.charcoalGray;

    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    final iconSize = ResponsiveTokens.getIconSize(screenWidth);

    // Debug: Print card sizing info
    debugPrint(
      'DashboardCard - Screen width: $screenWidth, isMobile: $isMobile, isSmallMobile: $isSmallMobile',
    );

    // Responsive sizing - compact cards (fixed sizes to prevent overflow)
    final iconSizeValue = isSmallMobile
        ? 24.0
        : isMobile
        ? 28.0
        : 20.0; // Smaller icons for compact design
    final iconContainerPadding = isMobile ? 8.0 : 6.0;
    final cardPadding = EdgeInsets.all(isMobile ? 14.0 : 10.0); // Reduced padding to prevent overflow
    final titleSpacing = isMobile ? 6.0 : 4.0; // Reduced spacing
    final borderRadius = 12.0; // Fixed border radius

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
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                ],
                border: Border.all(
                  color: _isHovered
                      ? iconColor.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Main card content
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        debugPrint('DashboardCard - Tapped: ${widget.title}');
                        widget.onTap();
                      },
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Container(
                        padding: cardPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Icon Container with dark background and colored outline
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(iconContainerPadding),
                                  decoration: BoxDecoration(
                                    color: ChoiceLuxTheme.jetBlack,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: iconColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    size: iconSizeValue,
                                    color: iconColor,
                                  ),
                                ),
                                // Badge
                                if (widget.badge != null)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
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

                            // Title - gold color to match reference images (Outfit font)
                            Text(
                              widget.title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                                fontSize: isMobile ? 13.0 : 14.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Subtitle - always visible, consistent styling (Inter font)
                            if (widget.subtitle != null) ...[
                              SizedBox(height: 4),
                              Text(
                                widget.subtitle!,
                                style: GoogleFonts.inter(
                                  color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w400,
                                  fontSize: isMobile ? 10.0 : 11.0,
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
                  // Colored shine overlay on hover
                  if (_isHovered)
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.8,
                            colors: [
                              iconColor.withValues(alpha: 0.2),
                              iconColor.withValues(alpha: 0.08),
                              iconColor.withValues(alpha: 0.0),
                            ],
                            stops: [0.0, 0.3, 0.7],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
