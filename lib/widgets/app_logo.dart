import 'package:flutter/material.dart';

/// Brand mark: two stacked photo cards, the front one tilted mid-swipe.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88, this.tilt = 1});

  final double size;

  /// 0..1 — how far the front card is tilted (used by the splash animation).
  final double tilt;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D5BFF), Color(0xFF4F46E5), Color(0xFF3B2FC9)],
  );

  @override
  Widget build(BuildContext context) {
    final card = size * 0.42;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.16,
            child: _MiniCard(width: card, height: card * 1.28, opacity: 0.35),
          ),
          Transform.translate(
            offset: Offset(size * 0.08 * tilt, -size * 0.02 * tilt),
            child: Transform.rotate(
              angle: 0.2 * tilt,
              child: _MiniCard(
                width: card,
                height: card * 1.28,
                opacity: 1,
                child: Icon(Icons.check_rounded, size: card * 0.55, color: const Color(0xFF4F46E5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.width, required this.height, required this.opacity, this.child});

  final double width;
  final double height;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(width * 0.22),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
