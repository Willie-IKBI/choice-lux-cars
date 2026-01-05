import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';

/// Backward-compatible shim for legacy ChoiceLuxTheme usages.
/// Maps to a stable palette to unblock web without altering logic.
class ChoiceLuxTheme {
  // Core brand palette (Obsidian Luxury Ops)
  static const Color richGold = Color(0xFFC6A87C); // Champagne Gold (was #C8A24A)
  static const Color purple = Color(0xFF8E24AA);
  static const Color orange = Color(0xFFFFA726);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color infoColor = Color(0xFF42A5F5);
  static const Color warningColor = Color(0xFFFFC107);

  static const Color jetBlack = Color(0xFF09090B); // Deepest Onyx (was #0B0B0C)
  static const Color charcoalGray = Color(0xFF18181B); // Zinc 900 (was #202125)
  static const Color grey = Color(0xFF9E9E9E);
  static const Color platinumSilver = Color(0xFF94A3B8); // Steel (was #B0B7C3)
  static const Color softWhite = Color(0xFFFFFFFF); // Pure White for headings (was #F5F7FA)

  // Gradients used across dashboard/cards/backgrounds (Obsidian)
  // Auth screens: Dark gradient with very soft gold backlight in corner
  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF09090B), // Obsidian background
      Color(0xFF121316), // Slightly lighter for subtle variation
      Color(0xFF09090B),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Auth background: Dark gradient with very soft gold backlight glow in top-right corner
  static const Gradient authBackgroundGradient = RadialGradient(
    center: Alignment.topRight,
    radius: 1.5,
    colors: [
      Color(0xFF13100D), // Very subtle gold tint (almost imperceptible)
      Color(0xFF0D0B09),
      Color(0xFF09090B), // Obsidian
    ],
    stops: [0.0, 0.4, 1.0],
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


