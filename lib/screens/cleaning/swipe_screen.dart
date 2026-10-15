import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/photo.dart';
import '../../models/photo_album.dart';
import '../../models/photo_category.dart';
import '../../state/app_scope.dart';
import '../../state/cleaning_session.dart';
import '../../state/library_store.dart';
import '../../widgets/ad_banner_slot.dart';
import '../../widgets/app_button.dart';
import '../../widgets/category_style.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/swipe_deck.dart';
import '../../widgets/swipe_hint.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key, this.category = CategoryKind.all, this.album, this.startAtId});

  final CategoryKind category;

  /// Clean one device album instead of a category.
  final PhotoAlbum? album;

  /// Start the session at this photo (tapped in an album grid).
  final String? startAtId;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _deck = SwipeDeckController();
  CleaningSession? _session;
  bool _finishing = false;
  bool _adVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session == null) _load();
  }

  static const _sessionSize = 50;

  Future<void> _load() async {
    final store = LibraryScope.read(context);
    final settings = SettingsScope.read(context);
    final album = widget.album;
    List<Photo> queue;
    try {
      queue = album != null
          ? await store.service.loadAlbumPhotos(album.id)
          : await store.service.loadReviewQueue(widget.category);
    } catch (_) {
      queue = const []; // shows the "All caught up" empty state
    }
    if (!mounted) return;
    // Large files stay biggest-first; everything else follows the date order.
    if (album != null || widget.category != CategoryKind.largeFiles) {
      queue = settings.photoOrder.apply(queue);
    }
    // Skip what was already reviewed or deleted, and keep sessions bite-sized.
    var pending = store.pending(queue).where((p) => !store.isDeleted(p.id)).toList();
    final start = widget.startAtId == null ? -1 : pending.indexWhere((p) => p.id == widget.startAtId);
    if (start > 0) pending = pending.sublist(start);
    final photos = pending.take(_sessionSize).toList();
    setState(() {
      _session = CleaningSession(photos: photos, store: store, maxUndo: settings.undoSteps)
        ..addListener(_onSessionChanged);
    });
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _session?.dispose();
    _deck.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    setState(() {});
    final s = _session!;
    final settings = SettingsScope.read(context);
    if (s.index > 0 && !settings.swipeHintSeen) settings.swipeHintSeen = true;
    if (s.isFinished && s.total > 0 && !_finishing) _finish();
  }

  Future<void> _finish() async {
    _finishing = true;
    final summary = _session!.summary();
    LibraryScope.read(context).recordSession(summary);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) AppRouter.toCompletion(context, summary);
  }

  void _close() {
    final s = _session;
    if (s != null && s.kept + s.marked > 0) {
      LibraryScope.read(context).recordSession(s.summary());
      Navigator.of(context).pop();
      showAppSnack(context, 'Progress saved · ${s.kept + s.marked} reviewed');
    } else {
      Navigator.of(context).pop();
    }
  }

  void _undo() {
    final s = _session;
    if (s == null || !s.canUndo || _deck.isAnimating) return;
    final last = s.undo();
    if (last != null) _deck.bringBack(last.decision);
  }

  void _showMore(Photo photo) {
    AppSheet.show<void>(
      context,
      builder: (context) => _PhotoDetailsSheet(
        photo: photo,
        onFinish: () {
          Navigator.of(context).pop();
          if (_session!.kept + _session!.marked > 0) {
            _finish();
          } else {
            Navigator.of(this.context).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final settings = SettingsScope.of(context);
    final store = LibraryScope.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        bottomNavigationBar: AdBannerSlot(onVisibleChanged: (v) => setState(() => _adVisible = v)),
        body: SafeArea(
          bottom: !_adVisible, // the banner covers the system-navigation area
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: Column(
                children: [
                  _TopBar(
                    category: widget.category,
                    album: widget.album,
                    session: s,
                    trashCount: store.trash.length,
                    onClose: _close,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.md,
                        AppSpacing.gutter,
                        AppSpacing.xl,
                      ),
                      child: AnimatedSwitcher(
                        duration: AppDurations.medium,
                        child: s == null
                            ? const Skeleton(radius: AppRadius.card, height: double.infinity)
                            : s.total == 0
                            ? EmptyState(
                                icon: Icons.check_circle_outline_rounded,
                                color: context.colors.keep,
                                title: 'All caught up',
                                message: 'There is nothing left to review here.',
                                actionLabel: 'Back to library',
                                onAction: () => Navigator.of(context).pop(),
                              )
                            : Stack(
                                children: [
                                  SwipeDeck(
                                    photos: s.upcoming(3),
                                    controller: _deck,
                                    threshold: settings.swipeThreshold,
                                    onSwiped: s.decide,
                                  ),
                                  // First-time tutorial: arrows over the card, fading while dragging.
                                  if (!settings.swipeHintSeen)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: ValueListenableBuilder<double>(
                                          valueListenable: _deck.dragProgress,
                                          builder: (context, p, child) => AnimatedOpacity(
                                            opacity: p.abs() < 0.05 ? 1 : 0,
                                            duration: AppDurations.fast,
                                            child: child,
                                          ),
                                          child: const Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                              child: SwipeHintArrows(overPhoto: true),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  _Controls(
                    deck: _deck,
                    canUndo: s?.canUndo ?? false,
                    enabled: s != null && !s.isFinished,
                    onUndo: _undo,
                    onDelete: () => _deck.swipe(SwipeDecision.delete),
                    onKeep: () => _deck.swipe(SwipeDecision.keep),
                    onMore: s?.current == null ? null : () => _showMore(s!.current!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.category,
    required this.session,
    required this.trashCount,
    required this.onClose,
    this.album,
  });

  final CategoryKind category;
  final PhotoAlbum? album;
  final CleaningSession? session;
  final int trashCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = session;
    final title =
        album?.name ??
        switch (category) {
          CategoryKind.all => 'All photos',
          CategoryKind.screenshots => 'Screenshots',
          CategoryKind.videos => 'Videos',
          CategoryKind.largeFiles => 'Large files',
          CategoryKind.oldPhotos => 'Old photos',
          CategoryKind.duplicates => 'Duplicates',
          CategoryKind.similar => 'Similar',
        };
    final position = s == null ? 0 : (s.index + 1).clamp(1, s.total == 0 ? 1 : s.total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, 0),
      child: Row(
        children: [
          AppIconButton(icon: Icons.close_rounded, tooltip: 'Close', onPressed: onClose),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        album != null ? Icons.photo_album_rounded : category.icon,
                        size: 16,
                        color: album != null ? c.accent : category.color(context),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          style: context.text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('·', style: context.text.bodySmall),
                      const SizedBox(width: 6),
                      AnimatedSwitcher(
                        duration: AppDurations.fast,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                            child: child,
                          ),
                        ),
                        child: Text(
                          s == null ? '–' : '$position of ${s.total}',
                          key: ValueKey(position),
                          style: context.text.bodySmall?.copyWith(
                            color: c.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProgressBar(value: s?.progress ?? 0, height: 5),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Trash',
                onPressed: () => AppRouter.toTrash(context),
              ),
              if (trashCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(trashCount),
                    tween: Tween(begin: 1.4, end: 1),
                    duration: AppDurations.medium,
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: c.delete,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.background, width: 2),
                      ),
                      child: Text(
                        '$trashCount',
                        textAlign: TextAlign.center,
                        style: context.text.labelSmall?.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.deck,
    required this.canUndo,
    required this.enabled,
    required this.onUndo,
    required this.onDelete,
    required this.onKeep,
    required this.onMore,
  });

  final SwipeDeckController deck;
  final bool canUndo;
  final bool enabled;
  final VoidCallback onUndo;
  final VoidCallback onDelete;
  final VoidCallback onKeep;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        bottomInset > 0 ? AppSpacing.xs : AppSpacing.lg,
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: deck.dragProgress,
        builder: (context, p, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppIconButton(icon: Icons.undo_rounded, tooltip: 'Undo', onPressed: canUndo ? onUndo : null),
            _BigAction(
              icon: Icons.close_rounded,
              label: 'Delete',
              color: c.delete,
              soft: c.deleteSoft,
              highlight: p < 0 ? -p : 0,
              onTap: enabled ? onDelete : null,
            ),
            _BigAction(
              icon: Icons.check_rounded,
              label: 'Keep',
              color: c.keep,
              soft: c.keepSoft,
              highlight: p > 0 ? p : 0,
              onTap: enabled ? onKeep : null,
            ),
            AppIconButton(icon: Icons.more_horiz_rounded, tooltip: 'More', onPressed: onMore),
          ],
        ),
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.soft,
    required this.highlight,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color soft;
  final double highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = 72.0 + 8 * highlight;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        haptic: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Color.lerp(soft, color, highlight),
                    shape: BoxShape.circle,
                    boxShadow: highlight > 0.05
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35 * highlight),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, size: 34, color: Color.lerp(color, Colors.white, highlight)),
                ),
              ),
            ),
            Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _PhotoDetailsSheet extends StatelessWidget {
  const _PhotoDetailsSheet({required this.photo, required this.onFinish});

  final Photo photo;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: context.text.bodyMedium),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
          ),
        ],
      ),
    );

    void mock(String message) {
      Navigator.of(context).pop();
      showAppSnack(context, message);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: context.text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        row(Icons.calendar_today_rounded, 'Taken', Fmt.date(photo.takenAt)),
        if (photo.location != null) row(Icons.place_outlined, 'Location', photo.location!),
        if (photo.album != null) row(Icons.folder_outlined, 'Album', photo.album!),
        row(Icons.sd_storage_outlined, 'Size', Fmt.bytes(photo.sizeBytes)),
        row(Icons.aspect_ratio_rounded, 'Dimensions', '${photo.width} × ${photo.height}'),
        const SizedBox(height: AppSpacing.sm),
        const Divider(),
        const SizedBox(height: AppSpacing.xs),
        SheetAction(
          icon: Icons.favorite_border_rounded,
          label: 'Add to Favorites',
          onTap: () => mock('Added to Favorites'),
        ),
        SheetAction(
          icon: Icons.ios_share_rounded,
          label: 'Share',
          onTap: () => mock('Sharing is available in the full version'),
        ),
        SheetAction(icon: Icons.flag_outlined, label: 'Finish session', onTap: onFinish),
      ],
    );
  }
}
