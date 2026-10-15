import 'package:flutter/foundation.dart';

import '../models/photo.dart';
import '../models/photo_album.dart';
import '../models/photo_category.dart';
import '../models/statistics.dart';
import '../services/photo_library_service.dart';

enum SwipeDecision { keep, delete }

/// App-wide library state: permission, overview numbers, trash, activity.
///
/// Review progress and the in-app Trash live in memory for now, so they reset
/// when the app is closed. Deleting from Trash really removes the files.
class LibraryStore extends ChangeNotifier {
  LibraryStore(this.service);

  final PhotoLibraryService service;

  LibraryAccess? _access;
  bool _loaded = false;
  Future<void>? _loading;
  Object? _loadError;
  bool _deletionRecoverable = false;

  LibraryOverview _overview = const LibraryOverview(
    totalPhotos: 0,
    reviewed: 0,
    kept: 0,
    markedForDeletion: 0,
    recoverableBytes: 0,
    recoveredBytes: 0,
  );
  List<PhotoCategory> _categories = const [];
  List<PhotoAlbum> _albums = const [];
  final Set<String> _deleted = {};
  final List<Photo> _trash = [];
  final List<ActivityEntry> _activity = [];
  final Set<String> _reviewed = {};
  InsightsStats? _baseInsights;

  // Live additions on top of the stored insights.
  int _sessions = 0;
  int _sessionMinutes = 0;
  int _reviewedCount = 0;
  int _keptCount = 0;
  int _deletedCount = 0;
  int _bytesRecovered = 0;

  /// Null until the first permission check has finished.
  LibraryAccess? get access => _access;
  bool get hasAccess => _access?.canRead ?? false;
  bool get isLoaded => _loaded;
  bool get isLoading => _loading != null;
  Object? get loadError => _loadError;
  ValueListenable<double> get scanProgress => service.scanProgress;

  /// True when deleted photos go to the phone's Recycle Bin / Recently Deleted.
  bool get deletionRecoverable => _deletionRecoverable;

  LibraryOverview get overview => _overview;
  List<PhotoCategory> get categories => _categories;
  List<PhotoAlbum> get albums => _albums;

  /// Whether the item was deleted from the device during this run.
  bool isDeleted(String id) => _deleted.contains(id);

  bool isInTrash(String id) => _trash.any((p) => p.id == id);
  List<Photo> get trash => List.unmodifiable(_trash);
  List<ActivityEntry> get activity => List.unmodifiable(_activity);

  int get trashBytes => _trash.fold(0, (sum, p) => sum + p.sizeBytes);

  PhotoCategory? category(CategoryKind kind) {
    for (final c in _categories) {
      if (c.kind == kind) return c;
    }
    return null;
  }

  /// Photos from [photos] that haven't been reviewed or marked yet.
  List<Photo> pending(List<Photo> photos) {
    final inTrash = {for (final p in _trash) p.id};
    return photos.where((p) => !_reviewed.contains(p.id) && !inTrash.contains(p.id)).toList();
  }

  // ------------------------------------------------------------ permission

  /// Reads the permission state without prompting. Reloads if it changed.
  Future<LibraryAccess> refreshAccess() async {
    final access = await service.checkAccess();
    _applyAccess(access);
    return access;
  }

  /// Shows the system prompt, then loads the library if allowed.
  Future<LibraryAccess> requestAccess() async {
    final access = await service.requestAccess();
    _applyAccess(access, force: true);
    return access;
  }

  Future<void> openSettings() => service.openSystemSettings();

  Future<void> manageLimitedAccess() async {
    await service.manageLimitedAccess();
    await reset();
  }

  void _applyAccess(LibraryAccess access, {bool force = false}) {
    final changed = access != _access;
    _access = access;
    if (changed || force) {
      if (changed && _loaded) {
        // Different set of photos is now visible: start over.
        _loaded = false;
        service.invalidate();
      }
      notifyListeners();
    }
    if (access.canRead && !_loaded) load();
  }

  // ------------------------------------------------------------------ load

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    _loadError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        service.loadOverview(),
        service.loadCategories(),
        service.loadTrash(),
        service.loadRecentActivity(),
        service.loadInsights(),
        service.deletionIsRecoverable(),
        service.loadAlbums(),
      ]);
      _overview = results[0] as LibraryOverview;
      _categories = results[1] as List<PhotoCategory>;
      _trash
        ..clear()
        ..addAll(results[2] as List<Photo>);
      _activity
        ..clear()
        ..addAll(results[3] as List<ActivityEntry>);
      _baseInsights = results[4] as InsightsStats;
      _deletionRecoverable = results[5] as bool;
      _albums = results[6] as List<PhotoAlbum>;
      _loaded = true;
    } catch (e) {
      _loadError = e;
    }
    notifyListeners();
  }

  /// Rescans the library and clears this run's review progress.
  Future<void> reset() async {
    _loaded = false;
    _reviewed.clear();
    service.invalidate();
    notifyListeners();
    await load();
  }

  // ------------------------------------------------------------- decisions

  void recordDecision(Photo photo, SwipeDecision decision) {
    _reviewed.add(photo.id);
    _reviewedCount++;
    if (decision == SwipeDecision.keep) _keptCount++;
    _overview = _overview.copyWith(
      reviewed: _overview.reviewed + 1,
      kept: decision == SwipeDecision.keep ? _overview.kept + 1 : null,
      markedForDeletion: decision == SwipeDecision.delete ? _overview.markedForDeletion + 1 : null,
    );
    if (decision == SwipeDecision.delete && !_trash.contains(photo)) {
      _trash.insert(0, photo);
    }
    notifyListeners();
  }

  void revertDecision(Photo photo, SwipeDecision decision) {
    _reviewed.remove(photo.id);
    _reviewedCount--;
    if (decision == SwipeDecision.keep) _keptCount--;
    _overview = _overview.copyWith(
      reviewed: _overview.reviewed - 1,
      kept: decision == SwipeDecision.keep ? _overview.kept - 1 : null,
      markedForDeletion: decision == SwipeDecision.delete ? _overview.markedForDeletion - 1 : null,
    );
    if (decision == SwipeDecision.delete) _trash.remove(photo);
    notifyListeners();
  }

  void markForDeletion(List<Photo> photos) {
    var added = 0;
    for (final p in photos) {
      _reviewed.add(p.id);
      if (!_trash.contains(p)) {
        _trash.insert(0, p);
        added++;
      }
    }
    _overview = _overview.copyWith(markedForDeletion: _overview.markedForDeletion + added);
    notifyListeners();
  }

  void restore(Iterable<Photo> photos) {
    final set = photos.toSet();
    final removed = _trash.where(set.contains).length;
    _trash.removeWhere(set.contains);
    _overview = _overview.copyWith(
      markedForDeletion: (_overview.markedForDeletion - removed).clamp(0, 1 << 31),
      kept: _overview.kept + removed,
    );
    notifyListeners();
  }

  /// Deletes photos from the device. The OS asks the user to confirm.
  ///
  /// Returns the photos that were actually deleted — empty if cancelled.
  Future<List<Photo>> deletePermanently(Iterable<Photo> photos) async {
    final list = photos.toList();
    final ids = await service.deletePhotos(list);
    final deleted = list.where((p) => ids.contains(p.id)).toList();
    if (deleted.isEmpty) return deleted;

    final bytes = deleted.fold<int>(0, (s, p) => s + p.sizeBytes);
    _trash.removeWhere((p) => ids.contains(p.id));
    _deleted.addAll(ids);
    try {
      // Counts & sizes changed.
      _categories = await service.loadCategories();
      _albums = await service.loadAlbums();
    } catch (_) {
      // keep the previous numbers
    }
    _deletedCount += deleted.length;
    _bytesRecovered += bytes;
    _overview = _overview.copyWith(
      totalPhotos: (_overview.totalPhotos - deleted.length).clamp(0, 1 << 31),
      markedForDeletion: (_overview.markedForDeletion - deleted.length).clamp(0, 1 << 31),
      recoveredBytes: _overview.recoveredBytes + bytes,
      recoverableBytes: (_overview.recoverableBytes - bytes).clamp(0, 1 << 62),
    );
    _activity.insert(
      0,
      ActivityEntry(
        type: ActivityType.emptied,
        date: DateTime.now(),
        title: 'Trash emptied',
        detail: '${deleted.length} ${deleted.length == 1 ? 'item' : 'items'} removed',
      ),
    );
    notifyListeners();
    return deleted;
  }

  void recordSession(SessionSummary summary) {
    if (summary.reviewed == 0) return;
    _sessions++;
    _sessionMinutes += summary.duration.inMinutes;
    _activity.insert(
      0,
      ActivityEntry(
        type: ActivityType.session,
        date: DateTime.now(),
        title: 'Swipe session',
        detail: '${summary.reviewed} reviewed · ${summary.marked} marked',
      ),
    );
    notifyListeners();
  }

  // -------------------------------------------------------------- insights

  /// Stored insights plus everything done since the app was opened.
  InsightsStats? get insights {
    final base = _baseInsights;
    if (base == null) return null;
    final monthly = List.of(base.monthly);
    if (monthly.isNotEmpty) {
      final last = monthly.removeLast();
      monthly.add(
        MonthlyActivity(
          month: last.month,
          reviewed: last.reviewed + _reviewedCount,
          deleted: last.deleted + _deletedCount,
        ),
      );
    }
    final sessions = base.sessions + _sessions;
    return InsightsStats(
      photosReviewed: base.photosReviewed + _reviewedCount,
      photosKept: base.photosKept + _keptCount,
      photosDeleted: base.photosDeleted + _deletedCount,
      bytesRecovered: base.bytesRecovered + _bytesRecovered,
      sessions: sessions,
      streakDays: base.streakDays == 0 && _sessions > 0 ? 1 : base.streakDays,
      averageSessionMinutes: base.sessions == 0 && _sessions > 0
          ? (_sessionMinutes / _sessions).ceil().clamp(1, 999)
          : base.averageSessionMinutes,
      monthly: monthly,
    );
  }
}
