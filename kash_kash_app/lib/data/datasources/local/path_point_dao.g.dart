// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_point_dao.dart';

// ignore_for_file: type=lint
mixin _$PathPointDaoMixin on DatabaseAccessor<AppDatabase> {
  $PathPointsTable get pathPoints => attachedDatabase.pathPoints;
  PathPointDaoManager get managers => PathPointDaoManager(this);
}

class PathPointDaoManager {
  final _$PathPointDaoMixin _db;
  PathPointDaoManager(this._db);
  $$PathPointsTableTableManager get pathPoints =>
      $$PathPointsTableTableManager(_db.attachedDatabase, _db.pathPoints);
}
