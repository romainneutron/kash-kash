import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('PathPoint', () {
    group('creation', () {
      test('should create path point with all required fields', () {
        final point = FakeData.createPathPoint();

        expect(point.id, 'point-123');
        expect(point.attemptId, 'attempt-123');
        expect(point.latitude, 48.8566);
        expect(point.longitude, 2.3522);
        expect(point.accuracy, 5.0);
        expect(point.speed, 1.5);
        expect(point.synced, isFalse);
      });

      test('should create path point with custom coordinates', () {
        final point = FakeData.createPathPoint(
          latitude: 51.5074,
          longitude: -0.1278,
        );

        expect(point.latitude, 51.5074);
        expect(point.longitude, -0.1278);
      });

      test('should create path point with custom GPS data', () {
        final point = FakeData.createPathPoint(
          accuracy: 10.0,
          speed: 3.5,
        );

        expect(point.accuracy, 10.0);
        expect(point.speed, 3.5);
      });
    });

    group('copyWith', () {
      test('should create copy with modified coordinates', () {
        final point = FakeData.createPathPoint();
        final copy = point.copyWith(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        expect(copy.latitude, 40.7128);
        expect(copy.longitude, -74.0060);
        expect(copy.id, point.id);
        expect(copy.attemptId, point.attemptId);
      });

      test('should create copy with modified accuracy', () {
        final point = FakeData.createPathPoint(accuracy: 5.0);
        final copy = point.copyWith(accuracy: 2.0);

        expect(copy.accuracy, 2.0);
      });

      test('should create copy with modified speed', () {
        final point = FakeData.createPathPoint(speed: 1.0);
        final copy = point.copyWith(speed: 2.5);

        expect(copy.speed, 2.5);
      });

      test('should create copy with synced flag', () {
        final point = FakeData.createPathPoint(synced: false);
        final copy = point.copyWith(synced: true);

        expect(copy.synced, isTrue);
      });

      test('should preserve all fields when no changes', () {
        final point = FakeData.createPathPoint();
        final copy = point.copyWith();

        expect(copy.id, point.id);
        expect(copy.attemptId, point.attemptId);
        expect(copy.latitude, point.latitude);
        expect(copy.longitude, point.longitude);
        expect(copy.timestamp, point.timestamp);
        expect(copy.accuracy, point.accuracy);
        expect(copy.speed, point.speed);
        expect(copy.synced, point.synced);
      });
    });

    group('equality', () {
      test('should be equal when ids match', () {
        final point1 = FakeData.createPathPoint(id: 'same-id');
        final point2 = FakeData.createPathPoint(id: 'same-id', latitude: 0);

        expect(point1, equals(point2));
      });

      test('should not be equal when ids differ', () {
        final point1 = FakeData.createPathPoint(id: 'id-1');
        final point2 = FakeData.createPathPoint(id: 'id-2');

        expect(point1, isNot(equals(point2)));
      });

      test('should have same hashCode for equal points', () {
        final point1 = FakeData.createPathPoint(id: 'same-id');
        final point2 = FakeData.createPathPoint(id: 'same-id');

        expect(point1.hashCode, equals(point2.hashCode));
      });
    });

    group('timestamp handling', () {
      test('should store timestamp correctly', () {
        final timestamp = DateTime(2024, 6, 15, 14, 30, 45);
        final point = FakeData.createPathPoint(timestamp: timestamp);

        expect(point.timestamp, timestamp);
        expect(point.timestamp.year, 2024);
        expect(point.timestamp.month, 6);
        expect(point.timestamp.day, 15);
      });

      test('should allow copyWith for timestamp', () {
        final point = FakeData.createPathPoint();
        final newTimestamp = DateTime(2024, 12, 25, 12, 0);
        final copy = point.copyWith(timestamp: newTimestamp);

        expect(copy.timestamp, newTimestamp);
      });
    });
  });
}
