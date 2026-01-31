import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kash_kash_app/data/repositories/auth_repository_impl.dart';
import 'package:kash_kash_app/domain/entities/user.dart';
import 'package:kash_kash_app/core/errors/failures.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/fakes.dart';

void main() {
  late MockSecureStorage mockStorage;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockStorage = MockSecureStorage();
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      secureStorage: mockStorage,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  group('AuthRepositoryImpl', () {
    group('isSignedIn', () {
      test('should return true when tokens exist', () async {
        when(() => mockStorage.hasTokens())
          .thenAnswer((_) async => true);

        final result = await repository.isSignedIn;

        expect(result, isTrue);
        verify(() => mockStorage.hasTokens()).called(1);
      });

      test('should return false when no tokens', () async {
        when(() => mockStorage.hasTokens())
          .thenAnswer((_) async => false);

        final result = await repository.isSignedIn;

        expect(result, isFalse);
      });
    });

    group('signInWithGoogle', () {
      test('should return user on successful sign in', () async {
        final userModel = FakeData.createUserModel();

        when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => userModel);
        when(() => mockStorage.saveUser(any()))
          .thenAnswer((_) async {});

        final result = await repository.signInWithGoogle();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) {
            expect(user.id, userModel.id);
            expect(user.email, userModel.email);
          },
        );

        verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
        verify(() => mockStorage.saveUser(any())).called(1);
      });

      test('should emit authenticated state on successful sign in', () async {
        final userModel = FakeData.createUserModel();

        when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => userModel);
        when(() => mockStorage.saveUser(any()))
          .thenAnswer((_) async {});

        // Listen to auth state changes
        final states = <User?>[];
        repository.authStateChanges.listen(states.add);

        await repository.signInWithGoogle();

        // Give time for stream to emit
        await Future.delayed(const Duration(milliseconds: 10));

        expect(states.length, 1);
        expect(states.first, isNotNull);
        expect(states.first!.id, userModel.id);
      });

      test('should return AuthFailure on error', () async {
        when(() => mockRemoteDataSource.getCurrentUser())
          .thenThrow(Exception('Network error'));

        final result = await repository.signInWithGoogle();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('signOut', () {
      test('should clear all stored data', () async {
        when(() => mockRemoteDataSource.logout())
          .thenAnswer((_) async {});
        when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

        final result = await repository.signOut();

        expect(result.isRight(), isTrue);
        verify(() => mockRemoteDataSource.logout()).called(1);
        verify(() => mockStorage.clearAll()).called(1);
      });

      test('should emit null state on sign out', () async {
        when(() => mockRemoteDataSource.logout())
          .thenAnswer((_) async {});
        when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

        final states = <User?>[];
        repository.authStateChanges.listen(states.add);

        await repository.signOut();

        await Future.delayed(const Duration(milliseconds: 10));

        expect(states.last, isNull);
      });

      test('should still clear local state even if remote logout fails', () async {
        when(() => mockRemoteDataSource.logout())
          .thenThrow(Exception('Network error'));
        when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

        final result = await repository.signOut();

        expect(result.isRight(), isTrue);
        verify(() => mockStorage.clearAll()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return cached user from memory if available', () async {
        final userModel = FakeData.createUserModel();

        when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => userModel);
        when(() => mockStorage.saveUser(any()))
          .thenAnswer((_) async {});

        // First call to populate memory cache
        await repository.signInWithGoogle();

        // Second call should use memory cache
        final result = await repository.getCurrentUser();

        expect(result.isRight(), isTrue);
        // Only called once (during signIn)
        verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
      });

      test('should return cached user from storage when memory cache empty', () async {
        when(() => mockStorage.getCachedUser())
          .thenAnswer((_) async => FakeData.createUserJson());

        final result = await repository.getCurrentUser();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) => expect(user, isNotNull),
        );
      });

      test('should fetch from remote when online and no cache', () async {
        final userModel = FakeData.createUserModel();

        when(() => mockStorage.getCachedUser())
          .thenAnswer((_) async => null);
        when(() => mockStorage.hasTokens())
          .thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => userModel);
        when(() => mockStorage.saveUser(any()))
          .thenAnswer((_) async {});

        final result = await repository.getCurrentUser();

        expect(result.isRight(), isTrue);
        verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
      });

      test('should return null when no tokens and no cache', () async {
        when(() => mockStorage.getCachedUser())
          .thenAnswer((_) async => null);
        when(() => mockStorage.hasTokens())
          .thenAnswer((_) async => false);

        final result = await repository.getCurrentUser();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (user) => expect(user, isNull),
        );
      });

      test('should return AuthFailure when remote fetch fails', () async {
        when(() => mockStorage.getCachedUser())
          .thenAnswer((_) async => null);
        when(() => mockStorage.hasTokens())
          .thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCurrentUser())
          .thenThrow(Exception('Network error'));

        final result = await repository.getCurrentUser();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('handleAuthCallback', () {
      test('should save tokens and user data', () async {
        when(() => mockStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
        when(() => mockStorage.saveUser(any()))
          .thenAnswer((_) async {});

        await repository.handleAuthCallback(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          userData: FakeData.createUserJson(),
        );

        verify(() => mockStorage.saveTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        )).called(1);
        verify(() => mockStorage.saveUser(any())).called(1);
      });

      test('should emit authenticated state after callback', () async {
        when(() => mockStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});
        when(() => mockStorage.saveUser(any()))
          .thenAnswer((_) async {});

        final states = <User?>[];
        repository.authStateChanges.listen(states.add);

        await repository.handleAuthCallback(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          userData: FakeData.createUserJson(),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(states.length, 1);
        expect(states.first, isNotNull);
      });
    });

    group('authStateChanges', () {
      test('should be a broadcast stream', () async {
        final listener1 = <User?>[];
        final listener2 = <User?>[];

        repository.authStateChanges.listen(listener1.add);
        repository.authStateChanges.listen(listener2.add);

        // Both listeners should receive events
        when(() => mockRemoteDataSource.logout())
          .thenAnswer((_) async {});
        when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

        await repository.signOut();

        await Future.delayed(const Duration(milliseconds: 10));

        expect(listener1.last, isNull);
        expect(listener2.last, isNull);
      });
    });
  });
}
