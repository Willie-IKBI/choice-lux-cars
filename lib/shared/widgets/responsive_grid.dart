import 'package:flutter/material.dart';

/// Centralized responsive breakpoints for consistent design across the app
class ResponsiveBreakpoints {
  // Standard breakpoints following Material Design guidelines
  static const double smallMobile = 400;
  static const double mobile = 600;
  static const double tablet = 800;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;

  // Utility methods for consistent breakpoint checking
  static bool isSmallMobile(double width) => width < smallMobile;
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet && width < desktop;
  static bool isLargeDesktop(double width) => width >= desktop;

  // Combined checks for common patterns
  static bool isMobileOrSmall(double width) => width < mobile;
  static bool isTabletOrLarger(double width) => width >= tablet;
  static bool isDesktopOrLarger(double width) => width >= desktop;
}

/// Responsive design tokens for consistent spacing and sizing
class ResponsiveTokens {
  static double getPadding(double width) {
    if (ResponsiveBreakpoints.isSmallMobile(width)) return 8.0;
    if (ResponsiveBreakpoints.isMobile(width)) return 12.0;
    if (ResponsiveBreakpoints.isTablet(width)) return 16.0;
    if (ResponsiveBreakpoints.isDesktop(width)) return 20.0;
    return 24.0; // Large desktop
  }

  static double getSpacing(double width) {
    if (ResponsiveBreakpoints.isSmallMobile(width)) return 4.0;
    if (ResponsiveBreakpoints.isMobile(width)) return 6.0;
    if (ResponsiveBreakpoints.isTablet(width)) return 8.0;
    if (ResponsiveBreakpoints.isDesktop(width)) return 12.0;
    return 16.0; // Large desktop
  }

  static double getCornerRadius(double width) {
    if (ResponsiveBreakpoints.isSmallMobile(width)) return 6.0;
    if (ResponsiveBreakpoints.isMobile(width)) return 8.0;
    if (ResponsiveBreakpoints.isTablet(width)) return 10.0;
    if (ResponsiveBreakpoints.isDesktop(width)) return 12.0;
    return 16.0; // Large desktop
  }

  static double getIconSize(double width) {
    if (ResponsiveBreakpoints.isSmallMobile(width)) return 16.0;
    if (ResponsiveBreakpoints.isMobile(width)) return 18.0;
    if (ResponsiveBreakpoints.isTablet(width)) return 20.0;
    if (ResponsiveBreakpoints.isDesktop(width)) return 24.0;
    return 28.0; // Large desktop
  }

  static double getFontSize(double width, {double baseSize = 14.0}) {
    if (ResponsiveBreakpoints.isSmallMobile(width)) return baseSize - 2;
    if (ResponsiveBreakpoints.isMobile(width)) return baseSize - 1;
    if (ResponsiveBreakpoints.isTablet(width)) return baseSize;
    if (ResponsiveBreakpoints.isDesktop(width)) return baseSize + 1;
    return baseSize + 2; // Large desktop
  }
}

/// Enhanced responsive grid with proper overflow handling
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

        // Use centralized breakpoints
        final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(
          availableWidth,
        );
        final isMobile = ResponsiveBreakpoints.isMobile(availableWidth);
        final isTablet = ResponsiveBreakpoints.isTablet(availableWidth);
        final isDesktop = ResponsiveBreakpoints.isDesktop(availableWidth);
        final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(
          availableWidth,
        );

        // Grid configuration based on screen size
        final gridConfig = _getGridConfiguration(
          availableWidth,
          isSmallMobile,
          isMobile,
          isTablet,
          isDesktop,
          isLargeDesktop,
        );

        return GridView.builder(
          padding: padding ?? gridConfig.padding,
          shrinkWrap: shrinkWrap,
          physics:
              physics ??
              (isMobile ? const AlwaysScrollableScrollPhysics() : null),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: gridConfig.maxCrossAxisExtent,
            crossAxisSpacing: gridConfig.spacing,
            mainAxisSpacing: gridConfig.spacing,
            childAspectRatio: gridConfig.aspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  _GridConfiguration _getGridConfiguration(
    double width,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool isLargeDesktop,
  ) {
    if (isSmallMobile) {
      return _GridConfiguration(
        maxCrossAxisExtent: width - 32, // Full width minus padding
        spacing: ResponsiveTokens.getSpacing(width),
        padding: EdgeInsets.all(ResponsiveTokens.getPadding(width)),
        aspectRatio: 1.6, // Shorter aspect ratio to prevent overflow
      );
    } else if (isMobile) {
      return _GridConfiguration(
        maxCrossAxisExtent: width < 500
            ? width - 32
            : (width - 48) / 2, // 1 or 2 columns
        spacing: ResponsiveTokens.getSpacing(width),
        padding: EdgeInsets.all(ResponsiveTokens.getPadding(width)),
        aspectRatio: 1.8, // Shorter aspect ratio to prevent overflow
      );
    } else if (isTablet) {
      return _GridConfiguration(
        maxCrossAxisExtent: (width - 64) / 2, // 2 columns
        spacing: ResponsiveTokens.getSpacing(width),
        padding: EdgeInsets.all(ResponsiveTokens.getPadding(width)),
        aspectRatio: 2.0, // Shorter aspect ratio to prevent overflow
      );
    } else if (isDesktop) {
      return _GridConfiguration(
        maxCrossAxisExtent: (width - 96) / 3, // 3 columns
        spacing: ResponsiveTokens.getSpacing(width),
        padding: EdgeInsets.all(ResponsiveTokens.getPadding(width)),
        aspectRatio: 2.2, // Shorter aspect ratio to prevent overflow
      );
    } else {
      return _GridConfiguration(
        maxCrossAxisExtent: (width - 128) / 4, // 4 columns
        spacing: ResponsiveTokens.getSpacing(width),
        padding: EdgeInsets.all(ResponsiveTokens.getPadding(width)),
        aspectRatio: 2.4, // Shorter aspect ratio to prevent overflow
      );
    }
  }
}

/// Internal configuration class for grid settings
class _GridConfiguration {
  final double maxCrossAxisExtent;
  final double spacing;
  final EdgeInsets padding;
  final double aspectRatio;

  const _GridConfiguration({
    required this.maxCrossAxisExtent,
    required this.spacing,
    required this.padding,
    required this.aspectRatio,
  });
}

/// Extension for easy responsive access in widgets
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isSmallMobile => ResponsiveBreakpoints.isSmallMobile(screenWidth);
  bool get isMobile => ResponsiveBreakpoints.isMobile(screenWidth);
  bool get isTablet => ResponsiveBreakpoints.isTablet(screenWidth);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(screenWidth);
  bool get isLargeDesktop => ResponsiveBreakpoints.isLargeDesktop(screenWidth);

  double get responsivePadding => ResponsiveTokens.getPadding(screenWidth);
  double get responsiveSpacing => ResponsiveTokens.getSpacing(screenWidth);
  double get responsiveCornerRadius =>
      ResponsiveTokens.getCornerRadius(screenWidth);
  double get responsiveIconSize => ResponsiveTokens.getIconSize(screenWidth);

  double responsiveFontSize(double baseSize) =>
      ResponsiveTokens.getFontSize(screenWidth, baseSize: baseSize);
}
