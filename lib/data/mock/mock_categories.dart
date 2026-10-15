import '../../models/photo_category.dart';
import 'mock_photos.dart';

abstract final class MockCategories {
  static const int _mb = 1024 * 1024;
  static const int _gb = 1024 * _mb;

  static List<PhotoCategory> get all => [
    PhotoCategory(
      kind: CategoryKind.all,
      title: 'All Photos',
      description: 'Everything on your phone',
      count: 1248,
      sizeBytes: (18.6 * _gb).round(),
      reviewed: 742,
      previews: MockPhotos.previewsFor(CategoryKind.all),
    ),
    PhotoCategory(
      kind: CategoryKind.screenshots,
      title: 'Screenshots',
      description: 'Usually safe to clear',
      count: 328,
      sizeBytes: (412 * _mb).round(),
      reviewed: 301,
      previews: MockPhotos.previewsFor(CategoryKind.screenshots),
    ),
    PhotoCategory(
      kind: CategoryKind.videos,
      title: 'Videos',
      description: 'Often the biggest space savers',
      count: 86,
      sizeBytes: (9.2 * _gb).round(),
      reviewed: 24,
      previews: MockPhotos.previewsFor(CategoryKind.videos),
    ),
    PhotoCategory(
      kind: CategoryKind.largeFiles,
      title: 'Big Files',
      description: 'Take up the most space',
      count: 47,
      sizeBytes: (6.1 * _gb).round(),
      reviewed: 12,
      previews: MockPhotos.previewsFor(CategoryKind.largeFiles),
    ),
    PhotoCategory(
      kind: CategoryKind.duplicates,
      title: 'Same Photos',
      description: 'The same photo saved twice',
      count: 126,
      sizeBytes: (486 * _mb).round(),
      reviewed: 88,
      previews: MockPhotos.duplicateGroups.first.photos,
    ),
    PhotoCategory(
      kind: CategoryKind.similar,
      title: 'Similar Photos',
      description: 'Almost the same picture, taken together',
      count: 214,
      sizeBytes: (1.2 * _gb).round(),
      reviewed: 64,
      previews: MockPhotos.similarGroups[1].photos,
    ),
    PhotoCategory(
      kind: CategoryKind.oldPhotos,
      title: 'Old Photos',
      description: 'From over 2 years ago',
      count: 402,
      sizeBytes: (3.1 * _gb).round(),
      reviewed: 253,
      previews: MockPhotos.previewsFor(CategoryKind.oldPhotos),
    ),
  ];
}
