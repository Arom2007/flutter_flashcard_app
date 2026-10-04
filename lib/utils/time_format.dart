/// Turns a Duration into the clock style shown on the stopwatch:
/// "03:12", or "1:03:12" once it passes an hour.
String formatClock(Duration d) {
  final h = d.inHours;
  // inMinutes counts ALL minutes, so '% 60' keeps only the leftover minutes
  // after whole hours. 'padLeft(2, "0")' turns 5 into "05".
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Turns a Duration into words: "12 min 5 sec" or "1 hr 3 min 12 sec".
String formatSpoken(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;

  // A list where each 'if' decides whether that piece is included.
  // Seconds are always shown when it's under a minute, so we never print
  // an empty string.
  final parts = [
    if (h > 0) '$h hr',
    if (m > 0) '$m min',
    if (s > 0 || (h == 0 && m == 0)) '$s sec',
  ];
  return parts.join(' ');
}