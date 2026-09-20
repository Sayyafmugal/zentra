import 'package:flutter/material.dart';

/// Single source of truth for every brand/semantic color in the app.
/// Screens should read colors from here or from `Theme.of(context)` —
/// never redeclare a local `primaryColor` constant (this app used to have
/// the same brand orange duplicated, with two slightly different hex
/// values, across 15+ screen files).
abstract class AppColors {
  // Brand
  static const primary = Color(0xFFFF5722);
  static const primaryDark = Color(0xFFE64A19);
  static const onPrimary = Colors.white;

  // Light theme surfaces
  static const lightBackground = Colors.white;
  static const lightSurface = Color(0xFFF7F7F8);
  static const lightSurfaceVariant = Color(0xFFF0F0F2);
  static const lightBorder = Color(0xFFE4E4E7);

  // Dark theme surfaces
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceVariant = Color(0xFF262626);
  static const darkBorder = Color(0xFF333333);

  // Semantic
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  static const error = Color(0xFFD32F2F);
  static const info = Color(0xFF1976D2);

  // Neutral scale (light-mode text/icons on light surfaces)
  static const neutral900 = Color(0xFF1A1A1A);
  static const neutral700 = Color(0xFF404040);
  static const neutral500 = Color(0xFF737373);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral100 = Color(0xFFF5F5F5);
}
