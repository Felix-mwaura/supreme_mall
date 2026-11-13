import 'package:flutter/material.dart';

/// Supreme Mall brand palette.
///
/// Sourced from the Developer Brief, section 3 (brand direction):
/// Supreme Navy #0B2D5B and Ivory White #F8FAFC as the foundation,
/// Royal Gold #D4A017 for highlights, Emerald Green #27AE60 and
/// Sky Blue #3498DB as selective service accents, Charcoal Grey #4B5563
/// for supporting text.
class AppColors {
  const AppColors._();

  // Foundation
  static const Color navy = Color(0xFF0B2D5B);
  static const Color navyDeep = Color(0xFF071E3D);
  static const Color navyLift = Color(0xFF16407C);
  static const Color ivory = Color(0xFFF8FAFC);

  // Highlights + service accents
  static const Color gold = Color(0xFFD4A017);
  static const Color goldInk = Color(0xFF9A7208); // gold dark enough for text
  static const Color emerald = Color(0xFF27AE60);
  static const Color sky = Color(0xFF3498DB);

  // Supporting text + neutrals
  static const Color charcoal = Color(0xFF4B5563);
  static const Color slate = Color(0xFF8A97A8);
  static const Color line = Color(0xFFE3E9F2);
  static const Color white = Color(0xFFFFFFFF);

  // Translucent helpers (kept as const literals so no deprecated
  // withOpacity / withValues calls are needed anywhere in the codebase).
  static const Color navySoft = Color(0x140B2D5B); // navy @ 8%
  static const Color goldSoft = Color(0x26D4A017); // gold @ 15%
  static const Color emeraldSoft = Color(0x1F27AE60);
  static const Color skySoft = Color(0x1F3498DB);
  static const Color whiteGlass = Color(0x1FFFFFFF); // white @ 12%
  static const Color whiteFaint = Color(0x12FFFFFF); // white @ 7%
  static const Color whiteMuted = Color(0x8AFFFFFF); // white @ 54%
  static const Color hairline = Color(0x1FFFFFFF);

  // --- Dark "Bento" surfaces (customer dashboard) -------------------------
  // Navy is the canvas here, so department accents must come from the bright
  // end of the palette; navy itself would disappear against the background.
  static const Color canvas = Color(0xFF071E3D);
  static const Color canvasDeep = Color(0xFF041123);
  static const Color surface = Color(0xFF0F2E52);
  static const Color surfaceRaised = Color(0xFF143A66);
  static const Color hairlineDark = Color(0x1AFFFFFF); // white @ 10%
  static const Color inkOnDark = Color(0xFFF2F6FC);
  static const Color inkMutedOnDark = Color(0xFFAFC3DC);

  // Glass navigation
  static const Color glassFill = Color(0xB80B2D5B); // navy @ 72%
  static const Color glassFillDeep = Color(0xE6071E3D); // navy @ 90%
  static const Color glassEdge = Color(0x24FFFFFF);
}
