import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../models/duplicate_group.dart';
import '../../models/photo.dart';
import '../../widgets/app_button.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/pressable.dart';

/// Side-by-side comparison with a draggable divider.
/// Pops with the set of photo ids to delete.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.group});

  final DuplicateGroup group;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late int _a = widget.group.photos.indexWhere((p) => p.id == widget.group.bestPhotoId).clamp(0, 99);
  late int _b = _a == 0 ? 1 : 0;
  double _split = 0.5;

  List<Photo> get _photos => widget.group.photos;

  void _pick(int i) {
    AppHaptics.selection(context);
    setState(() {
      if (i == _a) {
        _a = _b;
        _b = i;
      } else {
        _b = i;
      }
    });
  }

  void _keep(int index) {
    final keep = _photos[index].id;
    Navigator.of(context).pop(_photos.where((p) => p.id != keep).map((p) => p.id).toSet());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = _photos[_a];
    final b = _photos[_b];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compare'),
            Text('Drag the divider to compare', style: context.text.bodySmall),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    child: LayoutBuilder(
                      builder: (context, box) {
                        return GestureDetector(
                          onHorizontalDragUpdate: (d) => setState(() {
                            _split = (_split + d.delta.dx / box.maxWidth).clamp(0.05, 0.95);
                          }),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                PhotoView(photo: b, large: true),
                                ClipRect(
                                  clipper: _SplitClipper(_split),
                                  child: PhotoView(photo: a, large: true),
                                ),
                                Positioned(
                                  left: box.maxWidth * _split - 1.5,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(width: 3, color: Colors.white),
                                ),
                                Positioned(
                                  left: box.maxWidth * _split - 22,
                                  top: box.maxHeight / 2 - 22,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12),
                                      ],
                                    ),
                                    child: const Icon(Icons.compare_arrows_rounded, color: Color(0xFF15161B)),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: _Label(text: 'A', best: a.id == widget.group.bestPhotoId),
                                ),
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: _Label(text: 'B', best: b.id == widget.group.bestPhotoId),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Info(tag: 'A', photo: a),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _Info(tag: 'B', photo: b),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, i) {
                      final tag = i == _a ? 'A' : (i == _b ? 'B' : null);
                      return Pressable(
                        onTap: () => _pick(i),
                        semanticLabel: 'Photo ${i + 1}',
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          width: 52,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tag != null ? c.accent : Colors.transparent, width: 2),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PhotoView(photo: _photos[i], borderRadius: BorderRadius.circular(8)),
                              if (tag != null)
                                Center(
                                  child: CircleAvatar(
                                    radius: 11,
                                    backgroundColor: c.accent,
                                    child: Text(tag, style: context.text.labelSmall?.copyWith(color: c.onAccent)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(label: 'Keep A', onPressed: () => _keep(_a)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(label: 'Keep B', onPressed: () => _keep(_b)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('The others in this group will be selected for deletion.', style: context.text.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  _SplitClipper(this.split);

  final double split;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * split, size.height);

  @override
  bool shouldReclip(_SplitClipper old) => old.split != split;
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.best});

  final String text;
  final bool best;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: best ? context.colors.keep : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(best ? '$text · Best' : text, style: context.text.labelMedium?.copyWith(color: Colors.white)),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.tag, required this.photo});

  final String tag;
  final Photo photo;

  @override
  Widget build(BuildContext context) {
    final t = photo.takenAt;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          Text(tag, style: context.text.titleMedium?.copyWith(color: context.colors.accent)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Fmt.bytes(photo.sizeBytes), style: context.text.titleSmall),
                Text(time, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
