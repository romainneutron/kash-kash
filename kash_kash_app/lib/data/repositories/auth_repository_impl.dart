import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:kash_kash_app/data/models/user_model.dart';
import 'package:kash_kash_app/domain/entities/user.dart';
import 'package:kash_kash_app/domain/repositories/auth_repository.dart';
import 'package:kash_kash_app/infrastructure/storage/secure_storage.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorage secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<bool> get isSignedIn async {
    return _secureStorage.hasTokens();
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    // Note: Google Sign-In flow is handled via WebView/browser
    // This method is called after tokens are saved from the OAuth callback
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      _currentUser = userModel.toDomain();
      _authStateController.add(_currentUser);

      await _secureStorage.saveUser(userModel.toJson());

      return Right(_currentUser!);
    } catch (e) {
      return Left(AuthFailure('Failed to complete sign in: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDataSource.logout();
      await _secureStorage.clearAll();

      _currentUser = null;
      _authStateController.add(null);

      return const Right(unit);
    } catch (e) {
      // Still clear local state even if remote logout fails
      await _secureStorage.clearAll();
      _currentUser = null;
      _authStateController.add(null);

      return const Right(unit);
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    // Return cached user if available
    if (_currentUser != null) {
      return Right(_currentUser);
    }

    // Try to get cached user from storage
    final cachedUser = await _secureStorage.getCachedUser();
    if (cachedUser != null) {
      _currentUser = UserModel.fromJson(cachedUser).toDomain();
      return Right(_currentUser);
    }

    // Try to fetch from remote if we have tokens
    final hasTokens = await _secureStorage.hasTokens();
    if (!hasTokens) {
      return const Right(null);
    }

    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      _currentUser = userModel.toDomain();
      await _secureStorage.saveUser(userModel.toJson());
      return Right(_currentUser);
    } catch (e) {
      return Left(AuthFailure('Failed to get current user: $e'));
    }
  }

  String getGoogleAuthUrl() {
    return _remoteDataSource.getGoogleAuthUrl();
  }

  Future<void> handleAuthCallback({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    await _secureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _secureStorage.saveUser(userData);

    _currentUser = UserModel.fromJson(userData).toDomain();
    _authStateController.add(_currentUser);
  }

  void dispose() {
    _authStateController.close();
  }
}
