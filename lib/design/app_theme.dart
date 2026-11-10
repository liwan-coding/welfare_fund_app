import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_tokens.dart';
import 'app_type.dart';

/// Material ThemeData styled to the Apple HIG: flat surfaces, no elevation,
/// hairline separators, grouped backgrounds, 50pt filled buttons.
class AppTheme {
  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness b) {
    final isLight = b == Brightness.light;
    final scheme = ColorScheme(
      brightness: b,
      primary: p.tint,
      onPrimary: Colors.white,
      secondary: p.tint,
      onSecondary: Colors.white,
      error: p.destructive,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.label,
      surfaceContainerHighest: p.fill,
      outline: p.separator,
      outlineVariant: p.separator,
    );
    final radius = BorderRadius.circular(AppRadius.md);
    final text = AppType.textTheme(p.label, p.secondaryLabel);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: 'IBMPlexSansArabic',
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: text,
      dividerTheme: DividerThemeData(color: p.separator, thickness: 0.5, space: 0.5),
      splashFactory: NoSplash.splashFactory, // iOS has no ink ripple
      highlightColor: p.fill,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.label,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppType.headline.copyWith(color: p.label),
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.tint,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          textStyle: AppType.headline,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.tint,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          textStyle: AppType.headline,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.tint,
          minimumSize: const Size.fromHeight(50),
          textStyle: AppType.headline,
          side: BorderSide(color: p.separator),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.tint,
          minimumSize: const Size(44, 44),
          textStyle: AppType.body,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.fill,
        hintStyle: AppType.body.copyWith(color: p.tertiaryLabel),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: radius, borderSide: BorderSide(color: p.tint, width: 1.5)),
        errorBorder:
            OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.destructive)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius, borderSide: BorderSide(color: p.destructive, width: 1.5)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? const Color(0xFF2C2C2E) : const Color(0xFF3A3A3C),
        contentTextStyle: AppType.subheadline.copyWith(color: Colors.white),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: AppType.headline.copyWith(color: p.label),
        contentTextStyle: AppType.footnote.copyWith(color: p.label),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(AppType.caption2),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.success : p.fill),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.tint),
      iconTheme: IconThemeData(color: p.label, size: 24),
    );
  }
}
