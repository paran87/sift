import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/photo_category.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_style.dart';
import '../../widgets/progress_widgets.dart';

/// Library-wide cleaning progress.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LibraryScope.of(context);
    final o = store.overview;
    final c = context.colors;
    final percent = (o.progress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaning progress')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xxl),
            children: [
              Center(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = (box.maxWidth * 0.62).clamp(180.0, 260.0);
                    return ProgressRing(
                      value: o.progress,
                      size: size,
                      stroke: 16,
                      duration: const Duration(milliseconds: 1600),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountUpText(
                            value: o.reviewed,
                            style: context.text.displaySmall,
                            duration: const Duration(milliseconds: 1600),
                          ),
                          Text('of ${Fmt.number(o.totalPhotos)} reviewed', style: context.text.bodyMedium),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                percent >= 100 ? 'Your library is spotless ✨' : 'Your library is $percent% clean',
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${Fmt.number(o.remaining)} photos left · about ${(o.remaining / 90).ceil()} min of swiping',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.6,
                children: [
                  _Metric(icon: Icons.check_rounded, color: c.keep, label: 'Kept', value: Fmt.number(o.kept)),
                  _Metric(
                    icon: Icons.close_rounded,
                    color: c.delete,
                    label: 'Marked',
                    value: Fmt.number(o.markedForDeletion),
                  ),
                  _Metric(
                    icon: Icons.cloud_queue_rounded,
                    color: c.accent,
                    label: 'Potential',
                    value: Fmt.bytes(o.recoverableBytes),
                  ),
                  _Metric(
                    icon: Icons.cloud_done_rounded,
                    color: c.warning,
                    label: 'Recovered',
                    value: Fmt.bytes(o.recoveredBytes),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(title: 'By category'),
              AppCard(
                child: Column(
                  children: [
                    for (final cat in store.categories.where((c) => c.kind != CategoryKind.all))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(cat.kind.icon, color: cat.kind.color(context), size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(width: 104, child: Text(cat.title, style: context.text.bodyMedium, maxLines: 1)),
                            Expanded(
                              child: ProgressBar(value: cat.progress, color: cat.kind.color(context)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${(cat.progress * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: context.text.labelMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Continue Cleaning',
                icon: Icons.swipe_rounded,
                onPressed: () => AppRouter.toCleaning(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary)),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.headlineSmall),
          ),
        ],
      ),
    );
  }
}
