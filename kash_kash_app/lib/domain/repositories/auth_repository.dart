import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// Authentication repository interface
abstract class IAuthRepository {
  /// Sign in with Google OAuth
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign out the current user
  Future<Either<Failure, Unit>> signOut();

  /// Get the currently authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Check if user is currently signed in
  Future<bool> get isSignedIn;
}
