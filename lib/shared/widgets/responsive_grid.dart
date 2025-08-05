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
        final isMobile = availableWidth < 768; // Increased mobile breakpoint
        final isTablet = availableWidth < 900;
        final isMedium = availableWidth < 1200;
        final isLarge = availableWidth < 1600;
        
        // Debug logging
        print('ResponsiveGrid - Available width: $availableWidth');
        print('ResponsiveGrid - isMobile: $isMobile, isTablet: $isTablet');
        
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing;
        double mainAxisSpacing;
        
        if (isMobile) {
          crossAxisCount = 1;
          childAspectRatio = 1.2; // Very compact aspect ratio for mobile cards
          crossAxisSpacing = 4; // Minimal spacing for mobile
          mainAxisSpacing = 4; // Minimal vertical spacing between cards
        } else if (isTablet) {
          crossAxisCount = 2;
          childAspectRatio = 1.8; // Taller aspect ratio for more compact cards
          crossAxisSpacing = 16;
          mainAxisSpacing = 12; // Reduced vertical spacing
        } else if (isMedium) {
          crossAxisCount = 3;
          childAspectRatio = 1.6; // Taller aspect ratio for compact cards
          crossAxisSpacing = 20; // Reduced horizontal spacing
          mainAxisSpacing = 16; // Reduced vertical spacing
        } else if (isLarge) {
          crossAxisCount = 4;
          childAspectRatio = 1.4; // Taller aspect ratio for compact cards
          crossAxisSpacing = 20; // Reduced spacing
          mainAxisSpacing = 16;
        } else {
          crossAxisCount = 5;
          childAspectRatio = 1.3; // Taller aspect ratio for compact cards
          crossAxisSpacing = 20;
          mainAxisSpacing = 16;
        }

        // Use GridView for all screen sizes, but with different configurations
        print('ResponsiveGrid - Using GridView layout for all screen sizes');
        return GridView.builder(
          padding: padding ?? EdgeInsets.all(isMobile ? 6 : 12),
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: availableWidth / crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            // Remove childAspectRatio to let cards determine their own height
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
  static const double tablet = 900;
  static const double medium = 1200;
  static const double large = 1600;
  
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isMedium(double width) => width >= tablet && width < medium;
  static bool isLarge(double width) => width >= medium && width < large;
  static bool isXLarge(double width) => width >= large;
} 