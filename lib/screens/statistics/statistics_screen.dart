import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/navigation/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../models/statistics.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/stats_widgets.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LibraryScope.of(context);
    final stats = store.insights;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl),
            children: [
              Text('Your progress', style: context.text.headlineLarge),
              const SizedBox(height: 2),
              Text('See how much you have cleaned up.', style: context.text.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              if (stats == null)
                const Skeleton(height: 200, radius: AppRadius.card)
              else if (stats.photosReviewed == 0 && stats.bytesRecovered == 0)
                const _NoInsightsYet()
              else ...[
                _RecoveredHero(stats: stats, recoveredNow: store.overview.recoveredBytes),
                const SizedBox(height: AppSpacing.md),
                _TileGrid(stats: stats),
                const SizedBox(height: AppSpacing.md),
                _MonthlyCard(stats: stats),
                const SizedBox(height: AppSpacing.md),
                _RatioCard(stats: stats),
                const SizedBox(height: AppSpacing.md),
                _StreakCard(days: stats.streakDays),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveredHero extends StatelessWidget {
  const _RecoveredHero({required this.stats, required this.recoveredNow});

  final InsightsStats stats;
  final int recoveredNow;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final bytes = stats.bytesRecovered > recoveredNow ? stats.bytesRecovered : recoveredNow;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPACE FREED UP',
                  style: context.text.labelSmall?.copyWith(color: white.withValues(alpha: 0.7), letterSpacing: 1.4),
                ),
                const SizedBox(height: AppSpacing.xs),
                CountUpText(
                  value: bytes,
                  format: (v) => Fmt.bytes(v.round()),
                  style: context.text.displaySmall?.copyWith(color: white),
                ),
                const SizedBox(height: 2),
                Text(
                  'That’s about ${Fmt.number(bytes / (3.2 * 1024 * 1024))} photos’ worth',
                  style: context.text.bodyMedium?.copyWith(color: white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: white.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_done_rounded, color: white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.stats});

  final InsightsStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tiles = [
      StatTile(
        icon: Icons.photo_library_rounded,
        color: c.accent,
        label: 'Photos reviewed',
        value: stats.photosReviewed,
      ),
      StatTile(icon: Icons.check_rounded, color: c.keep, label: 'Photos kept', value: stats.photosKept),
      StatTile(
        icon: Icons.delete_outline_rounded,
        color: c.delete,
        label: 'Photos deleted',
        value: stats.photosDeleted,
      ),
      StatTile(
        icon: Icons.timer_outlined,
        color: c.warning,
        label: 'Cleaning sessions',
        value: stats.sessions,
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({required this.stats});

  final InsightsStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = stats.monthly.last;
    final prev = stats.monthly[stats.monthly.length - 2];
    final change = prev.reviewed == 0 ? 0 : ((last.reviewed - prev.reviewed) / prev.reviewed * 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Month by month', style: context.text.titleMedium)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: change >= 0 ? c.keepSoft : c.deleteSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${change >= 0 ? '↑' : '↓'} ${change.abs()}%',
                  style: context.text.labelSmall?.copyWith(color: change >= 0 ? c.keep : c.delete),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('${Fmt.number(last.reviewed)} reviewed this month', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          MonthlyBarChart(data: stats.monthly),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              LegendDot(color: c.accent, label: 'Reviewed'),
              const SizedBox(width: AppSpacing.lg),
              LegendDot(color: c.delete, label: 'Deleted'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatioCard extends StatelessWidget {
  const _RatioCard({required this.stats});

  final InsightsStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = stats.photosKept + stats.photosDeleted;
    final keepPct = total == 0 ? 0.0 : stats.photosKept / total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kept and deleted', style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text('You keep about ${(keepPct * 100).round()}% of what you review.', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          ProgressBar(value: keepPct, height: 12, color: c.keep, trackColor: c.delete.withValues(alpha: 0.85)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              LegendDot(color: c.keep, label: 'Kept ${Fmt.number(stats.photosKept)}'),
              const Spacer(),
              LegendDot(color: c.delete, label: 'Deleted ${Fmt.number(stats.photosDeleted)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🔥', style: context.text.headlineSmall),
              const SizedBox(width: AppSpacing.xs),
              Text('$days-day streak', style: context.text.titleMedium),
            ],
          ),
          const SizedBox(height: 2),
          Text('A few swipes a day keeps the clutter away.', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Builder(
                  builder: (context) {
                    // Last seven days, ending today.
                    final daysAgo = 6 - i;
                    final day = now.subtract(Duration(days: daysAgo));
                    final active = daysAgo < days;
                    final isToday = daysAgo == 0;
                    return Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: active ? c.warning : c.surfaceMuted,
                            shape: BoxShape.circle,
                            border: isToday ? Border.all(color: c.textPrimary, width: 2) : null,
                          ),
                          child: active ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                        ),
                        const SizedBox(height: 4),
                        Text(labels[day.weekday - 1], style: context.text.labelSmall?.copyWith(color: c.textTertiary)),
                      ],
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown until the first photos have been reviewed.
class _NoInsightsYet extends StatelessWidget {
  const _NoInsightsYet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(Icons.insights_rounded, color: c.accent, size: 34),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Nothing to show yet', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Review a few photos and your progress, space saved and streaks will show up here.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Start cleaning',
            icon: Icons.swipe_rounded,
            expanded: false,
            large: false,
            onPressed: () => AppRouter.toCleaning(context),
          ),
        ],
      ),
    );
  }
}
