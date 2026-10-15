abstract final class Fmt {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// 1234567 → "1.2 MB"
  static String bytes(int bytes, {int decimals = 1}) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final text = unit <= 1 || value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(decimals);
    return '$text ${units[unit]}';
  }

  /// 1248 → "1,248"
  static String number(num n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String month(DateTime d) => _months[d.month - 1];

  static const _fullMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "September 2026"
  static String monthYear(DateTime d) => '${_fullMonths[d.month - 1]} ${d.year}';

  static String date(DateTime d) {
    final now = DateTime.now();
    final sameYear = d.year == now.year;
    return sameYear ? '${_months[d.month - 1]} ${d.day}' : '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return date(d);
  }

  static String duration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String greeting([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String plural(int n, String singular, [String? pluralForm]) =>
      '${number(n)} ${n == 1 ? singular : (pluralForm ?? '${singular}s')}';
}
