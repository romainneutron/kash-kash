import '../../core/utils/distance_calculator.dart';

/// Direction state relative to target location.
enum DirectionState {
  /// User is getting closer to the target.
  gettingCloser,

  /// User is getting farther from the target.
  gettingFarther,

  /// No significant change in distance (within threshold).
  noChange,
}

/// Detects if user is getting closer or farther from a target location.
///
/// Compares current distance to the previous distance and determines
/// the direction of movement relative to the target.
class DirectionDetector {
  /// Minimum movement in meters required to register a direction change.
  /// Small movements within this threshold return [DirectionState.noChange].
  static const double defaultMinMovementMeters = 2.0;

  /// Target latitude.
  final double targetLat;

  /// Target longitude.
  final double targetLng;

  /// Minimum movement threshold in meters.
  final double minMovementMeters;

  /// Previous distance to target.
  double? _previousDistance;

  /// Creates a direction detector for the given target location.
  DirectionDetector({
    required this.targetLat,
    required this.targetLng,
    this.minMovementMeters = defaultMinMovementMeters,
  });

  /// Detect direction relative to target based on current position.
  ///
  /// Returns [DirectionState.noChange] for the first reading or when
  /// movement is within the minimum threshold.
  ///
  /// [currentLat], [currentLng] - Current GPS coordinates.
  DirectionState detect(double currentLat, double currentLng) {
    final currentDistance = DistanceCalculator.haversine(
      currentLat,
      currentLng,
      targetLat,
      targetLng,
    );

    // First reading - no previous distance to compare
    if (_previousDistance == null) {
      _previousDistance = currentDistance;
      return DirectionState.noChange;
    }

    final difference = _previousDistance! - currentDistance;

    // Always update previous distance to prevent drift accumulation
    _previousDistance = currentDistance;

    // Require minimum movement to register change
    if (difference.abs() < minMovementMeters) {
      return DirectionState.noChange;
    }

    // Positive difference = getting closer (distance decreased)
    return difference > 0
        ? DirectionState.gettingCloser
        : DirectionState.gettingFarther;
  }

  /// Get current distance to target in meters.
  ///
  /// Returns [double.infinity] if no position has been detected yet.
  double get currentDistance => _previousDistance ?? double.infinity;

  /// Check if within a given radius of the target.
  bool isWithinRadius(double radiusMeters) {
    if (_previousDistance == null) return false;
    return _previousDistance! <= radiusMeters;
  }

  /// Reset the detector state.
  ///
  /// Clears previous distance, useful when starting a new gameplay session.
  void reset() {
    _previousDistance = null;
  }
}
