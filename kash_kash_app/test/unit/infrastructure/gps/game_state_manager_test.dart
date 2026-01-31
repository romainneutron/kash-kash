import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/infrastructure/gps/game_state_manager.dart';
import 'package:kash_kash_app/infrastructure/gps/gps_service.dart';
import 'package:kash_kash_app/presentation/widgets/game_background.dart';
import 'package:mocktail/mocktail.dart';

class MockGpsService extends Mock implements GpsService {}

void main() {
  late MockGpsService mockGpsService;
  late Quest testQuest;
  late GameStateManager manager;
  late StreamController<Position> positionController;

  // Create a fake Position for testing
  Position createPosition({
    required double latitude,
    required double longitude,
    double speed = 0.0,
    double accuracy = 5.0,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speed,
      speedAccuracy: 0,
    );
  }

  setUp(() {
    mockGpsService = MockGpsService();
    positionController = StreamController<Position>.broadcast();

    when(() => mockGpsService.watchPosition(
          distanceFilter: any(named: 'distanceFilter'),
        )).thenAnswer((_) => positionController.stream);

    // Target: Eiffel Tower
    final now = DateTime.now();
    testQuest = Quest(
      id: 'quest-1',
      title: 'Test Quest',
      latitude: 48.8584,
      longitude: 2.2945,
      radiusMeters: 5.0,
      createdBy: 'user-1',
      published: true,
      createdAt: now,
      updatedAt: now,
    );

    manager = GameStateManager(
      quest: testQuest,
      gpsService: mockGpsService,
    );
  });

  tearDown(() async {
    await positionController.close();
    await manager.dispose();
  });

  group('GameStateManager', () {
    group('initial state', () {
      test('should start in initializing state', () {
        expect(manager.currentState, GameplayState.initializing);
      });

      test('should have infinite distance before any position', () {
        expect(manager.distanceToTarget, double.infinity);
      });

      test('should not have won initially', () {
        expect(manager.hasWon, false);
      });
    });

    group('start', () {
      test('should subscribe to position stream', () {
        manager.start();

        verify(() => mockGpsService.watchPosition(distanceFilter: 1)).called(1);
      });

      test('should not start if disposed', () async {
        await manager.dispose();
        manager.start();

        verifyNever(() => mockGpsService.watchPosition(distanceFilter: any(named: 'distanceFilter')));
      });
    });

    group('stationary state', () {
      test('should be stationary when speed is below threshold', () async {
        manager.start();

        final states = <GameplayState>[];
        manager.stateStream.listen(states.add);

        // Position far from target with no speed
        positionController.add(createPosition(
          latitude: 48.8700,
          longitude: 2.2945,
          speed: 0.0,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.last, GameplayState.stationary);
      });
    });

    group('getting closer', () {
      test('should detect getting closer when approaching target', () async {
        manager.start();

        final states = <GameplayState>[];
        manager.stateStream.listen(states.add);

        // First position: far away
        positionController.add(createPosition(
          latitude: 48.8700,
          longitude: 2.2945,
          speed: 1.5,
        ));
        await Future.delayed(const Duration(milliseconds: 10));

        // Second position: closer to target (moving at walking speed)
        positionController.add(createPosition(
          latitude: 48.8650,
          longitude: 2.2945,
          speed: 1.5,
        ));
        positionController.add(createPosition(
          latitude: 48.8640,
          longitude: 2.2945,
          speed: 1.5,
        ));
        positionController.add(createPosition(
          latitude: 48.8630,
          longitude: 2.2945,
          speed: 1.5,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.contains(GameplayState.gettingCloser), true);
      });
    });

    group('getting farther', () {
      test('should detect getting farther when moving away', () async {
        manager.start();

        final states = <GameplayState>[];
        manager.stateStream.listen(states.add);

        // First position: close to target
        positionController.add(createPosition(
          latitude: 48.8600,
          longitude: 2.2945,
          speed: 1.5,
        ));
        await Future.delayed(const Duration(milliseconds: 10));

        // Second position: farther from target
        positionController.add(createPosition(
          latitude: 48.8650,
          longitude: 2.2945,
          speed: 1.5,
        ));
        positionController.add(createPosition(
          latitude: 48.8660,
          longitude: 2.2945,
          speed: 1.5,
        ));
        positionController.add(createPosition(
          latitude: 48.8670,
          longitude: 2.2945,
          speed: 1.5,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.contains(GameplayState.gettingFarther), true);
      });
    });

    group('win detection', () {
      test('should win when within radius', () async {
        manager.start();

        final states = <GameplayState>[];
        manager.stateStream.listen(states.add);

        // Position at target
        positionController.add(createPosition(
          latitude: 48.8584,
          longitude: 2.2945,
          speed: 0.0,
          accuracy: 3.0,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.last, GameplayState.won);
        expect(manager.hasWon, true);
      });

      test('should expand radius when GPS accuracy is poor', () async {
        manager.start();

        final states = <GameplayState>[];
        manager.stateStream.listen(states.add);

        // Position 8m from target with 15m accuracy
        // Effective radius = max(5, 15*0.8) = 12m
        // So 8m should win
        positionController.add(createPosition(
          latitude: 48.85847, // ~8m from target
          longitude: 2.2945,
          speed: 0.0,
          accuracy: 15.0,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.last, GameplayState.won);
      });
    });

    group('error handling', () {
      test('should transition to error state on GPS error', () async {
        manager.start();

        final states = <GameplayState>[];
        manager.stateStream.listen(states.add);

        positionController.addError(Exception('GPS error'));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.last, GameplayState.error);
      });
    });

    group('currentPosition', () {
      test('should be null initially', () {
        expect(manager.currentPosition, isNull);
      });

      test('should update on position change', () async {
        manager.start();

        positionController.add(createPosition(
          latitude: 48.8700,
          longitude: 2.2945,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(manager.currentPosition, isNotNull);
        expect(manager.currentPosition!.latitude, 48.8700);
      });
    });

    group('distanceToTarget', () {
      test('should update after position received', () async {
        manager.start();

        positionController.add(createPosition(
          latitude: 48.8700,
          longitude: 2.2945,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(manager.distanceToTarget, isNot(double.infinity));
        expect(manager.distanceToTarget, greaterThan(0));
      });
    });

    group('reset', () {
      test('should reset to initializing state', () async {
        manager.start();

        positionController.add(createPosition(
          latitude: 48.8700,
          longitude: 2.2945,
          speed: 0.0,
        ));

        await Future.delayed(const Duration(milliseconds: 50));
        expect(manager.currentState, isNot(GameplayState.initializing));

        manager.reset();

        expect(manager.currentState, GameplayState.initializing);
        expect(manager.currentPosition, isNull);
      });
    });

    group('dispose', () {
      test('should mark as disposed', () async {
        expect(manager.isDisposed, false);

        await manager.dispose();

        expect(manager.isDisposed, true);
      });

      test('should cancel GPS subscription', () async {
        manager.start();

        await manager.dispose();

        // Adding position after dispose should not cause error
        positionController.add(createPosition(
          latitude: 48.8700,
          longitude: 2.2945,
        ));

        // No error thrown
      });

      test('should not emit after dispose', () async {
        manager.start();

        final states = <GameplayState>[];
        manager.stateStream.listen(states.add);

        await manager.dispose();

        // Clear states after dispose
        states.clear();

        // This should not emit
        positionController.add(createPosition(
          latitude: 48.8584,
          longitude: 2.2945,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(states, isEmpty);
      });
    });

    group('isWithinDistance', () {
      test('should return false before position received', () {
        expect(manager.isWithinDistance(100), false);
      });

      test('should return true when within specified distance', () async {
        manager.start();

        // Position 50m from target
        positionController.add(createPosition(
          latitude: 48.8589, // ~55m from target
          longitude: 2.2945,
          speed: 0.0,
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(manager.isWithinDistance(100), true);
        expect(manager.isWithinDistance(30), false);
      });
    });
  });
}
