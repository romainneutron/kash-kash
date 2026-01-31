import 'dart:collection';

/// Movement state indicating whether the user is moving or stationary.
enum MovementState {
  /// User is stationary (speed below threshold).
  stationary,

  /// User is moving (speed at or above threshold).
  moving,
}

/// Detects if user is moving or stationary based on GPS speed.
///
/// Uses smoothing to prevent flickering from momentary GPS glitches.
/// Requires a majority of recent readings to agree before changing state.
class MovementDetector {
  /// Default speed threshold in m/s.
  /// 0.5 m/s = slow walking speed (normal walking is ~1.4 m/s).
  /// Lower threshold catches intentional movement while filtering GPS drift.
  static const double defaultThreshold = 0.5;

  /// Number of consecutive readings to consider for smoothing.
  /// Prevents flickering from momentary GPS glitches.
  static const int smoothingCount = 3;

  /// Speed threshold in m/s. Speeds below this are considered stationary.
  final double threshold;

  /// Recent speed readings for smoothing (using Queue for O(1) removal).
  final Queue<bool> _recentReadings = Queue<bool>();

  /// Creates a movement detector with optional custom threshold.
  MovementDetector({this.threshold = defaultThreshold});

  /// Detect movement state from current speed.
  ///
  /// Uses smoothing to require a majority of recent readings to agree
  /// before changing state. This prevents flickering from GPS noise.
  ///
  /// [speed] - Current speed in m/s from GPS.
  /// Returns [MovementState.moving] if moving, [MovementState.stationary] otherwise.
  MovementState detect(double speed) {
    // Clamp negative speeds (some devices report -1 for unknown)
    final clampedSpeed = speed < 0 ? 0.0 : speed;
    final isMoving = clampedSpeed >= threshold;
    _recentReadings.add(isMoving);

    // Keep only the most recent readings (O(1) with Queue)
    if (_recentReadings.length > smoothingCount) {
      _recentReadings.removeFirst();
    }

    // Require majority of recent readings to agree
    final movingCount = _recentReadings.where((r) => r).length;
    return movingCount > _recentReadings.length / 2
        ? MovementState.moving
        : MovementState.stationary;
  }

  /// Reset the detector state.
  ///
  /// Clears all recent readings, useful when starting a new gameplay session.
  void reset() {
    _recentReadings.clear();
  }

  /// Get the current number of readings in the buffer.
  int get readingCount => _recentReadings.length;
}
