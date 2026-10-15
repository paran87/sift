import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/mock/mock_photos.dart';
import '../../services/photo_library_service.dart';
import '../../state/app_scope.dart';
import '../../state/library_store.dart';
import '../../widgets/app_button.dart';
import '../../widgets/swipe_hint.dart';
import '../permission/photo_access_view.dart';
import 'onboarding_visuals.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver, PhotoAccessFlow {
  final _pages = PageController();
  final _photos = MockPhotos.showcase;
  int _index = 0;
  Timer? _autoAdvance;

  static const _count = 5;

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _autoAdvance?.cancel();
    setState(() => _index = i);
    _pages.animateToPage(
      i,
      duration: SettingsScope.read(context).motion(const Duration(milliseconds: 520)),
      curve: AppCurves.emphasized,
    );
  }

  void _next() {
    if (_index < _count - 1) {
      _goTo(_index + 1);
    } else if (!LibraryScope.read(context).hasAccess) {
      askForAccess();
    } else {
      AppRouter.toHome(context, startCleaning: true);
    }
  }

  void _demoCompleted() {
    _autoAdvance?.cancel();
    _autoAdvance = Timer(const Duration(milliseconds: 750), () {
      if (mounted) _next();
    });
  }

  String _cta(bool hasAccess, bool loaded) => switch (_index) {
    0 => 'Get Started',
    4 when !hasAccess => refused ? 'Open Settings' : 'Allow Access',
    4 when !loaded => 'Scanning your library…',
    4 => 'Start Cleaning',
    _ => 'Continue',
  };

  IconData? _ctaIcon(bool hasAccess) {
    if (_index != _count - 1) return null;
    if (!hasAccess) return refused ? Icons.settings_rounded : Icons.photo_library_rounded;
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final store = LibraryScope.of(context);
    final c = context.colors;

    final pages = <_PageSpec>[
      _PageSpec(
        title: 'Clean your photos.\nKeep the memories.',
        body: 'Sift turns a cluttered gallery into a few calm minutes of swiping.',
        visual: WelcomeVisual(photos: _photos),
        arrows: SwipeHintSide.both,
      ),
      _PageSpec(
        eyebrow: 'Swipe right',
        eyebrowColor: c.keep,
        title: 'Keep what you love',
        body: 'Send a photo right and it stays safely in your library.',
        hint: 'Try it — drag the card to the right',
        arrows: SwipeHintSide.keep,
        visual: SwipeDemo(decision: SwipeDecision.keep, photos: [_photos[1], _photos[2]], onCompleted: _demoCompleted),
      ),
      _PageSpec(
        eyebrow: 'Swipe left',
        eyebrowColor: c.delete,
        title: 'Let go of the rest',
        body: 'Swipe left to delete. Photos wait in Trash first — nothing is removed until you say so.',
        hint: 'Try it — drag the card to the left',
        arrows: SwipeHintSide.delete,
        visual: SwipeDemo(
          decision: SwipeDecision.delete,
          photos: [_photos[4], _photos[3]],
          onCompleted: _demoCompleted,
        ),
      ),
      _PageSpec(
        eyebrow: 'Undo',
        eyebrowColor: c.accent,
        title: 'Made a mistake?\nUndo it.',
        body: 'One tap brings back the last photo, instantly.',
        visual: UndoDemo(photos: [_photos[3], _photos[0]]),
      ),
      if (store.hasAccess)
        _PageSpec(
          eyebrow: 'All set',
          eyebrowColor: c.keep,
          title: store.isLoaded ? 'Your library is ready\nto be cleaned' : 'Looking through\nyour library',
          body: store.loadError != null
              ? 'Something went wrong reading your photos. Please try again.'
              : store.access == LibraryAccess.limited
              ? 'You shared only some photos, so Sift will only show those. You can share more any time.'
              : 'Everything stays on your phone. You review, you decide.',
          visual: ValueListenableBuilder<double>(
            valueListenable: store.scanProgress,
            builder: (context, progress, _) => ReadyVisual(
              progress: progress,
              loaded: store.isLoaded,
              totalPhotos: store.overview.totalPhotos,
              recoverableBytes: store.overview.recoverableBytes,
            ),
          ),
        )
      else
        _PageSpec(
          eyebrow: 'Photo access',
          eyebrowColor: c.accent,
          title: refused ? 'Photo access is off' : 'Allow access to\nyour photos',
          body: refused
              ? 'Open Settings › Permissions › Photos and videos, then choose “Allow all”.'
              : 'Sift needs to see your photos and videos to help you tidy them up. Nothing leaves your phone.',
          visual: const PhotoAccessVisual(),
        ),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) _goTo(_index - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: Column(
                children: [
                  _TopBar(
                    index: _index,
                    count: _count,
                    onBack: _index > 0 ? () => _goTo(_index - 1) : null,
                    onSkip: _index < _count - 1 ? () => _goTo(_count - 1) : null,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pages.length,
                      itemBuilder: (context, i) => _OnboardingPage(spec: pages[i], active: i == _index),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xs,
                      AppSpacing.gutter,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          label: store.loadError != null && _index == _count - 1
                              ? 'Try again'
                              : _cta(store.hasAccess, store.isLoaded),
                          icon: _ctaIcon(store.hasAccess),
                          loading: busy || (_index == _count - 1 && store.hasAccess && store.isLoading),
                          onPressed: _index == _count - 1 && store.loadError != null ? store.reset : _next,
                        ),
                        if (_index == _count - 1 && store.access == LibraryAccess.limited && store.isLoaded)
                          AppButton.ghost(
                            label: 'Choose more photos',
                            large: false,
                            onPressed: store.manageLimitedAccess,
                          ),
                        if (_index == _count - 1 && refused && !store.hasAccess)
                          AppButton.ghost(
                            label: 'Try again',
                            large: false,
                            onPressed: () {
                              setState(() => refused = false);
                              askForAccess();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageSpec {
  const _PageSpec({
    required this.title,
    required this.body,
    required this.visual,
    this.eyebrow,
    this.eyebrowColor,
    this.hint,
    this.arrows,
  });

  final String title;
  final String body;
  final Widget visual;
  final String? eyebrow;
  final Color? eyebrowColor;
  final String? hint;

  /// Tutorial arrows shown under the visual.
  final SwipeHintSide? arrows;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.count, this.onBack, this.onSkip});

  final int index;
  final int count;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: AnimatedOpacity(
                opacity: onBack != null ? 1 : 0,
                duration: AppDurations.fast,
                child: IconButton(tooltip: 'Back', onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
              ),
            ),
            Expanded(
              child: Semantics(
                label: 'Step ${index + 1} of $count',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < count; i++)
                      AnimatedContainer(
                        duration: AppDurations.medium,
                        curve: AppCurves.emphasized,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i <= index ? c.textPrimary : c.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: AnimatedOpacity(
                opacity: onSkip != null ? 1 : 0,
                duration: AppDurations.fast,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                  child: const Text('Skip'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.spec, required this.active});

  final _PageSpec spec;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final compact = MediaQuery.sizeOf(context).height < 700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: spec.visual,
            ),
          ),
          if (spec.arrows != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: SwipeHintArrows(side: spec.arrows!),
            ),
          AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: AppDurations.slow,
            child: AnimatedSlide(
              offset: active ? Offset.zero : const Offset(0, 0.08),
              duration: AppDurations.slow,
              curve: AppCurves.emphasized,
              child: Column(
                children: [
                  if (spec.eyebrow != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: spec.eyebrowColor!.withValues(alpha: context.isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        spec.eyebrow!.toUpperCase(),
                        style: t.labelSmall?.copyWith(color: spec.eyebrowColor, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(spec.title, textAlign: TextAlign.center, style: compact ? t.headlineMedium : t.headlineLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(spec.body, textAlign: TextAlign.center, style: t.bodyLarge),
                  SizedBox(
                    height: 36,
                    child: spec.hint == null
                        ? null
                        : Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swipe_rounded, size: 16, color: c.textTertiary),
                                const SizedBox(width: 6),
                                Text(spec.hint!, style: t.bodySmall),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
