import 'package:flutter/material.dart';

import '../../models/duplicate_group.dart';
import '../../models/photo_album.dart';
import '../../models/photo_category.dart';
import '../../models/statistics.dart';
import '../../screens/albums/album_screen.dart';
import '../../screens/cleaning/completion_screen.dart';
import '../../screens/cleaning/swipe_screen.dart';
import '../../screens/duplicates/compare_screen.dart';
import '../../screens/duplicates/duplicates_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/shell/home_shell.dart';
import '../../screens/trash/trash_screen.dart';
import '../theme/app_tokens.dart';

/// Central place for navigation so screens don't build routes themselves.
abstract final class AppRouter {
  static Route<T> _fade<T>(Widget page, {Duration duration = AppDurations.page}) => PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: AppDurations.medium,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppCurves.emphasized);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(curved), child: child),
      );
    },
  );

  static Route<T> _slide<T>(Widget page) => MaterialPageRoute<T>(builder: (_) => page);

  static Route<T> _modal<T>(Widget page) => PageRouteBuilder<T>(
    transitionDuration: AppDurations.page,
    reverseTransitionDuration: AppDurations.medium,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppCurves.emphasized);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );

  static void toOnboarding(BuildContext context) =>
      Navigator.of(context).pushReplacement(_fade(const OnboardingScreen(), duration: AppDurations.slow));

  static void toHome(BuildContext context, {bool startCleaning = false}) {
    Navigator.of(context).pushAndRemoveUntil(_fade(HomeShell(startCleaning: startCleaning)), (_) => false);
  }

  static Future<void> toCleaning(BuildContext context, [CategoryKind kind = CategoryKind.all]) =>
      Navigator.of(context).push(_modal(SwipeScreen(category: kind)));

  /// Cleans one album, optionally starting at a specific photo.
  static Future<void> toAlbumCleaning(BuildContext context, PhotoAlbum album, {String? startAtId}) =>
      Navigator.of(context).push(_modal(SwipeScreen(album: album, startAtId: startAtId)));

  static Future<void> toAlbum(BuildContext context, PhotoAlbum album) =>
      Navigator.of(context).push(_slide(AlbumScreen(album: album)));

  static void toCompletion(BuildContext context, SessionSummary summary) =>
      Navigator.of(context).pushReplacement(_fade(CompletionScreen(summary: summary)));

  static Future<void> toTrash(BuildContext context, {bool replace = false}) {
    final route = _slide<void>(const TrashScreen());
    return replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
  }

  static Future<void> toGroups(BuildContext context, GroupKind kind) =>
      Navigator.of(context).push(_slide(DuplicatesScreen(kind: kind)));

  static Future<Set<String>?> toCompare(BuildContext context, DuplicateGroup group) =>
      Navigator.of(context).push<Set<String>>(_modal(CompareScreen(group: group)));

  static Future<void> toProgress(BuildContext context) => Navigator.of(context).push(_slide(const ProgressScreen()));

  /// Opens the right screen for a category.
  static Future<void> openCategory(BuildContext context, CategoryKind kind) => switch (kind) {
    CategoryKind.duplicates => toGroups(context, GroupKind.duplicate),
    CategoryKind.similar => toGroups(context, GroupKind.similar),
    _ => toCleaning(context, kind),
  };
}
