import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../models/photo.dart';
import '../../state/library_store.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/swipe_card.dart';

/// Card size that fits the available visual area.
Size _cardSize(BoxConstraints c) {
  final w = min(c.maxWidth * 0.64, c.maxHeight * 0.78 * 0.75);
  return Size(w, w / 0.75);
}

// ------------------------------------------------------------------ welcome

class WelcomeVisual extends StatefulWidget {
  const WelcomeVisual({super.key, required this.photos});

  final List<Photo> photos;

  @override
  State<WelcomeVisual> createState() => _WelcomeVisualState();
}

class _WelcomeVisualState extends State<WelcomeVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final size = _cardSize(box) * 0.86;
        return AnimatedBuilder(
          animation: _float,
          builder: (context, _) {
            final t = _float.value * 2 * pi;
            Widget card(Photo p, double angle, double dx, double phase) => Transform.translate(
              offset: Offset(dx * size.width, sin(t + phase) * 6),
              child: Transform.rotate(
                angle: angle,
                child: SizedBox.fromSize(
                  size: size,
                  child: SwipePhotoCard(photo: p, showDetails: false),
                ),
              ),
            );
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                card(widget.photos[1], -0.16, -0.32, 0),
                card(widget.photos[2], 0.16, 0.32, 2),
                card(widget.photos[0], 0, 0, 4),
                Positioned(
                  left: max(0, box.maxWidth / 2 - size.width * 1.05),
                  top: box.maxHeight / 2 - size.height * 0.28 + sin(t + 1) * 5,
                  child: _Chip(icon: Icons.close_rounded, label: 'Delete', color: c.delete),
                ),
                Positioned(
                  right: max(0, box.maxWidth / 2 - size.width * 1.05),
                  top: box.maxHeight / 2 + size.height * 0.12 + sin(t + 3) * 5,
                  child: _Chip(icon: Icons.check_rounded, label: 'Keep', color: c.keep),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.glow(color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(label, style: context.text.labelLarge?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- swipe demo

/// Looping gesture demo that the user can also try for real. Swiping the
/// card in the taught direction calls [onCompleted].
class SwipeDemo extends StatefulWidget {
  const SwipeDemo({super.key, required this.decision, required this.photos, required this.onCompleted});

  final SwipeDecision decision;
  final List<Photo> photos;
  final VoidCallback onCompleted;

  @override
  State<SwipeDemo> createState() => _SwipeDemoState();
}

class _SwipeDemoState extends State<SwipeDemo> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
    ..repeat();
  late final AnimationController _manualCtrl = AnimationController(vsync: this);
  Animation<Offset>? _manualAnim;
  Offset? _manual;
  bool _done = false;
  Size _card = Size.zero;

  double get _dir => widget.decision == SwipeDecision.keep ? 1 : -1;

  @override
  void initState() {
    super.initState();
    _manualCtrl.addListener(() {
      final a = _manualAnim;
      if (a != null) setState(() => _manual = a.value);
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  // Scripted timeline for the looping demo.
  Offset _loopOffset(double t) {
    final w = _card.width;
    if (t < 0.15) return Offset.zero;
    if (t < 0.55) {
      final p = Curves.easeInOut.transform((t - 0.15) / 0.4);
      return Offset(_dir * w * 0.42 * p, -8 * p);
    }
    if (t < 0.72) {
      final p = Curves.easeIn.transform((t - 0.55) / 0.17);
      return Offset(_dir * (w * 0.42 + w * 1.3 * p), -8 - 30 * p);
    }
    return Offset.zero;
  }

  double _loopAppear(double t) {
    if (t < 0.72) return 1;
    if (t < 0.76) return 0;
    return Curves.easeOut.transform(((t - 0.76) / 0.14).clamp(0, 1));
  }

  double _handOpacity(double t) {
    if (t < 0.06) return t / 0.06;
    if (t < 0.55) return 1;
    if (t < 0.65) return 1 - (t - 0.55) / 0.1;
    return 0;
  }

  Future<void> _animateManual(Offset to, Duration d, Curve curve) async {
    _manualAnim = Tween(
      begin: _manual ?? Offset.zero,
      end: to,
    ).animate(CurvedAnimation(parent: _manualCtrl, curve: curve));
    _manualCtrl.duration = d;
    await _manualCtrl.forward(from: 0);
    _manualAnim = null;
  }

  void _onStart(DragStartDetails d) {
    if (_done) return;
    _loop.stop();
    _manualCtrl.stop();
    setState(() => _manual = _loopAppear(_loop.value) < 1 ? Offset.zero : _loopOffset(_loop.value));
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_done || _manual == null) return;
    setState(() => _manual = _manual! + d.delta);
  }

  Future<void> _onEnd(DragEndDetails d) async {
    if (_done || _manual == null) return;
    final dx = _manual!.dx;
    final v = d.velocity.pixelsPerSecond.dx;
    final success = dx * _dir > _card.width * 0.3 || (v * _dir > 900 && dx * _dir > 20);
    if (success) {
      _done = true;
      AppHaptics.medium(context);
      await _animateManual(
        Offset(_dir * _card.width * 2, _manual!.dy - 30),
        const Duration(milliseconds: 320),
        Curves.easeOutCubic,
      );
      if (!mounted) return;
      setState(() {});
      widget.onCompleted();
    } else {
      await _animateManual(Offset.zero, const Duration(milliseconds: 450), Curves.easeOutBack);
      if (!mounted) return;
      setState(() => _manual = null);
      _loop.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        _card = _cardSize(box);
        return AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final t = _loop.value;
            final manual = _manual != null;
            final offset = manual ? _manual! : _loopOffset(t);
            final appear = manual ? 1.0 : _loopAppear(t);
            final amount = offset.dx / (_card.width * 0.3);

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: const Offset(0, 16),
                  child: Transform.scale(
                    scale: 0.93,
                    child: SizedBox.fromSize(
                      size: _card,
                      child: SwipePhotoCard(photo: widget.photos[1], showDetails: false),
                    ),
                  ),
                ),
                if (!_done || _manualCtrl.isAnimating)
                  GestureDetector(
                    onPanStart: _onStart,
                    onPanUpdate: _onUpdate,
                    onPanEnd: _onEnd,
                    child: Opacity(
                      opacity: appear,
                      child: Transform.scale(
                        scale: 0.92 + 0.08 * appear,
                        child: Transform.translate(
                          offset: offset,
                          child: Transform.rotate(
                            angle: offset.dx / _card.width * 0.3,
                            child: SizedBox.fromSize(
                              size: _card,
                              child: SwipePhotoCard(
                                photo: widget.photos[0],
                                showDetails: false,
                                keepAmount: amount > 0 ? amount.clamp(0, 1) : 0,
                                deleteAmount: amount < 0 ? (-amount).clamp(0, 1) : 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!manual && !_done)
                  IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(offset.dx, _card.height * 0.22 + offset.dy),
                      child: Opacity(opacity: _handOpacity(t), child: const _Hand()),
                    ),
                  ),
                if (_done && !_manualCtrl.isAnimating)
                  _SuccessBadge(color: widget.decision == SwipeDecision.keep ? c.keep : c.delete),
              ],
            );
          },
        );
      },
    );
  }
}

class _Hand extends StatelessWidget {
  const _Hand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: const Icon(Icons.touch_app_rounded, color: Color(0xFF15161B), size: 30),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => Transform.scale(
        scale: t,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: AppShadows.glow(color)),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- undo demo

class UndoDemo extends StatefulWidget {
  const UndoDemo({super.key, required this.photos});

  final List<Photo> photos;

  @override
  State<UndoDemo> createState() => _UndoDemoState();
}

class _UndoDemoState extends State<UndoDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final inner = BoxConstraints(maxWidth: box.maxWidth, maxHeight: box.maxHeight - 96);
        final card = _cardSize(inner);
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            double dx;
            if (t < 0.1) {
              dx = 0;
            } else if (t < 0.32) {
              dx = -Curves.easeIn.transform((t - 0.1) / 0.22) * card.width * 1.6;
            } else if (t < 0.56) {
              dx = -card.width * 1.6;
            } else if (t < 0.8) {
              dx = -card.width * 1.6 * (1 - Curves.easeOutBack.transform((t - 0.56) / 0.24));
            } else {
              dx = 0;
            }
            final pressed = t > 0.46 && t < 0.56;
            final handVisible = t > 0.36 && t < 0.62;
            final amount = (-dx / (card.width * 0.3)).clamp(0.0, 1.0);

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 16),
                        child: Transform.scale(
                          scale: 0.93,
                          child: SizedBox.fromSize(
                            size: card,
                            child: SwipePhotoCard(photo: widget.photos[1], showDetails: false),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(dx, 0),
                        child: Transform.rotate(
                          angle: dx / card.width * 0.3,
                          child: SizedBox.fromSize(
                            size: card,
                            child: SwipePhotoCard(photo: widget.photos[0], showDetails: false, deleteAmount: amount),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedScale(
                        scale: pressed ? 0.88 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: pressed ? c.accent : c.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: pressed ? c.accent : c.border),
                            boxShadow: AppShadows.soft(c),
                          ),
                          child: Icon(Icons.undo_rounded, color: pressed ? c.onAccent : c.textPrimary, size: 28),
                        ),
                      ),
                      Positioned(
                        left: null,
                        top: 30,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: handVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Transform.translate(offset: Offset(22, pressed ? -6 : 4), child: const _Hand()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --------------------------------------------------------------- ready

/// Library scan progress, then the real number of photos found.
class ReadyVisual extends StatelessWidget {
  const ReadyVisual({
    super.key,
    required this.progress,
    required this.loaded,
    required this.totalPhotos,
    required this.recoverableBytes,
  });

  /// Scan progress, 0 to 1.
  final double progress;
  final bool loaded;
  final int totalPhotos;
  final int recoverableBytes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final size = min(box.maxWidth * 0.62, box.maxHeight * 0.8);
        final value = loaded ? 1.0 : progress.clamp(0.0, 0.99);
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 1.15,
                height: size * 1.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.accent.withValues(alpha: 0.18 * value),
                      c.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              ProgressRing(
                value: value,
                size: size,
                stroke: 14,
                duration: const Duration(milliseconds: 400),
                color: loaded ? c.keep : c.accent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: AppDurations.medium,
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: loaded
                          ? Icon(Icons.check_circle_rounded, key: const ValueKey('done'), color: c.keep, size: 32)
                          : Icon(Icons.photo_library_rounded, key: const ValueKey('scan'), color: c.accent, size: 28),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (loaded) ...[
                      CountUpText(value: totalPhotos, style: context.text.displaySmall),
                      Text(totalPhotos == 1 ? 'item found' : 'items found', style: context.text.bodyMedium),
                    ] else ...[
                      Text('${(value * 100).round()}%', style: context.text.displaySmall),
                      Text('scanning', style: context.text.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    AnimatedOpacity(
                      opacity: loaded && recoverableBytes > 0 ? 1 : 0,
                      duration: AppDurations.medium,
                      child: Text(
                        'Up to ${Fmt.bytes(recoverableBytes)} to free',
                        style: context.text.labelMedium?.copyWith(color: c.keep),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
