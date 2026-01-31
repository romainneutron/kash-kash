import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';

void main() {
  group('DistanceFilter', () {
    test('should have all expected values', () {
      expect(DistanceFilter.values, hasLength(4));
      expect(DistanceFilter.km2, isNotNull);
      expect(DistanceFilter.km5, isNotNull);
      expect(DistanceFilter.km10, isNotNull);
      expect(DistanceFilter.km20, isNotNull);
    });

    test('kilometers should return correct values', () {
      expect(DistanceFilter.km2.kilometers, equals(2.0));
      expect(DistanceFilter.km5.kilometers, equals(5.0));
      expect(DistanceFilter.km10.kilometers, equals(10.0));
      expect(DistanceFilter.km20.kilometers, equals(20.0));
    });

    test('label should return correct display strings', () {
      expect(DistanceFilter.km2.label, equals('2 km'));
      expect(DistanceFilter.km5.label, equals('5 km'));
      expect(DistanceFilter.km10.label, equals('10 km'));
      expect(DistanceFilter.km20.label, equals('20 km'));
    });
  });

  group('QuestWithDistance', () {
    test('should create with quest and distance', () {
      final quest = Quest(
        id: 'test-id',
        title: 'Test Quest',
        latitude: 48.8566,
        longitude: 2.3522,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      const distanceMeters = 1500.0;

      final questWithDistance = QuestWithDistance(
        quest: quest,
        distanceMeters: distanceMeters,
      );

      expect(questWithDistance.quest, equals(quest));
      expect(questWithDistance.distanceMeters, equals(distanceMeters));
    });
  });

  group('QuestListState', () {
    test('should create with default values', () {
      const state = QuestListState();

      expect(state.quests, isEmpty);
      expect(state.userPosition, isNull);
      expect(state.filter, equals(DistanceFilter.km5));
      expect(state.isOffline, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('isEmpty should return true when quests list is empty', () {
      const state = QuestListState();
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty should return false when quests list is not empty', () {
      final quest = Quest(
        id: 'test-id',
        title: 'Test Quest',
        latitude: 48.8566,
        longitude: 2.3522,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final state = QuestListState(
        quests: [QuestWithDistance(quest: quest, distanceMeters: 100)],
      );
      expect(state.isEmpty, isFalse);
    });

    test('hasError should return true when error is not null', () {
      const state = QuestListState(error: 'Something went wrong');
      expect(state.hasError, isTrue);
    });

    test('hasError should return false when error is null', () {
      const state = QuestListState();
      expect(state.hasError, isFalse);
    });

    group('copyWith', () {
      test('should copy with new quests', () {
        const originalState = QuestListState();
        final quest = Quest(
          id: 'test-id',
          title: 'Test Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final newQuests = [
          QuestWithDistance(quest: quest, distanceMeters: 100),
        ];

        final newState = originalState.copyWith(quests: newQuests);

        expect(newState.quests, equals(newQuests));
        expect(newState.filter, equals(originalState.filter));
      });

      test('should copy with new filter', () {
        const originalState = QuestListState();
        final newState = originalState.copyWith(filter: DistanceFilter.km20);

        expect(newState.filter, equals(DistanceFilter.km20));
      });

      test('should copy with new loading state', () {
        const originalState = QuestListState();
        final newState = originalState.copyWith(isLoading: true);

        expect(newState.isLoading, isTrue);
      });

      test('should copy with new error', () {
        const originalState = QuestListState();
        final newState = originalState.copyWith(error: 'Error message');

        expect(newState.error, equals('Error message'));
      });

      test('should clear error with clearError flag', () {
        const originalState = QuestListState(error: 'Original error');
        final newState = originalState.copyWith(clearError: true);

        expect(newState.error, isNull);
      });

      test('should not clear error when clearError is false', () {
        const originalState = QuestListState(error: 'Original error');
        final newState = originalState.copyWith(clearError: false);

        expect(newState.error, equals('Original error'));
      });

      test('should copy with new userPosition', () {
        const originalState = QuestListState();
        final position = Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final newState = originalState.copyWith(userPosition: position);

        expect(newState.userPosition, equals(position));
      });

      test('should clear userPosition with clearUserPosition flag', () {
        final position = Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        final originalState = QuestListState(userPosition: position);
        final newState = originalState.copyWith(clearUserPosition: true);

        expect(newState.userPosition, isNull);
      });

      test('should copy with isOffline flag', () {
        const originalState = QuestListState();
        final newState = originalState.copyWith(isOffline: true);

        expect(newState.isOffline, isTrue);
      });

      test('should preserve all fields when no changes', () {
        final position = Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        final quest = Quest(
          id: 'test-id',
          title: 'Test Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final originalState = QuestListState(
          quests: [QuestWithDistance(quest: quest, distanceMeters: 100)],
          userPosition: position,
          filter: DistanceFilter.km10,
          isOffline: true,
          isLoading: true,
          error: 'Some error',
        );

        final newState = originalState.copyWith();

        expect(newState.quests, equals(originalState.quests));
        expect(newState.userPosition, equals(originalState.userPosition));
        expect(newState.filter, equals(originalState.filter));
        expect(newState.isOffline, equals(originalState.isOffline));
        expect(newState.isLoading, equals(originalState.isLoading));
        expect(newState.error, equals(originalState.error));
      });
    });
  });

  group('Either result handling for providers', () {
    test('Right should contain Position for currentPosition', () {
      final position = Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      final result = Right<Failure, Position>(position);

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!.latitude, equals(48.8566));
      expect(result.getRight().toNullable()!.longitude, equals(2.3522));
    });

    test('Left should contain LocationFailure', () {
      const failure = LocationFailure('GPS unavailable');
      final result = Left<Failure, Position>(failure);

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()!.message, equals('GPS unavailable'));
    });

    test('Right should contain List<Quest> for quests', () {
      final quests = [
        Quest(
          id: 'quest-1',
          title: 'Quest 1',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Quest(
          id: 'quest-2',
          title: 'Quest 2',
          latitude: 48.8606,
          longitude: 2.3376,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final result = Right<Failure, List<Quest>>(quests);

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!, hasLength(2));
    });

    test('Left should contain NetworkFailure for quests', () {
      const failure = NetworkFailure('Connection timeout');
      final result = Left<Failure, List<Quest>>(failure);

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()!.message,
        equals('Connection timeout'),
      );
    });
  });
}
