import 'package:flutter/painting.dart';

enum MediaType { photo, video, screenshot }

/// Visual recipe for a generated placeholder image (mock-only).
///
/// Real device photos leave this null and set [Photo.image] instead.
enum ArtScene { sunset, mountains, ocean, city, forest, desert, aurora, food, screenshot, document }

class PhotoArt {
  const PhotoArt(this.scene, this.seed, {this.variant = 0});

  final ArtScene scene;
  final int seed;

  /// Small variation used to render near-identical "similar" shots.
  final double variant;
}

class Photo {
  const Photo({
    required this.id,
    required this.takenAt,
    required this.sizeBytes,
    this.art,
    this.type = MediaType.photo,
    this.location,
    this.album,
    this.videoDuration,
    this.width = 3024,
    this.height = 4032,
    this.image,
    this.thumbnail,
  });

  final String id;
  final DateTime takenAt;
  final int sizeBytes;
  final MediaType type;

  /// Generated placeholder art for mock data. Null for real photos.
  final PhotoArt? art;
  final String? location;

  /// Folder the item lives in on the device, e.g. "Camera" or "Screenshots".
  final String? album;
  final Duration? videoDuration;
  final int width;
  final int height;

  /// Large preview used on the swipe card. Null for mock data.
  final ImageProvider? image;

  /// Small preview for grids and thumbnails. Falls back to [image].
  final ImageProvider? thumbnail;

  bool get isVideo => type == MediaType.video;
  bool get isScreenshot => type == MediaType.screenshot;

  /// Where the photo came from, for captions: a place if known, else its folder.
  String? get origin => location ?? album;

  @override
  bool operator ==(Object other) => other is Photo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
