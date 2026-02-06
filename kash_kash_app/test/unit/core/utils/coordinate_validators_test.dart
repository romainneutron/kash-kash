import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/core/utils/coordinate_validators.dart';

void main() {
  group('CoordinateValidators', () {
    group('validateLatitude', () {
      test('returns null for valid latitude', () {
        expect(CoordinateValidators.validateLatitude('48.8566'), isNull);
      });

      test('returns null at boundary -90', () {
        expect(CoordinateValidators.validateLatitude('-90'), isNull);
      });

      test('returns null at boundary 90', () {
        expect(CoordinateValidators.validateLatitude('90'), isNull);
      });

      test('returns error for empty string', () {
        expect(
          CoordinateValidators.validateLatitude(''),
          'Latitude is required',
        );
      });

      test('returns error for null', () {
        expect(
          CoordinateValidators.validateLatitude(null),
          'Latitude is required',
        );
      });

      test('returns error for non-numeric string', () {
        expect(
          CoordinateValidators.validateLatitude('abc'),
          'Must be between -90.0 and 90.0',
        );
      });

      test('returns error for out-of-range positive', () {
        expect(
          CoordinateValidators.validateLatitude('91'),
          'Must be between -90.0 and 90.0',
        );
      });

      test('returns error for out-of-range negative', () {
        expect(
          CoordinateValidators.validateLatitude('-91'),
          'Must be between -90.0 and 90.0',
        );
      });
    });

    group('validateLongitude', () {
      test('returns null for valid longitude', () {
        expect(CoordinateValidators.validateLongitude('2.3522'), isNull);
      });

      test('returns null at boundary -180', () {
        expect(CoordinateValidators.validateLongitude('-180'), isNull);
      });

      test('returns null at boundary 180', () {
        expect(CoordinateValidators.validateLongitude('180'), isNull);
      });

      test('returns error for empty string', () {
        expect(
          CoordinateValidators.validateLongitude(''),
          'Longitude is required',
        );
      });

      test('returns error for null', () {
        expect(
          CoordinateValidators.validateLongitude(null),
          'Longitude is required',
        );
      });

      test('returns error for non-numeric string', () {
        expect(
          CoordinateValidators.validateLongitude('xyz'),
          'Must be between -180.0 and 180.0',
        );
      });

      test('returns error for out-of-range positive', () {
        expect(
          CoordinateValidators.validateLongitude('181'),
          'Must be between -180.0 and 180.0',
        );
      });

      test('returns error for out-of-range negative', () {
        expect(
          CoordinateValidators.validateLongitude('-181'),
          'Must be between -180.0 and 180.0',
        );
      });
    });

    group('areCoordinatesInRange', () {
      test('returns true for valid coordinates', () {
        expect(
          CoordinateValidators.areCoordinatesInRange(48.8566, 2.3522),
          isTrue,
        );
      });

      test('returns true at boundaries', () {
        expect(
          CoordinateValidators.areCoordinatesInRange(-90, -180),
          isTrue,
        );
        expect(
          CoordinateValidators.areCoordinatesInRange(90, 180),
          isTrue,
        );
      });

      test('returns false for out-of-range latitude', () {
        expect(
          CoordinateValidators.areCoordinatesInRange(91, 0),
          isFalse,
        );
      });

      test('returns false for out-of-range longitude', () {
        expect(
          CoordinateValidators.areCoordinatesInRange(0, 181),
          isFalse,
        );
      });

      test('returns false when both out of range', () {
        expect(
          CoordinateValidators.areCoordinatesInRange(-91, -181),
          isFalse,
        );
      });
    });

    group('formatLatLng', () {
      test('formats coordinates with 4 decimal places', () {
        expect(
          CoordinateValidators.formatLatLng(48.8566, 2.3522),
          '48.8566, 2.3522',
        );
      });

      test('pads short decimals with zeros', () {
        expect(
          CoordinateValidators.formatLatLng(48.0, 2.0),
          '48.0000, 2.0000',
        );
      });

      test('truncates long decimals', () {
        expect(
          CoordinateValidators.formatLatLng(48.856612345, 2.352298765),
          '48.8566, 2.3523',
        );
      });

      test('handles negative coordinates', () {
        expect(
          CoordinateValidators.formatLatLng(-33.8688, 151.2093),
          '-33.8688, 151.2093',
        );
      });
    });
  });
}
