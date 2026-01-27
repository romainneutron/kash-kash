# Sprint 2: Authentication

**Goal**: Implement complete Google authentication flow with JWT tokens and session persistence for offline use.

**Deliverable**:
- Users can sign in with Google on mobile app
- Backend validates OAuth and issues JWT tokens
- Session persists for offline access

**Prerequisites**: Sprint 1 completed

---

## Tasks

### S2-T1: Symfony Google OAuth Setup
**Type**: infrastructure
**Dependencies**: S1-T10, S1-T11

**Description**:
Configure Google OAuth provider in Symfony with KnpUOAuth2ClientBundle.

**Acceptance Criteria**:
- [ ] Google Cloud Console project created
- [ ] OAuth 2.0 credentials configured (web application)
- [x] KnpUOAuth2Client configured for Google
- [x] Redirect URIs set correctly
- [x] Environment variables for client ID/secret

**Configuration**:
```yaml
# config/packages/knpu_oauth2_client.yaml
knpu_oauth2_client:
    clients:
        google:
            type: google
            client_id: '%env(GOOGLE_CLIENT_ID)%'
            client_secret: '%env(GOOGLE_CLIENT_SECRET)%'
            redirect_route: connect_google_check
            redirect_params: {}
```

**Routes**:
```yaml
# config/routes.yaml
connect_google:
    path: /auth/google
    controller: App\Controller\AuthController::connectGoogle

connect_google_check:
    path: /auth/google/callback
    controller: App\Controller\AuthController::connectGoogleCheck
```

---

### S2-T2: Symfony JWT Configuration
**Type**: infrastructure
**Dependencies**: S2-T1

**Description**:
Configure LexikJWTAuthenticationBundle for token-based authentication.

**Acceptance Criteria**:
- [ ] JWT keys generated (private/public)
- [x] Token TTL configured (1 hour access, 7 days refresh)
- [x] Refresh token endpoint working
- [x] Security firewall configured

**Commands**:
```bash
php bin/console lexik:jwt:generate-keypair
```

**Configuration**:
```yaml
# config/packages/lexik_jwt_authentication.yaml
lexik_jwt_authentication:
    secret_key: '%env(resolve:JWT_SECRET_KEY)%'
    public_key: '%env(resolve:JWT_PUBLIC_KEY)%'
    pass_phrase: '%env(JWT_PASSPHRASE)%'
    token_ttl: 3600 # 1 hour

# config/packages/security.yaml
security:
    firewalls:
        api:
            pattern: ^/api
            stateless: true
            jwt: ~

        main:
            lazy: true
            custom_authenticators:
                - App\Security\GoogleAuthenticator
```

---

### S2-T3: Symfony Auth Controller
**Type**: feature
**Dependencies**: S2-T1, S2-T2

**Description**:
Create authentication controller handling Google OAuth flow and JWT issuance.

**Acceptance Criteria**:
- [x] `/auth/google` initiates OAuth flow
- [x] Callback creates/updates user in database
- [x] Returns JWT access token and refresh token
- [x] Handles new user vs existing user
- [x] Returns user profile with token

**Controller**:
```php
#[Route('/auth')]
class AuthController extends AbstractController
{
    #[Route('/google', name: 'connect_google')]
    public function connectGoogle(ClientRegistry $clientRegistry): RedirectResponse
    {
        return $clientRegistry->getClient('google')->redirect([
            'email', 'profile'
        ]);
    }

    #[Route('/google/callback', name: 'connect_google_check')]
    public function connectGoogleCheck(
        Request $request,
        ClientRegistry $clientRegistry,
        UserRepository $userRepository,
        JWTTokenManagerInterface $jwtManager
    ): JsonResponse {
        $client = $clientRegistry->getClient('google');
        $googleUser = $client->fetchUser();

        $user = $userRepository->findOneBy(['email' => $googleUser->getEmail()]);

        if (!$user) {
            $user = new User();
            $user->setEmail($googleUser->getEmail());
            $user->setDisplayName($googleUser->getName());
            $user->setAvatarUrl($googleUser->getAvatar());
            $userRepository->save($user, true);
        }

        $token = $jwtManager->create($user);
        $refreshToken = $this->generateRefreshToken($user);

        return $this->json([
            'token' => $token,
            'refresh_token' => $refreshToken,
            'user' => [
                'id' => $user->getId(),
                'email' => $user->getEmail(),
                'displayName' => $user->getDisplayName(),
                'avatarUrl' => $user->getAvatarUrl(),
                'role' => $user->getRoles()[0] ?? 'ROLE_USER',
            ]
        ]);
    }

    #[Route('/token/refresh', name: 'token_refresh', methods: ['POST'])]
    public function refreshToken(Request $request): JsonResponse
    {
        // Validate refresh token and issue new access token
    }

    #[Route('/me', name: 'get_current_user', methods: ['GET'])]
    public function me(): JsonResponse
    {
        $user = $this->getUser();
        return $this->json([
            'id' => $user->getId(),
            'email' => $user->getEmail(),
            'displayName' => $user->getDisplayName(),
            'avatarUrl' => $user->getAvatarUrl(),
            'role' => $user->getRoles()[0] ?? 'ROLE_USER',
        ]);
    }
}
```

---

### S2-T4: Flutter API Client Setup
**Type**: infrastructure
**Dependencies**: S1-T2

**Description**:
Create Dio-based API client with interceptors for authentication.

**Acceptance Criteria**:
- [ ] Dio client configured with base URL
- [ ] Auth interceptor adds JWT to requests
- [ ] Token refresh on 401 response
- [ ] Error handling for network failures
- [ ] Configurable via environment

**Implementation**:
```dart
class ApiClient {
  late final Dio _dio;
  final SecureStorage _secureStorage;

  ApiClient(this._secureStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_URL',
        defaultValue: 'http://localhost:8080'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(AuthInterceptor(_secureStorage, _dio));
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }
}

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh token
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry original request
        return handler.resolve(await _retry(err.requestOptions));
      }
    }
    handler.next(err);
  }
}
```

---

### S2-T5: Flutter Auth Remote Data Source
**Type**: feature
**Dependencies**: S2-T4

**Description**:
Create remote data source for authentication operations.

**Acceptance Criteria**:
- [ ] Initiate Google Sign-In via WebView or deep link
- [ ] Handle OAuth callback and extract tokens
- [ ] Get current user from /api/me
- [ ] Refresh token functionality
- [ ] Proper error handling

**Implementation**:
```dart
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  Future<AuthResult> signInWithGoogle() async {
    // Open Google OAuth URL in WebView
    // Capture callback with tokens
    // Return AuthResult with tokens and user
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/api/me');
    return UserModel.fromJson(response.data);
  }

  Future<TokenPair> refreshToken(String refreshToken) async {
    final response = await _apiClient.post('/auth/token/refresh',
      data: {'refresh_token': refreshToken});
    return TokenPair.fromJson(response.data);
  }
}
```

---

### S2-T6: Flutter Secure Storage
**Type**: feature
**Dependencies**: S1-T2

**Description**:
Implement secure storage for tokens and session data.

**Acceptance Criteria**:
- [ ] Store access token securely
- [ ] Store refresh token securely
- [ ] Store user data for offline access
- [ ] Clear all on logout
- [ ] Platform-appropriate encryption

**Implementation**:
```dart
class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'cached_user';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<UserModel?> getCachedUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json));
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

---

### S2-T7: Flutter Auth Repository
**Type**: feature
**Dependencies**: S2-T5, S2-T6, S1-T6

**Description**:
Implement AuthRepository combining remote and local data sources.

**Acceptance Criteria**:
- [ ] Sign in stores session in secure storage
- [ ] Sign out clears session
- [ ] getCurrentUser returns cached user when offline
- [ ] Auth state changes exposed as Stream
- [ ] Handles token expiry

**Implementation**:
```dart
class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorage _storage;
  final ConnectivityService _connectivity;

  final _authStateController = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> watchAuthState() => _authStateController.stream;

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final result = await _remote.signInWithGoogle();
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.saveUser(result.user);

      // Set Sentry user context for error tracking
      SentryService.setUser(result.user.toDomain());
      SentryService.addBreadcrumb('User signed in', category: 'auth');

      _authStateController.add(AuthState.authenticated(result.user.toDomain()));
      return Right(result.user.toDomain());
    } catch (e, stackTrace) {
      // Capture auth failures to Sentry
      await SentryService.captureException(e, stackTrace, extras: {
        'auth_method': 'google',
      });
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    // Try remote first if online
    if (await _connectivity.isOnline) {
      try {
        final user = await _remote.getCurrentUser();
        await _storage.saveUser(user);
        return Right(user.toDomain());
      } catch (_) {
        // Fall through to cache
      }
    }

    // Return cached user
    final cached = await _storage.getCachedUser();
    if (cached != null) {
      return Right(cached.toDomain());
    }
    return Left(AuthFailure('No cached user'));
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await _storage.clearAll();

    // Clear Sentry user context
    SentryService.clearUser();
    SentryService.addBreadcrumb('User signed out', category: 'auth');

    _authStateController.add(AuthState.unauthenticated());
    return const Right(null);
  }
}
```

---

### S2-T8: Flutter Auth Provider
**Type**: feature
**Dependencies**: S2-T7

**Description**:
Create Riverpod providers for auth state management.

**Acceptance Criteria**:
- [ ] authStateProvider exposes current auth state
- [ ] currentUserProvider exposes current user
- [ ] isAdminProvider derived from user role
- [ ] Loading and error states properly exposed

**Implementation**:
```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final result = await repo.getCurrentUser();
    return result.fold(
      (failure) => AuthState.unauthenticated(),
      (user) => AuthState.authenticated(user),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signInWithGoogle();
    state = AsyncData(result.fold(
      (failure) => AuthState.error(failure.message),
      (user) => AuthState.authenticated(user),
    ));
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncData(AuthState.unauthenticated());
  }
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.valueOrNull?.user;
}

@riverpod
bool isAdmin(IsAdminRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role == UserRole.admin;
}
```

---

### S2-T9: Flutter Login Screen
**Type**: feature
**Dependencies**: S2-T8, S1-T8

**Description**:
Build the complete login screen with Google Sign-In.

**Acceptance Criteria**:
- [ ] App logo and title displayed
- [ ] "Sign in with Google" button styled correctly
- [ ] Loading overlay during sign-in
- [ ] Error messages displayed on failure
- [ ] Successful sign-in navigates to quest list
- [ ] Responsive for different device sizes

**Implementation**:
```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 24),

            // Title
            Text('Kash-Kash',
              style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 48),

            // Error message
            if (authState.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(authState.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),

            // Sign in button
            authState.isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: () => ref.read(authNotifierProvider.notifier)
                    .signInWithGoogle(),
                  icon: Image.asset('assets/images/google_logo.png', height: 24),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
```

---

### S2-T10: Flutter Router Auth Guards
**Type**: feature
**Dependencies**: S2-T8, S1-T7

**Description**:
Update router with real authentication guards.

**Acceptance Criteria**:
- [ ] Unauthenticated users redirected to /login
- [ ] Authenticated users redirected away from /login
- [ ] Non-admin users redirected away from /admin/*
- [ ] Auth state changes trigger route reevaluation

**Implementation**:
```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authNotifierProvider.notifier).stream),
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isAdmin = authState.valueOrNull?.user?.role == UserRole.admin;
      final isLoginRoute = state.matchedLocation == '/login';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated && isLoginRoute) {
        return '/quests';
      }
      if (isAdminRoute && !isAdmin) {
        return '/quests';
      }
      return null;
    },
    routes: [...],
  );
});
```

---

## Sprint 2 Validation

```bash
# Backend
curl http://localhost:8080/auth/google  # Should redirect to Google
# Complete OAuth flow in browser
# Verify JWT token returned

# Flutter
flutter run --debug
# Tap Sign in with Google
# Complete OAuth flow
# Verify navigation to quest list
# Kill and restart app - verify still logged in
# Verify admin routes blocked for non-admin
```

**Checklist**:
- [ ] Google OAuth flow completes successfully
- [ ] JWT tokens issued and stored
- [ ] User created in database
- [ ] App persists session across restarts
- [ ] Offline access works with cached session
- [ ] Sign out clears session
- [ ] Admin routes protected

---

## Risk Notes

- Google OAuth setup requires correct redirect URIs
- iOS may need additional URL scheme configuration
- SHA-1 fingerprint required for Android
- WebView approach for OAuth may have UX issues on some devices
- Token refresh timing needs careful handling
