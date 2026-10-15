import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/photo_category.dart';

/// Visual identity (icon + color) for each category.
extension CategoryStyle on CategoryKind {
  IconData get icon => switch (this) {
    CategoryKind.all => Icons.photo_library_rounded,
    CategoryKind.screenshots => Icons.screenshot_rounded,
    CategoryKind.videos => Icons.videocam_rounded,
    CategoryKind.largeFiles => Icons.sd_storage_rounded,
    CategoryKind.duplicates => Icons.content_copy_rounded,
    CategoryKind.similar => Icons.burst_mode_rounded,
    CategoryKind.oldPhotos => Icons.history_rounded,
  };

  Color color(BuildContext context) {
    final dark = context.isDark;
    return switch (this) {
      CategoryKind.all => context.colors.accent,
      CategoryKind.screenshots => dark ? const Color(0xFF5CC8FF) : const Color(0xFF0B8BD6),
      CategoryKind.videos => dark ? const Color(0xFFFF7AB6) : const Color(0xFFE0457F),
      CategoryKind.largeFiles => context.colors.warning,
      CategoryKind.duplicates => dark ? const Color(0xFFB794FF) : const Color(0xFF7C4DDB),
      CategoryKind.similar => context.colors.keep,
      CategoryKind.oldPhotos => dark ? const Color(0xFFFF9D6B) : const Color(0xFFDB6A2E),
    };
  }
}
