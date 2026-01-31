import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/core/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator', () {
    group('haversine', () {
      test('should return 0 for same point', () {
        final distance = DistanceCalculator.haversine(
          48.8566,
          2.3522,
          48.8566,
          2.3522,
        );

        expect(distance, equals(0));
      });

      test('should calculate Paris to London distance correctly', () {
        // Paris: 48.8566°N, 2.3522°E
        // London: 51.5074°N, 0.1278°W
        final distance = DistanceCalculator.haversine(
          48.8566,
          2.3522,
          51.5074,
          -0.1278,
        );

        // Expected: ~343 km (within 1km tolerance)
        expect(distance, closeTo(343000, 1000));
      });

      test('should calculate short distance accurately', () {
        // ~11.1 meters at the equator (0.0001 degrees latitude)
        final distance = DistanceCalculator.haversine(
          0.0,
          0.0,
          0.0001,
          0.0,
        );

        // Should be approximately 11.1 meters
        expect(distance, closeTo(11.1, 1));
      });

      test('should handle coordinates crossing date line', () {
        // From 179°E to 179°W should be ~200km at equator (not ~40000km)
        final distance = DistanceCalculator.haversine(
          0.0,
          179.0,
          0.0,
          -179.0,
        );

        // 2 degrees at equator ~ 222km
        expect(distance, closeTo(222389, 1000));
      });

      test('should handle coordinates at poles', () {
        // North Pole to a point 1 degree south
        final distance = DistanceCalculator.haversine(
          90.0,
          0.0,
          89.0,
          0.0,
        );

        // 1 degree of latitude ~ 111km
        expect(distance, closeTo(111000, 1000));
      });

      test('should handle antipodal points', () {
        // North Pole to South Pole
        final distance = DistanceCalculator.haversine(
          90.0,
          0.0,
          -90.0,
          0.0,
        );

        // Half circumference of Earth ~ 20,015 km
        expect(distance, closeTo(20015000, 10000));
      });

      test('should handle negative coordinates', () {
        // Sydney, Australia to Buenos Aires, Argentina
        final distance = DistanceCalculator.haversine(
          -33.8688,
          151.2093,
          -34.6037,
          -58.3816,
        );

        // Expected: ~11,900 km
        expect(distance, closeTo(11900000, 100000));
      });

      test('should be symmetric', () {
        final d1 = DistanceCalculator.haversine(48.8566, 2.3522, 51.5074, -0.1278);
        final d2 = DistanceCalculator.haversine(51.5074, -0.1278, 48.8566, 2.3522);

        expect(d1, equals(d2));
      });
    });

    group('formatDistance', () {
      test('should format meters for distances under 1km', () {
        expect(DistanceCalculator.formatDistance(0), '0 m');
        expect(DistanceCalculator.formatDistance(100), '100 m');
        expect(DistanceCalculator.formatDistance(500), '500 m');
        expect(DistanceCalculator.formatDistance(999), '999 m');
      });

      test('should format kilometers for distances 1km and over', () {
        expect(DistanceCalculator.formatDistance(1000), '1.0 km');
        expect(DistanceCalculator.formatDistance(1500), '1.5 km');
        expect(DistanceCalculator.formatDistance(10000), '10.0 km');
        expect(DistanceCalculator.formatDistance(343000), '343.0 km');
      });

      test('should round meters to nearest integer', () {
        expect(DistanceCalculator.formatDistance(99.4), '99 m');
        expect(DistanceCalculator.formatDistance(99.6), '100 m');
      });

      test('should show one decimal place for kilometers', () {
        expect(DistanceCalculator.formatDistance(1234), '1.2 km');
        expect(DistanceCalculator.formatDistance(1249), '1.2 km');
        expect(DistanceCalculator.formatDistance(1250), '1.3 km');
      });
    });
  });
}
