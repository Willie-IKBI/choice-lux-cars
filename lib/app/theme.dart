import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';

/// Backward-compatible shim for legacy ChoiceLuxTheme usages.
/// Maps to a stable palette to unblock web without altering logic.
class ChoiceLuxTheme {
  // Core brand palette (tuned to existing UI expectations)
  static const Color richGold = Color(0xFFC8A24A);
  static const Color purple = Color(0xFF8E24AA);
  static const Color orange = Color(0xFFFFA726);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color infoColor = Color(0xFF42A5F5);
  static const Color warningColor = Color(0xFFFFC107);

  static const Color jetBlack = Color(0xFF0B0B0C);
  static const Color charcoalGray = Color(0xFF202125);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color platinumSilver = Color(0xFFB0B7C3);
  static const Color softWhite = Color(0xFFF5F7FA);

  // Gradients used across dashboard/cards/backgrounds
  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E0F12), // deep charcoal
      Color(0xFF15171B),
      Color(0xFF1B1E23),
    ],
  );

  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F2126),
      Color(0xFF262A31),
    ],
  );

  // Minimal theme datas to satisfy app.dart references
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: richGold,
      primary: richGold,
      secondary: platinumSilver,
      error: errorColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: softWhite,
    appBarTheme: const AppBarTheme(backgroundColor: softWhite, foregroundColor: jetBlack),
    extensions: const <ThemeExtension<dynamic>>[
      AppTokens(
        brandGold: richGold,
        brandBlack: jetBlack,
        radiusMd: 12.0,
        spacing: 12.0,
      ),
    ],
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: richGold,
      primary: richGold,
      secondary: platinumSilver,
      error: errorColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: charcoalGray,
    appBarTheme: const AppBarTheme(backgroundColor: charcoalGray, foregroundColor: softWhite),
    extensions: const <ThemeExtension<dynamic>>[
      AppTokens(
        brandGold: richGold,
        brandBlack: softWhite,
        radiusMd: 12.0,
        spacing: 12.0,
      ),
    ],
  );
}


