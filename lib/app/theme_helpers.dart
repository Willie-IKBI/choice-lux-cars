import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';

/// Extension methods for easier theme token access
///
/// This extension provides convenient access to AppTokens and ColorScheme
/// from BuildContext, following the patterns defined in /ai/THEME_RULES.md
extension ThemeExtension on BuildContext {
  /// Get the app tokens from the current theme
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;

  /// Get the color scheme from the current theme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get the text theme from the current theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get brand gold color (primary color)
  /// 
  /// Deprecated: Use colorScheme.primary instead
  @Deprecated('Use colorScheme.primary instead')
  Color get brandGold => colorScheme.primary;

  /// Get medium border radius
  /// 
  /// Deprecated: Use tokens.cardRadius instead
  @Deprecated('Use tokens.cardRadius instead')
  double get radiusMd => tokens.cardRadius;
}
