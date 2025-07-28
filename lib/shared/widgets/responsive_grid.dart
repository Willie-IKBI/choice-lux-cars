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
        final isMobile = availableWidth < 600;
        final isTablet = availableWidth < 900;
        final isMedium = availableWidth < 1200;
        final isLarge = availableWidth < 1600;
        
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing;
        double mainAxisSpacing;
        
        if (isMobile) {
          crossAxisCount = 1;
          childAspectRatio = 1.1;
          crossAxisSpacing = 12;
          mainAxisSpacing = 12;
        } else if (isTablet) {
          crossAxisCount = 2;
          childAspectRatio = 1.0;
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        } else if (isMedium) {
          crossAxisCount = 3;
          childAspectRatio = 0.9;
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        } else if (isLarge) {
          crossAxisCount = 4;
          childAspectRatio = 0.85;
          crossAxisSpacing = 20;
          mainAxisSpacing = 20;
        } else {
          crossAxisCount = 5;
          childAspectRatio = 0.8;
          crossAxisSpacing = 24;
          mainAxisSpacing = 24;
        }

        return GridView.builder(
          padding: padding ?? EdgeInsets.all(isMobile ? 12 : 16),
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
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