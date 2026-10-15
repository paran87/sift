import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/formatters.dart';
import '../models/photo.dart';
import 'photo_view.dart';

/// A photo card with KEEP / DELETE stamps whose visibility is driven by
/// [keepAmount] / [deleteAmount] (0..1).
class SwipePhotoCard extends StatelessWidget {
  const SwipePhotoCard({
    super.key,
    required this.photo,
    this.keepAmount = 0,
    this.deleteAmount = 0,
    this.showDetails = true,
  });

  final Photo photo;
  final double keepAmount;
  final double deleteAmount;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const radius = BorderRadius.all(Radius.circular(AppRadius.card));
    final tint = keepAmount > 0 ? c.keep : c.delete;
    final tintAmount = keepAmount > 0 ? keepAmount : deleteAmount;

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: AppShadows.card(c)),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoView(photo: photo, large: true),
            if (photo.isVideo)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
            if (showDetails) _Details(photo: photo),
            if (tintAmount > 0)
              IgnorePointer(
                child: ColoredBox(color: tint.withValues(alpha: 0.22 * tintAmount)),
              ),
            Positioned(
              top: AppSpacing.xl,
              left: AppSpacing.xl,
              child: _Stamp(label: 'KEEP', icon: Icons.check_rounded, color: c.keep, amount: keepAmount, angle: -0.22),
            ),
            Positioned(
              top: AppSpacing.xl,
              right: AppSpacing.xl,
              child: _Stamp(
                label: 'DELETE',
                icon: Icons.close_rounded,
                color: c.delete,
                amount: deleteAmount,
                angle: 0.22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.icon,
    required this.color,
    required this.amount,
    required this.angle,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double amount;
  final double angle;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final a = amount.clamp(0.0, 1.0);
    return Opacity(
      opacity: a,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: 0.8 + 0.2 * a,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.glow(color),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.photo});

  final Photo photo;

  /// "Camera · Photo", but just "Screenshots" instead of "Screenshots · Screenshot".
  static String _caption(String? origin, String type) {
    if (origin == null) return type;
    if (origin.toLowerCase().startsWith(type.toLowerCase())) return origin;
    return '$origin · $type';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final type = switch (photo.type) {
      MediaType.video => 'Video · ${Fmt.duration(photo.videoDuration ?? Duration.zero)}',
      MediaType.screenshot => 'Screenshot',
      MediaType.photo => 'Photo',
    };
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.62)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.huge, AppSpacing.xl, AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Fmt.date(photo.takenAt), style: t.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      _caption(photo.origin, type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(Fmt.bytes(photo.sizeBytes), style: t.labelMedium?.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
