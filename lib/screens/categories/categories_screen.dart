import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/photo_album.dart';
import '../../models/photo_category.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_style.dart';
import '../../widgets/photo_order_toggle.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_widgets.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LibraryScope.of(context);
    final categories = store.categories;
    final all = store.category(CategoryKind.all);
    final rest = categories.where((c) => c.kind != CategoryKind.all).toList();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xl),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Library', style: context.text.headlineLarge)),
                          const PhotoOrderToggle(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Pick where to start. Smaller sets go faster.', style: context.text.bodyLarge),
                    ],
                  ),
                ),
              ),
              if (!store.isLoaded)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  sliver: SliverToBoxAdapter(child: Skeleton(height: 180, radius: AppRadius.card)),
                )
              else ...[
                if (all != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    sliver: SliverToBoxAdapter(
                      child: _Staggered(index: 0, child: _AllPhotosCard(category: all)),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent > 460 ? 3 : 2;
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisExtent: 212,
                        ),
                        itemCount: rest.length,
                        itemBuilder: (context, i) => _Staggered(
                          index: i + 1,
                          child: _CategoryCard(category: rest[i]),
                        ),
                      );
                    },
                  ),
                ),
                if (store.albums.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: Text('Albums', style: context.text.titleLarge)),
                          Text(Fmt.plural(store.albums.length, 'album'), style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.md,
                      AppSpacing.gutter,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) => SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.crossAxisExtent > 460 ? 3 : 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: store.albums.length,
                        itemBuilder: (context, i) => _AlbumCard(album: store.albums[i]),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: AppCurves.emphasized,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
      ),
      child: child,
    );
  }
}

class _AllPhotosCard extends StatelessWidget {
  const _AllPhotosCard({required this.category});

  final PhotoCategory category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: () => AppRouter.openCategory(context, category.kind),
      semanticLabel: 'All photos, ${category.count} items',
      padding: const EdgeInsets.all(AppSpacing.xs),
      radius: AppRadius.card,
      child: Column(
        children: [
          SizedBox(
            height: 132,
            child: Row(
              children: [
                for (var i = 0; i < category.previews.length && i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    flex: i == 0 ? 2 : 1,
                    child: PhotoView(
                      photo: category.previews[i],
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(i == 0 ? AppRadius.xl - 4 : 4),
                        right: Radius.circular(i == 2 ? AppRadius.xl - 4 : 4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                IconTile(icon: category.kind.icon, color: category.kind.color(context), size: 44),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.title, style: context.text.titleMedium),
                      Text(
                        '${Fmt.number(category.count)} photos · ${Fmt.bytes(category.sizeBytes)}',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.textPrimary, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward_rounded, color: c.background, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final PhotoCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.kind.color(context);
    return AppCard(
      onTap: () => AppRouter.openCategory(context, category.kind),
      semanticLabel: '${category.title}, ${category.count} items',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: category.kind.icon, color: color, size: 40),
              const Spacer(),
              _Thumbs(category: category),
            ],
          ),
          const Spacer(),
          Text(category.title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(category.description, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.number(category.count), style: context.text.headlineSmall),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(Fmt.bytes(category.sizeBytes), style: context.text.bodySmall, maxLines: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressBar(value: category.progress, height: 4, color: color),
        ],
      ),
    );
  }
}

/// Small overlapping thumbnails.
class _Thumbs extends StatelessWidget {
  const _Thumbs({required this.category});

  final PhotoCategory category;

  @override
  Widget build(BuildContext context) {
    final photos = category.previews.take(2).toList();
    final c = context.colors;
    return SizedBox(
      width: 22.0 + photos.length * 18,
      height: 40,
      child: Stack(
        children: [
          for (var i = 0; i < photos.length; i++)
            Positioned(
              right: i * 18.0,
              child: Container(
                width: 32,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: PhotoView(photo: photos[i], borderRadius: BorderRadius.circular(7)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cover image with the album name and item count underneath.
class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final PhotoAlbum album;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cover = album.cover;
    return Pressable(
      onTap: () => AppRouter.toAlbum(context, album),
      scale: 0.97,
      semanticLabel: '${album.name}, ${album.count} items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: cover != null
                ? PhotoView(photo: cover, borderRadius: BorderRadius.circular(AppRadius.lg))
                : Container(
                    decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.lg)),
                    child: Center(child: Icon(Icons.photo_album_outlined, color: c.textTertiary)),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(album.name, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(Fmt.plural(album.count, 'item'), style: context.text.bodySmall),
        ],
      ),
    );
  }
}
