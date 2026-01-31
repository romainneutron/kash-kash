import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kash_kash_app/infrastructure/storage/secure_storage.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorage secureStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorage(storage: mockStorage);
  });

  group('SecureStorage', () {
    group('saveTokens', () {
      test('should save access and refresh tokens', () async {
        when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

        await secureStorage.saveTokens(
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
        );

        verify(() => mockStorage.write(key: 'access_token', value: 'access-token-123')).called(1);
        verify(() => mockStorage.write(key: 'refresh_token', value: 'refresh-token-456')).called(1);
      });
    });

    group('getAccessToken', () {
      test('should return access token when exists', () async {
        when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'access-token-123');

        final result = await secureStorage.getAccessToken();

        expect(result, 'access-token-123');
      });

      test('should return null when no access token', () async {
        when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

        final result = await secureStorage.getAccessToken();

        expect(result, isNull);
      });
    });

    group('getRefreshToken', () {
      test('should return refresh token when exists', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refresh-token-456');

        final result = await secureStorage.getRefreshToken();

        expect(result, 'refresh-token-456');
      });

      test('should return null when no refresh token', () async {
        when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => null);

        final result = await secureStorage.getRefreshToken();

        expect(result, isNull);
      });
    });

    group('saveUser', () {
      test('should save user as JSON', () async {
        when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

        await secureStorage.saveUser({
          'id': 'user-123',
          'email': 'test@example.com',
        });

        verify(() => mockStorage.write(
          key: 'cached_user',
          value: any(named: 'value', that: contains('"id":"user-123"')),
        )).called(1);
      });
    });

    group('getCachedUser', () {
      test('should return user map when exists', () async {
        when(() => mockStorage.read(key: 'cached_user'))
          .thenAnswer((_) async => '{"id":"user-123","email":"test@example.com"}');

        final result = await secureStorage.getCachedUser();

        expect(result, isNotNull);
        expect(result!['id'], 'user-123');
        expect(result['email'], 'test@example.com');
      });

      test('should return null when no cached user', () async {
        when(() => mockStorage.read(key: 'cached_user'))
          .thenAnswer((_) async => null);

        final result = await secureStorage.getCachedUser();

        expect(result, isNull);
      });
    });

    group('clearTokens', () {
      test('should delete access and refresh tokens', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

        await secureStorage.clearTokens();

        verify(() => mockStorage.delete(key: 'access_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
      });
    });

    group('clearAll', () {
      test('should delete all stored data', () async {
        when(() => mockStorage.deleteAll())
          .thenAnswer((_) async {});

        await secureStorage.clearAll();

        verify(() => mockStorage.deleteAll()).called(1);
      });
    });

    group('hasTokens', () {
      test('should return true when access token exists and is not empty', () async {
        when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => 'valid-token');

        final result = await secureStorage.hasTokens();

        expect(result, isTrue);
      });

      test('should return false when access token is null', () async {
        when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

        final result = await secureStorage.hasTokens();

        expect(result, isFalse);
      });

      test('should return false when access token is empty', () async {
        when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => '');

        final result = await secureStorage.hasTokens();

        expect(result, isFalse);
      });
    });
  });
}
