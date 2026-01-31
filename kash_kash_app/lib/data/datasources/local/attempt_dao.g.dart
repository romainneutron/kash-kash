// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_dao.dart';

// ignore_for_file: type=lint
mixin _$AttemptDaoMixin on DatabaseAccessor<AppDatabase> {
  $QuestAttemptsTable get questAttempts => attachedDatabase.questAttempts;
  AttemptDaoManager get managers => AttemptDaoManager(this);
}

class AttemptDaoManager {
  final _$AttemptDaoMixin _db;
  AttemptDaoManager(this._db);
  $$QuestAttemptsTableTableManager get questAttempts =>
      $$QuestAttemptsTableTableManager(_db.attachedDatabase, _db.questAttempts);
}
