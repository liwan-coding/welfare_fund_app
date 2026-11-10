import 'package:flutter/material.dart';

/// Legacy color constants, remapped to Apple HIG system colors.
/// New code should use `AppPalette` (lib/design/app_tokens.dart).
class AppColors {
  // Brand tint
  static const Color primary = Color(0xFFA0207E);
  static const Color primaryLight = Color(0xFFB84A9A);
  static const Color primaryDark = Color(0xFF8A1A6A);
  static const Color primaryDeep = Color(0xFF5C0F47);

  // Secondary: brand teal (from the logo)
  static const Color secondary = Color(0xFF2DAAE2);
  static const Color secondaryLight = Color(0xFF4FB8E8);
  static const Color secondaryDark = Color(0xFF1E8BC4);

  // Accent: iOS system orange
  static const Color accent = Color(0xFFFF9500);
  static const Color accentLight = Color(0xFFFF9500);
  static const Color accentDark = Color(0xFFC93400);

  // Background colors (grouped style)
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEEEF0);

  // Text colors (label hierarchy)
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6C6C70);
  static const Color textTertiary = Color(0xFF8E8E93);

  // Status colors
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF248A3D); // completed status
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Gradients are deprecated: HIG uses flat color. Kept as solid fills so
  // existing call sites render flat until they are migrated.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accent],
  );

  static const LinearGradient modernGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient reverseGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primary, primary],
  );
}
