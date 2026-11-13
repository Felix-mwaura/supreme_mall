import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A deliberately small [ThemeData]: only the values that are safe across
/// Flutter versions are set here (colour scheme + scaffold colour). Component
/// theming is done inside the reusable widgets instead, which keeps this app
/// free of version-specific theme classes.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const ColorScheme scheme = ColorScheme.light(
      primary: AppColors.navy,
      onPrimary: AppColors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.navy,
      surface: AppColors.white,
      onSurface: AppColors.charcoal,
      error: Color(0xFFB3261E),
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ivory,
      visualDensity: VisualDensity.standard,
    );
  }
}
