import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/infrastructure/gps/direction_detector.dart';

void main() {
  late DirectionDetector detector;

  // Target location: Eiffel Tower, Paris
  const targetLat = 48.8584;
  const targetLng = 2.2945;

  setUp(() {
    detector = DirectionDetector(
      targetLat: targetLat,
      targetLng: targetLng,
    );
  });

  group('DirectionDetector', () {
    group('first reading', () {
      test('should return noChange for first reading', () {
        final state = detector.detect(48.8600, 2.2945);
        expect(state, DirectionState.noChange);
      });

      test('should set currentDistance on first reading', () {
        expect(detector.currentDistance, double.infinity);

        detector.detect(48.8600, 2.2945);

        expect(detector.currentDistance, isNot(double.infinity));
        expect(detector.currentDistance, greaterThan(0));
      });
    });

    group('getting closer', () {
      test('should detect getting closer when approaching target', () {
        // Start ~180m away
        detector.detect(48.8600, 2.2945);

        // Move to ~100m away (closer)
        final state = detector.detect(48.8593, 2.2945);

        expect(state, DirectionState.gettingCloser);
      });

      test('should detect getting closer from multiple directions', () {
        // Start far north of target
        detector.detect(48.8700, 2.2945);

        // Move south toward target
        final state = detector.detect(48.8650, 2.2945);
        expect(state, DirectionState.gettingCloser);
      });
    });

    group('getting farther', () {
      test('should detect getting farther when moving away from target', () {
        // Start ~100m away
        detector.detect(48.8593, 2.2945);

        // Move to ~180m away (farther)
        final state = detector.detect(48.8600, 2.2945);

        expect(state, DirectionState.gettingFarther);
      });

      test('should detect getting farther from multiple directions', () {
        // Start close to target
        detector.detect(48.8590, 2.2945);

        // Move farther north
        final state = detector.detect(48.8650, 2.2945);
        expect(state, DirectionState.gettingFarther);
      });
    });

    group('noChange within threshold', () {
      test('should return noChange for small movements', () {
        // Start ~100m away
        detector.detect(48.8593, 2.2945);

        // Move only ~1m (less than 2m threshold)
        // 0.00001 degrees is approximately 1.1m
        final state = detector.detect(48.85931, 2.2945);

        expect(state, DirectionState.noChange);
      });

      test('should return noChange when exactly at threshold', () {
        detector.detect(48.8600, 2.2945);

        // Movement less than 2m
        final state = detector.detect(48.860015, 2.2945);
        expect(state, DirectionState.noChange);
      });
    });

    group('currentDistance', () {
      test('should return infinity before any detection', () {
        expect(detector.currentDistance, double.infinity);
      });

      test('should return correct distance after detection', () {
        // Position approximately 178m from target
        detector.detect(48.8600, 2.2945);

        final distance = detector.currentDistance;
        expect(distance, greaterThan(170));
        expect(distance, lessThan(190));
      });

      test('should update after getting closer', () {
        detector.detect(48.8600, 2.2945);
        final initial = detector.currentDistance;

        detector.detect(48.8590, 2.2945);
        final after = detector.currentDistance;

        expect(after, lessThan(initial));
      });

      test('should update after getting farther', () {
        detector.detect(48.8590, 2.2945);
        final initial = detector.currentDistance;

        detector.detect(48.8600, 2.2945);
        final after = detector.currentDistance;

        expect(after, greaterThan(initial));
      });
    });

    group('isWithinRadius', () {
      test('should return false before any detection', () {
        expect(detector.isWithinRadius(100), false);
      });

      test('should return true when within radius', () {
        // Position very close to target (~5m)
        detector.detect(48.8584, 2.2946);

        expect(detector.isWithinRadius(10), true);
        expect(detector.isWithinRadius(5), false);
      });

      test('should return false when outside radius', () {
        // Position ~100m from target
        detector.detect(48.8593, 2.2945);

        expect(detector.isWithinRadius(50), false);
        expect(detector.isWithinRadius(150), true);
      });
    });

    group('reset', () {
      test('should clear previous distance', () {
        detector.detect(48.8600, 2.2945);
        expect(detector.currentDistance, isNot(double.infinity));

        detector.reset();

        expect(detector.currentDistance, double.infinity);
      });

      test('should return noChange after reset', () {
        detector.detect(48.8600, 2.2945);
        detector.detect(48.8590, 2.2945);

        detector.reset();

        // First reading after reset should be noChange
        expect(detector.detect(48.8590, 2.2945), DirectionState.noChange);
      });

      test('should clear isWithinRadius state', () {
        detector.detect(48.8584, 2.2945);
        expect(detector.isWithinRadius(10), true);

        detector.reset();

        expect(detector.isWithinRadius(10), false);
      });
    });

    group('drift prevention', () {
      test('should detect direction after accumulated small movements', () {
        // With minMovementMeters = 2.0, we need movements >= 2m to detect
        // Each small movement individually is < 2m but should still update
        // _previousDistance to prevent drift

        // Start position
        detector.detect(48.8600, 2.2945);

        // Small movement 1 (~1.5m) - noChange expected
        detector.detect(48.860015, 2.2945);

        // Small movement 2 (~1.5m further away)
        // Without fix: would compare to original position (3m total = detected)
        // With fix: compares to last position (1.5m = noChange)
        final state = detector.detect(48.860030, 2.2945);
        expect(state, DirectionState.noChange);
      });

      test('should detect after movement exceeds threshold from last position', () {
        detector.detect(48.8600, 2.2945);

        // Small movement 1 - noChange
        detector.detect(48.860015, 2.2945);

        // Larger movement from last position (> 2m)
        final state = detector.detect(48.8604, 2.2945);
        expect(state, DirectionState.gettingFarther);
      });
    });

    group('custom minMovementMeters', () {
      test('should use custom threshold', () {
        detector = DirectionDetector(
          targetLat: targetLat,
          targetLng: targetLng,
          minMovementMeters: 10.0,
        );

        // Start position
        detector.detect(48.8600, 2.2945);

        // Move ~5m (less than 10m threshold)
        final state = detector.detect(48.86005, 2.2945);
        expect(state, DirectionState.noChange);
      });

      test('should detect with very small threshold', () {
        detector = DirectionDetector(
          targetLat: targetLat,
          targetLng: targetLng,
          minMovementMeters: 0.5,
        );

        detector.detect(48.8600, 2.2945);

        // Small movement should be detected
        final state = detector.detect(48.8601, 2.2945);
        expect(state, isNot(DirectionState.noChange));
      });
    });

    group('edge cases', () {
      test('should handle same position', () {
        detector.detect(48.8600, 2.2945);
        final state = detector.detect(48.8600, 2.2945);

        expect(state, DirectionState.noChange);
      });

      test('should handle coordinates at target', () {
        final state = detector.detect(targetLat, targetLng);

        expect(state, DirectionState.noChange);
        expect(detector.currentDistance, closeTo(0, 1));
      });

      test('should handle very far coordinates', () {
        // New York coordinates
        detector.detect(40.7128, -74.0060);

        expect(detector.currentDistance, greaterThan(5000000)); // >5000km
      });

      test('should handle crossing date line', () {
        final crossDateLine = DirectionDetector(
          targetLat: 0,
          targetLng: 179.9,
        );

        crossDateLine.detect(0, -179.9);
        expect(crossDateLine.currentDistance, lessThan(50000)); // < 50km
      });

      test('should handle polar coordinates', () {
        final polar = DirectionDetector(
          targetLat: 89.9,
          targetLng: 0,
        );

        polar.detect(89.8, 180);
        expect(polar.currentDistance, greaterThan(0));
      });
    });
  });
}
