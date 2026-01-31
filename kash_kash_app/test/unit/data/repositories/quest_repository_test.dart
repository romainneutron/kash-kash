import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart' as db;
import 'package:kash_kash_app/data/datasources/local/quest_dao.dart';
import 'package:kash_kash_app/data/datasources/remote/quest_remote_data_source.dart';
import 'package:kash_kash_app/data/models/quest_model.dart';
import 'package:kash_kash_app/data/repositories/quest_repository_impl.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:mocktail/mocktail.dart';

class MockQuestDao extends Mock implements QuestDao {}

class MockQuestRemoteDataSource extends Mock implements QuestRemoteDataSource {}

void main() {
  late QuestRepositoryImpl repository;
  late MockQuestDao mockDao;
  late MockQuestRemoteDataSource mockRemoteDataSource;
  late bool isOnlineValue;

  final now = DateTime.now();

  final testQuestModel = QuestModel(
    id: 'quest-1',
    title: 'Test Quest',
    description: 'A test quest',
    latitude: 48.8566,
    longitude: 2.3522,
    radiusMeters: 5.0,
    createdBy: 'user-1',
    published: true,
    difficulty: 'medium',
    locationType: 'park',
    createdAt: now,
    updatedAt: now,
  );

  final testDriftQuest = db.Quest(
    id: 'quest-1',
    title: 'Test Quest',
    description: 'A test quest',
    latitude: 48.8566,
    longitude: 2.3522,
    radiusMeters: 5.0,
    createdBy: 'user-1',
    published: true,
    difficulty: db.QuestDifficulty.medium,
    locationType: db.LocationType.park,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockDao = MockQuestDao();
    mockRemoteDataSource = MockQuestRemoteDataSource();
    isOnlineValue = true;

    repository = QuestRepositoryImpl(
      questDao: mockDao,
      remoteDataSource: mockRemoteDataSource,
      isOnline: () async => isOnlineValue,
    );
  });

  setUpAll(() {
    registerFallbackValue(testDriftQuest);
    registerFallbackValue(<db.Quest>[]);
    registerFallbackValue(testQuestModel);
  });

  group('QuestRepositoryImpl', () {
    group('getPublishedQuests', () {
      test('should return fresh data when online and remote succeeds', () async {
        when(() => mockDao.getAllPublished())
            .thenAnswer((_) async => [testDriftQuest]);
        when(() => mockRemoteDataSource.getPublishedQuests())
            .thenAnswer((_) async => [testQuestModel]);
        when(() => mockDao.batchUpsert(any(), markAsSynced: any(named: 'markAsSynced'))).thenAnswer((_) async {});

        final result = await repository.getPublishedQuests();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quests) {
            expect(quests.length, 1);
            expect(quests.first.id, 'quest-1');
          },
        );
        verify(() => mockRemoteDataSource.getPublishedQuests()).called(1);
        verify(() => mockDao.batchUpsert(any(), markAsSynced: any(named: 'markAsSynced'))).called(1);
      });

      test('should return cached data when remote fails but cache available',
          () async {
        when(() => mockDao.getAllPublished())
            .thenAnswer((_) async => [testDriftQuest]);
        when(() => mockRemoteDataSource.getPublishedQuests())
            .thenThrow(Exception('Network error'));

        final result = await repository.getPublishedQuests();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quests) {
            expect(quests.length, 1);
            expect(quests.first.id, 'quest-1');
          },
        );
      });

      test('should return cached data when offline', () async {
        isOnlineValue = false;
        when(() => mockDao.getAllPublished())
            .thenAnswer((_) async => [testDriftQuest]);

        final result = await repository.getPublishedQuests();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quests) {
            expect(quests.length, 1);
          },
        );
        verifyNever(() => mockRemoteDataSource.getPublishedQuests());
      });

      test('should return failure when remote fails and no cache', () async {
        when(() => mockDao.getAllPublished()).thenAnswer((_) async => []);
        when(() => mockRemoteDataSource.getPublishedQuests())
            .thenThrow(Exception('Network error'));

        final result = await repository.getPublishedQuests();

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getQuestById', () {
      test('should return remote quest when online and remote succeeds',
          () async {
        when(() => mockDao.getById('quest-1'))
            .thenAnswer((_) async => testDriftQuest);
        when(() => mockRemoteDataSource.getQuestById('quest-1'))
            .thenAnswer((_) async => testQuestModel);
        when(() => mockDao.upsert(any())).thenAnswer((_) async {});

        final result = await repository.getQuestById('quest-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quest) {
            expect(quest.id, 'quest-1');
            expect(quest.title, 'Test Quest');
          },
        );
        verify(() => mockDao.upsert(any())).called(1);
      });

      test('should return cached quest when online but remote fails', () async {
        when(() => mockDao.getById('quest-1'))
            .thenAnswer((_) async => testDriftQuest);
        when(() => mockRemoteDataSource.getQuestById('quest-1'))
            .thenThrow(Exception('Network error'));

        final result = await repository.getQuestById('quest-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quest) {
            expect(quest.id, 'quest-1');
          },
        );
      });

      test('should return cached quest when offline', () async {
        isOnlineValue = false;
        when(() => mockDao.getById('quest-1'))
            .thenAnswer((_) async => testDriftQuest);

        final result = await repository.getQuestById('quest-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quest) {
            expect(quest.id, 'quest-1');
          },
        );
        verifyNever(() => mockRemoteDataSource.getQuestById(any()));
      });

      test('should return CacheFailure when quest not found', () async {
        isOnlineValue = false;
        when(() => mockDao.getById('quest-1')).thenAnswer((_) async => null);

        final result = await repository.getQuestById('quest-1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, 'Quest not found');
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getNearbyQuests', () {
      test('should return remote quests when online', () async {
        when(() => mockDao.getAllPublished())
            .thenAnswer((_) async => [testDriftQuest]);
        when(() => mockRemoteDataSource.getNearbyQuests(
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
              radiusKm: any(named: 'radiusKm'),
            )).thenAnswer((_) async => [testQuestModel]);
        when(() => mockDao.batchUpsert(any(), markAsSynced: any(named: 'markAsSynced'))).thenAnswer((_) async {});

        final result = await repository.getNearbyQuests(
          latitude: 48.8566,
          longitude: 2.3522,
          radiusKm: 5.0,
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quests) {
            expect(quests.length, 1);
          },
        );
      });

      test('should filter cached quests by distance when offline', () async {
        isOnlineValue = false;
        // Quest at Paris (48.8566, 2.3522)
        when(() => mockDao.getAllPublished())
            .thenAnswer((_) async => [testDriftQuest]);

        // Search from same location with 5km radius
        final result = await repository.getNearbyQuests(
          latitude: 48.8566,
          longitude: 2.3522,
          radiusKm: 5.0,
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quests) {
            // Quest at same location should be within 5km
            expect(quests.length, 1);
          },
        );
      });

      test('should exclude quests outside radius when offline', () async {
        isOnlineValue = false;
        // Quest at Paris
        when(() => mockDao.getAllPublished())
            .thenAnswer((_) async => [testDriftQuest]);

        // Search from London with 100m radius - Paris is ~343km away
        final result = await repository.getNearbyQuests(
          latitude: 51.5074,
          longitude: -0.1278,
          radiusKm: 0.1, // 100 meters
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (quests) {
            expect(quests.isEmpty, true);
          },
        );
      });
    });

    group('createQuest', () {
      test('should create quest when online', () async {
        final questToCreate = Quest(
          id: 'new-quest',
          title: 'New Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockRemoteDataSource.createQuest(any()))
            .thenAnswer((_) async => testQuestModel);
        when(() => mockDao.upsert(any())).thenAnswer((_) async {});

        final result = await repository.createQuest(questToCreate);

        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.createQuest(any())).called(1);
        verify(() => mockDao.upsert(any())).called(1);
      });

      test('should return NetworkFailure when offline', () async {
        isOnlineValue = false;
        final questToCreate = Quest(
          id: 'new-quest',
          title: 'New Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        final result = await repository.createQuest(questToCreate);

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'Cannot create quest while offline');
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('updateQuest', () {
      test('should update quest when online', () async {
        final questToUpdate = Quest(
          id: 'quest-1',
          title: 'Updated Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockRemoteDataSource.updateQuest(any()))
            .thenAnswer((_) async => testQuestModel);
        when(() => mockDao.upsert(any())).thenAnswer((_) async {});

        final result = await repository.updateQuest(questToUpdate);

        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.updateQuest(any())).called(1);
      });

      test('should return NetworkFailure when offline', () async {
        isOnlineValue = false;
        final questToUpdate = Quest(
          id: 'quest-1',
          title: 'Updated Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        final result = await repository.updateQuest(questToUpdate);

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('deleteQuest', () {
      test('should delete quest when online', () async {
        when(() => mockRemoteDataSource.deleteQuest('quest-1'))
            .thenAnswer((_) async {});
        when(() => mockDao.deleteById('quest-1')).thenAnswer((_) async => 1);

        final result = await repository.deleteQuest('quest-1');

        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.deleteQuest('quest-1')).called(1);
        verify(() => mockDao.deleteById('quest-1')).called(1);
      });

      test('should return NetworkFailure when offline', () async {
        isOnlineValue = false;

        final result = await repository.deleteQuest('quest-1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('batchUpsert', () {
      test('should batch upsert quests to local cache', () async {
        final quests = [
          Quest(
            id: 'quest-1',
            title: 'Quest 1',
            latitude: 48.8566,
            longitude: 2.3522,
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ),
          Quest(
            id: 'quest-2',
            title: 'Quest 2',
            latitude: 51.5074,
            longitude: -0.1278,
            createdBy: 'user-1',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockDao.batchUpsert(any(), markAsSynced: any(named: 'markAsSynced'))).thenAnswer((_) async {});

        final result = await repository.batchUpsert(quests);

        expect(result.isRight(), true);
        verify(() => mockDao.batchUpsert(any(), markAsSynced: any(named: 'markAsSynced'))).called(1);
      });

      test('should return CacheFailure on error', () async {
        when(() => mockDao.batchUpsert(any()))
            .thenThrow(Exception('Database error'));

        final result = await repository.batchUpsert([]);

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
          },
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
