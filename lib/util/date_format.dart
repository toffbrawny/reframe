import 'package:intl/intl.dart';

/// Formats remaining countdown time as e.g. "3d 4h", "12h 30m", "45m 10s".
String formatRemaining(Duration d) {
  if (d.isNegative) return 'now';
  final days = d.inDays;
  final hours = d.inHours.remainder(24);
  final mins = d.inMinutes.remainder(60);
  final secs = d.inSeconds.remainder(60);
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${mins}m';
  if (mins > 0) return '${mins}m ${secs}s';
  return '${secs}s';
}

String formatDate(DateTime dt) =>
    DateFormat('MMM d, y · HH:mm').format(dt);

String formatDateShort(DateTime dt) => DateFormat('MMM d, y').format(dt);

/// Human-friendly span for a duration, e.g. "1 yr 2 mo", "3 mo 12 d",
/// "12 d 4 h", "6 h 20 m", "35 m".
String formatSpan(Duration d) {
  if (d.isNegative) d = -d;
  final days = d.inDays;
  if (days >= 365) {
    final y = days ~/ 365;
    final remDays = days % 365;
    final mo = remDays ~/ 30;
    return mo > 0 ? '$y yr $mo mo' : '$y yr';
  }
  if (days >= 30) {
    final mo = days ~/ 30;
    final remDays = days % 30;
    return remDays > 0 ? '$mo mo $remDays d' : '$mo mo';
  }
  if (days >= 1) return '$days d ${d.inHours.remainder(24)} h';
  if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes.remainder(60)} m';
  return '${d.inMinutes} m';
}