import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../models/photo.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_widgets.dart';

/// Confirms, then really removes [photos] from the phone's gallery: they move
/// to the system Recycle Bin (Android 11+ / iOS) after the system's own
/// confirmation. Returns what was actually deleted (empty if cancelled/failed).
Future<List<Photo>> deletePhotosFlow(BuildContext context, List<Photo> photos) async {
  if (photos.isEmpty) return const [];
  final settings = SettingsScope.read(context);
  final recoverable = LibraryScope.read(context).deletionRecoverable;
  final bytes = photos.fold<int>(0, (s, p) => s + p.sizeBytes);
  if (settings.confirmBeforeDelete) {
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.delete_forever_rounded,
      title: 'Delete ${Fmt.plural(photos.length, 'item')}?',
      message: recoverable
          ? 'They’ll move to your phone’s Recycle Bin, where you can restore them for 30 days. '
                'Your phone will ask you to confirm.'
          : 'This frees ${Fmt.bytes(bytes)} and can’t be undone. Your phone will ask you to confirm.',
      confirmLabel: recoverable ? 'Delete' : 'Delete permanently',
      destructive: true,
    );
    if (!ok || !context.mounted) return const [];
  }
  final deleted = await showGeneralDialog<List<Photo>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: AppDurations.medium,
    transitionBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
    pageBuilder: (dialogContext, _, _) => _DeletingDialog(photos: photos, bytes: bytes),
  );
  if (!context.mounted) return deleted ?? const [];
  if (deleted == null) {
    showAppSnack(context, 'Couldn’t delete. Please try again.');
    return const [];
  }
  if (deleted.isEmpty) {
    showAppSnack(context, 'Nothing was deleted');
    return const [];
  }
  final freed = deleted.fold<int>(0, (s, p) => s + p.sizeBytes);
  showAppSnack(context, '${Fmt.bytes(freed)} freed up');
  return deleted;
}

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final Set<String> _selected = {};
  bool _selecting = false;

  void _toggleSelecting() {
    setState(() {
      _selecting = !_selecting;
      _selected.clear();
    });
  }

  void _toggle(Photo p) {
    AppHaptics.selection(context);
    setState(() {
      _selecting = true;
      _selected.contains(p.id) ? _selected.remove(p.id) : _selected.add(p.id);
    });
  }

  List<Photo> _targets(List<Photo> trash) =>
      _selecting && _selected.isNotEmpty ? trash.where((p) => _selected.contains(p.id)).toList() : trash;

  void _restore(List<Photo> photos) {
    final store = LibraryScope.read(context);
    AppHaptics.light(context);
    store.restore(photos);
    setState(() {
      _selected.clear();
      _selecting = false;
    });
    showAppSnack(
      context,
      '${Fmt.plural(photos.length, 'photo')} restored',
      actionLabel: 'Undo',
      onAction: () => store.markForDeletion(photos),
    );
  }

  Future<void> _delete(List<Photo> photos) async {
    final deleted = await deletePhotosFlow(context, photos);
    if (!mounted || deleted.isEmpty) return;
    setState(() {
      _selected.clear();
      _selecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = LibraryScope.of(context);
    final trash = store.trash;
    final c = context.colors;
    final targets = _targets(trash);
    final selectionActive = _selecting && _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (trash.isNotEmpty)
            TextButton(
              onPressed: _toggleSelecting,
              style: TextButton.styleFrom(foregroundColor: c.accent),
              child: Text(_selecting ? 'Cancel' : 'Select'),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: AnimatedSwitcher(
            duration: AppDurations.medium,
            child: trash.isEmpty
                ? EmptyState(
                    key: const ValueKey('empty'),
                    icon: Icons.auto_delete_outlined,
                    color: c.keep,
                    title: 'Trash is empty',
                    message: 'Photos you swipe left on wait here, so you can double-check before anything is deleted.',
                    actionLabel: 'Start cleaning',
                    onAction: () => AppRouter.toCleaning(context),
                  )
                : CustomScrollView(
                    key: const ValueKey('grid'),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.xs,
                          AppSpacing.gutter,
                          AppSpacing.md,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: AppCard(
                            color: c.deleteSoft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Recently marked', style: context.text.titleMedium),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${Fmt.plural(trash.length, 'photo')} · ${Fmt.bytes(store.trashBytes)}',
                                        style: context.text.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.info_outline_rounded, color: c.delete, size: 20),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Not deleted yet',
                                    style: context.text.labelMedium?.copyWith(color: c.delete),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 140),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = (constraints.crossAxisExtent / 120).floor().clamp(3, 5);
                            return SliverGrid.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: trash.length,
                              itemBuilder: (context, i) {
                                final p = trash[i];
                                return _TrashTile(
                                  key: ValueKey(p.id),
                                  photo: p,
                                  selecting: _selecting,
                                  selected: _selected.contains(p.id),
                                  onTap: () => _toggle(p),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: trash.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: selectionActive ? 'Restore ${targets.length}' : 'Restore all',
                        icon: Icons.restore_rounded,
                        onPressed: _selecting && _selected.isEmpty ? null : () => _restore(targets),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: selectionActive ? 'Delete ${targets.length}' : 'Delete all',
                        icon: Icons.delete_forever_rounded,
                        variant: AppButtonVariant.destructive,
                        onPressed: _selecting && _selected.isEmpty ? null : () => _delete(targets),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TrashTile extends StatelessWidget {
  const _TrashTile({
    super.key,
    required this.photo,
    required this.selecting,
    required this.selected,
    required this.onTap,
  });

  final Photo photo;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: AppDurations.medium,
      curve: AppCurves.emphasized,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Pressable(
        onTap: onTap,
        haptic: false,
        semanticLabel: selected ? 'Selected' : 'Photo',
        child: AnimatedScale(
          scale: selected ? 0.9 : 1,
          duration: AppDurations.fast,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoView(photo: photo, borderRadius: BorderRadius.circular(AppRadius.sm), showTypeBadge: true),
              if (selecting)
                Positioned(
                  right: 6,
                  top: 6,
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? c.accent : Colors.black.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satisfying "freeing space" progress while the (mock) delete runs.
class _DeletingDialog extends StatefulWidget {
  const _DeletingDialog({required this.photos, required this.bytes});

  final List<Photo> photos;
  final int bytes;

  @override
  State<_DeletingDialog> createState() => _DeletingDialogState();
}

class _DeletingDialogState extends State<_DeletingDialog> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // The system confirmation appears on top of this dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<Photo>? deleted;
      try {
        deleted = await LibraryScope.read(context).deletePermanently(widget.photos);
      } catch (_) {
        deleted = null;
      }
      if (!mounted) return;
      if (deleted == null || deleted.isEmpty) {
        Navigator.of(context).pop(deleted);
        return;
      }
      AppHaptics.heavy(context);
      setState(() => _done = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(deleted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeInOutCubic,
                  builder: (context, t, _) => ProgressRing(
                    value: _done ? 1 : t * 0.96,
                    size: 96,
                    stroke: 8,
                    duration: const Duration(milliseconds: 200),
                    color: _done ? c.keep : c.accent,
                    child: AnimatedSwitcher(
                      duration: AppDurations.medium,
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: _done
                          ? Icon(Icons.check_rounded, key: const ValueKey('ok'), color: c.keep, size: 40)
                          : Text(
                              Fmt.bytes((widget.bytes * t).round()),
                              key: const ValueKey('n'),
                              style: context.text.labelMedium,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(_done ? 'All clean' : 'Freeing up space…', style: context.text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  _done
                      ? '${Fmt.bytes(widget.bytes)} recovered'
                      : 'Deleting ${Fmt.plural(widget.photos.length, 'photo')}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
