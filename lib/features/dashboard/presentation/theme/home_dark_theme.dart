import 'package:flutter/material.dart';

/// Shared color tokens for the Home screen's purple background theme.
/// Scoped to the Home-screen-only widgets under
/// `dashboard/presentation/widgets/` — deliberately not folded into either
/// shared `AppColors` class, since this look belongs to this one screen,
/// not the rest of the (still light-themed) app.
class HomeDarkTheme {
  HomeDarkTheme._();

  /// Page background gradient — the actual Eskoolia brand purples
  /// (matching `AppColors.brandPurple`/`purpleDeep`, used elsewhere for
  /// buttons/the greeting card), not a custom near-black shade. Vivid
  /// purple throughout, never crossing into dark/black territory.
  static const Color bgTop = Color(0xFF7C5CFF);
  static const Color bgBottom = Color(0xFF4F35CC);

  /// "Glass" card surface — a translucent white wash + a brighter
  /// translucent border, so every card reads as a frosted panel over the
  /// gradient no matter where on it the card happens to sit. Slightly
  /// higher opacity than a near-black background would need, since a
  /// brighter purple backdrop washes out very faint overlays more easily.
  static const Color cardFill = Color(0x1FFFFFFF); // ~12% white
  static const Color cardBorder = Color(0x38FFFFFF); // ~22% white

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCFC9E8); // soft lavender-white
  static const Color textTertiary = Color(0xFF9C93C4); // muted lavender
}
