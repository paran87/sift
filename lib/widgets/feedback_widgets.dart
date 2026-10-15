import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = color ?? c.accent;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.slow,
          curve: AppCurves.emphasized,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: context.isDark ? 0.16 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 42, color: tint),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(message, style: context.text.bodyMedium, textAlign: TextAlign.center),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: actionLabel!, onPressed: onAction, expanded: false, large: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class AppDialog {
  /// Confirmation dialog. Returns true when confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
    IconData? icon,
  }) async {
    final c = context.colors;
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: AppDurations.medium,
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppCurves.emphasized);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
        );
      },
      pageBuilder: (context, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: destructive ? c.deleteSoft : c.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: destructive ? c.delete : c.accent),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs),
                    Text(message, style: context.text.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: confirmLabel,
                      variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
                      large: false,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton.ghost(
                      label: cancelLabel,
                      large: false,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

abstract final class AppSheet {
  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
          child: builder(context),
        ),
      ),
    );
  }
}

/// A row inside a bottom sheet action list.
class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = destructive ? c.delete : c.textPrimary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      leading: Icon(icon, color: color),
      title: Text(label, style: context.text.titleSmall?.copyWith(color: color)),
    );
  }
}

void showAppSnack(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: actionLabel != null ? SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}) : null,
      ),
    );
}
