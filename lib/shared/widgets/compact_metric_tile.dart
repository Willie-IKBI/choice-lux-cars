import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Compact metric tile for displaying simple metrics (numbers with labels)
/// Use this instead of full cards for metrics like "Total Clients: 25"
/// 
/// Guidelines:
/// - Mobile: Horizontal layout, minimal padding
/// - Tablet: Horizontal or vertical layout
/// - Desktop: Vertical layout, compact spacing
class CompactMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const CompactMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    final iconSize = ResponsiveTokens.getIconSize(screenWidth);
    
    final iconColorValue = iconColor ?? ChoiceLuxTheme.richGold;
    final backgroundColorValue = backgroundColor ?? 
        ChoiceLuxTheme.charcoalGray;

    Widget content;

    if (isMobile) {
      // Mobile: Horizontal layout for better space usage
      content = LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final isVerySmall = availableHeight < 60;
          
          final adjustedPadding = isVerySmall ? padding * 0.5 : padding * 0.75;
          final adjustedIconPadding = isVerySmall ? spacing * 0.6 : spacing;
          final adjustedIconSize = isVerySmall ? iconSize * 0.6 : iconSize * 0.75;
          final adjustedRowSpacing = isVerySmall ? spacing : spacing * 1.5;
          final adjustedColumnSpacing = isVerySmall ? spacing * 0.15 : spacing * 0.25;
          final adjustedValueFontSize = isVerySmall
              ? ResponsiveTokens.getFontSize(screenWidth, baseSize: 14)
              : ResponsiveTokens.getFontSize(screenWidth, baseSize: 16);
          final adjustedLabelFontSize = isVerySmall
              ? ResponsiveTokens.getFontSize(screenWidth, baseSize: 11)
              : ResponsiveTokens.getFontSize(screenWidth, baseSize: 12);
          
          return Container(
            padding: EdgeInsets.all(adjustedPadding),
            decoration: BoxDecoration(
              color: backgroundColorValue,
              borderRadius: BorderRadius.circular(ResponsiveTokens.getCornerRadius(screenWidth)),
              border: Border.all(
                color: iconColorValue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(adjustedIconPadding),
                  decoration: BoxDecoration(
                    color: iconColorValue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(ResponsiveTokens.getCornerRadius(screenWidth) * 0.8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColorValue,
                    size: adjustedIconSize,
                  ),
                ),
                SizedBox(width: adjustedRowSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Value - allow 2 lines for longer values
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: adjustedValueFontSize,
                          fontWeight: FontWeight.w700,
                          color: ChoiceLuxTheme.softWhite,
                        ),
                        maxLines: 2, // Changed from 1 to 2
                        overflow: TextOverflow.visible, // Changed from ellipsis to visible
                      ),
                      SizedBox(height: adjustedColumnSpacing),
                      // Label - allow wrapping
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: adjustedLabelFontSize,
                          color: ChoiceLuxTheme.platinumSilver,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2, // Changed from 1 to 2
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Tablet/Desktop: Vertical layout for better density
      // Use LayoutBuilder to get available height and adjust sizes accordingly
      content = LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final isVerySmall = availableHeight < 100;
          
          // Adjust sizes based on available space - reduced to prevent text cutoff
          final adjustedPadding = isVerySmall ? padding * 0.5 : padding * 0.75;
          final adjustedIconPadding = isVerySmall ? spacing * 0.6 : spacing * 1.0; // Reduced from 1.5
          final adjustedIconSize = isVerySmall ? iconSize * 0.5 : iconSize * 0.65; // Reduced from 0.75
          final adjustedSpacing = isVerySmall ? spacing * 0.3 : spacing * 0.8; // Reduced from 1.5
          final adjustedValueFontSize = isVerySmall 
              ? ResponsiveTokens.getFontSize(screenWidth, baseSize: 12) // Reduced from 14
              : ResponsiveTokens.getFontSize(screenWidth, baseSize: 16); // Reduced from 18
          final adjustedLabelFontSize = isVerySmall
              ? ResponsiveTokens.getFontSize(screenWidth, baseSize: 9) // Reduced from 10
              : ResponsiveTokens.getFontSize(screenWidth, baseSize: 11); // Reduced from 12
          final adjustedSmallSpacing = isVerySmall ? spacing * 0.2 : spacing * 0.4; // Reduced from 0.5
          
          return Container(
            padding: EdgeInsets.all(adjustedPadding),
            decoration: BoxDecoration(
              color: backgroundColorValue,
              borderRadius: BorderRadius.circular(ResponsiveTokens.getCornerRadius(screenWidth)),
              border: Border.all(
                color: iconColorValue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon - use fixed size instead of Flexible to prevent taking too much space
                Container(
                  padding: EdgeInsets.all(adjustedIconPadding),
                  decoration: BoxDecoration(
                    color: iconColorValue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(ResponsiveTokens.getCornerRadius(screenWidth) * 0.8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColorValue,
                    size: adjustedIconSize,
                  ),
                ),
                SizedBox(height: adjustedSpacing),
                // Value - allow up to 2 lines and use Flexible with constraints
                Flexible(
                  child: SizedBox(
                    height: adjustedValueFontSize * 2.5, // Max height for 2 lines
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: adjustedValueFontSize,
                          fontWeight: FontWeight.w700,
                          color: ChoiceLuxTheme.softWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: adjustedSmallSpacing),
                // Label - allow wrapping
                Text(
                  label,
                  style: TextStyle(
                    fontSize: adjustedLabelFontSize,
                    color: ChoiceLuxTheme.platinumSilver,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveTokens.getCornerRadius(screenWidth)),
        child: content,
      );
    }

    return content;
  }
}

