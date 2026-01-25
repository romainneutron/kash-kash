import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/quest.dart';

/// Quest repository interface
abstract class IQuestRepository {
  /// Get all published quests
  Future<Either<Failure, List<Quest>>> getPublishedQuests();

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
