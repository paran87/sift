import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/utils/haptics.dart';

/// Wraps a child with a subtle press-scale and optional haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                if (widget.haptic) AppHaptics.selection(context);
                widget.onTap?.call();
              }
            : null,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          child: widget.child,
        ),
      ),
    );
  }
}
