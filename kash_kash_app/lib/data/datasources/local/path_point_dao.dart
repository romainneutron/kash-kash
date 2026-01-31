import 'package:drift/drift.dart';

import '../../../core/utils/distance_calculator.dart';
import 'database.dart';

part 'path_point_dao.g.dart';

/// Data Access Object for PathPoint operations.
@DriftAccessor(tables: [PathPoints])
class PathPointDao extends DatabaseAccessor<AppDatabase>
    with _$PathPointDaoMixin {
  PathPointDao(super.db);

  /// Get all path points.
  Future<List<PathPoint>> getAll() {
    return select(pathPoints).get();
  }

  /// Get path point by ID.
  Future<PathPoint?> getById(String id) {
    return (select(pathPoints)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get all path points for an attempt, ordered by timestamp.
  Future<List<PathPoint>> getForAttempt(String attemptId) {
    return (select(pathPoints)
          ..where((p) => p.attemptId.equals(attemptId))
          ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
        .get();
  }

  /// Watch path points for an attempt.
  Stream<List<PathPoint>> watchForAttempt(String attemptId) {
    return (select(pathPoints)
          ..where((p) => p.attemptId.equals(attemptId))
          ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
        .watch();
  }

  /// Add a new path point.
  Future<void> add(PathPoint point) {
    return into(pathPoints).insert(point);
  }

  /// Batch add multiple path points.
  Future<void> addBatch(List<PathPoint> points) async {
    await batch((batch) {
      batch.insertAll(pathPoints, points);
    });
  }

  /// Insert or update a path point.
  Future<void> upsert(PathPoint point) {
    return into(pathPoints).insertOnConflictUpdate(point);
  }

  /// Delete path point by ID.
  Future<int> deleteById(String id) {
    return (delete(pathPoints)..where((p) => p.id.equals(id))).go();
  }

  /// Delete all path points for an attempt.
  Future<int> deleteForAttempt(String attemptId) {
    return (delete(pathPoints)..where((p) => p.attemptId.equals(attemptId)))
        .go();
  }

  /// Delete all path points.
  Future<int> deleteAll() {
    return delete(pathPoints).go();
  }

  /// Count path points for an attempt.
  Future<int> countForAttempt(String attemptId) async {
    final query = selectOnly(pathPoints)
      ..addColumns([pathPoints.id.count()])
      ..where(pathPoints.attemptId.equals(attemptId));
    final result = await query.getSingle();
    return result.read(pathPoints.id.count()) ?? 0;
  }

  /// Calculate total distance walked for an attempt.
  Future<double> calculateTotalDistance(String attemptId) async {
    final points = await getForAttempt(attemptId);
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += DistanceCalculator.haversine(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return total;
  }

  /// Mark path point as synced.
  Future<bool> markSynced(String id) {
    return (update(pathPoints)..where((p) => p.id.equals(id)))
        .write(const PathPointsCompanion(synced: Value(true)))
        .then((rows) => rows > 0);
  }

  /// Get unsynced path points.
  Future<List<PathPoint>> getUnsynced() {
    return (select(pathPoints)..where((p) => p.synced.equals(false))).get();
  }

  /// Get unsynced path points for an attempt.
  Future<List<PathPoint>> getUnsyncedForAttempt(String attemptId) {
    return (select(pathPoints)
          ..where((p) => p.attemptId.equals(attemptId))
          ..where((p) => p.synced.equals(false)))
        .get();
  }
}
