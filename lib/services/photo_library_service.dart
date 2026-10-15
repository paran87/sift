import 'package:flutter/foundation.dart';

import '../models/duplicate_group.dart';
import '../models/photo.dart';
import '../models/photo_album.dart';
import '../models/photo_category.dart';
import '../models/statistics.dart';

/// How much of the photo library the app may read.
enum LibraryAccess {
  /// Full access to photos and videos.
  granted,

  /// The user shared only some photos (Android 14+ / iOS "Selected photos").
  limited,

  /// No access yet, or the user said no.
  denied;

  bool get canRead => this != LibraryAccess.denied;
}

/// Contract between the UI and the photo library.
///
/// [DevicePhotoLibraryService] reads the real library on the phone;
/// [MockPhotoLibraryService] serves sample data for tests and design work.
abstract interface class PhotoLibraryService {
  /// Current permission state, without prompting the user.
  Future<LibraryAccess> checkAccess();

  /// Shows the system permission prompt (when the OS still allows it).
  Future<LibraryAccess> requestAccess();

  /// Opens this app's page in the system settings.
  Future<void> openSystemSettings();

  /// Lets the user change which photos are shared when access is [LibraryAccess.limited].
  Future<void> manageLimitedAccess();

  /// Progress of the library scan, 0 to 1.
  ValueListenable<double> get scanProgress;

  /// Drops cached scan results so the next load re-reads the library.
  void invalidate();

  Future<LibraryOverview> loadOverview();

  Future<List<PhotoCategory>> loadCategories();

  /// Photos to review in a swipe session.
  Future<List<Photo>> loadReviewQueue(CategoryKind category);

  Future<List<DuplicateGroup>> loadGroups(GroupKind kind);

  /// Folders on the device (Camera, Screenshots, WhatsApp Images, …), largest first.
  Future<List<PhotoAlbum>> loadAlbums();

  /// Everything in one album, newest first.
  Future<List<Photo>> loadAlbumPhotos(String albumId);

  Future<List<Photo>> loadTrash();

  Future<InsightsStats> loadInsights();

  Future<List<ActivityEntry>> loadRecentActivity();

  /// Whether deleted items land in the phone's own Recycle Bin / Recently
  /// Deleted, where the user can still restore them.
  Future<bool> deletionIsRecoverable();

  /// Deletes photos from the device. The OS shows its own confirmation.
  ///
  /// Returns the ids that were actually deleted — empty if the user cancelled.
  Future<Set<String>> deletePhotos(List<Photo> photos);
}
