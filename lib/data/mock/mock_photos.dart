import 'dart:math';

import '../../models/duplicate_group.dart';
import '../../models/photo.dart';
import '../../models/photo_category.dart';

/// Deterministic mock photo library. Replace with a MediaStore-backed
/// implementation of `PhotoLibraryService` in the functionality phase.
abstract final class MockPhotos {
  static const int _mb = 1024 * 1024;

  static final DateTime _now = DateTime.now();

  static const _locations = <String?>[
    'Lisbon, Portugal',
    'Kyoto, Japan',
    'Big Sur, California',
    'Reykjavík, Iceland',
    'Home',
    null,
    'Cape Town, South Africa',
    'Palawan, Philippines',
    null,
    'Banff, Canada',
  ];

  static const _photoScenes = [
    ArtScene.sunset,
    ArtScene.mountains,
    ArtScene.ocean,
    ArtScene.city,
    ArtScene.forest,
    ArtScene.desert,
    ArtScene.aurora,
    ArtScene.food,
  ];

  /// The full mock library, newest first.
  static final List<Photo> library = _generate(64);

  static List<Photo> _generate(int count) {
    final rnd = Random(42);
    final photos = <Photo>[];
    for (var i = 0; i < count; i++) {
      final roll = rnd.nextDouble();
      final MediaType type;
      final ArtScene scene;
      final int size;
      Duration? videoDuration;

      if (roll < 0.18) {
        type = MediaType.screenshot;
        scene = rnd.nextBool() ? ArtScene.screenshot : ArtScene.document;
        size = (0.3 * _mb + rnd.nextDouble() * 1.4 * _mb).round();
      } else if (roll < 0.30) {
        type = MediaType.video;
        scene = _photoScenes[rnd.nextInt(_photoScenes.length)];
        final seconds = 6 + rnd.nextInt(170);
        videoDuration = Duration(seconds: seconds);
        size = (seconds * 0.9 * _mb).round();
      } else {
        type = MediaType.photo;
        scene = _photoScenes[rnd.nextInt(_photoScenes.length)];
        size = (1.8 * _mb + rnd.nextDouble() * 4.6 * _mb).round();
      }

      photos.add(
        Photo(
          id: 'p$i',
          takenAt: _now.subtract(Duration(days: i * 9 + rnd.nextInt(8), hours: rnd.nextInt(20))),
          sizeBytes: size,
          type: type,
          art: PhotoArt(scene, 1000 + i * 37),
          location: type == MediaType.screenshot ? null : _locations[rnd.nextInt(_locations.length)],
          videoDuration: videoDuration,
          width: type == MediaType.screenshot ? 1080 : 3024,
          height: type == MediaType.screenshot ? 2400 : 4032,
        ),
      );
    }
    return photos;
  }

  /// Photos queued for a swipe session in the given category.
  static List<Photo> queueFor(CategoryKind kind) {
    final List<Photo> list = switch (kind) {
      CategoryKind.screenshots => library.where((p) => p.isScreenshot).toList(),
      CategoryKind.videos => library.where((p) => p.isVideo).toList(),
      CategoryKind.largeFiles =>
        (library.toList()..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes))).take(14).toList(),
      CategoryKind.oldPhotos => library.reversed.take(16).toList(),
      _ => library.skip(8).take(24).toList(),
    };
    return list;
  }

  /// Photos already sitting in the trash when the prototype starts.
  static List<Photo> get initialTrash => library.take(8).toList();

  /// Hand-picked photos for onboarding illustrations.
  static List<Photo> get showcase {
    Photo pick(ArtScene scene, int fallback) =>
        library.firstWhere((p) => p.art?.scene == scene && !p.isVideo, orElse: () => library[fallback]);
    return [
      pick(ArtScene.sunset, 0),
      pick(ArtScene.mountains, 1),
      pick(ArtScene.ocean, 2),
      pick(ArtScene.city, 3),
      pick(ArtScene.screenshot, 4),
    ];
  }

  static List<Photo> previewsFor(CategoryKind kind) => queueFor(kind).take(3).toList();

  /// Groups of near-identical shots.
  static final List<DuplicateGroup> duplicateGroups = _groups(GroupKind.duplicate);
  static final List<DuplicateGroup> similarGroups = _groups(GroupKind.similar);

  static List<DuplicateGroup> _groups(GroupKind kind) {
    final rnd = Random(kind == GroupKind.duplicate ? 7 : 11);
    const scenes = [ArtScene.sunset, ArtScene.mountains, ArtScene.ocean, ArtScene.city, ArtScene.food, ArtScene.aurora];
    const labels = ['Golden hour, Lisbon', 'Moraine Lake', 'Beach day', 'City lights', 'Brunch', 'Northern lights'];
    final groups = <DuplicateGroup>[];
    for (var g = 0; g < scenes.length; g++) {
      final n = kind == GroupKind.duplicate ? 2 + rnd.nextInt(2) : 3 + rnd.nextInt(3);
      final base = _now.subtract(Duration(days: 3 + g * 17, hours: rnd.nextInt(10)));
      final seed = 5000 + g * 91 + (kind == GroupKind.similar ? 400 : 0);
      final photos = List.generate(n, (i) {
        return Photo(
          id: '${kind.name}_${g}_$i',
          takenAt: base.add(Duration(seconds: i * (kind == GroupKind.duplicate ? 0 : 2))),
          sizeBytes: (2.4 * _mb + rnd.nextDouble() * 3.2 * _mb).round(),
          art: PhotoArt(scenes[g], seed, variant: kind == GroupKind.duplicate ? 0 : i * 0.18),
          location: _locations[g % _locations.length],
        );
      });
      final best = photos[rnd.nextInt(photos.length)];
      groups.add(
        DuplicateGroup(id: '${kind.name}_$g', kind: kind, photos: photos, bestPhotoId: best.id, label: labels[g]),
      );
    }
    return groups;
  }
}
