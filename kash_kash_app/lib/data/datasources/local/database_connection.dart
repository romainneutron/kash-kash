import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the database connection using drift_flutter (works on all platforms).
QueryExecutor openConnection() {
  return driftDatabase(name: 'kashkash');
}
