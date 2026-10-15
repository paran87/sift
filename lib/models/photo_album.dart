import 'photo.dart';

/// A folder of photos/videos on the device, e.g. "Camera" or "WhatsApp Images".
class PhotoAlbum {
  const PhotoAlbum({required this.id, required this.name, required this.count, this.cover});

  final String id;
  final String name;
  final int count;

  /// Newest item, used as the album's thumbnail.
  final Photo? cover;
}

/// Date order for album grids and cleaning sessions.
enum PhotoOrder {
  newestFirst,
  oldestFirst;

  String get label => this == newestFirst ? 'Newest first' : 'Oldest first';

  String get shortLabel => this == newestFirst ? 'Newest' : 'Oldest';

  PhotoOrder get flipped => this == newestFirst ? oldestFirst : newestFirst;

  /// Returns a new list sorted by the date each item was taken.
  List<Photo> apply(Iterable<Photo> photos) {
    final list = photos.toList();
    list.sort((a, b) => this == newestFirst ? b.takenAt.compareTo(a.takenAt) : a.takenAt.compareTo(b.takenAt));
    return list;
  }
}
