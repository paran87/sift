import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/photo.dart';
import '../../models/photo_album.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/photo_order_toggle.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_widgets.dart';

/// All photos in one device album, grouped by month and sorted by date.
/// Tapping a photo starts cleaning from there.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.album});

  final PhotoAlbum album;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<Photo>? _photos;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_photos == null && !_failed) _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final photos = await LibraryScope.read(context).service.loadAlbumPhotos(widget.album.id);
      if (mounted) setState(() => _photos = photos);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _open(Photo photo) {
    if (LibraryScope.read(context).isInTrash(photo.id)) {
      showAppSnack(context, 'Already in Trash');
      return;
    }
    AppRouter.toAlbumCleaning(context, widget.album, startAtId: photo.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = LibraryScope.of(context);
    final order = SettingsScope.of(context).photoOrder;
    final photos = _photos == null ? null : order.apply(_photos!.where((p) => !store.isDeleted(p.id)));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.album.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(Fmt.plural(photos?.length ?? widget.album.count, 'item'), style: context.text.bodySmall),
          ],
        ),
        actions: const [
          PhotoOrderToggle(),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: AnimatedSwitcher(
            duration: AppDurations.medium,
            child: _failed
                ? EmptyState(
                    icon: Icons.error_outline_rounded,
                    color: context.colors.delete,
                    title: 'Couldn’t open this album',
                    message: 'Something went wrong while reading it.',
                    actionLabel: 'Try again',
                    onAction: _load,
                  )
                : photos == null
                ? const _GridSkeleton()
                : photos.isEmpty
                ? const EmptyState(
                    icon: Icons.photo_album_outlined,
                    title: 'Nothing here',
                    message: 'This album is empty now.',
                  )
                : _MonthGrid(key: ValueKey(order), photos: photos, onTap: _open),
          ),
        ),
      ),
      bottomNavigationBar: photos == null || photos.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
                child: AppButton(
                  label: 'Clean this album',
                  icon: Icons.swipe_rounded,
                  onPressed: () => AppRouter.toAlbumCleaning(context, widget.album),
                ),
              ),
            ),
    );
  }
}

/// Photos in sections per month, in the order given.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({super.key, required this.photos, required this.onTap});

  final List<Photo> photos;
  final ValueChanged<Photo> onTap;

  @override
  Widget build(BuildContext context) {
    final sections = <(DateTime, List<Photo>)>[];
    for (final p in photos) {
      final month = DateTime(p.takenAt.year, p.takenAt.month);
      if (sections.isEmpty || sections.last.$1 != month) sections.add((month, []));
      sections.last.$2.add(p);
    }

    return CustomScrollView(
      slivers: [
        for (final (month, items) in sections) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xs),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: Text(Fmt.monthYear(month), style: context.text.titleMedium)),
                  Text(Fmt.plural(items.length, 'item'), style: context.text.bodySmall),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (constraints.crossAxisExtent / 110).floor().clamp(3, 6),
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _Tile(photo: items[i], onTap: () => onTap(items[i])),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.photo, required this.onTap});

  final Photo photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final inTrash = LibraryScope.of(context).isInTrash(photo.id);
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: '${Fmt.date(photo.takenAt)}${inTrash ? ', in Trash' : ''}. Start cleaning from here.',
      child: Stack(
        fit: StackFit.expand,
        children: [
          PhotoView(photo: photo, borderRadius: BorderRadius.circular(6), showTypeBadge: true),
          if (inTrash) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: c.delete, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, size: 13, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: 24,
      itemBuilder: (_, _) => const Skeleton(radius: 6),
    );
  }
}
