import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../services/ads/ad_config.dart';
import '../state/app_scope.dart';

/// An adaptive banner pinned to the bottom of a screen.
///
/// Takes no space until an ad has actually loaded — with ads off, offline,
/// no consent, or no fill, the layout above simply keeps the full height.
/// It includes the bottom safe area when shown, so [onVisibleChanged] lets
/// the parent stop padding for the system navigation bar itself.
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key, this.onVisibleChanged});

  final ValueChanged<bool>? onVisibleChanged;

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

/// Debug-only layout preview without network or an ad account:
/// `flutter run --dart-define=AD_PREVIEW=true`. Ignored in release builds.
const bool _preview = bool.fromEnvironment('AD_PREVIEW') && !kReleaseMode;

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _width;
  ValueNotifier<bool>? _canShow;

  @override
  void initState() {
    super.initState();
    if (_preview) WidgetsBinding.instance.addPostFrameCallback((_) => widget.onVisibleChanged?.call(true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preview) return;
    final canShow = AdsScope.of(context).canShowAds;
    if (canShow != _canShow) {
      _canShow?.removeListener(_maybeLoad);
      _canShow = canShow..addListener(_maybeLoad);
    }
    _maybeLoad();
  }

  @override
  void dispose() {
    _canShow?.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  void _setLoaded(bool loaded) {
    if (!mounted || loaded == _loaded) return;
    setState(() => _loaded = loaded);
    widget.onVisibleChanged?.call(loaded);
  }

  Future<void> _maybeLoad() async {
    final unitId = AdConfig.bannerUnitId;
    if (!mounted || unitId == null) return;
    if (_canShow?.value != true) {
      // Consent withdrawn: remove the ad.
      _ad?.dispose();
      _ad = null;
      _width = null;
      _setLoaded(false);
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width == _width) return; // already loaded for this width
    _width = width;

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    await _ad?.dispose();
    _ad = null;
    _setLoaded(false);

    BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _ad = ad as BannerAd;
          _setLoaded(true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _setLoaded(false); // stay collapsed
        },
      ),
    ).load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final c = context.colors;
    if (_preview) return _PreviewBanner(color: c.surfaceMuted, border: c.border);
    return AnimatedSize(
      duration: AppDurations.medium,
      curve: AppCurves.emphasized,
      alignment: Alignment.topCenter,
      child: _loaded && ad != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.6))),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: SizedBox(
                    width: ad.size.width.toDouble(),
                    height: ad.size.height.toDouble(),
                    child: AdWidget(ad: ad),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

/// Stand-in with a typical adaptive banner height (debug preview only).
class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.color, required this.border});

  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Center(child: Text('ADAPTIVE AD BANNER · preview', style: context.text.labelMedium)),
        ),
      ),
    );
  }
}
