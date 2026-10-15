import '../../models/statistics.dart';

abstract final class MockStatistics {
  static const int _mb = 1024 * 1024;
  static const int _gb = 1024 * _mb;

  static const overview = LibraryOverview(
    totalPhotos: 1248,
    reviewed: 742,
    kept: 520,
    markedForDeletion: 222,
    recoverableBytes: (4.8 * _gb) ~/ 1,
    recoveredBytes: (2.1 * _gb) ~/ 1,
  );

  static InsightsStats get insights {
    final now = DateTime.now();
    const reviewed = [180, 320, 260, 540, 410, 612];
    const deleted = [42, 96, 71, 168, 120, 199];
    return InsightsStats(
      photosReviewed: 3486,
      photosKept: 2690,
      photosDeleted: 796,
      bytesRecovered: (6.4 * _gb).round(),
      sessions: 42,
      streakDays: 5,
      averageSessionMinutes: 6,
      monthly: List.generate(6, (i) {
        return MonthlyActivity(
          month: DateTime(now.year, now.month - 5 + i),
          reviewed: reviewed[i],
          deleted: deleted[i],
        );
      }),
    );
  }

  static List<ActivityEntry> get recentActivity {
    final now = DateTime.now();
    return [
      ActivityEntry(
        type: ActivityType.session,
        date: now.subtract(const Duration(hours: 3)),
        title: 'Swipe session',
        detail: '86 reviewed · 24 marked',
      ),
      ActivityEntry(
        type: ActivityType.emptied,
        date: now.subtract(const Duration(days: 1, hours: 2)),
        title: 'Trash emptied',
        detail: '312 MB freed',
      ),
      ActivityEntry(
        type: ActivityType.duplicates,
        date: now.subtract(const Duration(days: 3)),
        title: 'Duplicates cleaned',
        detail: '18 copies removed',
      ),
    ];
  }
}
