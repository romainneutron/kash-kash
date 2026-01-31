import 'package:fpdart/fpdart.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/core/utils/distance_calculator.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart';
import 'package:kash_kash_app/data/datasources/local/quest_dao.dart';
import 'package:kash_kash_app/data/datasources/remote/quest_remote_data_source.dart';
import 'package:kash_kash_app/data/models/quest_model.dart';
import 'package:kash_kash_app/domain/entities/quest.dart' as domain;
import 'package:kash_kash_app/domain/repositories/quest_repository.dart';

/// Offline-first quest repository implementation.
///
/// This repository follows the offline-first pattern:
/// 1. Return cached data immediately (if available)
/// 2. Fetch fresh data from remote when online
/// 3. Update local cache with remote data
class QuestRepositoryImpl implements IQuestRepository {
  final QuestDao _questDao;
  final QuestRemoteDataSource _remoteDataSource;
  final Future<bool> Function() _isOnline;

  QuestRepositoryImpl({
    required QuestDao questDao,
    required QuestRemoteDataSource remoteDataSource,
    required Future<bool> Function() isOnline,
  })  : _questDao = questDao,
        _remoteDataSource = remoteDataSource,
        _isOnline = isOnline;

  @override
  Future<Either<Failure, List<domain.Quest>>> getPublishedQuests() async {
    try {
      // Try to get cached quests first
      final cachedQuests = await _questDao.getAllPublished();

      // Try to fetch fresh data from remote
      if (await _isOnline()) {
        try {
          final remoteQuests = await _remoteDataSource.getPublishedQuests();
          await _questDao.batchUpsert(remoteQuests.map((q) => q.toDrift()).toList());

          // Return fresh data
          final freshQuests = await _questDao.getAllPublished();
          return Right(
            freshQuests.map((q) => QuestModel.fromDrift(q).toDomain()).toList(),
          );
        } catch (_) {
          // Failed to fetch remote, return cached data if available
          if (cachedQuests.isNotEmpty) {
            return Right(
              cachedQuests.map((q) => QuestModel.fromDrift(q).toDomain()).toList(),
            );
          }
          rethrow;
        }
      }

      // Offline - return cached data
      return Right(
        cachedQuests.map((q) => QuestModel.fromDrift(q).toDomain()).toList(),
      );
    } on NetworkFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Failed to get quests: $e'));
    }
  }

  @override
  Future<Either<Failure, List<domain.Quest>>> getNearbyQuests({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // Get cached quests first
      final cachedQuests = await _questDao.getAllPublished();
      final filteredCached = _filterByDistance(
        cachedQuests,
        latitude,
        longitude,
        radiusKm,
      );

      // Try to fetch fresh data from remote
      if (await _isOnline()) {
        try {
          final remoteQuests = await _remoteDataSource.getNearbyQuests(
            lat: latitude,
            lng: longitude,
            radiusKm: radiusKm,
          );
          await _questDao.batchUpsert(remoteQuests.map((q) => q.toDrift()).toList());

          // Return remote quests with distance (they come pre-filtered)
          return Right(
            remoteQuests.map((q) => q.toDomain()).toList(),
          );
        } catch (_) {
          // Failed to fetch remote, return filtered cached data
          if (filteredCached.isNotEmpty) {
            return Right(filteredCached);
          }
          rethrow;
        }
      }

      // Offline - return filtered cached data
      return Right(filteredCached);
    } on NetworkFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Failed to get nearby quests: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.Quest>> getQuestById(String id) async {
    try {
      final cached = await _questDao.getById(id);
      final isOnline = await _isOnline();

      // Try to fetch from remote if online
      if (isOnline) {
        try {
          final remote = await _remoteDataSource.getQuestById(id);
          await _questDao.upsert(remote.toDrift());
          return Right(remote.toDomain());
        } catch (_) {
          // Failed to fetch remote, fall through to cached
        }
      }

      // Return cached if available
      if (cached != null) {
        return Right(QuestModel.fromDrift(cached).toDomain());
      }

      return const Left(CacheFailure('Quest not found'));
    } catch (e) {
      return Left(NetworkFailure('Failed to get quest: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.Quest>> createQuest(domain.Quest quest) async {
    try {
      if (!await _isOnline()) {
        return const Left(NetworkFailure('Cannot create quest while offline'));
      }

      final model = QuestModel.fromDomain(quest);
      final created = await _remoteDataSource.createQuest(model);
      await _questDao.upsert(created.toDrift());

      return Right(created.toDomain());
    } catch (e) {
      return Left(ServerFailure('Failed to create quest: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.Quest>> updateQuest(domain.Quest quest) async {
    try {
      if (!await _isOnline()) {
        return const Left(NetworkFailure('Cannot update quest while offline'));
      }

      final model = QuestModel.fromDomain(quest);
      final updated = await _remoteDataSource.updateQuest(model);
      await _questDao.upsert(updated.toDrift());

      return Right(updated.toDomain());
    } catch (e) {
      return Left(ServerFailure('Failed to update quest: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteQuest(String id) async {
    try {
      if (!await _isOnline()) {
        return const Left(NetworkFailure('Cannot delete quest while offline'));
      }

      await _remoteDataSource.deleteQuest(id);
      await _questDao.deleteById(id);

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Failed to delete quest: $e'));
    }
  }

  @override
  Future<Either<Failure, List<domain.Quest>>> getAllQuests() async {
    try {
      // Try to get cached quests first
      final cachedQuests = await _questDao.getAll();

      // Try to fetch fresh data from remote
      if (await _isOnline()) {
        try {
          final remoteQuests = await _remoteDataSource.getPublishedQuests();
          await _questDao.batchUpsert(remoteQuests.map((q) => q.toDrift()).toList());

          final freshQuests = await _questDao.getAll();
          return Right(
            freshQuests.map((q) => QuestModel.fromDrift(q).toDomain()).toList(),
          );
        } catch (_) {
          if (cachedQuests.isNotEmpty) {
            return Right(
              cachedQuests.map((q) => QuestModel.fromDrift(q).toDomain()).toList(),
            );
          }
          rethrow;
        }
      }

      return Right(
        cachedQuests.map((q) => QuestModel.fromDrift(q).toDomain()).toList(),
      );
    } catch (e) {
      return Left(NetworkFailure('Failed to get quests: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> batchUpsert(List<domain.Quest> quests) async {
    try {
      final driftQuests = quests
          .map((q) => QuestModel.fromDomain(q).toDrift())
          .toList();
      await _questDao.batchUpsert(driftQuests);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to batch upsert quests: $e'));
    }
  }

  /// Filter quests by distance from user location.
  List<domain.Quest> _filterByDistance(
    List<Quest> quests,
    double lat,
    double lng,
    double radiusKm,
  ) {
    final radiusMeters = radiusKm * 1000;

    // Calculate distance once and store with quest
    final withDistance = <(domain.Quest, double)>[];

    for (final quest in quests) {
      final distance = DistanceCalculator.haversine(
        lat,
        lng,
        quest.latitude,
        quest.longitude,
      );

      if (distance <= radiusMeters) {
        withDistance.add((QuestModel.fromDrift(quest).toDomain(), distance));
      }
    }

    // Sort by cached distance
    withDistance.sort((a, b) => a.$2.compareTo(b.$2));

    return withDistance.map((e) => e.$1).toList();
  }
}
