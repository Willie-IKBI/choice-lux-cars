import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.padding,
    this.maxWidth,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = maxWidth ?? constraints.maxWidth;
        
        // Card width from JobCard design tokens
        const double cardWidth = 380.0;
        const double cardMargin = 16.0; // 8px margin on each side
        const double gridSpacing = 16.0;
        
        // Calculate how many cards can fit in the available width
        final effectiveCardWidth = cardWidth + cardMargin * 2; // Card + margins
        final availableSpaceForCards = availableWidth - (gridSpacing * 2); // Account for grid padding
        final maxCardsPerRow = (availableSpaceForCards / (effectiveCardWidth + gridSpacing)).floor();
        
        // Ensure at least 1 column and cap at 4 columns for very large screens
        final crossAxisCount = maxCardsPerRow.clamp(1, 4);
        
        // Debug logging
        print('ResponsiveGrid - Available width: $availableWidth');
        print('ResponsiveGrid - Effective card width: $effectiveCardWidth');
        print('ResponsiveGrid - Available space for cards: $availableSpaceForCards');
        print('ResponsiveGrid - Max cards per row: $maxCardsPerRow');
        print('ResponsiveGrid - Final column count: $crossAxisCount');
        
        // Use GridView with calculated cross axis count
        return GridView.builder(
          padding: padding ?? EdgeInsets.all(gridSpacing),
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            // Let cards size themselves naturally
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double smallTablet = 840;
  static const double largeTablet = 1200;
  static const double desktop = 1200;
  
  static bool isMobile(double width) => width <= mobile;
  static bool isSmallTablet(double width) => width > mobile && width <= smallTablet;
  static bool isLargeTablet(double width) => width > smallTablet && width <= largeTablet;
  static bool isDesktop(double width) => width > largeTablet;
} 