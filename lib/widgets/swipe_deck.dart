import 'dart:math';

import 'package:flutter/material.dart';

import '../core/utils/haptics.dart';
import '../models/photo.dart';
import '../state/app_scope.dart';
import '../state/library_store.dart';
import 'swipe_card.dart';

/// Lets parents trigger swipes (buttons) and return animations (undo), and
/// observe live drag progress.
class SwipeDeckController {
  _SwipeDeckState? _state;

  /// -1 (full delete) … 0 … 1 (full keep) while dragging.
  final ValueNotifier<double> dragProgress = ValueNotifier(0);

  Future<void> swipe(SwipeDecision decision) => _state?._swipe(decision) ?? Future.value();

  /// Animates the (already restored) top card back in from the side it left.
  Future<void> bringBack(SwipeDecision from) => _state?._bringBack(from) ?? Future.value();

  bool get isAnimating => _state?._busy ?? false;

  void dispose() => dragProgress.dispose();
}

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.photos,
    required this.onSwiped,
    required this.controller,
    this.threshold = 0.28,
    this.visibleCards = 3,
  });

  /// Upcoming photos; the first one is on top.
  final List<Photo> photos;
  final ValueChanged<SwipeDecision> onSwiped;
  final SwipeDeckController controller;

  /// Fraction of the card width a drag must pass to count as a swipe.
  final double threshold;
  final int visibleCards;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this);
  Animation<Offset>? _anim;
  Offset _offset = Offset.zero;
  Size _size = Size.zero;
  bool _dragging = false;
  bool _busy = false;
  bool _pastThreshold = false;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _ctrl.addListener(() {
      final a = _anim;
      if (a != null) _setOffset(a.value);
    });
  }

  @override
  void didUpdateWidget(SwipeDeck old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _ctrl.dispose();
    super.dispose();
  }

  double get _thresholdPx => max(60, _size.width * widget.threshold);

  void _setOffset(Offset o) {
    setState(() => _offset = o);
    final p = _size.width == 0 ? 0.0 : (o.dx / _thresholdPx).clamp(-1.0, 1.0);
    widget.controller.dragProgress.value = p;
  }

  Duration _motion(Duration d) => SettingsScope.read(context).motion(d);

  Future<void> _animateTo(Offset target, Duration duration, Curve curve) async {
    _anim = Tween(begin: _offset, end: target).animate(CurvedAnimation(parent: _ctrl, curve: curve));
    _ctrl.duration = _motion(duration);
    await _ctrl.forward(from: 0);
    _anim = null;
  }

  Future<void> _swipe(SwipeDecision decision, {Offset velocity = Offset.zero}) async {
    if (_busy || widget.photos.isEmpty || _size.isEmpty) return;
    _busy = true;
    final dir = decision == SwipeDecision.keep ? 1.0 : -1.0;
    final lift = _dragging ? 0.0 : -_size.height * 0.06;
    final target = Offset(dir * _size.width * 1.5, _offset.dy + lift + velocity.dy * 0.12);
    _dragging = false;
    AppHaptics.medium(context);
    await _animateTo(target, const Duration(milliseconds: 300), Curves.easeOutCubic);
    if (!mounted) return;
    widget.onSwiped(decision);
    _pastThreshold = false;
    _setOffset(Offset.zero);
    _busy = false;
  }

  Future<void> _bringBack(SwipeDecision from) async {
    if (_size.isEmpty) return;
    _ctrl.stop();
    _busy = true;
    final dir = from == SwipeDecision.keep ? 1.0 : -1.0;
    _setOffset(Offset(dir * _size.width * 1.4, -_size.height * 0.08));
    AppHaptics.light(context);
    await _animateTo(Offset.zero, const Duration(milliseconds: 520), Curves.easeOutBack);
    if (!mounted) return;
    widget.controller.dragProgress.value = 0;
    _busy = false;
  }

  void _onPanStart(DragStartDetails d) {
    if (_busy) return;
    _ctrl.stop();
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _setOffset(_offset + d.delta);
    final past = _offset.dx.abs() >= _thresholdPx;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      AppHaptics.selection(context);
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_dragging) return;
    final v = d.velocity.pixelsPerSecond;
    final flung = v.dx.abs() > 900 && v.dx.sign == _offset.dx.sign && _offset.dx.abs() > 24;
    if (_offset.dx.abs() >= _thresholdPx || flung) {
      _swipe(_offset.dx > 0 ? SwipeDecision.keep : SwipeDecision.delete, velocity: v);
    } else {
      setState(() => _dragging = false);
      _pastThreshold = false;
      _animateTo(Offset.zero, const Duration(milliseconds: 420), Curves.easeOutBack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final photos = widget.photos.take(widget.visibleCards).toList();
        final progress = (_offset.dx.abs() / _thresholdPx).clamp(0.0, 1.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = photos.length - 1; i >= 0; i--)
              i == 0 ? _buildTop(photos[0]) : _buildBehind(photos[i], i, progress),
          ],
        );
      },
    );
  }

  Widget _buildBehind(Photo photo, int depth, double progress) {
    // Cards behind move up one slot as the top card is dragged away.
    final d = depth - progress;
    return Positioned.fill(
      key: ValueKey(photo.id),
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(0, 14.0 * d),
          child: Transform.scale(
            scale: 1 - 0.05 * d,
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: (1 - 0.25 * (d - 1)).clamp(0.0, 1.0),
              child: SwipePhotoCard(photo: photo, showDetails: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTop(Photo photo) {
    final w = _size.width == 0 ? 1 : _size.width;
    final angle = (_offset.dx / w) * 0.32;
    final amount = _offset.dx / _thresholdPx;
    return Positioned.fill(
      key: ValueKey(photo.id),
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.translate(
          offset: _offset,
          child: Transform.rotate(
            angle: angle,
            origin: Offset(0, _size.height * 0.4),
            child: AnimatedScale(
              scale: _dragging ? 1.02 : 1,
              duration: const Duration(milliseconds: 180),
              child: Semantics(
                label: 'Photo from ${photo.origin ?? 'your library'}. Swipe right to keep, left to delete.',
                child: SwipePhotoCard(
                  photo: photo,
                  keepAmount: amount > 0 ? amount : 0,
                  deleteAmount: amount < 0 ? -amount : 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
