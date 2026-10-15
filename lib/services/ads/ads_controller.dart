import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Starts the ads SDK after asking for consent where the law requires it
/// (EEA, UK, Switzerland), and tells banner slots when they may load.
class AdsController {
  AdsController({required this.enabled});

  /// False in tests and when ads are switched off entirely.
  final bool enabled;

  /// True once ads may be requested. Banner slots stay collapsed until then.
  final ValueNotifier<bool> canShowAds = ValueNotifier(false);

  /// True when the user must be offered a way to change their ad choices.
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  bool _started = false;

  bool get _configured => enabled && AdConfig.bannerUnitId != null;

  /// Call once the user reaches the main app. Safe to call more than once.
  void start() {
    if (!_configured || _started) return;
    _started = true;
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) => _initIfAllowed()),
      // Offline or misconfigured: fall back to any consent given earlier.
      (_) => _initIfAllowed(),
    );
  }

  Future<void> _initIfAllowed() async {
    try {
      privacyOptionsRequired.value =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        canShowAds.value = true;
      }
    } catch (e) {
      debugPrint('Ads unavailable: $e');
    }
  }

  /// Lets the user review or change their ad consent (from Settings).
  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((_) {});
    canShowAds.value = false;
    await _initIfAllowed();
  }

  void dispose() {
    canShowAds.dispose();
    privacyOptionsRequired.dispose();
  }
}
