/// Utility class for formatting Duration values.
class DurationFormatter {
  DurationFormatter._();

  /// Format a duration to a compact timer format (MM:SS or HH:MM:SS).
  ///
  /// Examples: "05:30", "01:23:45"
  static String formatTimer(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Format a duration to a human-readable string with units.
  ///
  /// Examples: "5s", "2m 30s", "1h 5m 30s"
  static String formatHuman(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
