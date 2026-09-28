import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// Matches the Zentra mobile mockup's typeface (Plus Jakarta Sans).
class AppTextStyles {
  // headings
  static TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static TextStyle h3 = GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600);
  // body text

  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400);

  //button text

  static TextStyle buttonLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle buttonMedium = GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600);

  static TextStyle buttonSmall = GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500);

  //label text
  static TextStyle labelMedium = GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600);

  //helper function for color variations

  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  //
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
}
