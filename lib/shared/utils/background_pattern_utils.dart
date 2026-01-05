import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

/// Shared background pattern painter to eliminate duplication across screens
class BackgroundPatternPainter extends CustomPainter {
  final double opacity;
  final double strokeWidth;
  final double gridSpacing;

  const BackgroundPatternPainter({
    this.opacity = 0.03,
    this.strokeWidth = 1.0,
    this.gridSpacing = 50.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ChoiceLuxTheme.richGold.withOpacity(opacity)
      ..strokeWidth = strokeWidth;

    // Draw subtle grid pattern
    for (double i = 0; i < size.width; i += gridSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += gridSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vertical grid painter for architectural structure (auth screens)
class VerticalGridPainter extends CustomPainter {
  final double opacity;
  final double strokeWidth;
  final double gridSpacing;

  const VerticalGridPainter({
    this.opacity = 0.015,
    this.strokeWidth = 1.0,
    this.gridSpacing = 80.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ChoiceLuxTheme.richGold.withOpacity(opacity)
      ..strokeWidth = strokeWidth;

    // Draw only vertical lines for architectural structure
    for (double i = 0; i < size.width; i += gridSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Predefined background patterns for different screen types
class BackgroundPatterns {
  /// Signin screen pattern - vertical grid only (architectural structure)
  static const signin = VerticalGridPainter(
    opacity: 0.015,
    strokeWidth: 1.0,
    gridSpacing: 80.0,
  );

  /// Dashboard pattern - more subtle
  static const dashboard = BackgroundPatternPainter(
    opacity: 0.05,
    strokeWidth: 1.0,
    gridSpacing: 60.0,
  );
}
