import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle outfitSafe({
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  Color? color,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
  TextOverflow? overflow,
}) {
  try {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  } catch (_) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      overflow: overflow,
      fontFamilyFallback: const ['system-ui', 'Arial', 'sans-serif'],
    );
  }
}

TextStyle interSafe({
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  Color? color,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
  TextOverflow? overflow,
}) {
  try {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  } catch (_) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      overflow: overflow,
      fontFamilyFallback: const ['system-ui', 'Arial', 'sans-serif'],
    );
  }
}


