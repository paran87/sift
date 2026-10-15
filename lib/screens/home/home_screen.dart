import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/photo_category.dart';
import '../../models/statistics.dart';
import '../../services/photo_library_service.dart';
import '../../state/app_scope.dart';
import '../../state/library_store.dart';
import '../../widgets/app_card.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/category_style.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final store = LibraryScope.of(context);
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: AnimatedSwitcher(
            duration: AppDurations.slow,
            child: store.isLoaded
                ? _Content(store: store, onOpenTab: onOpenTab)
                : store.loadError != null
                ? EmptyState(
                    icon: Icons.error_outline_rounded,
                    color: context.colors.delete,
                    title: 'Couldn’t read your photos',
                    message: 'Something went wrong while scanning your library.',
                    actionLabel: 'Try again',
                    onAction: store.reset,
                  )
                : _Loading(progress: store.scanProgress),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.store, required this.onOpenTab});

  final LibraryStore store;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final o = store.overview;
    final picks = [
      CategoryKind.screenshots,
      CategoryKind.duplicates,
      CategoryKind.largeFiles,
      CategoryKind.similar,
    ].map(store.category).whereType<PhotoCategory>().toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
          sliver: SliverList.list(
            children: [
              _Header(trashCount: store.trash.length),
              if (store.access == LibraryAccess.limited) ...[
                const SizedBox(height: AppSpacing.md),
                _LimitedAccessBanner(onManage: store.manageLimitedAccess),
              ],
              const SizedBox(height: AppSpacing.xl),
              _Entrance(index: 0, child: _HeroCard(overview: o)),
              const SizedBox(height: AppSpacing.md),
              _Entrance(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.cloud_done_rounded,
                        color: context.colors.keep,
                        value: Fmt.bytes(o.recoverableBytes),
                        label: 'Potential cleanup',
                        onTap: () => AppRouter.toProgress(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.delete_outline_rounded,
                        color: context.colors.delete,
                        value: Fmt.number(store.trash.length),
                        label: 'In Trash · ${Fmt.bytes(store.trashBytes)}',
                        onTap: () => AppRouter.toTrash(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: 'Smart picks', actionLabel: 'See all', onAction: () => onOpenTab(1)),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: _Entrance(
            index: 2,
            child: SizedBox(
              height: 196,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                scrollDirection: Axis.horizontal,
                itemCount: picks.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => _PickCard(category: picks[i]),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl, AppSpacing.gutter, AppSpacing.xxl),
          sliver: SliverList.list(
            children: [
              SectionHeader(
                title: 'Cleaning progress',
                actionLabel: 'Details',
                onAction: () => AppRouter.toProgress(context),
              ),
              _Entrance(index: 3, child: _ProgressCard(overview: o)),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(title: 'Recent activity'),
              _Entrance(index: 4, child: _ActivityList(entries: store.activity.take(4).toList())),
            ],
          ),
        ),
      ],
    );
  }
}

/// Staggered fade/slide-in for home sections.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: AppCurves.emphasized,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.trashCount});

  final int trashCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${Fmt.greeting()} 👋', style: context.text.bodyLarge),
              const SizedBox(height: 2),
              Text('Your photo library', style: context.text.headlineLarge),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Tooltip(
              message: 'Trash',
              child: Pressable(
                onTap: () => AppRouter.toTrash(context),
                semanticLabel: 'Trash, $trashCount photos',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: c.textPrimary),
                ),
              ),
            ),
            if (trashCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 20),
                  decoration: BoxDecoration(
                    color: c.delete,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.background, width: 2),
                  ),
                  child: Text(
                    '$trashCount',
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.overview});

  final LibraryOverview overview;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    const onHero = Colors.white;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: context.colors.accent.withValues(alpha: context.isDark ? 0.2 : 0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TO REVIEW',
                      style: t.labelSmall?.copyWith(color: onHero.withValues(alpha: 0.7), letterSpacing: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CountUpText(
                        value: overview.remaining,
                        style: t.displayMedium?.copyWith(color: onHero),
                      ),
                    ),
                    Text(
                      'of ${Fmt.number(overview.totalPhotos)} photos left',
                      style: t.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                value: overview.progress,
                size: 76,
                stroke: 8,
                color: onHero,
                trackColor: onHero.withValues(alpha: 0.18),
                child: Text('${(overview.progress * 100).round()}%', style: t.titleMedium?.copyWith(color: onHero)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Pressable(
            onTap: () => AppRouter.toCleaning(context),
            semanticLabel: 'Start cleaning',
            child: Container(
              height: 58,
              decoration: BoxDecoration(color: onHero, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swipe_rounded, color: Color(0xFF15161B)),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Start Cleaning', style: t.titleMedium?.copyWith(color: const Color(0xFF15161B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon, color: color, size: 36),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: context.colors.textTertiary, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: context.text.headlineSmall, maxLines: 1),
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.category});

  final PhotoCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.kind.color(context);
    return SizedBox(
      width: 150,
      child: AppCard(
        onTap: () => AppRouter.openCategory(context, category.kind),
        semanticLabel: '${category.title}, ${category.count} items',
        padding: const EdgeInsets.all(AppSpacing.xs),
        radius: AppRadius.lg + 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (category.previews.isNotEmpty)
                    PhotoView(photo: category.previews.first, borderRadius: BorderRadius.circular(AppRadius.lg - 2)),
                  Positioned(
                    left: AppSpacing.xs,
                    top: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                      child: Icon(category.kind.icon, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, AppSpacing.sm, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${Fmt.number(category.count)} · ${Fmt.bytes(category.sizeBytes)}',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.overview});

  final LibraryOverview overview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = overview.totalPhotos == 0 ? 1 : overview.totalPhotos;
    return AppCard(
      onTap: () => AppRouter.toProgress(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.number(overview.reviewed), style: context.text.headlineMedium),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('/ ${Fmt.number(overview.totalPhotos)} reviewed', style: context.text.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stacked bar: kept vs marked vs remaining.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: overview.kept,
                    child: ColoredBox(color: c.keep),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: overview.markedForDeletion,
                    child: ColoredBox(color: c.delete),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (total - overview.reviewed).clamp(1, total),
                    child: ColoredBox(color: c.surfaceMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _Legend(color: c.keep, label: 'Kept ${Fmt.number(overview.kept)}'),
              _Legend(color: c.delete, label: 'Marked ${Fmt.number(overview.markedForDeletion)}'),
              _Legend(color: c.surfaceMuted, label: 'Left ${Fmt.number(overview.remaining)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

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

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.entries});

  final List<ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (entries.isEmpty) {
      return AppCard(child: Text('Your cleaning history will show up here.', style: context.text.bodyMedium));
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(indent: 72, color: c.border.withValues(alpha: 0.6)),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              leading: IconTile(
                icon: switch (entries[i].type) {
                  ActivityType.session => Icons.swipe_rounded,
                  ActivityType.emptied => Icons.delete_sweep_rounded,
                  ActivityType.duplicates => Icons.content_copy_rounded,
                },
                color: switch (entries[i].type) {
                  ActivityType.session => c.accent,
                  ActivityType.emptied => c.delete,
                  ActivityType.duplicates => c.keep,
                },
                size: 40,
              ),
              title: Text(entries[i].title, style: context.text.titleSmall),
              subtitle: Text(entries[i].detail, style: context.text.bodySmall),
              trailing: Text(Fmt.relative(entries[i].date), style: context.text.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.progress});

  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 140, height: 16),
          const SizedBox(height: AppSpacing.xs),
          const Skeleton(width: 240, height: 32),
          const SizedBox(height: AppSpacing.xl),
          const Skeleton(height: 220, radius: AppRadius.card),
          const SizedBox(height: AppSpacing.lg),
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, p, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanning your library… ${(p * 100).round()}%', style: context.text.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                ProgressBar(value: p),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the user shared only some photos (Android 14+ / iOS).
class _LimitedAccessBanner extends StatelessWidget {
  const _LimitedAccessBanner({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      color: c.warningSoft,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.photo_library_outlined, color: c.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Sift can only see the photos you selected.',
              style: context.text.bodySmall?.copyWith(color: c.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(foregroundColor: c.textPrimary),
            child: const Text('Choose more'),
          ),
        ],
      ),
    );
  }
}
