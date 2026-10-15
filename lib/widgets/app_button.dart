import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = true,
    this.loading = false,
    this.large = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.large = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.loading = false,
    this.large = true,
  }) : variant = AppButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expanded;
  final bool loading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (variant) {
      AppButtonVariant.primary => (c.textPrimary, c.background),
      AppButtonVariant.secondary => (c.surfaceMuted, c.textPrimary),
      AppButtonVariant.ghost => (Colors.transparent, c.textPrimary),
      AppButtonVariant.destructive => (c.delete, Colors.white),
    };
    final enabled = onPressed != null && !loading;
    final height = large ? 58.0 : 46.0;

    final content = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.md, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (large ? context.text.titleMedium : context.text.labelLarge)?.copyWith(color: fg),
                  ),
                ),
              ],
            ),
    );

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedOpacity(
        opacity: enabled || loading ? 1 : 0.4,
        duration: AppDurations.fast,
        child: Container(
          height: height,
          width: expanded ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: large ? AppSpacing.xl : AppSpacing.lg),
          // An alignment would make the container fill the available width.
          alignment: expanded ? Alignment.center : null,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: variant == AppButtonVariant.primary && enabled ? AppShadows.soft(c) : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Circular icon button with a comfortable 48dp touch target.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.filled = true,
    this.size = 44,
    this.color,
    this.background,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool filled;
  final double size;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onPressed,
        semanticLabel: tooltip,
        scale: 0.9,
        child: SizedBox(
          width: size < 48 ? 48 : size,
          height: size < 48 ? 48 : size,
          child: Center(
            child: AnimatedOpacity(
              opacity: onPressed == null ? 0.35 : 1,
              duration: AppDurations.fast,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: filled ? (background ?? c.surface) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: filled && background == null ? Border.all(color: c.border) : null,
                ),
                child: Icon(icon, size: size * 0.48, color: color ?? c.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
