import 'package:flutter/material.dart';

/// Semantic colors that are not covered by [ColorScheme].
///
/// Light and dark palettes are designed separately rather than inverted.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.keep,
    required this.keepSoft,
    required this.delete,
    required this.deleteSoft,
    required this.warning,
    required this.warningSoft,
    required this.shadow,
    required this.cardShadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color keep;
  final Color keepSoft;
  final Color delete;
  final Color deleteSoft;
  final Color warning;
  final Color warningSoft;
  final Color shadow;
  final Color cardShadow;

  static const light = AppColors(
    background: Color(0xFFF6F5F1),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEDECE7),
    border: Color(0xFFE4E2DC),
    textPrimary: Color(0xFF15161B),
    textSecondary: Color(0xFF5E6069),
    textTertiary: Color(0xFF9A9CA4),
    accent: Color(0xFF4F46E5),
    accentSoft: Color(0xFFE8E7FC),
    onAccent: Color(0xFFFFFFFF),
    keep: Color(0xFF12A56B),
    keepSoft: Color(0xFFDDF4EA),
    delete: Color(0xFFF04E4E),
    deleteSoft: Color(0xFFFDE4E2),
    warning: Color(0xFFE39A12),
    warningSoft: Color(0xFFFCF0D8),
    shadow: Color(0x14151A2E),
    cardShadow: Color(0x2A151A2E),
  );

  static const dark = AppColors(
    background: Color(0xFF0E0F13),
    surface: Color(0xFF17181D),
    surfaceRaised: Color(0xFF1F2027),
    surfaceMuted: Color(0xFF24252D),
    border: Color(0xFF2B2C35),
    textPrimary: Color(0xFFF3F3F6),
    textSecondary: Color(0xFFA7A9B3),
    textTertiary: Color(0xFF6D6F7A),
    accent: Color(0xFF8B85FF),
    accentSoft: Color(0xFF25234A),
    onAccent: Color(0xFF0E0F13),
    keep: Color(0xFF34D399),
    keepSoft: Color(0xFF123127),
    delete: Color(0xFFFF6B6B),
    deleteSoft: Color(0xFF3A1A1C),
    warning: Color(0xFFF5B942),
    warningSoft: Color(0xFF362A12),
    shadow: Color(0x66000000),
    cardShadow: Color(0x99000000),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? keep,
    Color? keepSoft,
    Color? delete,
    Color? deleteSoft,
    Color? warning,
    Color? warningSoft,
    Color? shadow,
    Color? cardShadow,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      keep: keep ?? this.keep,
      keepSoft: keepSoft ?? this.keepSoft,
      delete: delete ?? this.delete,
      deleteSoft: deleteSoft ?? this.deleteSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      shadow: shadow ?? this.shadow,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      keep: l(keep, other.keep),
      keepSoft: l(keepSoft, other.keepSoft),
      delete: l(delete, other.delete),
      deleteSoft: l(deleteSoft, other.deleteSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      shadow: l(shadow, other.shadow),
      cardShadow: l(cardShadow, other.cardShadow),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
