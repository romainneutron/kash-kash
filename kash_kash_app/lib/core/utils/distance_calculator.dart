import 'dart:math';

/// Utility class for GPS distance calculations using the Haversine formula.
class DistanceCalculator {
  DistanceCalculator._();

  /// Earth's radius in meters.
  static const double _earthRadiusMeters = 6371000;

  /// Calculate the distance between two GPS coordinates in meters.
  ///
  /// Uses the Haversine formula which gives great-circle distances between
  /// two points on a sphere from their longitudes and latitudes.
  ///
  /// [lat1], [lng1] - First coordinate (latitude, longitude in degrees)
  /// [lat2], [lng2] - Second coordinate (latitude, longitude in degrees)
  ///
  /// Returns distance in meters.
  static double haversine(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Convert degrees to radians.
  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Format a distance in meters to a human-readable string.
  ///
  /// Returns meters for distances under 1km, kilometers otherwise.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
