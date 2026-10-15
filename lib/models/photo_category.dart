import 'photo.dart';

enum CategoryKind { all, screenshots, videos, largeFiles, duplicates, similar, oldPhotos }

class PhotoCategory {
  const PhotoCategory({
    required this.kind,
    required this.title,
    required this.description,
    required this.count,
    required this.sizeBytes,
    this.reviewed = 0,
    this.previews = const [],
  });

  final CategoryKind kind;
  final String title;
  final String description;
  final int count;
  final int sizeBytes;
  final List<Photo> previews;

  /// How many items in this category have been reviewed already.
  final int reviewed;

  double get progress => count == 0 ? 0 : reviewed / count;

  /// Duplicate-style categories open the grouped review UI instead of the
  /// swipe deck.
  bool get isGrouped => kind == CategoryKind.duplicates || kind == CategoryKind.similar;
}
