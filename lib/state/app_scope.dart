import 'package:flutter/widgets.dart';

import '../services/ads/ads_controller.dart';
import 'library_store.dart';
import 'settings_controller.dart';

class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({super.key, required SettingsController controller, required super.child})
    : super(notifier: controller);

  /// Rebuilds the caller when settings change.
  static SettingsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// Reads without subscribing — use in callbacks.
  static SettingsController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

class LibraryScope extends InheritedNotifier<LibraryStore> {
  const LibraryScope({super.key, required LibraryStore store, required super.child}) : super(notifier: store);

  static LibraryStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LibraryScope>()!.notifier!;

  static LibraryStore read(BuildContext context) => context.getInheritedWidgetOfExactType<LibraryScope>()!.notifier!;
}

/// Gives widgets access to the ads controller (no rebuilds; listen to its notifiers).
class AdsScope extends InheritedWidget {
  const AdsScope({super.key, required this.controller, required super.child});

  final AdsController controller;

  static AdsController of(BuildContext context) => context.getInheritedWidgetOfExactType<AdsScope>()!.controller;

  @override
  bool updateShouldNotify(AdsScope old) => old.controller != controller;
}
