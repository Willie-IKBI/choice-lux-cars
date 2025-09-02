import 'package:flutter/material.dart';

/// App-wide design tokens for consistent theming
///
/// This class provides centralized access to brand colors, spacing, and radius values
/// that can be used throughout the app for consistent design.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color brandGold;
  final Color brandBlack;
  final double radiusMd;
  final double spacing;

  const AppTokens({
    required this.brandGold,
    required this.brandBlack,
    required this.radiusMd,
    required this.spacing,
  });

  @override
  AppTokens copyWith({
    Color? brandGold,
    Color? brandBlack,
    double? radiusMd,
    double? spacing,
  }) => AppTokens(
    brandGold: brandGold ?? this.brandGold,
    brandBlack: brandBlack ?? this.brandBlack,
    radiusMd: radiusMd ?? this.radiusMd,
    spacing: spacing ?? this.spacing,
  );

  @override
  ThemeExtension<AppTokens> lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      brandGold: Color.lerp(brandGold, other.brandGold, t)!,
      brandBlack: Color.lerp(brandBlack, other.brandBlack, t)!,
      radiusMd: radiusMd + (other.radiusMd - radiusMd) * t,
      spacing: spacing + (other.spacing - spacing) * t,
    );
  }
}
