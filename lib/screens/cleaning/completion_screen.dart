import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../models/statistics.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/progress_widgets.dart';
import '../trash/trash_screen.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key, required this.summary});

  final SessionSummary summary;

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.duration = SettingsScope.read(context).motion(_c.duration!);
      _c.forward();
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) AppHaptics.heavy(context);
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Moves everything marked in the Trash to the phone's Recycle Bin.
  Future<void> _deleteNow() async {
    final store = LibraryScope.read(context);
    final deleted = await deletePhotosFlow(context, store.trash);
    if (!mounted || deleted.isEmpty) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = widget.summary;
    final hasMarked = s.marked > 0;
    final badgeIn = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
    );
    final contentIn = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.3, 0.8, curve: AppCurves.emphasized),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          SizedBox(
                            height: 200,
                            child: AnimatedBuilder(
                              animation: _c,
                              builder: (context, _) => CustomPaint(
                                painter: _ConfettiPainter(_c.value, [c.accent, c.keep, c.warning, c.delete]),
                                child: Center(
                                  child: Transform.scale(
                                    scale: badgeIn.value,
                                    child: Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: c.keep,
                                        boxShadow: [
                                          BoxShadow(
                                            color: c.keep.withValues(alpha: 0.4),
                                            blurRadius: 40,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: const Center(child: Text('🎉', style: TextStyle(fontSize: 48))),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: contentIn,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(contentIn),
                              child: Column(
                                children: [
                                  const SizedBox(height: AppSpacing.md),
                                  Text('Great job!', style: context.text.displaySmall),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    hasMarked
                                        ? 'Session complete. Delete your marked photos now, or review them first.'
                                        : 'Session complete. Everything was a keeper.',
                                    textAlign: TextAlign.center,
                                    style: context.text.bodyLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  AppCard(
                                    child: Column(
                                      children: [
                                        _Row(
                                          icon: Icons.photo_library_rounded,
                                          color: c.accent,
                                          label: 'Photos reviewed',
                                          value: s.reviewed,
                                        ),
                                        _Row(icon: Icons.check_rounded, color: c.keep, label: 'Kept', value: s.kept),
                                        _Row(
                                          icon: Icons.close_rounded,
                                          color: c.delete,
                                          label: 'Marked for deletion',
                                          value: s.marked,
                                        ),
                                        if (hasMarked) ...[
                                          const Divider(height: AppSpacing.xl),
                                          Row(
                                            children: [
                                              Text('Potential space', style: context.text.titleSmall),
                                              const Spacer(),
                                              CountUpText(
                                                value: s.markedBytes,
                                                format: (v) => Fmt.bytes(v.round()),
                                                style: context.text.headlineSmall?.copyWith(color: c.keep),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text('Finished in ${Fmt.duration(s.duration)}', style: context.text.bodySmall),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: contentIn,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg, top: AppSpacing.md),
                      child: Column(
                        children: [
                          if (hasMarked) ...[
                            AppButton(
                              label: 'Delete ${Fmt.plural(s.marked, 'photo')}',
                              icon: Icons.delete_forever_rounded,
                              variant: AppButtonVariant.destructive,
                              onPressed: _deleteNow,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppButton.secondary(
                              label: 'Review in Trash first',
                              icon: Icons.delete_outline_rounded,
                              onPressed: () => AppRouter.toTrash(context, replace: true),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                          hasMarked
                              ? AppButton.ghost(label: 'Done', onPressed: () => Navigator.of(context).pop())
                              : AppButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
                        ],
                      ),
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

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          IconTile(icon: icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: context.text.bodyLarge?.copyWith(color: context.colors.textPrimary)),
          ),
          CountUpText(value: value, style: context.text.titleLarge),
        ],
      ),
    );
  }
}

/// One-shot burst of confetti that fades out; intentionally brief.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.colors);

  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.08 || t >= 1) return;
    final p = ((t - 0.08) / 0.92).clamp(0.0, 1.0);
    final r = Random(3);
    final center = size.center(Offset.zero);
    final paint = Paint();
    for (var i = 0; i < 36; i++) {
      final angle = r.nextDouble() * pi * 2;
      final speed = 80 + r.nextDouble() * 110;
      final dist = speed * Curves.easeOutCubic.transform(p);
      final gravity = 60 * p * p;
      final pos = center + Offset(cos(angle) * dist, sin(angle) * dist + gravity);
      paint.color = colors[i % colors.length].withValues(alpha: (1 - p).clamp(0, 1));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + p * 6);
      if (i.isEven) {
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(1)), paint);
      } else {
        canvas.drawCircle(Offset.zero, 3, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
