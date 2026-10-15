import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/photo.dart';
import 'photo_art_painter.dart';

/// Renders a [Photo]: the real image when available, otherwise the mock art.
class PhotoView extends StatelessWidget {
  const PhotoView({
    super.key,
    required this.photo,
    this.borderRadius = BorderRadius.zero,
    this.showTypeBadge = false,
    this.large = false,
  });

  final Photo photo;
  final BorderRadius borderRadius;
  final bool showTypeBadge;

  /// Use the full-size preview (swipe card, compare) instead of the thumbnail.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final provider = large ? (photo.image ?? photo.thumbnail) : (photo.thumbnail ?? photo.image);
    final art = photo.art;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: provider != null
                ? _DeviceImage(provider: provider)
                : art != null
                ? CustomPaint(painter: PhotoArtPainter(art))
                : ColoredBox(color: context.colors.surfaceMuted),
          ),
          if (showTypeBadge && photo.isVideo)
            Positioned(
              right: 6,
              bottom: 6,
              child: _Badge(icon: Icons.play_arrow_rounded, label: Fmt.duration(photo.videoDuration ?? Duration.zero)),
            ),
        ],
      ),
    );
  }
}

/// Device image with a soft placeholder, a fade-in, and an error state.
class _DeviceImage extends StatelessWidget {
  const _DeviceImage({required this.provider});

  final ImageProvider provider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Image(
      image: provider,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.surfaceMuted),
            AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 220), child: child),
          ],
        );
      },
      errorBuilder: (context, _, _) => ColoredBox(
        color: c.surfaceMuted,
        child: Icon(Icons.broken_image_outlined, color: c.textTertiary),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          Text(label, style: context.text.labelSmall?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
