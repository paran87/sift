import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../state/app_scope.dart';
import 'pressable.dart';

/// Pill that flips between "Newest" and "Oldest" first. The choice is shared
/// app-wide (album grids and cleaning sessions).
class PhotoOrderToggle extends StatelessWidget {
  const PhotoOrderToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final order = settings.photoOrder;
    final c = context.colors;
    return Tooltip(
      message: 'Sort by date',
      child: Pressable(
        onTap: () => settings.photoOrder = order.flipped,
        semanticLabel: 'Sorted ${order.label.toLowerCase()}. Tap to change.',
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: order.index * 0.5,
                duration: AppDurations.medium,
                curve: AppCurves.emphasized,
                child: Icon(Icons.arrow_downward_rounded, size: 16, color: c.accent),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Text(
                  order.shortLabel,
                  key: ValueKey(order),
                  style: context.text.labelMedium?.copyWith(color: c.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
