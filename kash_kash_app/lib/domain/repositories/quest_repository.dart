import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/quest.dart';

/// Pagination parameters for list queries.
class PaginationParams {
  /// Current page number (1-indexed).
  final int page;

  /// Number of items per page.
  final int perPage;

  const PaginationParams({
    this.page = 1,
    this.perPage = 30,
  });

  /// Default pagination (first page, 30 items).
  static const defaultParams = PaginationParams();
}

/// Paginated response containing items and metadata.
class PaginatedResult<T> {
  /// The items for this page.
  final List<T> items;

  /// Total number of items across all pages.
  final int totalItems;

  /// Current page number (1-indexed).
  final int currentPage;

  /// Number of items per page.
  final int perPage;

  const PaginatedResult({
    required this.items,
    required this.totalItems,
    required this.currentPage,
    required this.perPage,
  });

  /// Total number of pages.
  int get totalPages => (totalItems / perPage).ceil();

  /// Whether there is a next page.
  bool get hasNextPage => currentPage < totalPages;

  /// Whether there is a previous page.
  bool get hasPreviousPage => currentPage > 1;
}

/// Quest repository interface
abstract class IQuestRepository {
  /// Get all published quests with optional pagination.
  ///
  /// If [pagination] is null, returns all quests (backward compatible).
  Future<Either<Failure, List<Quest>>> getPublishedQuests({
    PaginationParams? pagination,
  });

  /// Get quests near a location
  Future<Either<Failure, List<Quest>>> getNearbyQuests({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });

  /// Get a single quest by ID
  Future<Either<Failure, Quest>> getQuestById(String id);

  /// Create a new quest (admin only)
  Future<Either<Failure, Quest>> createQuest(Quest quest);

  /// Update an existing quest (admin only)
  Future<Either<Failure, Quest>> updateQuest(Quest quest);

  /// Delete a quest (admin only)
  Future<Either<Failure, Unit>> deleteQuest(String id);

  /// Get all quests (admin only, including unpublished)
  Future<Either<Failure, List<Quest>>> getAllQuests();

  /// Batch upsert quests from sync
  Future<Either<Failure, Unit>> batchUpsert(List<Quest> quests);
}
