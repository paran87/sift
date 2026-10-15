import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness).copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      error: c.delete,
      outline: c.border,
      outlineVariant: c.border,
    );

    final text = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: text,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: c.textPrimary,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.textPrimary, size: AppIconSize.md),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(AppRadius.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark ? c.surfaceMuted : c.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: brightness == Brightness.dark ? c.textPrimary : c.background,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: c.accent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(AppRadius.md)),
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : c.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.surfaceMuted,
        thumbColor: c.accent,
        overlayColor: c.accent.withValues(alpha: 0.12),
        trackHeight: 6,
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceMuted,
        circularTrackColor: c.surfaceMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accentSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            color: s.contains(WidgetState.selected) ? c.textPrimary : c.textTertiary,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) =>
              IconThemeData(color: s.contains(WidgetState.selected) ? c.accent : c.textTertiary, size: AppIconSize.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.textPrimary, borderRadius: AppRadius.circular(AppRadius.sm)),
        textStyle: text.labelMedium?.copyWith(color: c.background),
      ),
    );
  }

  static TextTheme _textTheme(AppColors c) {
    // Tuned Roboto (system font) — tight tracking on large sizes for a
    // more editorial, less "default Material" look.
    TextStyle s(double size, FontWeight w, {double? h, double ls = 0, Color? color}) =>
        TextStyle(fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: color ?? c.textPrimary);

    return TextTheme(
      displayLarge: s(56, FontWeight.w800, h: 1.02, ls: -2.2),
      displayMedium: s(44, FontWeight.w800, h: 1.05, ls: -1.6),
      displaySmall: s(34, FontWeight.w800, h: 1.1, ls: -1.1),
      headlineLarge: s(30, FontWeight.w700, h: 1.15, ls: -0.9),
      headlineMedium: s(26, FontWeight.w700, h: 1.18, ls: -0.7),
      headlineSmall: s(22, FontWeight.w700, h: 1.2, ls: -0.4),
      titleLarge: s(20, FontWeight.w700, h: 1.25, ls: -0.3),
      titleMedium: s(16, FontWeight.w600, h: 1.3, ls: -0.1),
      titleSmall: s(14, FontWeight.w600, h: 1.3),
      bodyLarge: s(16, FontWeight.w400, h: 1.5, color: c.textSecondary),
      bodyMedium: s(14, FontWeight.w400, h: 1.45, color: c.textSecondary),
      bodySmall: s(12.5, FontWeight.w400, h: 1.4, color: c.textTertiary),
      labelLarge: s(15, FontWeight.w600, ls: 0.1),
      labelMedium: s(13, FontWeight.w600, ls: 0.1),
      labelSmall: s(11, FontWeight.w600, ls: 0.4),
    );
  }
}

abstract final class AppShadows {
  static List<BoxShadow> soft(AppColors c) => [BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 8))];

  static List<BoxShadow> card(AppColors c) => [
    BoxShadow(color: c.cardShadow, blurRadius: 40, spreadRadius: -8, offset: const Offset(0, 20)),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
  ];
}

abstract final class AppGradients {
  /// Signature gradient for hero surfaces; deeper in dark mode.
  static LinearGradient hero(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? const [Color(0xFF4B43C9), Color(0xFF2E2A7A), Color(0xFF1C1B45)]
          : const [Color(0xFF6D5BFF), Color(0xFF4F46E5), Color(0xFF3A2FB8)],
    );
  }
}
