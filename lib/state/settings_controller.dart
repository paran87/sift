import 'package:flutter/material.dart';

import '../models/photo_album.dart';

enum SwipeSensitivity { relaxed, normal, quick }

/// UI-only preferences (kept in memory for the prototype).
class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _haptics = true;
  bool _reduceMotion = false;
  bool _confirmBeforeDelete = true;
  SwipeSensitivity _sensitivity = SwipeSensitivity.normal;
  int _undoSteps = 10;
  PhotoOrder _photoOrder = PhotoOrder.newestFirst;
  bool _swipeHintSeen = false;

  ThemeMode get themeMode => _themeMode;
  bool get haptics => _haptics;
  bool get reduceMotion => _reduceMotion;
  bool get confirmBeforeDelete => _confirmBeforeDelete;
  SwipeSensitivity get sensitivity => _sensitivity;
  int get undoSteps => _undoSteps;

  /// Date order used by album grids and cleaning sessions.
  PhotoOrder get photoOrder => _photoOrder;

  /// The left/right arrow hint shows until the first swipe.
  bool get swipeHintSeen => _swipeHintSeen;

  /// Fraction of card width a drag must travel to count as a swipe.
  double get swipeThreshold => switch (_sensitivity) {
    SwipeSensitivity.relaxed => 0.38,
    SwipeSensitivity.normal => 0.28,
    SwipeSensitivity.quick => 0.18,
  };

  /// Scales animation durations; near-zero when motion is reduced.
  Duration motion(Duration d) => _reduceMotion ? Duration(milliseconds: d.inMilliseconds ~/ 4) : d;

  set themeMode(ThemeMode v) => _set(() => _themeMode = v);
  set haptics(bool v) => _set(() => _haptics = v);
  set reduceMotion(bool v) => _set(() => _reduceMotion = v);
  set confirmBeforeDelete(bool v) => _set(() => _confirmBeforeDelete = v);
  set sensitivity(SwipeSensitivity v) => _set(() => _sensitivity = v);
  set undoSteps(int v) => _set(() => _undoSteps = v);
  set photoOrder(PhotoOrder v) => _set(() => _photoOrder = v);
  set swipeHintSeen(bool v) => _set(() => _swipeHintSeen = v);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }
}
