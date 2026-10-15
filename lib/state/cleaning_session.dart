import 'package:flutter/foundation.dart';

import '../models/photo.dart';
import '../models/statistics.dart';
import 'library_store.dart';

typedef Decision = ({Photo photo, SwipeDecision decision});

/// State for one swipe session. Lives only as long as the swipe screen.
class CleaningSession extends ChangeNotifier {
  CleaningSession({required this.photos, required this.store, this.maxUndo = 10}) : _startedAt = DateTime.now();

  final List<Photo> photos;
  final LibraryStore store;
  final int maxUndo;
  final DateTime _startedAt;

  int _index = 0;
  int _kept = 0;
  int _marked = 0;
  int _markedBytes = 0;
  final List<Decision> _history = [];

  int get index => _index;
  int get total => photos.length;
  int get kept => _kept;
  int get marked => _marked;
  int get markedBytes => _markedBytes;
  bool get isFinished => _index >= photos.length;
  bool get canUndo => _history.isNotEmpty;
  double get progress => total == 0 ? 1 : _index / total;
  Photo? get current => isFinished ? null : photos[_index];

  /// Upcoming photos, including the current one.
  List<Photo> upcoming(int count) => photos.sublist(_index, (_index + count).clamp(0, photos.length));

  void decide(SwipeDecision decision) {
    final photo = current;
    if (photo == null) return;
    _history.add((photo: photo, decision: decision));
    if (_history.length > maxUndo) _history.removeAt(0);
    if (decision == SwipeDecision.keep) {
      _kept++;
    } else {
      _marked++;
      _markedBytes += photo.sizeBytes;
    }
    _index++;
    store.recordDecision(photo, decision);
    notifyListeners();
  }

  /// Reverts the last decision and returns it (for the return animation).
  Decision? undo() {
    if (_history.isEmpty) return null;
    final last = _history.removeLast();
    if (last.decision == SwipeDecision.keep) {
      _kept--;
    } else {
      _marked--;
      _markedBytes -= last.photo.sizeBytes;
    }
    _index--;
    store.revertDecision(last.photo, last.decision);
    notifyListeners();
    return last;
  }

  SessionSummary summary() => SessionSummary(
    reviewed: _kept + _marked,
    kept: _kept,
    marked: _marked,
    markedBytes: _markedBytes,
    duration: DateTime.now().difference(_startedAt),
  );
}
