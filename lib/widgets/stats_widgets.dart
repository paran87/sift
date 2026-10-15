import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/formatters.dart';
import '../models/statistics.dart';
import 'app_card.dart';
import 'progress_widgets.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.format,
    this.caption,
  });

  final IconData icon;
  final Color color;
  final String label;
  final num value;
  final String Function(num)? format;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, color: color, size: 36),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUpText(value: value, format: format, style: context.text.headlineMedium),
          ),
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary)),
          if (caption != null) ...[const SizedBox(height: 2), Text(caption!, style: context.text.bodySmall)],
        ],
      ),
    );
  }
}

/// Grouped monthly bars (reviewed vs deleted), animated on first build.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({super.key, required this.data, this.height = 180});

  final List<MonthlyActivity> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = data.fold<int>(1, (m, d) => d.reviewed > m ? d.reviewed : m);
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: AppCurves.emphasized,
        builder: (context, t, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < data.length; i++)
              Expanded(
                child: Semantics(
                  label: '${Fmt.month(data[i].month)}: ${data[i].reviewed} reviewed, ${data[i].deleted} deleted',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Bar(
                              fraction: data[i].reviewed / maxValue * t,
                              color: i == data.length - 1 ? c.accent : c.accent.withValues(alpha: 0.35),
                            ),
                            const SizedBox(width: 3),
                            _Bar(fraction: data[i].deleted / maxValue * t, color: c.delete.withValues(alpha: 0.85)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        Fmt.month(data[i].month),
                        style: context.text.labelSmall?.copyWith(
                          color: i == data.length - 1 ? c.textPrimary : c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: 12,
        height: (constraints.maxHeight * fraction).clamp(4, constraints.maxHeight),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary)),
      ],
    );
  }
}
