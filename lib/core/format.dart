class Fmt {
  static const List<String> _months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const List<String> _monthsLong = <String>[
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

  static String _group(int v) {
    final neg = v < 0;
    final s = v.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return neg ? '-$b' : b.toString();
  }

  static String number(double v) {
    if (v == v.roundToDouble()) return _group(v.round());
    final whole = v.truncate();
    final frac = ((v - whole).abs() * 100).round().toString().padLeft(2, '0');
    return '${_group(whole)}.$frac';
  }

  static String money(double v) => 'Rs ${number(v)}';

  static String km(double? v) {
    if (v == null) return '—';
    final s = v >= 100 ? v.round().toString() : v.toStringAsFixed(1);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s} km';
  }

  static String minutes(int? v) => v == null ? '—' : '$v min';

  static String duration(int totalMin) {
    final m = totalMin < 0 ? 0 : totalMin;
    final h = m ~/ 60;
    final r = m % 60;
    if (h == 0) return '${r}m';
    return '${h}h ${r}m';
  }

  static String time(DateTime? d) {
    if (d == null) return '—';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    return '$h:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static String dateTime(DateTime? d) => d == null ? '—' : '${date(d)} · ${time(d)}';

  static String dayMonthUpper(DateTime d) => '${d.day} ${_months[d.month - 1].toUpperCase()}';

  static String monthYear(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseYmd(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} d';
    return '${d.day} ${_months[d.month - 1]}';
  }

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  static String titleCase(String s) {
    if (s.isEmpty) return s;
    final lower = s.toLowerCase().replaceAll('_', ' ');
    return lower.substring(0, 1).toUpperCase() + lower.substring(1);
  }
}
