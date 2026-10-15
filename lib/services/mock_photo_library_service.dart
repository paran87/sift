import 'package:flutter/foundation.dart';

import '../data/mock/mock_categories.dart';
import '../data/mock/mock_photos.dart';
import '../data/mock/mock_statistics.dart';
import '../models/duplicate_group.dart';
import '../models/photo.dart';
import '../models/photo_album.dart';
import '../models/photo_category.dart';
import '../models/statistics.dart';
import 'photo_library_service.dart';

/// In-memory sample library for tests and design work. Adds small delays so
/// loading states are exercised.
class MockPhotoLibraryService implements PhotoLibraryService {
  MockPhotoLibraryService({this.latency = const Duration(milliseconds: 450)});

  final Duration latency;
  final ValueNotifier<double> _progress = ValueNotifier(1);

  Future<T> _delay<T>(T value) => Future.delayed(latency, () => value);

  @override
  Future<LibraryAccess> checkAccess() async => LibraryAccess.granted;

  @override
  Future<LibraryAccess> requestAccess() async => LibraryAccess.granted;

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<void> manageLimitedAccess() async {}

  @override
  ValueListenable<double> get scanProgress => _progress;

  @override
  void invalidate() {}

  @override
  Future<LibraryOverview> loadOverview() => _delay(MockStatistics.overview);

  @override
  Future<List<PhotoCategory>> loadCategories() => _delay(MockCategories.all);

  @override
  Future<List<Photo>> loadReviewQueue(CategoryKind category) => _delay(MockPhotos.queueFor(category));

  @override
  Future<List<DuplicateGroup>> loadGroups(GroupKind kind) =>
      _delay(kind == GroupKind.duplicate ? MockPhotos.duplicateGroups : MockPhotos.similarGroups);

  static final Map<String, (String, bool Function(Photo))> _albums = {
    'm_camera': ('Camera', (p) => p.type == MediaType.photo),
    'm_screens': ('Screenshots', (p) => p.isScreenshot),
    'm_videos': ('Videos', (p) => p.isVideo),
    'm_travel': ('Travel', (p) => p.location != null && p.location != 'Home' && !p.isScreenshot),
  };

  @override
  Future<List<PhotoAlbum>> loadAlbums() {
    final albums = [
      for (final MapEntry(key: id, value: (name, test)) in _albums.entries)
        if (MockPhotos.library.where(test).toList() case final items when items.isNotEmpty)
          PhotoAlbum(id: id, name: name, count: items.length, cover: items.first),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return _delay(albums);
  }

  @override
  Future<List<Photo>> loadAlbumPhotos(String albumId) {
    final test = _albums[albumId]?.$2;
    return _delay(test == null ? const <Photo>[] : MockPhotos.library.where(test).toList());
  }

  @override
  Future<List<Photo>> loadTrash() => _delay(MockPhotos.initialTrash);

  @override
  Future<InsightsStats> loadInsights() => _delay(MockStatistics.insights);

  @override
  Future<List<ActivityEntry>> loadRecentActivity() => _delay(MockStatistics.recentActivity);

  @override
  Future<bool> deletionIsRecoverable() async => false;

  @override
  Future<Set<String>> deletePhotos(List<Photo> photos) =>
      Future.delayed(const Duration(milliseconds: 1800), () => photos.map((p) => p.id).toSet());
}
