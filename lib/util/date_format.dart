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