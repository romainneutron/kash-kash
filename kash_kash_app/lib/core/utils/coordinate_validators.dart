/// Shared coordinate validation for form fields and provider-level checks.
abstract final class CoordinateValidators {
  static const double minLatitude = -90;
  static const double maxLatitude = 90;
  static const double minLongitude = -180;
  static const double maxLongitude = 180;

  /// Validator for latitude [TextFormField].
  static String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    final lat = double.tryParse(value.trim());
    if (lat == null || lat < minLatitude || lat > maxLatitude) {
      return 'Must be between $minLatitude and $maxLatitude';
    }
    return null;
  }

  /// Validator for longitude [TextFormField].
  static String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    final lng = double.tryParse(value.trim());
    if (lng == null || lng < minLongitude || lng > maxLongitude) {
      return 'Must be between $minLongitude and $maxLongitude';
    }
    return null;
  }

  /// Display precision for coordinates (~11 m accuracy).
  static const int displayPrecision = 4;

  /// Format a coordinate pair for display, e.g. "48.8566, 2.3522".
  static String formatLatLng(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(displayPrecision)}, '
        '${longitude.toStringAsFixed(displayPrecision)}';
  }

  /// Provider-level range check for parsed coordinates.
  static bool areCoordinatesInRange(double latitude, double longitude) {
    return latitude >= minLatitude &&
        latitude <= maxLatitude &&
        longitude >= minLongitude &&
        longitude <= maxLongitude;
  }
}
