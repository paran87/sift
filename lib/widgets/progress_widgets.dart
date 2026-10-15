import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/formatters.dart';

/// Circular progress that animates to [value] whenever it changes.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.stroke = 10,
    this.color,
    this.trackColor,
    this.child,
    this.duration = const Duration(milliseconds: 1100),
  });

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? trackColor;
  final Widget? child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: duration,
      curve: AppCurves.emphasized,
      builder: (context, v, child) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(v, stroke, color ?? c.accent, trackColor ?? c.surfaceMuted),
          child: Center(child: child),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color, this.track);

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, pi * 2, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(rect, -pi / 2, pi * 2 * value, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.stroke != stroke;
}

/// Thin rounded linear progress with animated fill.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 6, this.color, this.trackColor});

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: AppDurations.slow,
          curve: AppCurves.emphasized,
          builder: (context, v, _) => Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: trackColor ?? c.surfaceMuted),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color ?? c.accent, borderRadius: BorderRadius.circular(height)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Number that counts up from its previous value.
class CountUpText extends StatelessWidget {
  const CountUpText({super.key, required this.value, this.style, this.format, this.duration = AppDurations.countUp});

  final num value;
  final TextStyle? style;
  final String Function(num value)? format;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: AppCurves.standard,
      builder: (context, v, _) => Text(format != null ? format!(v) : Fmt.number(v), style: style),
    );
  }
}

/// Placeholder block with a gentle shimmer, for loading states.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = AppRadius.md});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 3 - 1;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [c.surfaceMuted, c.surface, c.surfaceMuted],
            ),
          ),
        );
      },
    );
  }
}
