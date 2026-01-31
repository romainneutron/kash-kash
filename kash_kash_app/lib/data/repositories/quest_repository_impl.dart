import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Maximum number of retry attempts for transient failures.
  static const int _maxRetries = 1;

  /// Delay between retry attempts.
  static const Duration _retryDelay = Duration(milliseconds: 500);

  QuestRepositoryImpl({
    required QuestDao questDao,
    required QuestRemoteDataSource remoteDataSource,
    required Future<bool> Function() isOnline,
  })  : _questDao = questDao,
        _remoteDataSource = remoteDataSource,
        _isOnline = isOnline;

  /// Execute an operation with retry on transient failures.
  ///
  /// Only retries on network-related errors (socket, timeout, connection).
  /// Does not retry on validation or server errors.
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        final isLastAttempt = attempt == _maxRetries;
        if (isLastAttempt) rethrow;

        // Only retry on transient network errors (by exception type)
        final isTransient = _isTransientError(e);
        if (!isTransient) rethrow;

        await Future.delayed(_retryDelay);
      }
    }
    throw StateError('Unreachable');
  }

  /// Check if an error is transient and should be retried.
  bool _isTransientError(Object error) {
    // Socket/connection errors
    if (error is SocketException) return true;

    // Timeout errors
    if (error is TimeoutException) return true;

    // Dio-specific errors
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          return false;
      }
    }

    return false;
  }

  @override
  Future<Either<Failure, List<domain.Quest>>> getPublishedQuests({
    PaginationParams? pagination,
  }) async {
    try {
      // Try to get cached quests first
      final cachedQuests = await _questDao.getAllPublished();

      // Try to fetch fresh data from remote with retry
      if (await _isOnline()) {
        try {
          final remoteQuests = await _withRetry(
            () => _remoteDataSource.getPublishedQuests(
              page: pagination?.page,
              perPage: pagination?.perPage,
            ),
          );
          await _questDao.batchUpsert(
            remoteQuests.map((q) => q.toDrift()).toList(),
            markAsSynced: true,
          );

          final freshQuests = await _questDao.getAllPublished();
          return Right(_toDomainList(freshQuests));
        } catch (e) {
          debugPrint('Remote fetch failed, falling back to cache: $e');
          if (cachedQuests.isNotEmpty) {
            return Right(_toDomainList(cachedQuests));
          }
          rethrow;
        }
      }

      return Right(_toDomainList(cachedQuests));
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

      // Try to fetch fresh data from remote with retry
      if (await _isOnline()) {
        try {
          final remoteQuests = await _withRetry(
            () => _remoteDataSource.getNearbyQuests(
              lat: latitude,
              lng: longitude,
              radiusKm: radiusKm,
            ),
          );
          await _questDao.batchUpsert(
            remoteQuests.map((q) => q.toDrift()).toList(),
            markAsSynced: true,
          );

          // Return remote quests with distance (they come pre-filtered)
          return Right(
            remoteQuests.map((q) => q.toDomain()).toList(),
          );
        } catch (e) {
          // Failed to fetch remote, return filtered cached data
          debugPrint('Remote nearby fetch failed, falling back to cache: $e');
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

      // Try to fetch from remote if online with retry
      if (isOnline) {
        try {
          final remote = await _withRetry(
            () => _remoteDataSource.getQuestById(id),
          );
          await _questDao.upsert(remote.toDrift());
          return Right(remote.toDomain());
        } catch (e) {
          // Failed to fetch remote, fall through to cached
          debugPrint('Remote getQuestById failed, trying cache: $e');
        }
      }

      if (cached != null) {
        return Right(_toDomain(cached));
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

      // Try to fetch fresh data from remote with retry
      if (await _isOnline()) {
        try {
          final remoteQuests = await _withRetry(
            () => _remoteDataSource.getPublishedQuests(),
          );
          await _questDao.batchUpsert(
            remoteQuests.map((q) => q.toDrift()).toList(),
            markAsSynced: true,
          );

          final freshQuests = await _questDao.getAll();
          return Right(_toDomainList(freshQuests));
        } catch (e) {
          debugPrint('Remote getAllQuests failed, falling back to cache: $e');
          if (cachedQuests.isNotEmpty) {
            return Right(_toDomainList(cachedQuests));
          }
          rethrow;
        }
      }

      return Right(_toDomainList(cachedQuests));
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

  /// Convert Drift quest to domain entity.
  domain.Quest _toDomain(Quest quest) => QuestModel.fromDrift(quest).toDomain();

  /// Convert list of Drift quests to domain entities.
  List<domain.Quest> _toDomainList(List<Quest> quests) =>
      quests.map(_toDomain).toList();

  /// Filter quests by distance from user location.
  List<domain.Quest> _filterByDistance(
    List<Quest> quests,
    double lat,
    double lng,
    double radiusKm,
  ) {
    final radiusMeters = radiusKm * 1000;

    final withDistance = quests
        .map((quest) {
          final distance = DistanceCalculator.haversine(
            lat,
            lng,
            quest.latitude,
            quest.longitude,
          );
          return (quest, distance);
        })
        .where((entry) => entry.$2 <= radiusMeters)
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));

    return withDistance.map((e) => _toDomain(e.$1)).toList();
  }
}
