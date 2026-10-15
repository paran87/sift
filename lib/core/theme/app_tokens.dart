import 'package:flutter/material.dart';

/// Spacing scale. Use these instead of arbitrary numbers.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  /// Horizontal page gutter.
  static const double gutter = 20;

  /// Max width of content on large phones / tablets.
  static const double maxContentWidth = 560;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double card = 32;
  static const double pill = 999;

  static BorderRadius circular(double r) => BorderRadius.circular(r);
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration page = Duration(milliseconds: 380);
  static const Duration countUp = Duration(milliseconds: 1200);
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve spring = Curves.easeOutBack;
}

abstract final class AppIconSize {
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;
}
