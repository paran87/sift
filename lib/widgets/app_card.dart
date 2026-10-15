import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import 'pressable.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.radius = AppRadius.xl,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // A Material surface (not a plain decorated box) so list tiles inside
    // show their tap ripples, clipped to the rounded corners.
    final card = Material(
      color: color ?? c.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: context.isDark ? BorderSide(color: c.border.withValues(alpha: 0.6)) : BorderSide.none,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap, scale: 0.98, semanticLabel: semanticLabel, child: card);
  }
}

/// Rounded square icon tile used in lists and categories.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.color, this.size = 44, this.soft});

  final IconData icon;
  final Color color;
  final Color? soft;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: soft ?? color.withValues(alpha: context.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: context.colors.accent),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
