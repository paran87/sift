import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../models/duplicate_group.dart';
import '../../models/photo.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_widgets.dart';

class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key, required this.kind});

  final GroupKind kind;

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  List<DuplicateGroup>? _groups;
  final Set<String> _selected = {};
  final Set<String> _collapsing = {};

  String get _title => widget.kind == GroupKind.duplicate ? 'Duplicates' : 'Similar Photos';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_groups == null) _load();
  }

  Future<void> _load() async {
    final store = LibraryScope.read(context);
    List<DuplicateGroup> groups;
    try {
      groups = await store.service.loadGroups(widget.kind);
    } catch (_) {
      groups = const [];
    }
    // Leave out photos already waiting in Trash.
    final inTrash = {for (final p in store.trash) p.id};
    final visible = [
      for (final g in groups)
        if (g.photos.where((p) => !inTrash.contains(p.id)).length > 1)
          DuplicateGroup(
            id: g.id,
            kind: g.kind,
            photos: g.photos.where((p) => !inTrash.contains(p.id)).toList(),
            bestPhotoId: g.bestPhotoId,
            label: g.label,
          ),
    ];
    if (mounted) setState(() => _groups = visible);
  }

  Iterable<Photo> get _selectedPhotos => (_groups ?? []).expand((g) => g.photos).where((p) => _selected.contains(p.id));

  void _toggle(Photo p) {
    AppHaptics.selection(context);
    setState(() => _selected.contains(p.id) ? _selected.remove(p.id) : _selected.add(p.id));
  }

  void _keepBest(DuplicateGroup g) {
    AppHaptics.light(context);
    setState(() {
      for (final p in g.photos) {
        p.id == g.bestPhotoId ? _selected.remove(p.id) : _selected.add(p.id);
      }
    });
  }

  void _smartSelect() {
    AppHaptics.medium(context);
    setState(() {
      for (final g in _groups!) {
        for (final p in g.photos) {
          if (p.id != g.bestPhotoId) _selected.add(p.id);
        }
      }
    });
  }

  Future<void> _compare(DuplicateGroup g) async {
    final toDelete = await AppRouter.toCompare(context, g);
    if (toDelete == null || !mounted) return;
    setState(() {
      _selected.removeAll(g.photos.map((p) => p.id));
      _selected.addAll(toDelete);
    });
  }

  /// "Keep all" — the group is reviewed without deleting anything.
  void _dismiss(DuplicateGroup g) {
    _collapse([g]);
    showAppSnack(context, 'Kept all ${g.photos.length} photos');
  }

  void _collapse(List<DuplicateGroup> groups) {
    setState(() => _collapsing.addAll(groups.map((g) => g.id)));
    Future.delayed(AppDurations.slow, () {
      if (!mounted) return;
      setState(() {
        _groups!.removeWhere((g) => groups.contains(g));
        _collapsing.removeAll(groups.map((g) => g.id));
      });
    });
  }

  Future<void> _moveToTrash() async {
    final photos = _selectedPhotos.toList();
    if (photos.isEmpty) return;
    final affected = _groups!.where((g) => g.photos.any((p) => _selected.contains(p.id))).toList();
    final store = LibraryScope.read(context);
    AppHaptics.medium(context);
    store.markForDeletion(photos);
    _selected.clear();
    _collapse(affected);
    showAppSnack(
      context,
      '${Fmt.plural(photos.length, 'photo')} moved to Trash',
      actionLabel: 'Undo',
      onAction: () {
        store.restore(photos);
        if (!mounted) return;
        setState(() {
          for (final g in affected) {
            if (!_groups!.contains(g)) _groups!.add(g);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final groups = _groups;
    final selectedPhotos = _selectedPhotos.toList();
    final selectedBytes = selectedPhotos.fold<int>(0, (s, p) => s + p.sizeBytes);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: AnimatedSwitcher(
            duration: AppDurations.medium,
            child: groups == null
                ? const _Loading()
                : groups.isEmpty
                ? EmptyState(
                    icon: Icons.task_alt_rounded,
                    color: c.keep,
                    title: 'All sorted',
                    message: 'No more ${_title.toLowerCase()} to review. Nicely done.',
                    actionLabel: 'Back to library',
                    onAction: () => Navigator.of(context).pop(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, 120),
                    children: [
                      _Summary(groups: groups, onSmartSelect: _smartSelect, kind: widget.kind),
                      const SizedBox(height: AppSpacing.md),
                      for (final g in groups)
                        _Collapsible(
                          key: ValueKey(g.id),
                          collapsed: _collapsing.contains(g.id),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _GroupCard(
                              group: g,
                              selected: _selected,
                              onToggle: _toggle,
                              onKeepBest: () => _keepBest(g),
                              onKeepAll: () => _dismiss(g),
                              onCompare: () => _compare(g),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: AppDurations.medium,
        curve: AppCurves.emphasized,
        child: selectedPhotos.isEmpty
            ? const SizedBox(width: double.infinity)
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.xs,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: AppButton(
                    label: selectedPhotos.isEmpty
                        ? 'Move to Trash'
                        : 'Move ${selectedPhotos.length} to Trash · ${Fmt.bytes(selectedBytes)}',
                    icon: Icons.delete_outline_rounded,
                    variant: AppButtonVariant.destructive,
                    onPressed: selectedPhotos.isEmpty ? null : _moveToTrash,
                  ),
                ),
              ),
      ),
    );
  }
}

class _Collapsible extends StatelessWidget {
  const _Collapsible({super.key, required this.collapsed, required this.child});

  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDurations.slow,
      curve: AppCurves.emphasized,
      child: AnimatedOpacity(
        opacity: collapsed ? 0 : 1,
        duration: AppDurations.medium,
        child: collapsed ? const SizedBox(width: double.infinity) : child,
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.groups, required this.onSmartSelect, required this.kind});

  final List<DuplicateGroup> groups;
  final VoidCallback onSmartSelect;
  final GroupKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photos = groups.fold<int>(0, (s, g) => s + g.photos.length);
    final extraBytes = groups.fold<int>(
      0,
      (s, g) => s + g.photos.where((p) => p.id != g.bestPhotoId).fold<int>(0, (a, p) => a + p.sizeBytes),
    );
    return AppCard(
      color: c.accentSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Fmt.plural(groups.length, 'group')} · ${Fmt.plural(photos, 'photo')}',
            style: context.text.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            kind == GroupKind.duplicate
                ? 'Keep one of each and free up to ${Fmt.bytes(extraBytes)}.'
                : 'We marked the most detailed shot in each burst as Best. Free up to ${Fmt.bytes(extraBytes)}.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Smart select',
            icon: Icons.auto_awesome_rounded,
            large: false,
            expanded: false,
            onPressed: onSmartSelect,
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.selected,
    required this.onToggle,
    required this.onKeepBest,
    required this.onKeepAll,
    required this.onCompare,
  });

  final DuplicateGroup group;
  final Set<String> selected;
  final ValueChanged<Photo> onToggle;
  final VoidCallback onKeepBest;
  final VoidCallback onKeepAll;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = group.photos.where((p) => selected.contains(p.id)).length;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.label, style: context.text.titleMedium),
                    Text(
                      [
                        '${group.photos.length} photos',
                        Fmt.bytes(group.totalBytes),
                        // Skip the date when the title already shows it.
                        if (!group.label.startsWith(Fmt.date(group.photos.first.takenAt)))
                          Fmt.date(group.photos.first.takenAt),
                      ].join(' · '),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onCompare,
                icon: const Icon(Icons.compare_rounded, size: 18),
                label: const Text('Compare'),
                style: TextButton.styleFrom(foregroundColor: c.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, box) {
              const gap = AppSpacing.xs;
              final perRow = group.photos.length <= 3 ? 3 : 3.4;
              final w = (box.maxWidth - gap * 2) / perRow;
              return SizedBox(
                height: w * 1.3,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: group.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: gap),
                  itemBuilder: (context, i) {
                    final p = group.photos[i];
                    return SizedBox(
                      width: w,
                      child: _Thumb(
                        photo: p,
                        best: p.id == group.bestPhotoId,
                        selected: selected.contains(p.id),
                        onTap: () => onToggle(p),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Text(
                    count == 0 ? 'Tap photos to select' : '$count selected',
                    key: ValueKey(count),
                    style: context.text.bodySmall?.copyWith(color: count == 0 ? c.textTertiary : c.delete),
                  ),
                ),
              ),
              _SmallButton(label: 'Keep all', onTap: onKeepAll),
              const SizedBox(width: AppSpacing.xs),
              _SmallButton(label: 'Keep best', onTap: onKeepBest, filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? c.textPrimary : c.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label, style: context.text.labelMedium?.copyWith(color: filled ? c.background : c.textPrimary)),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.best, required this.selected, required this.onTap});

  final Photo photo;
  final bool best;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      haptic: false,
      semanticLabel: '${best ? 'Best shot. ' : ''}${selected ? 'Selected for deletion' : 'Not selected'}',
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.all(selected ? 3 : 0),
        decoration: BoxDecoration(color: c.delete, borderRadius: BorderRadius.circular(AppRadius.md + 2)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoView(photo: photo, borderRadius: BorderRadius.circular(AppRadius.md)),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: AppDurations.fast,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            if (best)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 3, 8, 3),
                  decoration: BoxDecoration(color: c.keep, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 2),
                      Text('Best', style: context.text.labelSmall?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 6,
              top: 6,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.delete : Colors.black.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Text(
                Fmt.bytes(photo.sizeBytes),
                style: context.text.labelSmall?.copyWith(
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: const [
        Skeleton(height: 140, radius: AppRadius.xl),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 240, radius: AppRadius.xl),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 240, radius: AppRadius.xl),
      ],
    );
  }
}
