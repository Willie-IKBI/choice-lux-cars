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
        
        // Responsive breakpoints for mobile optimization
        final isMobile = availableWidth < 600;
        final isSmallMobile = availableWidth < 400;
        final isTablet = availableWidth >= 600 && availableWidth < 800;
        final isDesktop = availableWidth >= 800;
        final isLargeDesktop = availableWidth >= 1200;
        
        // Mobile-optimized grid configuration
        int crossAxisCount;
        double gridSpacing;
        EdgeInsets gridPadding;
        
        if (isSmallMobile) {
          // Small mobile: 1 column, compact spacing
          crossAxisCount = 1;
          gridSpacing = 8.0;
          gridPadding = const EdgeInsets.all(8.0);
        } else if (isMobile) {
          // Mobile: 1-2 columns, moderate spacing
          crossAxisCount = availableWidth < 500 ? 1 : 2;
          gridSpacing = 12.0;
          gridPadding = const EdgeInsets.all(12.0);
        } else if (isTablet) {
          // Tablet: 2 columns, standard spacing
          crossAxisCount = 2;
          gridSpacing = 16.0;
          gridPadding = const EdgeInsets.all(16.0);
        } else if (isDesktop) {
          // Desktop: 3 columns, generous spacing
          crossAxisCount = 3;
          gridSpacing = 20.0;
          gridPadding = const EdgeInsets.all(20.0);
        } else {
          // Large desktop: 4 columns, premium spacing
          crossAxisCount = 4;
          gridSpacing = 24.0;
          gridPadding = const EdgeInsets.all(24.0);
        }
        
        // Use GridView with mobile-optimized configuration
        return GridView.builder(
          padding: padding ?? gridPadding,
          shrinkWrap: shrinkWrap,
          physics: physics ?? (isMobile ? const AlwaysScrollableScrollPhysics() : null),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            childAspectRatio: _getChildAspectRatio(isMobile, isSmallMobile),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  double _getChildAspectRatio(bool isMobile, bool isSmallMobile) {
    // Mobile-optimized aspect ratios for better card proportions
    if (isSmallMobile) {
      return 1.2; // More compact for small screens
    } else if (isMobile) {
      return 1.4; // Slightly taller for mobile
    } else {
      return 1.6; // Standard aspect ratio for larger screens
    }
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