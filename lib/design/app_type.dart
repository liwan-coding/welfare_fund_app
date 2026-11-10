import 'package:flutter/material.dart';

/// iOS text styles (point sizes at the default Dynamic Type setting)
/// rendered in IBM Plex Sans Arabic. Sizes scale with the system text scaler.
class AppType {
  static const String _font = 'IBMPlexSansArabic';

  static TextStyle _s(double size, FontWeight w, double h) =>
      TextStyle(fontFamily: _font, fontSize: size, fontWeight: w, height: h);

  static final largeTitle = _s(34, FontWeight.w700, 1.2);
  static final title1 = _s(28, FontWeight.w700, 1.25);
  static final title2 = _s(22, FontWeight.w700, 1.3);
  static final title3 = _s(20, FontWeight.w600, 1.3);
  static final headline = _s(17, FontWeight.w600, 1.35);
  static final body = _s(17, FontWeight.w400, 1.45);
  static final callout = _s(16, FontWeight.w400, 1.4);
  static final subheadline = _s(15, FontWeight.w400, 1.4);
  static final footnote = _s(13, FontWeight.w400, 1.4);
  static final caption1 = _s(12, FontWeight.w400, 1.35);
  static final caption2 = _s(11, FontWeight.w400, 1.3);

  /// Material [TextTheme] built from the iOS scale.
  static TextTheme textTheme(Color label, Color secondary) => TextTheme(
        displayLarge: largeTitle.copyWith(color: label),
        displayMedium: title1.copyWith(color: label),
        displaySmall: title2.copyWith(color: label),
        headlineLarge: title2.copyWith(color: label),
        headlineMedium: title3.copyWith(color: label),
        headlineSmall: headline.copyWith(color: label),
        titleLarge: headline.copyWith(color: label),
        titleMedium: callout.copyWith(color: label, fontWeight: FontWeight.w500),
        titleSmall: subheadline.copyWith(color: label, fontWeight: FontWeight.w500),
        bodyLarge: body.copyWith(color: label),
        bodyMedium: subheadline.copyWith(color: label),
        bodySmall: footnote.copyWith(color: secondary),
        labelLarge: callout.copyWith(color: label, fontWeight: FontWeight.w500),
        labelMedium: caption1.copyWith(color: label, fontWeight: FontWeight.w500),
        labelSmall: caption2.copyWith(color: secondary),
      );
}
