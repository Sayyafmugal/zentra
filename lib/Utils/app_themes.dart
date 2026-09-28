import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_textstyles.dart';

/// Shared elevation/shadow presets so cards use one consistent look instead
/// of every screen hand-rolling its own BoxShadow.
abstract class AppShadows {
  static List<BoxShadow> card(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevated(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.5)
          : Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppThemes {
  static TextTheme _textTheme(Color bodyColor, Color displayColor) {
    return TextTheme(
      headlineMedium: AppTextStyles.h1.copyWith(color: displayColor),
      headlineSmall: AppTextStyles.h2.copyWith(color: displayColor),
      titleLarge: AppTextStyles.h2.copyWith(color: displayColor),
      titleMedium: AppTextStyles.h3.copyWith(color: displayColor),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: bodyColor),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: bodyColor),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: bodyColor),
      labelLarge: AppTextStyles.buttonLarge.copyWith(color: bodyColor),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: bodyColor),
    );
  }

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    hintColor: AppColors.neutral500,
    cardColor: AppColors.lightCard,
    dividerColor: AppColors.lightBorder,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.coral,
      brightness: Brightness.light,
      surface: AppColors.lightCard,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      error: AppColors.error,
    ),
    textTheme: _textTheme(AppColors.neutral700, AppColors.neutral900),
    // The app's top header is always teal/white regardless of light/dark
    // mode — a fixed brand color, not a surface that inverts with theme.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCard,
      selectedItemColor: AppColors.teal,
      unselectedItemColor: AppColors.neutral500,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.neutral300,
        minimumSize: const Size(88, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.buttonLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.4),
        minimumSize: const Size(88, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.buttonLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      labelStyle: const TextStyle(color: AppColors.neutral500),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurfaceVariant,
      selectedColor: AppColors.teal,
      labelStyle: const TextStyle(color: AppColors.neutral900),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral900,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.sage,
    scaffoldBackgroundColor: AppColors.darkBackground,
    hintColor: AppColors.neutral300,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkBorder,
    // Dark mode swaps teal for sage as the accent color — the mockup's
    // `dark:text-zentra-sage` pattern — since the deeper teal reads as
    // low-contrast against a near-black background.
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      primary: AppColors.sage,
      onPrimary: Colors.white,
      secondary: AppColors.coral,
      brightness: Brightness.dark,
      surface: AppColors.darkCard,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      error: AppColors.error,
    ),
    textTheme: _textTheme(AppColors.neutral300, Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      selectedItemColor: AppColors.sage,
      unselectedItemColor: AppColors.neutral300,
      type: BottomNavigationBarType.fixed,
    ),
    // "+ Add" / primary action buttons stay teal in both themes (the
    // mockup never gives them a dark: variant) — only inline text accents
    // (below) swap to sage.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.neutral700,
        minimumSize: const Size(88, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.buttonLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.sage,
        side: const BorderSide(color: AppColors.sage, width: 1.4),
        minimumSize: const Size(88, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.buttonLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.sage,
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: const BorderSide(color: AppColors.sage, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.button + 4),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      labelStyle: const TextStyle(color: AppColors.neutral300),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),
  );
}
