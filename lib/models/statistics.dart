/// Snapshot of the whole library's cleaning state.
class LibraryOverview {
  const LibraryOverview({
    required this.totalPhotos,
    required this.reviewed,
    required this.kept,
    required this.markedForDeletion,
    required this.recoverableBytes,
    required this.recoveredBytes,
  });

  final int totalPhotos;
  final int reviewed;
  final int kept;
  final int markedForDeletion;
  final int recoverableBytes;
  final int recoveredBytes;

  int get remaining => (totalPhotos - reviewed).clamp(0, totalPhotos);
  double get progress => totalPhotos == 0 ? 0 : reviewed / totalPhotos;

  LibraryOverview copyWith({
    int? totalPhotos,
    int? reviewed,
    int? kept,
    int? markedForDeletion,
    int? recoverableBytes,
    int? recoveredBytes,
  }) {
    return LibraryOverview(
      totalPhotos: totalPhotos ?? this.totalPhotos,
      reviewed: reviewed ?? this.reviewed,
      kept: kept ?? this.kept,
      markedForDeletion: markedForDeletion ?? this.markedForDeletion,
      recoverableBytes: recoverableBytes ?? this.recoverableBytes,
      recoveredBytes: recoveredBytes ?? this.recoveredBytes,
    );
  }
}

class MonthlyActivity {
  const MonthlyActivity({required this.month, required this.reviewed, required this.deleted});

  final DateTime month;
  final int reviewed;
  final int deleted;
}

class InsightsStats {
  const InsightsStats({
    required this.photosReviewed,
    required this.photosKept,
    required this.photosDeleted,
    required this.bytesRecovered,
    required this.sessions,
    required this.streakDays,
    required this.averageSessionMinutes,
    required this.monthly,
  });

  final int photosReviewed;
  final int photosKept;
  final int photosDeleted;
  final int bytesRecovered;
  final int sessions;
  final int streakDays;
  final int averageSessionMinutes;
  final List<MonthlyActivity> monthly;
}

enum ActivityType { session, emptied, duplicates }

class ActivityEntry {
  const ActivityEntry({required this.type, required this.date, required this.title, required this.detail});

  final ActivityType type;
  final DateTime date;
  final String title;
  final String detail;
}

/// Result of a single swipe session, shown on the completion screen.
class SessionSummary {
  const SessionSummary({
    required this.reviewed,
    required this.kept,
    required this.marked,
    required this.markedBytes,
    required this.duration,
  });

  final int reviewed;
  final int kept;
  final int marked;
  final int markedBytes;
  final Duration duration;
}
