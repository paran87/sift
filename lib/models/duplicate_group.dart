import 'photo.dart';

enum GroupKind { duplicate, similar }

class DuplicateGroup {
  const DuplicateGroup({
    required this.id,
    required this.kind,
    required this.photos,
    required this.bestPhotoId,
    required this.label,
  });

  final String id;
  final GroupKind kind;
  final List<Photo> photos;

  /// The shot we'd suggest keeping (sharpest / largest).
  final String bestPhotoId;
  final String label;

  int get totalBytes => photos.fold(0, (sum, p) => sum + p.sizeBytes);
}
