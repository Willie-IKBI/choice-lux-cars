import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';

class ChoiceLuxTheme {
  // Luxury brand colors from design.md
  static const Color richGold = Color(0xFFD4AF37); // Primary accent
  static const Color jetBlack = Color(0xFF0A0A0A); // Main background
  static const Color softWhite = Color(0xFFF5F5F5); // Surface contrast
  static const Color charcoalGray = Color(0xFF1E1E1E); // Cards, inputs
  static const Color platinumSilver = Color(0xFFC0C0C0); // Dividers, hints
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFF59E0B);

  // Semantic color tokens for consistent design
  static const Color infoColor = Color(0xFF3B82F6); // Blue for info/status
  static const Color purple = Color(0xFF8B5CF6); // Purple for special states
  static const Color orange = Color(0xFFF59E0B); // Orange for warnings/urgent
  static const Color grey = Color(0xFF6B7280); // Grey for neutral states

  // Background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
  );

  // Card gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
  );



  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: jetBlack,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: richGold,
        brightness: Brightness.dark,
        primary: richGold,
        secondary: platinumSilver,
        surface: charcoalGray,
        error: errorColor,
        tertiary: successColor,
        onPrimary: Colors.black,
        onSurface: softWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: softWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: softWhite,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: richGold, size: 24),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: charcoalGray,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: richGold,
          foregroundColor: Colors.black,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: platinumSilver),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: platinumSilver),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: richGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: charcoalGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: platinumSilver),
        hintStyle: const TextStyle(color: platinumSilver),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: richGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: richGold,
          side: const BorderSide(color: richGold),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: charcoalGray,
        selectedColor: richGold,
        disabledColor: Colors.grey,
        labelStyle: TextStyle(color: softWhite),
        secondaryLabelStyle: TextStyle(color: Colors.black),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: platinumSilver,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: softWhite,
        iconColor: richGold,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return richGold;
          }
          return platinumSilver;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return richGold.withValues(alpha: 0.3);
          }
          return platinumSilver.withValues(alpha: 0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return richGold;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.black),
        side: const BorderSide(color: platinumSilver),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return richGold;
          }
          return platinumSilver;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: richGold,
        inactiveTrackColor: platinumSilver.withValues(alpha: 0.3),
        thumbColor: richGold,
        overlayColor: richGold.withValues(alpha: 0.2),
        valueIndicatorColor: richGold,
        valueIndicatorTextStyle: const TextStyle(color: Colors.black),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: richGold,
        linearTrackColor: platinumSilver,
        circularTrackColor: platinumSilver,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: charcoalGray,
        selectedItemColor: richGold,
        unselectedItemColor: platinumSilver,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: charcoalGray,
        indicatorColor: richGold.withValues(alpha: 0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(color: softWhite, fontSize: 12),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: richGold);
          }
          return const IconThemeData(color: platinumSilver);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: charcoalGray,
        scrimColor: Colors.black54,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: richGold,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: charcoalGray,
        contentTextStyle: const TextStyle(color: softWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: charcoalGray,
        titleTextStyle: const TextStyle(
          color: softWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(color: platinumSilver),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: charcoalGray,
        textStyle: const TextStyle(color: softWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: charcoalGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: platinumSilver),
        ),
        textStyle: const TextStyle(color: softWhite),
      ),
      dataTableTheme: const DataTableThemeData(
        dataTextStyle: TextStyle(color: softWhite),
        headingTextStyle: TextStyle(
          color: richGold,
          fontWeight: FontWeight.w600,
        ),
        dividerThickness: 1,
        dataRowColor: MaterialStatePropertyAll(Colors.transparent),
        headingRowColor: MaterialStatePropertyAll(Colors.transparent),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: charcoalGray,
        hourMinuteTextColor: softWhite,
        hourMinuteColor: Colors.transparent,
        dayPeriodTextColor: softWhite,
        dayPeriodColor: Colors.transparent,
        dialHandColor: richGold,
        dialBackgroundColor: Colors.transparent,
        dialTextColor: softWhite,
        entryModeIconColor: richGold,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: charcoalGray,
        headerBackgroundColor: richGold,
        headerForegroundColor: Colors.black,
        dayForegroundColor: MaterialStateProperty.all(softWhite),
        yearForegroundColor: MaterialStateProperty.all(softWhite),
        dayBackgroundColor: MaterialStateProperty.all(Colors.transparent),
        yearBackgroundColor: MaterialStateProperty.all(Colors.transparent),
        todayForegroundColor: MaterialStateProperty.all(richGold),
        todayBackgroundColor: MaterialStateProperty.all(
          richGold.withValues(alpha: 0.2),
        ),
        dayOverlayColor: MaterialStateProperty.all(richGold.withValues(alpha: 0.1)),
        yearOverlayColor: MaterialStateProperty.all(richGold.withValues(alpha: 0.1)),
      ),
      extensions: [
        const AppTokens(
          brandGold: richGold,
          brandBlack: jetBlack,
          radiusMd: 12.0,
          spacing: 16.0,
        ),
      ],
    );
  }

  // Dark theme (same as light theme for this luxury dark design)
  static ThemeData get darkTheme => lightTheme;
}
