import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../state/app_scope.dart';

/// Haptic feedback that respects the user's setting.
abstract final class AppHaptics {
  static bool _enabled(BuildContext context) => SettingsScope.read(context).haptics;

  static void selection(BuildContext context) {
    if (_enabled(context)) HapticFeedback.selectionClick();
  }

  static void light(BuildContext context) {
    if (_enabled(context)) HapticFeedback.lightImpact();
  }

  static void medium(BuildContext context) {
    if (_enabled(context)) HapticFeedback.mediumImpact();
  }

  static void heavy(BuildContext context) {
    if (_enabled(context)) HapticFeedback.heavyImpact();
  }
}
