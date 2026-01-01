import 'package:flutter/material.dart';

/// App-wide design tokens for Stealth Luxury theme
///
/// This ThemeExtension provides centralized access to semantic color tokens,
/// text colors, interactive states, and visual effects that are not part
/// of Material 3's standard ColorScheme.
///
/// All tokens must match the values defined in /ai/THEME_SPEC.md
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // Status colors
  final Color successColor;
  final Color infoColor;
  final Color warningColor;
  final Color onSuccess;
  final Color onInfo;
  final Color onWarning;

  // Text color tokens
  final Color textHeading;
  final Color textBody;
  final Color textSubtle;

  // Interactive state tokens
  final Color hoverSurface;
  final Color activeSurface;
  final Color focusBorder;

  // Visual effect tokens
  final Color glowAmber;

  // Structural tokens (for convenience)
  final double cardRadius;
  final double buttonRadius;
  final double inputRadius;
  final Color borderColor;

  const AppTokens({
    required this.successColor,
    required this.infoColor,
    required this.warningColor,
    required this.onSuccess,
    required this.onInfo,
    required this.onWarning,
    required this.textHeading,
    required this.textBody,
    required this.textSubtle,
    required this.hoverSurface,
    required this.activeSurface,
    required this.focusBorder,
    required this.glowAmber,
    required this.cardRadius,
    required this.buttonRadius,
    required this.inputRadius,
    required this.borderColor,
  });

  @override
  AppTokens copyWith({
    Color? successColor,
    Color? infoColor,
    Color? warningColor,
    Color? onSuccess,
    Color? onInfo,
    Color? onWarning,
    Color? textHeading,
    Color? textBody,
    Color? textSubtle,
    Color? hoverSurface,
    Color? activeSurface,
    Color? focusBorder,
    Color? glowAmber,
    double? cardRadius,
    double? buttonRadius,
    double? inputRadius,
    Color? borderColor,
  }) {
    return AppTokens(
      successColor: successColor ?? this.successColor,
      infoColor: infoColor ?? this.infoColor,
      warningColor: warningColor ?? this.warningColor,
      onSuccess: onSuccess ?? this.onSuccess,
      onInfo: onInfo ?? this.onInfo,
      onWarning: onWarning ?? this.onWarning,
      textHeading: textHeading ?? this.textHeading,
      textBody: textBody ?? this.textBody,
      textSubtle: textSubtle ?? this.textSubtle,
      hoverSurface: hoverSurface ?? this.hoverSurface,
      activeSurface: activeSurface ?? this.activeSurface,
      focusBorder: focusBorder ?? this.focusBorder,
      glowAmber: glowAmber ?? this.glowAmber,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  ThemeExtension<AppTokens> lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      textHeading: Color.lerp(textHeading, other.textHeading, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      hoverSurface: Color.lerp(hoverSurface, other.hoverSurface, t)!,
      activeSurface: Color.lerp(activeSurface, other.activeSurface, t)!,
      focusBorder: Color.lerp(focusBorder, other.focusBorder, t)!,
      glowAmber: Color.lerp(glowAmber, other.glowAmber, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      buttonRadius: buttonRadius + (other.buttonRadius - buttonRadius) * t,
      inputRadius: inputRadius + (other.inputRadius - inputRadius) * t,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
    );
  }
}

/// Extension for easy access to AppTokens from BuildContext
extension AppTokensExtension on BuildContext {
  /// Get the app tokens from the current theme
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
