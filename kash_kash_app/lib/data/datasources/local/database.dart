import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// User roles
enum UserRole { user, admin }

/// Quest difficulty levels
enum QuestDifficulty { easy, medium, hard, expert }

/// Location types for quests
enum LocationType { city, forest, park, water, mountain, indoor }

/// Attempt status
enum AttemptStatus { inProgress, completed, abandoned }

/// Users table
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get role => intEnum<UserRole>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Quests table
class Quests extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radiusMeters => real().withDefault(const Constant(3.0))();
  TextColumn get createdBy => text()();
  BoolColumn get published => boolean().withDefault(const Constant(false))();
  IntColumn get difficulty => intEnum<QuestDifficulty>().nullable()();
  IntColumn get locationType => intEnum<LocationType>().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Quest attempts table
class QuestAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get questId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get abandonedAt => dateTime().nullable()();
  IntColumn get status => intEnum<AttemptStatus>()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceWalked => real().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Path points table - GPS coordinates during attempt
class PathPoints extends Table {
  TextColumn get id => text()();
  TextColumn get attemptId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get accuracy => real()();
  RealColumn get speed => real()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table for offline operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Users, Quests, QuestAttempts, PathPoints, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kashkash.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
