import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/mock/mock_photos.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/photo_view.dart';

/// Tracks whether we already asked and the user said no, so the next step
/// is "Open Settings" (Android stops showing the prompt after two refusals).
mixin PhotoAccessFlow<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  bool refused = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from system Settings: pick up a newly granted permission.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) LibraryScope.read(context).refreshAccess();
  }

  Future<void> askForAccess() async {
    final store = LibraryScope.read(context);
    if (refused) {
      await store.openSettings();
      return;
    }
    setState(() => busy = true);
    final access = await store.requestAccess();
    if (!mounted) return;
    setState(() {
      busy = false;
      refused = !access.canRead;
    });
  }
}

/// Full-screen ask used when the app has no photo access.
class PhotoAccessView extends StatefulWidget {
  const PhotoAccessView({super.key});

  @override
  State<PhotoAccessView> createState() => _PhotoAccessViewState();
}

class _PhotoAccessViewState extends State<PhotoAccessView> with WidgetsBindingObserver, PhotoAccessFlow {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: Column(
                children: [
                  const Expanded(child: PhotoAccessVisual()),
                  PhotoAccessText(refused: refused),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: refused ? 'Open Settings' : 'Allow Access',
                    icon: refused ? Icons.settings_rounded : Icons.photo_library_rounded,
                    loading: busy,
                    onPressed: askForAccess,
                  ),
                  if (refused) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton.ghost(
                      label: 'Try again',
                      large: false,
                      onPressed: () {
                        setState(() => refused = false);
                        askForAccess();
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title, explanation and privacy points for the permission ask.
class PhotoAccessText extends StatelessWidget {
  const PhotoAccessText({super.key, required this.refused, this.compact = false});

  final bool refused;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      children: [
        Text(
          refused ? 'Photo access is off' : 'Allow access to\nyour photos',
          textAlign: TextAlign.center,
          style: compact ? t.headlineMedium : t.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          refused
              ? 'To clean your library, open Settings › Permissions › Photos and videos, and choose “Allow all”.'
              : 'Sift needs to see your photos and videos to help you tidy them up.',
          textAlign: TextAlign.center,
          style: t.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _Point(icon: Icons.phone_android_rounded, label: 'Stays on your phone', color: c.keep),
            _Point(icon: Icons.verified_user_outlined, label: 'You approve every delete', color: c.accent),
          ],
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.textSecondary)),
      ],
    );
  }
}

/// A fan of sample photos behind a lock badge.
class PhotoAccessVisual extends StatelessWidget {
  const PhotoAccessVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photos = MockPhotos.showcase;
    return LayoutBuilder(
      builder: (context, box) {
        final tile = min(box.maxWidth * 0.28, box.maxHeight * 0.34);
        Widget card(int i, double angle, Offset offset) => Transform.translate(
          offset: offset * tile,
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: tile,
              height: tile * 1.3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card(c),
              ),
              child: PhotoView(photo: photos[i], borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            card(1, -0.22, const Offset(-0.85, 0.08)),
            card(2, 0.22, const Offset(0.85, 0.08)),
            card(0, 0, const Offset(0, -0.05)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppGradients.hero(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 4),
                  boxShadow: AppShadows.glow(c.accent),
                ),
                child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 32),
              ),
            ),
          ],
        );
      },
    );
  }
}
