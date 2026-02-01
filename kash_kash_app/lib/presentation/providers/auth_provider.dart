import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kash_kash_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:kash_kash_app/data/repositories/auth_repository_impl.dart';
import 'package:kash_kash_app/domain/entities/user.dart';
import 'package:kash_kash_app/main.dart' show pendingWebAuthTokens;
import 'package:kash_kash_app/presentation/providers/api_provider.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient: apiClient);
}

@Riverpod(keepAlive: true)
AuthRepositoryImpl authRepository(Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
  );
}

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Schedule _init() to run after build completes to avoid
    // modifying state during the build phase
    Future.microtask(_init);
    return const AuthState();
  }

  Future<void> _init() async {
    state = state.copyWith(status: AuthStatus.loading);

    // Check for web OAuth callback tokens (extracted and saved in main.dart)
    // Tokens are already saved to storage, just clear the pending flag and load user
    if (pendingWebAuthTokens != null) {
      pendingWebAuthTokens = null; // Clear after use
      // Tokens already saved in main.dart, just reload state from storage
    }

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getCurrentUser();

    result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          error: failure.message,
        );
      },
      (user) {
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signInWithGoogle();

    result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          error: failure.message,
        );
      },
      (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      },
    );
  }

  Future<void> handleAuthCallback({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.handleAuthCallback(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userData: userData,
    );

    // Refresh state - _init() will properly load user and set authenticated state
    await _init();
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String getGoogleAuthUrl({String? webRedirectUri}) {
    final repo = ref.read(authRepositoryProvider);
    return repo.getGoogleAuthUrl(webRedirectUri: webRedirectUri);
  }
}

@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
}

@riverpod
bool isAdmin(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
}

@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
}
