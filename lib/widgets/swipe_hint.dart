import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../state/app_scope.dart';

enum SwipeHintSide { both, delete, keep }

/// "← Swipe left to delete · Swipe right to keep →" with gently nudging
/// arrows. Used in onboarding and over the first card of a session.
class SwipeHintArrows extends StatefulWidget {
  const SwipeHintArrows({super.key, this.side = SwipeHintSide.both, this.overPhoto = false});

  final SwipeHintSide side;

  /// Draw on dark pills so the labels stay readable on top of a photo.
  final bool overPhoto;

  @override
  State<SwipeHintArrows> createState() => _SwipeHintArrowsState();
}

class _SwipeHintArrowsState extends State<SwipeHintArrows> with SingleTickerProviderStateMixin {
  late final AnimationController _nudge = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep still when the user asked for less motion.
    if (SettingsScope.of(context).reduceMotion) {
      _nudge.stop();
      _nudge.value = 0;
    } else if (!_nudge.isAnimating) {
      _nudge.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showDelete = widget.side != SwipeHintSide.keep;
    final showKeep = widget.side != SwipeHintSide.delete;
    return AnimatedBuilder(
      animation: _nudge,
      builder: (context, _) {
        final dx = 8 * Curves.easeInOut.transform(_nudge.value);
        return Row(
          children: [
            if (showDelete)
              Transform.translate(
                offset: Offset(-dx, 0),
                child: _Hint(
                  icon: Icons.arrow_back_rounded,
                  label: 'SWIPE LEFT\nTO DELETE',
                  color: c.delete,
                  overPhoto: widget.overPhoto,
                  iconFirst: true,
                ),
              ),
            const Spacer(),
            if (showKeep)
              Transform.translate(
                offset: Offset(dx, 0),
                child: _Hint(
                  icon: Icons.arrow_forward_rounded,
                  label: 'SWIPE RIGHT\nTO KEEP',
                  color: c.keep,
                  overPhoto: widget.overPhoto,
                  iconFirst: false,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.icon,
    required this.label,
    required this.color,
    required this.overPhoto,
    required this.iconFirst,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool overPhoto;
  final bool iconFirst;

  @override
  Widget build(BuildContext context) {
    final arrow = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 26),
    );
    final text = Text(
      label,
      textAlign: iconFirst ? TextAlign.left : TextAlign.right,
      style: context.text.labelSmall?.copyWith(
        color: overPhoto ? Colors.white : color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        height: 1.25,
      ),
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: iconFirst
          ? [arrow, const SizedBox(width: AppSpacing.xs), text]
          : [text, const SizedBox(width: AppSpacing.xs), arrow],
    );
    if (!overPhoto) return content;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: content,
    );
  }
}
