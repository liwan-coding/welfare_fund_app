import 'package:flutter/material.dart';

/// Apple HIG-aligned design tokens. Single source of truth for new UI;
/// legacy AppColors / AppConstants are remapped to these values.
class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard iOS horizontal screen margin.
  static const double screen = 16;
}

class AppRadius {
  /// Small controls, chips, thumbnails.
  static const double sm = 10;

  /// Buttons, text fields, grouped list sections.
  static const double md = 14;

  /// Cards, sheets.
  static const double lg = 22;
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
}

/// Semantic colors, light + dark, modelled on iOS system colors.
/// Resolve with [AppPalette.of] so widgets adapt to brightness.
@immutable
class AppPalette {
  final Color tint; // brand accent (interactive elements)
  final Color background; // systemGroupedBackground
  final Color surface; // secondarySystemGroupedBackground
  final Color fill; // tertiarySystemFill (inputs, chips)
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color separator;
  final Color success;
  final Color warning;
  final Color destructive;

  const AppPalette({
    required this.tint,
    required this.background,
    required this.surface,
    required this.fill,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.success,
    required this.warning,
    required this.destructive,
  });

  static const Color brand = Color(0xFFA0207E);

  static const light = AppPalette(
    tint: brand,
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    fill: Color(0xFFEEEEF0),
    label: Color(0xFF000000),
    secondaryLabel: Color(0xFF6C6C70),
    tertiaryLabel: Color(0xFF8E8E93),
    separator: Color(0xFFC6C6C8),
    success: Color(0xFF248A3D),
    warning: Color(0xFFC93400),
    destructive: Color(0xFFFF3B30),
  );

  static const dark = AppPalette(
    tint: Color(0xFFD65BB5), // lifted for contrast on black
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    fill: Color(0xFF2C2C2E),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0xFF98989F),
    tertiaryLabel: Color(0xFF6C6C70),
    separator: Color(0xFF38383A),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    destructive: Color(0xFFFF453A),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
