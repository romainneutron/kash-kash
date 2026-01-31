import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/core/errors/failures.dart';

void main() {
  group('Failure Classes', () {
    group('NetworkFailure', () {
      test('should create with default message', () {
        const failure = NetworkFailure();

        expect(failure.message, 'Network error occurred');
        expect(failure.code, isNull);
      });

      test('should create with custom message', () {
        const failure = NetworkFailure('Connection timeout');

        expect(failure.message, 'Connection timeout');
      });

      test('toString should include message', () {
        const failure = NetworkFailure('No internet');

        expect(failure.toString(), contains('No internet'));
      });
    });

    group('ServerFailure', () {
      test('should create with message and statusCode', () {
        const failure = ServerFailure('Internal server error', statusCode: 500);

        expect(failure.message, 'Internal server error');
        expect(failure.statusCode, 500);
      });

      test('should create with message and code', () {
        const failure = ServerFailure('Rate limited', code: 'RATE_LIMIT');

        expect(failure.message, 'Rate limited');
        expect(failure.code, 'RATE_LIMIT');
      });

      test('toString should include message and code', () {
        const failure = ServerFailure('Error', code: 'ERR_001');

        final str = failure.toString();
        expect(str, contains('Error'));
        expect(str, contains('ERR_001'));
      });
    });

    group('CacheFailure', () {
      test('should create with default message', () {
        const failure = CacheFailure();

        expect(failure.message, 'Cache error occurred');
      });

      test('should create with custom message', () {
        const failure = CacheFailure('Database corrupted');

        expect(failure.message, 'Database corrupted');
      });
    });

    group('AuthFailure', () {
      test('should create with default message', () {
        const failure = AuthFailure();

        expect(failure.message, 'Authentication failed');
      });

      test('should create with custom message', () {
        const failure = AuthFailure('Invalid token');

        expect(failure.message, 'Invalid token');
      });
    });

    group('ValidationFailure', () {
      test('should create with message', () {
        const failure = ValidationFailure('Invalid email format');

        expect(failure.message, 'Invalid email format');
      });
    });

    group('NotFoundFailure', () {
      test('should create with default message', () {
        const failure = NotFoundFailure();

        expect(failure.message, 'Resource not found');
      });

      test('should create with custom message', () {
        const failure = NotFoundFailure('User not found');

        expect(failure.message, 'User not found');
      });
    });

    group('PermissionFailure', () {
      test('should create with default message', () {
        const failure = PermissionFailure();

        expect(failure.message, 'Permission denied');
      });

      test('should create with custom message', () {
        const failure = PermissionFailure('Location permission required');

        expect(failure.message, 'Location permission required');
      });
    });

    group('LocationFailure', () {
      test('should create with default message', () {
        const failure = LocationFailure();

        expect(failure.message, 'Location error occurred');
      });

      test('should create with custom message', () {
        const failure = LocationFailure('GPS disabled');

        expect(failure.message, 'GPS disabled');
      });
    });

    group('SyncFailure', () {
      test('should create with default message', () {
        const failure = SyncFailure();

        expect(failure.message, 'Sync failed');
      });

      test('should create with custom message', () {
        const failure = SyncFailure('Conflict detected');

        expect(failure.message, 'Conflict detected');
      });
    });

    group('Failure base class', () {
      test('all failures should extend Failure', () {
        const List<Failure> failures = [
          NetworkFailure(),
          ServerFailure('error'),
          CacheFailure(),
          AuthFailure(),
          ValidationFailure('error'),
          NotFoundFailure(),
          PermissionFailure(),
          LocationFailure(),
          SyncFailure(),
        ];

        for (final failure in failures) {
          expect(failure, isA<Failure>());
        }
      });

      test('toString without code should not include code part', () {
        const failure = NetworkFailure('No connection');
        final str = failure.toString();

        expect(str, 'Failure: No connection');
        expect(str, isNot(contains('code:')));
      });

      test('toString with code should include code part', () {
        const failure = ServerFailure('Error', code: 'ERR_001');
        final str = failure.toString();

        expect(str, 'Failure: Error (code: ERR_001)');
      });
    });
  });
}
