import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../core/utils/formatters.dart';
import '../models/duplicate_group.dart';
import '../models/photo.dart';
import '../models/photo_album.dart';
import '../models/photo_category.dart';
import '../models/statistics.dart';
import 'photo_library_service.dart';

/// Reads the real photo & video library on the device via `photo_manager`.
///
/// Everything stays on the phone: nothing is uploaded or sent anywhere.
class DevicePhotoLibraryService implements PhotoLibraryService {
  DevicePhotoLibraryService({this.scanLimit = 3000});

  /// Newest items analysed for categories and duplicates. Keeps the first
  /// scan fast on very large libraries; the total count is always exact.
  final int scanLimit;

  static const int _largeFileBytes = 25 * 1024 * 1024;
  static const Duration _oldAge = Duration(days: 730);
  static const Duration _burstGap = Duration(seconds: 3);
  static const int _previewLongSide = 1440;
  static const ThumbnailSize _gridThumb = ThumbnailSize.square(320);

  final ValueNotifier<double> _progress = ValueNotifier(0);
  Future<_Scan>? _scan;
  final Map<String, AssetPathEntity> _albumPaths = {};
  int? _sdkInt;

  // ------------------------------------------------------------ permission

  static LibraryAccess _map(PermissionState s) => switch (s) {
    PermissionState.authorized => LibraryAccess.granted,
    PermissionState.limited => LibraryAccess.limited,
    _ => LibraryAccess.denied,
  };

  @override
  Future<LibraryAccess> checkAccess() async =>
      _map(await PhotoManager.getPermissionState(requestOption: const PermissionRequestOption()));

  @override
  Future<LibraryAccess> requestAccess() async {
    final access = _map(await PhotoManager.requestPermissionExtend());
    invalidate();
    return access;
  }

  @override
  Future<void> openSystemSettings() => PhotoManager.openSetting();

  @override
  Future<void> manageLimitedAccess() async {
    if (Platform.isIOS) {
      await PhotoManager.presentLimited();
    } else {
      // On Android 14+, asking again re-opens the system photo picker.
      await PhotoManager.requestPermissionExtend();
    }
    invalidate();
  }

  // ------------------------------------------------------------------ scan

  @override
  ValueListenable<double> get scanProgress => _progress;

  @override
  void invalidate() {
    _scan = null;
    _albumPaths.clear();
    _progress.value = 0;
  }

  Future<_Scan> _library() => _scan ??= _runScan().catchError((Object e) {
    _scan = null; // let the next call retry
    throw e;
  });

  Future<_Scan> _runScan() async {
    _progress.value = 0;
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
      filterOption: _newestFirst(),
    );
    if (paths.isEmpty) {
      _progress.value = 1;
      return _Scan.empty();
    }

    final root = paths.first;
    final total = await root.assetCountAsync;
    final count = min(total, scanLimit);

    // 1. Metadata (cheap), newest first.
    final entities = <AssetEntity>[];
    const page = 250;
    for (var start = 0; start < count; start += page) {
      entities.addAll(await root.getAssetListRange(start: start, end: min(start + page, count)));
      _progress.value = 0.25 * entities.length / max(count, 1);
    }

    // 2. Real file sizes, in parallel batches.
    final sizes = List<int>.filled(entities.length, 0);
    const batch = 40;
    for (var i = 0; i < entities.length; i += batch) {
      final end = min(i + batch, entities.length);
      final chunk = await Future.wait([for (var j = i; j < end; j++) _fileSize(entities[j])]);
      sizes.setRange(i, end, chunk);
      _progress.value = 0.25 + 0.75 * end / entities.length;
    }

    final byId = <String, AssetEntity>{};
    final photos = <Photo>[];
    for (var i = 0; i < entities.length; i++) {
      byId[entities[i].id] = entities[i];
      photos.add(_toPhoto(entities[i], sizes[i]));
    }

    final duplicates = _findDuplicates(photos);
    final inDuplicates = {for (final g in duplicates) ...g.photos.map((p) => p.id)};
    final similar = await _findSimilar(photos, byId, exclude: inDuplicates);

    _progress.value = 1;
    return _Scan(total: total, photos: photos, entities: byId, duplicates: duplicates, similar: similar);
  }

  static FilterOptionGroup _newestFirst() =>
      FilterOptionGroup(orders: const [OrderOption(type: OrderOptionType.createDate, asc: false)]);

  Future<int> _fileSize(AssetEntity e) async {
    try {
      return await e.fileSize;
    } catch (_) {
      return 0; // cloud-only or unreadable item; still reviewable
    }
  }

  Photo _toPhoto(AssetEntity e, int size) {
    final isVideo = e.type == AssetType.video;
    return Photo(
      id: e.id,
      takenAt: e.createDateTime,
      sizeBytes: size,
      type: isVideo
          ? MediaType.video
          : _isScreenshot(e)
          ? MediaType.screenshot
          : MediaType.photo,
      album: _album(e),
      videoDuration: isVideo ? e.videoDuration : null,
      width: e.orientatedWidth,
      height: e.orientatedHeight,
      image: AssetEntityImageProvider(e, isOriginal: false, thumbnailSize: _previewSize(e)),
      thumbnail: AssetEntityImageProvider(e, isOriginal: false, thumbnailSize: _gridThumb),
    );
  }

  static bool _isScreenshot(AssetEntity e) {
    final path = (e.relativePath ?? '').toLowerCase();
    final title = (e.title ?? '').toLowerCase();
    // iOS marks screenshots with PHAssetMediaSubtype.photoScreenshot (1 << 2).
    final iosScreenshot = Platform.isIOS && (e.subtype & 4) != 0;
    return path.contains('screenshot') || title.startsWith('screenshot') || iosScreenshot;
  }

  /// "DCIM/Camera/" → "Camera".
  static String? _album(AssetEntity e) {
    final parts = (e.relativePath ?? '').split('/').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.last;
  }

  static ThumbnailSize _previewSize(AssetEntity e) {
    final w = e.orientatedWidth;
    final h = e.orientatedHeight;
    if (w <= 0 || h <= 0) return const ThumbnailSize(1080, 1440);
    final scale = min(1.0, _previewLongSide / max(w, h));
    return ThumbnailSize(max(1, (w * scale).round()), max(1, (h * scale).round()));
  }

  // ------------------------------------------------------------- grouping

  /// Exact copies: same type, byte size and dimensions. Keeps the oldest.
  static List<DuplicateGroup> _findDuplicates(List<Photo> photos) {
    final buckets = <String, List<Photo>>{};
    for (final p in photos) {
      if (p.sizeBytes <= 0) continue;
      buckets.putIfAbsent('${p.type.name}|${p.sizeBytes}|${p.width}x${p.height}', () => []).add(p);
    }
    final groups = <DuplicateGroup>[];
    for (final list in buckets.values.where((l) => l.length > 1)) {
      list.sort((a, b) => a.takenAt.compareTo(b.takenAt));
      groups.add(
        DuplicateGroup(
          id: 'dup_${list.first.id}',
          kind: GroupKind.duplicate,
          photos: list,
          bestPhotoId: list.first.id,
          label: _groupLabel(list.first),
        ),
      );
    }
    groups.sort((a, b) => b.photos.first.takenAt.compareTo(a.photos.first.takenAt));
    return groups;
  }

  /// Burst shots: taken seconds apart, same size and album, AND visually
  /// alike (compared with a tiny image fingerprint). Suggests keeping the
  /// largest file, which is usually the most detailed.
  Future<List<DuplicateGroup>> _findSimilar(
    List<Photo> photos,
    Map<String, AssetEntity> entities, {
    required Set<String> exclude,
  }) async {
    final candidates = photos.where((p) => p.type == MediaType.photo && !exclude.contains(p.id)).toList()
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));

    // 1. Cheap pass: runs of photos close in time with matching size & album.
    final runs = <List<Photo>>[];
    var run = <Photo>[];
    bool fits(Photo a, Photo b) =>
        b.takenAt.difference(a.takenAt) <= _burstGap &&
        a.width == b.width &&
        a.height == b.height &&
        a.album == b.album;
    for (final p in candidates) {
      if (run.isNotEmpty && !fits(run.last, p)) {
        if (run.length > 1) runs.add(run);
        run = [];
      }
      run.add(p);
    }
    if (run.length > 1) runs.add(run);

    // 2. Visual pass: split each run where neighbouring shots stop looking alike.
    final groups = <DuplicateGroup>[];
    void addGroup(List<Photo> list) {
      if (list.length < 2) return;
      final best = list.reduce((a, b) => b.sizeBytes > a.sizeBytes ? b : a);
      groups.add(
        DuplicateGroup(
          id: 'sim_${list.first.id}',
          kind: GroupKind.similar,
          photos: List.of(list),
          bestPhotoId: best.id,
          label: _groupLabel(list.first),
        ),
      );
    }

    for (final r in runs) {
      final hashes = await Future.wait([for (final p in r) _fingerprint(entities[p.id])]);
      var cluster = <Photo>[];
      _Fingerprint? anchor;
      for (var i = 0; i < r.length; i++) {
        final h = hashes[i];
        if (h == null) continue;
        if (anchor != null && !anchor.looksLike(h)) {
          addGroup(cluster);
          cluster = [];
          anchor = null;
        }
        anchor ??= h;
        cluster.add(r[i]);
      }
      addGroup(cluster);
    }
    return groups.reversed.toList(); // newest bursts first
  }

  /// Layout + colour fingerprint of a photo, from an 8×8 thumbnail.
  static Future<_Fingerprint?> _fingerprint(AssetEntity? e) async {
    if (e == null) return null;
    try {
      final bytes = await e.thumbnailDataWithSize(const ThumbnailSize.square(64), format: ThumbnailFormat.png);
      if (bytes == null) return null;
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 8, targetHeight: 8);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      frame.image.dispose();
      codec.dispose();
      if (data == null) return null;
      var r = 0, g = 0, b = 0;
      final grey = List<int>.generate(64, (i) {
        final o = i * 4;
        final pr = data.getUint8(o), pg = data.getUint8(o + 1), pb = data.getUint8(o + 2);
        r += pr;
        g += pg;
        b += pb;
        return (pr * 299 + pg * 587 + pb * 114) ~/ 1000;
      });
      final mean = grey.reduce((a, b) => a + b) / 64;
      var hash = 0;
      for (var i = 0; i < 64; i++) {
        if (grey[i] > mean) hash |= 1 << i;
      }
      return _Fingerprint(hash, r ~/ 64, g ~/ 64, b ~/ 64);
    } catch (_) {
      return null;
    }
  }

  static String _groupLabel(Photo p) {
    final t = p.takenAt;
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final time = '$hour:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
    return '${Fmt.date(t)}, $time';
  }

  // ------------------------------------------------------------- queries

  static int _sum(Iterable<Photo> photos) => photos.fold(0, (s, p) => s + p.sizeBytes);

  static Iterable<Photo> _extras(List<DuplicateGroup> groups) =>
      groups.expand((g) => g.photos.where((p) => p.id != g.bestPhotoId));

  List<Photo> _queue(_Scan s, CategoryKind kind) {
    final now = DateTime.now();
    return switch (kind) {
      CategoryKind.all => List.of(s.photos),
      CategoryKind.screenshots => s.photos.where((p) => p.isScreenshot).toList(),
      CategoryKind.videos => s.photos.where((p) => p.isVideo).toList(),
      CategoryKind.largeFiles =>
        s.photos.where((p) => p.sizeBytes >= _largeFileBytes).toList()
          ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes)),
      CategoryKind.oldPhotos =>
        s.photos.where((p) => now.difference(p.takenAt) > _oldAge).toList()
          ..sort((a, b) => a.takenAt.compareTo(b.takenAt)),
      CategoryKind.duplicates => s.duplicates.expand((g) => g.photos).toList(),
      CategoryKind.similar => s.similar.expand((g) => g.photos).toList(),
    };
  }

  @override
  Future<LibraryOverview> loadOverview() async {
    final s = await _library();
    // Estimate: screenshots plus the extra copies in duplicate/similar groups.
    final candidates = <String, Photo>{
      for (final p in s.photos.where((p) => p.isScreenshot)) p.id: p,
      for (final p in _extras(s.duplicates)) p.id: p,
      for (final p in _extras(s.similar)) p.id: p,
    };
    return LibraryOverview(
      totalPhotos: s.total,
      reviewed: 0,
      kept: 0,
      markedForDeletion: 0,
      recoverableBytes: _sum(candidates.values),
      recoveredBytes: 0,
    );
  }

  @override
  Future<List<PhotoCategory>> loadCategories() async {
    final s = await _library();
    PhotoCategory cat(CategoryKind kind, String title, String description) {
      final items = _queue(s, kind);
      final grouped = kind == CategoryKind.duplicates || kind == CategoryKind.similar;
      final groups = kind == CategoryKind.duplicates ? s.duplicates : s.similar;
      return PhotoCategory(
        kind: kind,
        title: title,
        description: description,
        count: kind == CategoryKind.all ? s.total : items.length,
        sizeBytes: grouped ? _sum(_extras(groups)) : _sum(items),
        previews: grouped ? (groups.isEmpty ? const [] : groups.first.photos) : items.take(3).toList(),
      );
    }

    return [
      cat(CategoryKind.all, 'All Photos', 'Everything in your library'),
      cat(CategoryKind.screenshots, 'Screenshots', 'Usually safe to clear'),
      cat(CategoryKind.videos, 'Videos', 'Biggest space savers'),
      cat(CategoryKind.largeFiles, 'Large Files', 'Over 25 MB each'),
      cat(CategoryKind.duplicates, 'Duplicates', 'Exact copies'),
      cat(CategoryKind.similar, 'Similar Photos', 'Bursts & near-identical shots'),
      cat(CategoryKind.oldPhotos, 'Old Photos', 'Taken over 2 years ago'),
    ];
  }

  @override
  Future<List<Photo>> loadReviewQueue(CategoryKind category) async => _queue(await _library(), category);

  @override
  Future<List<DuplicateGroup>> loadGroups(GroupKind kind) async {
    final s = await _library();
    return List.of(kind == GroupKind.duplicate ? s.duplicates : s.similar);
  }

  // ---------------------------------------------------------------- albums

  @override
  Future<List<PhotoAlbum>> loadAlbums() async {
    final s = await _library();
    final paths = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: RequestType.common,
      filterOption: _newestFirst(),
    );
    _albumPaths
      ..clear()
      ..addAll({for (final p in paths) p.id: p});

    final albums = await Future.wait(
      paths.map((p) async {
        final count = await p.assetCountAsync;
        if (count == 0) return null;
        // Android orders albums by when files were added; for the cover,
        // pick the most recently *taken* among the latest few.
        final recent = await p.getAssetListRange(start: 0, end: min(count, 30));
        final newest = recent.isEmpty
            ? null
            : recent.reduce((a, b) => b.createDateTime.isAfter(a.createDateTime) ? b : a);
        final cover = newest == null ? null : (s.known[newest.id] ?? _toPhoto(newest, 0));
        return PhotoAlbum(id: p.id, name: p.name, count: count, cover: cover);
      }),
    );
    return albums.whereType<PhotoAlbum>().toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  @override
  Future<List<Photo>> loadAlbumPhotos(String albumId) async {
    final s = await _library();
    if (!_albumPaths.containsKey(albumId)) await loadAlbums();
    final path = _albumPaths[albumId];
    if (path == null) return const [];

    final count = min(await path.assetCountAsync, scanLimit);
    final entities = <AssetEntity>[];
    for (var start = 0; start < count; start += 250) {
      entities.addAll(await path.getAssetListRange(start: start, end: min(start + 250, count)));
    }

    // Items older than the main scan still need their real file size.
    final unknown = entities.where((e) => !s.known.containsKey(e.id)).toList();
    for (var i = 0; i < unknown.length; i += 40) {
      final chunk = unknown.sublist(i, min(i + 40, unknown.length));
      final sizes = await Future.wait(chunk.map(_fileSize));
      for (var j = 0; j < chunk.length; j++) {
        s.known[chunk[j].id] = _toPhoto(chunk[j], sizes[j]);
        s.entities[chunk[j].id] = chunk[j]; // so they can be deleted too
      }
    }
    return [for (final e in entities) s.known[e.id]!];
  }

  /// The in-app Trash starts empty; it only holds photos marked this session.
  @override
  Future<List<Photo>> loadTrash() async => const [];

  /// History isn't stored on the device yet, so insights start at zero and
  /// grow as you clean (see LibraryStore).
  @override
  Future<InsightsStats> loadInsights() async {
    final now = DateTime.now();
    return InsightsStats(
      photosReviewed: 0,
      photosKept: 0,
      photosDeleted: 0,
      bytesRecovered: 0,
      sessions: 0,
      streakDays: 0,
      averageSessionMinutes: 0,
      monthly: List.generate(
        6,
        (i) => MonthlyActivity(month: DateTime(now.year, now.month - 5 + i), reviewed: 0, deleted: 0),
      ),
    );
  }

  @override
  Future<List<ActivityEntry>> loadRecentActivity() async => const [];

  // --------------------------------------------------------------- delete

  Future<int> _sdk() async => _sdkInt ??= int.tryParse(await PhotoManager.systemVersion()) ?? 0;

  @override
  Future<bool> deletionIsRecoverable() async {
    if (Platform.isIOS) return true; // goes to "Recently Deleted"
    if (Platform.isAndroid) return await _sdk() >= 30; // system trash
    return false;
  }

  @override
  Future<Set<String>> deletePhotos(List<Photo> photos) async {
    final s = await _library();
    final entities = [for (final p in photos) ?s.entities[p.id]];
    if (entities.isEmpty) return {};

    final List<String> done;
    if (Platform.isAndroid && await _sdk() >= 30) {
      // Android 11+: move to the system Recycle Bin (restorable for ~30 days).
      done = await PhotoManager.editor.android.moveToTrash(entities);
    } else {
      done = await PhotoManager.editor.deleteWithIds(entities.map((e) => e.id).toList());
    }

    final removed = done.toSet();
    s.remove(removed);
    return removed;
  }
}

class _Scan {
  _Scan({
    required this.total,
    required this.photos,
    required this.entities,
    required this.duplicates,
    required this.similar,
  });

  factory _Scan.empty() => _Scan(total: 0, photos: [], entities: {}, duplicates: [], similar: []);

  int total;
  final List<Photo> photos;

  /// Every photo seen so far (main scan plus opened albums), by id.
  late final Map<String, Photo> known = {for (final p in photos) p.id: p};
  final Map<String, AssetEntity> entities;
  final List<DuplicateGroup> duplicates;
  final List<DuplicateGroup> similar;

  /// Keeps cached results in step after a delete, without a full rescan.
  void remove(Set<String> ids) {
    if (ids.isEmpty) return;
    final before = photos.length;
    photos.removeWhere((p) => ids.contains(p.id));
    total = max(0, total - (before - photos.length));
    ids.forEach(entities.remove);
    ids.forEach(known.remove);
    List<DuplicateGroup> prune(List<DuplicateGroup> groups) => [
      for (final g in groups)
        if (g.photos.where((p) => !ids.contains(p.id)).length > 1)
          DuplicateGroup(
            id: g.id,
            kind: g.kind,
            photos: g.photos.where((p) => !ids.contains(p.id)).toList(),
            bestPhotoId: ids.contains(g.bestPhotoId)
                ? g.photos.firstWhere((p) => !ids.contains(p.id)).id
                : g.bestPhotoId,
            label: g.label,
          ),
    ];
    final d = prune(duplicates), sim = prune(similar);
    duplicates
      ..clear()
      ..addAll(d);
    similar
      ..clear()
      ..addAll(sim);
  }
}

/// "Average hash" of an 8×8 grey thumbnail (1 bit per pixel: brighter or
/// darker than the mean) plus the average colour. Shots of the same scene
/// match on both; different scenes with a similar layout differ in colour.
class _Fingerprint {
  const _Fingerprint(this.hash, this.r, this.g, this.b);

  final int hash;
  final int r;
  final int g;
  final int b;

  /// Bits (out of 64) the layouts may differ by.
  static const int _maxBits = 10;

  /// How far the average colour may drift per channel (0–255).
  static const int _maxColour = 18;

  bool looksLike(_Fingerprint o) =>
      _bits(hash ^ o.hash) <= _maxBits &&
      (r - o.r).abs() <= _maxColour &&
      (g - o.g).abs() <= _maxColour &&
      (b - o.b).abs() <= _maxColour;

  static int _bits(int x) {
    var n = 0;
    while (x != 0) {
      x &= x - 1;
      n++;
    }
    return n;
  }
}
