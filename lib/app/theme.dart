import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';

/// Stealth Luxury (Fleet Command Dark) Theme
///
/// This is the authoritative theme implementation for Choice Lux Cars.
/// All theme configuration must be centralized here.
///
/// Theme specification: /ai/THEME_SPEC.md
/// Theme rules: /ai/THEME_RULES.md
class ChoiceLuxTheme {
  // Private constructor to prevent instantiation
  ChoiceLuxTheme._();

  // Legacy constants for backward compatibility (deprecated)
  // TODO: Migrate to theme tokens - see /ai/THEME_RULES.md
  @Deprecated('Use Theme.of(context).colorScheme.error instead')
  static const Color errorColor = Color(0xFFF43F5E);
  
  @Deprecated('Use Theme.of(context).extension<AppTokens>()!.textHeading instead')
  static const Color softWhite = Color(0xFFFAFAFA);
  
  @Deprecated('Use Theme.of(context).extension<AppTokens>()!.textBody instead')
  static const Color platinumSilver = Color(0xFFA1A1AA);
  
  @Deprecated('Use Theme.of(context).colorScheme.primary instead')
  static const Color richGold = Color(0xFFF59E0B);

  /// Dark theme (Stealth Luxury) - the only theme for this app
  ///
  /// This theme implements Material 3 with dark mode only.
  /// All color values match /ai/THEME_SPEC.md exactly.
  static ThemeData get darkTheme {
    // Define color scheme according to THEME_SPEC.md Section 3
    final colorScheme = ColorScheme.dark(
      // Primary colors
      primary: const Color(0xFFF59E0B), // primary token - amber
      onPrimary: const Color(0xFF09090B), // onPrimary token
      primaryContainer: const Color(0xFFF59E0B).withOpacity(0.1), // primaryContainer token

      // Secondary colors
      secondary: const Color(0xFF27272A), // secondary token
      onSecondary: const Color(0xFFFAFAFA), // onSecondary token
      secondaryContainer: const Color(0xFF27272A), // surfaceVariant token
      onSecondaryContainer: const Color(0xFFA1A1AA), // textBody token

      // Tertiary (matches secondary)
      tertiary: const Color(0xFF27272A),
      onTertiary: const Color(0xFFFAFAFA),

      // Error/Warning
      error: const Color(0xFFF43F5E), // warning token
      onError: const Color(0xFFFAFAFA), // onWarning token
      errorContainer: const Color(0xFFF43F5E).withOpacity(0.1),
      onErrorContainer: const Color(0xFFF43F5E),

      // Background & Surface
      background: const Color(0xFF09090B), // background token
      onBackground: const Color(0xFFFAFAFA), // textHeading token
      surface: const Color(0xFF18181B), // surface token
      onSurface: const Color(0xFFFAFAFA), // textHeading token
      surfaceVariant: const Color(0xFF27272A), // surfaceVariant token
      onSurfaceVariant: const Color(0xFFA1A1AA), // textBody token

      // Outline (borders)
      outline: const Color(0xFF27272A), // border token
      outlineVariant: const Color(0xFF27272A).withOpacity(0.5), // borderVariant token

      // Inverse (for elevated surfaces)
      inverseSurface: const Color(0xFF27272A),
      onInverseSurface: const Color(0xFFFAFAFA),
      inversePrimary: const Color(0xFFF59E0B),

      // Shadow
      shadow: Colors.black,
      scrim: Colors.black.withOpacity(0.5),

      // Surface tint (for elevation)
      surfaceTint: const Color(0xFF27272A),
    );

    // Define text theme according to THEME_SPEC.md Section 4
    final textTheme = TextTheme(
      // Display (largest, rarely used)
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFFFAFAFA), // textHeading
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFFFAFAFA),
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFFFAFAFA),
      ),

      // Headline (page titles, section headers)
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFFFAFAFA), // textHeading
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFFFAFAFA),
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: const Color(0xFFFAFAFA),
      ),

      // Title (card titles, subsection headers)
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: const Color(0xFFFAFAFA), // textHeading
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: const Color(0xFFFAFAFA),
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: const Color(0xFFFAFAFA),
      ),

      // Label (buttons, form labels, table headers)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5, // wide for small uppercase
        color: const Color(0xFFFAFAFA),
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: const Color(0xFFA1A1AA), // textBody
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: const Color(0xFF52525B), // textSubtle
      ),

      // Body (default text)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: const Color(0xFFA1A1AA), // textBody
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: const Color(0xFFA1A1AA),
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: const Color(0xFF52525B), // textSubtle
      ),
    );

    // Define AppTokens extension according to THEME_SPEC.md Section 2
    final appTokens = AppTokens(
      // Status colors
      successColor: const Color(0xFF10B981), // success token
      infoColor: const Color(0xFF3B82F6), // info token
      warningColor: const Color(0xFFF43F5E), // warning token
      onSuccess: const Color(0xFF09090B), // onSuccess token
      onInfo: const Color(0xFFFAFAFA), // onInfo token
      onWarning: const Color(0xFFFAFAFA), // onWarning token

      // Text color tokens
      textHeading: const Color(0xFFFAFAFA), // textHeading token
      textBody: const Color(0xFFA1A1AA), // textBody token
      textSubtle: const Color(0xFF52525B), // textSubtle token

      // Interactive state tokens
      hoverSurface: const Color(0xFF27272A), // hoverSurface token
      activeSurface: const Color(0xFFF59E0B).withOpacity(0.1), // activeSurface token
      focusBorder: const Color(0xFFF59E0B), // focusBorder token

      // Visual effect tokens
      glowAmber: const Color(0xFFF59E0B).withOpacity(0.3), // glowAmber token

      // Structural tokens
      cardRadius: 12.0, // 12px for cards
      buttonRadius: 8.0, // 8px for buttons/inputs
      inputRadius: 8.0, // 8px for inputs
      borderColor: const Color(0xFF27272A), // border token
    );

    // Build ThemeData with Material 3
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Scaffold
      scaffoldBackgroundColor: colorScheme.background,

      // AppBar theme according to THEME_SPEC.md Section 5
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface, // surface token
        foregroundColor: textTheme.titleLarge?.color, // textHeading
        elevation: 0, // no shadow, uses border instead
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: appTokens.textBody, // textBody color
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: appTokens.textHeading,
        ),
      ),

      // Card theme according to THEME_SPEC.md Section 5
      cardTheme: CardThemeData(
        color: colorScheme.surface, // surface token
        elevation: 0, // shadowSm handled by shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(appTokens.cardRadius), // 12px
          side: BorderSide(
            color: appTokens.borderColor, // border token
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(16),
      ),

      // Input decoration theme according to THEME_SPEC.md Section 5
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant, // surfaceVariant token
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appTokens.inputRadius), // 8px
          borderSide: BorderSide(
            color: appTokens.borderColor, // border token
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appTokens.inputRadius),
          borderSide: BorderSide(
            color: appTokens.borderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appTokens.inputRadius),
          borderSide: BorderSide(
            color: appTokens.focusBorder, // focusBorder token
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appTokens.inputRadius),
          borderSide: BorderSide(
            color: appTokens.warningColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appTokens.inputRadius),
          borderSide: BorderSide(
            color: appTokens.warningColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: appTokens.textSubtle, // textSubtle token
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: appTokens.textBody, // textBody token
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: appTokens.focusBorder, // primary when focused
        ),
      ),

      // ElevatedButton theme according to THEME_SPEC.md Section 5
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary, // primary token
          foregroundColor: colorScheme.onPrimary, // onPrimary token
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(appTokens.buttonRadius), // 8px
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
        ),
      ),

      // OutlinedButton theme according to THEME_SPEC.md Section 5
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: appTokens.textBody, // textBody token
          side: BorderSide(
            color: appTokens.borderColor, // border token
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(appTokens.buttonRadius), // 8px
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // TextButton theme according to THEME_SPEC.md Section 5
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: appTokens.textBody, // textBody token
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(appTokens.buttonRadius), // 8px
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Divider theme according to THEME_SPEC.md Section 5
      dividerTheme: DividerThemeData(
        color: appTokens.borderColor, // divider token
        thickness: 1,
        space: 8,
      ),

      // Snackbar theme according to THEME_SPEC.md Section 5
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface, // surface token
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: appTokens.textBody, // textBody token
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(appTokens.buttonRadius), // 8px
          side: BorderSide(
            color: appTokens.borderColor, // border token
            width: 1,
          ),
        ),
        actionTextColor: colorScheme.primary, // primary for action
        behavior: SnackBarBehavior.floating,
      ),

      // Extensions
      extensions: <ThemeExtension<dynamic>>[
        appTokens,
      ],
    );
  }

  // Legacy compatibility: Keep lightTheme for backward compatibility
  // but it's not used (app is dark-only)
  @Deprecated('App is dark-only. Use darkTheme instead.')
  static ThemeData get lightTheme => darkTheme;

  // Legacy color constants for backward compatibility (deprecated)
  // TODO: Migrate all usages to theme tokens - see /ai/THEME_RULES.md
  @Deprecated('Use context.colorScheme.surfaceVariant instead')
  static const Color charcoalGray = Color(0xFF27272A);

  @Deprecated('Use context.colorScheme.background instead')
  static const Color jetBlack = Color(0xFF09090B);

  @Deprecated('Use context.tokens.successColor instead')
  static const Color successColor = Color(0xFF10B981);

  @Deprecated('Use context.tokens.warningColor instead')
  static const Color warningColor = Color(0xFFF43F5E);

  @Deprecated('Use context.tokens.infoColor instead')
  static const Color infoColor = Color(0xFF3B82F6);

  @Deprecated('Use context.colorScheme.primary instead')
  static const Color orange = Color(0xFFF59E0B);

  @Deprecated('Use context.colorScheme.primary instead (readyToClose status)')
  static const Color purple = Color(0xFFF59E0B);

  @Deprecated('Use context.tokens.textSubtle instead')
  static const Color grey = Color(0xFF52525B);

  /// Background gradient (deprecated - use getBackgroundGradient(context) for theme-aware gradients)
  /// 
  /// This is a const-compatible fallback for legacy code.
  /// For new code, use ChoiceLuxTheme.getBackgroundGradient(context) instead
  @Deprecated('Use ChoiceLuxTheme.getBackgroundGradient(context) instead')
  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF09090B), Color(0xFF18181B)],
  );

  /// Get background gradient from theme context
  static LinearGradient getBackgroundGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.background,
        colorScheme.surface,
      ],
    );
  }

  /// Card gradient (deprecated - use getCardGradient(context) for theme-aware gradients)
  /// 
  /// This is a const-compatible fallback for legacy code.
  /// For new code, use ChoiceLuxTheme.getCardGradient(context) instead
  @Deprecated('Use ChoiceLuxTheme.getCardGradient(context) instead')
  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18181B), Color(0xFF27272A)],
  );

  /// Get card gradient from theme context
  static LinearGradient getCardGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.surface,
        colorScheme.surfaceVariant,
      ],
    );
  }
}
