import 'package:flutter/material.dart';

/// Single source of truth for every brand/semantic color in the app.
/// Screens should read colors from here or from `Theme.of(context)` —
/// never redeclare a local `primaryColor` constant. Matches the Zentra
/// mobile mockup's palette (teal / coral / sage).
abstract class AppColors {
  // Brand — teal is the primary surface/accent color in light mode; coral
  // is the one constant "call to action" color that never changes between
  // light/dark (buttons like Shop Now, Place Order, wishlist heart); sage
  // stands in for teal as the accent/text color in dark mode, where the
  // deeper teal would be too low-contrast against a near-black background.
  static const teal = Color(0xFF0F4C4A);
  static const tealDark = Color(0xFF0A3635);
  static const tealLight = Color(0xFF186865);
  static const coral = Color(0xFFE76F51);
  static const sage = Color(0xFF2A9D8F);

  static const primary = teal;
  static const primaryDark = tealDark;
  static const onPrimary = Colors.white;

  // Light theme surfaces
  static const lightBackground = Color(0xFFF4F6F8);
  static const lightSurface = Color(0xFFF8FAFC);
  static const lightSurfaceVariant = Color(0xFFF1F5F9);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightCard = Colors.white;

  // Dark theme surfaces
  static const darkBackground = Color(0xFF0B1A1A);
  static const darkSurface = Color(0xFF132A2A);
  static const darkSurfaceVariant = Color(0xFF0B1A1A);
  static const darkBorder = Color(0xFF1F3D3D);
  static const darkCard = Color(0xFF132A2A);

  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFE76F51);
  static const info = Color(0xFF1976D2);

  // Neutral scale — Tailwind's slate palette, matching the mockup's
  // text-slate-*/border-slate-* usage throughout.
  static const neutral900 = Color(0xFF0F172A);
  static const neutral700 = Color(0xFF334155);
  static const neutral500 = Color(0xFF64748B);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral100 = Color(0xFFF1F5F9);
}
