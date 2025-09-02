import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';

/// Extension methods for easier theme token access
extension ThemeExtension on BuildContext {
  /// Get the app tokens from the current theme
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  
  /// Get the brand gold color
  Color get brandGold => tokens.brandGold;
  
  /// Get the brand black color
  Color get brandBlack => tokens.brandBlack;
  
  /// Get the medium radius value
  double get radiusMd => tokens.radiusMd;
  
  /// Get the standard spacing value
  double get spacing => tokens.spacing;
}
