import 'dart:io';

import 'package:flutter/foundation.dart';

/// Where banner ads come from.
///
/// Debug/profile builds use Google's public **test** ad units, so they are
/// safe to tap while developing. Release builds use your real ad units,
/// passed in at build time — no code change needed:
///
/// ```
/// flutter build appbundle --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/YYYY
/// ```
///
/// A release build without a real unit shows **no** ads (never test ads).
/// The AdMob *App* ID is set separately in `android/gradle.properties`
/// (`admobAppId=ca-app-pub-XXXX~ZZZZ`).
abstract final class AdConfig {
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2435281174';

  static const _bannerAndroid = String.fromEnvironment('ADMOB_BANNER_ANDROID');
  static const _bannerIos = String.fromEnvironment('ADMOB_BANNER_IOS');

  /// The banner ad unit to load, or null when ads are off on this build/platform.
  static String? get bannerUnitId {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
    if (kReleaseMode) {
      final id = Platform.isAndroid ? _bannerAndroid : _bannerIos;
      return id.isEmpty ? null : id;
    }
    return Platform.isAndroid ? _testBannerAndroid : _testBannerIos;
  }
}
