import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/infrastructure/gps/movement_detector.dart';

void main() {
  late MovementDetector detector;

  setUp(() {
    detector = MovementDetector();
  });

  group('MovementDetector', () {
    group('detect with default threshold', () {
      test('should return stationary when speed is 0', () {
        final state = detector.detect(0.0);
        expect(state, MovementState.stationary);
      });

      test('should return stationary when speed is below threshold', () {
        final state = detector.detect(0.4);
        expect(state, MovementState.stationary);
      });

      test('should return moving when speed equals threshold', () {
        // Need multiple readings to overcome smoothing
        detector.detect(0.5);
        detector.detect(0.5);
        final state = detector.detect(0.5);
        expect(state, MovementState.moving);
      });

      test('should return moving when speed is above threshold', () {
        // Need multiple readings to overcome smoothing
        detector.detect(1.5);
        detector.detect(1.5);
        final state = detector.detect(1.5);
        expect(state, MovementState.moving);
      });
    });

    group('smoothing behavior', () {
      test('should require majority of readings to be moving', () {
        // First reading is stationary
        expect(detector.detect(0.0), MovementState.stationary);

        // Second reading is moving, but not majority yet
        expect(detector.detect(1.0), MovementState.stationary);

        // Third reading is moving, now 2/3 are moving
        expect(detector.detect(1.0), MovementState.moving);
      });

      test('should not change state from single reading', () {
        // Establish moving state
        detector.detect(1.5);
        detector.detect(1.5);
        detector.detect(1.5);
        expect(detector.detect(1.5), MovementState.moving);

        // Single stationary reading should not change state
        expect(detector.detect(0.0), MovementState.moving);
      });

      test('should change state when majority changes', () {
        // Establish moving state
        detector.detect(1.5);
        detector.detect(1.5);
        detector.detect(1.5);

        // Now add stationary readings until majority
        detector.detect(0.0);
        detector.detect(0.0);
        expect(detector.detect(0.0), MovementState.stationary);
      });

      test('should prevent flickering from GPS glitches', () {
        // Establish stationary state
        detector.detect(0.0);
        detector.detect(0.0);
        detector.detect(0.0);

        // Single moving reading (glitch) should not change state
        expect(detector.detect(2.0), MovementState.stationary);

        // Back to stationary
        expect(detector.detect(0.0), MovementState.stationary);
      });
    });

    group('reset', () {
      test('should clear reading history', () {
        // Add some readings
        detector.detect(1.5);
        detector.detect(1.5);
        detector.detect(1.5);
        expect(detector.readingCount, 3);

        detector.reset();

        expect(detector.readingCount, 0);
      });

      test('should start fresh after reset', () {
        // Establish moving state
        detector.detect(1.5);
        detector.detect(1.5);
        detector.detect(1.5);

        detector.reset();

        // First reading after reset should be stationary
        expect(detector.detect(0.0), MovementState.stationary);
      });
    });

    group('custom threshold', () {
      test('should use custom threshold', () {
        detector = MovementDetector(threshold: 1.0);

        // 0.9 is below 1.0 threshold
        detector.detect(0.9);
        detector.detect(0.9);
        expect(detector.detect(0.9), MovementState.stationary);

        detector.reset();

        // 1.0 is at threshold
        detector.detect(1.0);
        detector.detect(1.0);
        expect(detector.detect(1.0), MovementState.moving);
      });

      test('should work with very low threshold', () {
        detector = MovementDetector(threshold: 0.1);

        detector.detect(0.15);
        detector.detect(0.15);
        expect(detector.detect(0.15), MovementState.moving);
      });

      test('should work with high threshold', () {
        detector = MovementDetector(threshold: 2.0);

        // Normal walking speed (1.4 m/s) should be stationary
        detector.detect(1.4);
        detector.detect(1.4);
        expect(detector.detect(1.4), MovementState.stationary);

        detector.reset();

        // Running speed should be moving
        detector.detect(2.5);
        detector.detect(2.5);
        expect(detector.detect(2.5), MovementState.moving);
      });
    });

    group('readingCount', () {
      test('should return 0 initially', () {
        expect(detector.readingCount, 0);
      });

      test('should increase with readings', () {
        detector.detect(1.0);
        expect(detector.readingCount, 1);

        detector.detect(1.0);
        expect(detector.readingCount, 2);

        detector.detect(1.0);
        expect(detector.readingCount, 3);
      });

      test('should cap at smoothingCount', () {
        detector.detect(1.0);
        detector.detect(1.0);
        detector.detect(1.0);
        detector.detect(1.0);
        detector.detect(1.0);

        expect(detector.readingCount, MovementDetector.smoothingCount);
      });
    });

    group('edge cases', () {
      test('should handle negative speed', () {
        // Negative speed (invalid) should be treated as stationary
        expect(detector.detect(-1.0), MovementState.stationary);
      });

      test('should handle very high speed', () {
        detector.detect(100.0);
        detector.detect(100.0);
        expect(detector.detect(100.0), MovementState.moving);
      });

      test('should handle exactly threshold speed', () {
        detector.detect(MovementDetector.defaultThreshold);
        detector.detect(MovementDetector.defaultThreshold);
        expect(
          detector.detect(MovementDetector.defaultThreshold),
          MovementState.moving,
        );
      });

      test('should handle just below threshold', () {
        final justBelow = MovementDetector.defaultThreshold - 0.001;
        detector.detect(justBelow);
        detector.detect(justBelow);
        expect(detector.detect(justBelow), MovementState.stationary);
      });
    });
  });
}
