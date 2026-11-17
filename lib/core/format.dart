/// Small formatting helpers shared across the app.
library;

/// Normalised key used to match exercises by name (case/space insensitive).
String exerciseKey(String name) => name.trim().toLowerCase();

/// Shows a weight without trailing zeros: 60.0 -> "60", 22.50 -> "22.5".
String formatWeight(double w) {
  // Assisted machines log negative weights: shown with a real minus sign.
  if (w < 0) return '\u2212${formatWeight(-w)}';
  if (w == w.roundToDouble()) return w.toInt().toString();
  var s = w.toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

/// Joins weights like "40 · 55 · 65 · 75".
String formatWeights(Iterable<double> ws) => ws.map(formatWeight).join(' · ');

/// A bar's height (floor..1) for [w] among [all]. All non-negative values
/// scale from zero, as always; with assisted (negative) weights the bars
/// scale from the lowest to the highest, so less help is a taller bar.
double barFraction(double w, Iterable<double> all, {double floor = 0.04}) {
  final hi = all.reduce((a, b) => a > b ? a : b);
  final lo = all.reduce((a, b) => a < b ? a : b);
  if (lo >= 0) return hi <= 0 ? floor : (w / hi).clamp(floor, 1.0);
  if (hi == lo) return 1.0;
  return (floor + (1 - floor) * (w - lo) / (hi - lo)).clamp(floor, 1.0);
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Mon, 2 Nov"
String formatDayDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// "2 Nov"
String formatShortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "Today", "Yesterday", "3 days ago".
String formatAgo(DateTime d, DateTime now) {
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(now.year, now.month, now.day);
  final days = b.difference(a).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '$days days ago';
}

/// "32:10" or "1:05:09"
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '${d.inMinutes}:$s';
}
