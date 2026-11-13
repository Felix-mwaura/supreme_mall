import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Reusable text styles so the type scale stays consistent across screens.
/// Colours are passed in where a style is reused on both light and dark
/// surfaces.
class AppText {
  const AppText._();

  static const TextStyle display = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.16,
    letterSpacing: -0.6,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.1,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyTight = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static const TextStyle brandWordmark = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.2,
  );

  static const TextStyle brandSub = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  /// Muted ink used for explanatory copy on light surfaces.
  static const TextStyle mutedInk = TextStyle(
    fontSize: 12.5,
    height: 1.45,
    color: AppColors.slate,
  );
}
