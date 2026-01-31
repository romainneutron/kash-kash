import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart';

/// Creates an in-memory database for testing
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(
    NativeDatabase.memory(),
  );
}
