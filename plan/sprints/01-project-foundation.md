# Sprint 1: Project Foundation

**Goal**: Establish the Flutter project skeleton and Symfony backend with all dependencies, database schema, and basic navigation working.

**Deliverable**:
- A Flutter app that compiles on iOS/Android with placeholder screens, Drift database initialized, and navigation working
- A Symfony backend with Docker, PostgreSQL, and basic API structure

**Prerequisites**: None (greenfield project)

---

## Tasks

### S1-T1: Flutter Project Initialization
**Type**: infrastructure
**Dependencies**: None

**Description**:
Create a new Flutter project with the correct package name, minimum SDK versions, and basic project structure.

**Acceptance Criteria**:
- [x] Flutter project created with package name `com.kashkash.app`
- [x] Minimum iOS version set to 13.0
- [x] Minimum Android SDK set to 21, target SDK 34
- [x] Project compiles and runs on both iOS simulator and Android emulator
- [x] `.gitignore` properly configured for Flutter

**Commands**:
```bash
flutter create --org com.kashkash kash_kash_app
cd kash_kash_app
flutter run --debug
flutter build apk --debug
flutter build ios --debug --no-codesign
```

**Files Affected**:
- `pubspec.yaml`
- `android/app/build.gradle`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Podfile`

---

### S1-T2: Flutter Core Dependencies
**Type**: infrastructure
**Dependencies**: S1-T1

**Description**:
Add all required dependencies to pubspec.yaml and configure them.

**Acceptance Criteria**:
- [x] All dependencies added with compatible versions
- [x] `flutter pub get` succeeds without conflicts
- [x] Drift build_runner configuration in place
- [x] Riverpod ProviderScope added to main.dart

**pubspec.yaml dependencies**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  flutter_secure_storage: ^9.0.0
  geolocator: ^12.0.0
  dio: ^5.4.0
  google_sign_in: ^6.2.0
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
  uuid: ^4.4.0
  connectivity_plus: ^6.0.0
  fpdart: ^1.1.0
  wakelock_plus: ^1.2.0
  workmanager: ^0.5.2  # Background sync tasks
  sentry_flutter: ^8.0.0  # Error tracking & performance monitoring
  aptabase_flutter: ^0.1.0  # Privacy-first product analytics

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.0
  riverpod_lint: ^2.3.0
  mocktail: ^1.0.0
```

**Commands**:
```bash
flutter pub get
flutter pub deps
dart run build_runner build
```

---

### S1-T3: Flutter Folder Structure
**Type**: infrastructure
**Dependencies**: S1-T1

**Description**:
Create the complete folder structure for clean architecture.

**Acceptance Criteria**:
- [ ] All folders created as per architecture diagram
- [ ] Core barrel exports created
- [ ] Structure follows clean architecture separation

**Structure**:
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── extensions/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── datasources/local/
│   ├── datasources/remote/
│   ├── models/
│   └── repositories/
├── infrastructure/
│   ├── gps/
│   ├── sync/
│   └── background/
├── presentation/
│   ├── providers/
│   ├── screens/
│   ├── widgets/
│   └── theme/
└── router/
```

---

### S1-T4: Drift Database Schema
**Type**: infrastructure
**Dependencies**: S1-T2, S1-T3

**Description**:
Implement the complete Drift database schema with all tables and DAOs.

**Acceptance Criteria**:
- [ ] All 6 tables defined (users, quests, quest_attempts, path_points, analytics_events, sync_queue)
- [ ] Foreign key relationships correctly defined
- [ ] DAOs created for each table
- [ ] Database class generated successfully
- [ ] Database opens without errors

**Tables**:
```dart
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get role => intEnum<UserRole>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Quests extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radiusMeters => real().withDefault(const Constant(3.0))();
  TextColumn get createdBy => text()();
  BoolColumn get published => boolean().withDefault(const Constant(false))();
  IntColumn get difficulty => intEnum<QuestDifficulty>().nullable()();
  IntColumn get locationType => intEnum<LocationType>().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuestAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get questId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get abandonedAt => dateTime().nullable()();
  IntColumn get status => intEnum<AttemptStatus>()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceWalked => real().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PathPoints extends Table {
  TextColumn get id => text()();
  TextColumn get attemptId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get accuracy => real()();
  RealColumn get speed => real()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Note: Analytics tracked via Aptabase (privacy-first), no local storage needed

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
}
```

**Commands**:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/data/datasources/local/database_test.dart
```

---

### S1-T5: Domain Entities
**Type**: feature
**Dependencies**: S1-T3

**Description**:
Create all domain entities as immutable Dart classes.

**Acceptance Criteria**:
- [ ] User, Quest, QuestAttempt, Position, PathPoint, AnalyticsEvent entities
- [ ] All enums defined
- [ ] Entities are immutable (final fields)
- [ ] `copyWith` methods where needed
- [ ] Unit tests for entity creation

**Entities**:
```dart
// lib/domain/entities/user.dart
class User {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({...});
  User copyWith({...});
}

enum UserRole { user, admin }
enum QuestDifficulty { easy, medium, hard, expert }
enum LocationType { city, forest, park, water, mountain, indoor }
enum AttemptStatus { inProgress, completed, abandoned }
enum AnalyticsEventType { questStarted, questCompleted, questAbandoned, appOpened }
```

---

### S1-T6: Repository Interfaces
**Type**: feature
**Dependencies**: S1-T5

**Description**:
Define abstract repository interfaces for data access.

**Acceptance Criteria**:
- [ ] IAuthRepository, IQuestRepository, IAttemptRepository, IAnalyticsRepository, ISyncRepository
- [ ] Methods return `Future<Either<Failure, T>>` or `Stream<T>`
- [ ] Failure classes defined

**Failure types**:
```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure { ... }
class CacheFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class ServerFailure extends Failure { ... }
```

---

### S1-T7: App Router Setup
**Type**: feature
**Dependencies**: S1-T2, S1-T3

**Description**:
Configure go_router with all routes and placeholder screens.

**Acceptance Criteria**:
- [ ] GoRouter configured with all routes
- [ ] Placeholder screens for each route
- [ ] Route guards structure (mock for now)
- [ ] Navigation works between screens

**Routes**:
```dart
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/quests', builder: (_, __) => QuestListScreen()),
    GoRoute(path: '/quest/:id/play', builder: (_, state) =>
      ActiveQuestScreen(questId: state.pathParameters['id']!)),
    GoRoute(path: '/history', builder: (_, __) => QuestHistoryScreen()),
    GoRoute(path: '/admin/quests', builder: (_, __) => AdminQuestListScreen()),
    GoRoute(path: '/admin/quests/new', builder: (_, __) => QuestEditScreen()),
    GoRoute(path: '/admin/quests/:id/edit', builder: (_, state) =>
      QuestEditScreen(questId: state.pathParameters['id'])),
  ],
);
```

---

### S1-T8: Theme and Core UI
**Type**: feature
**Dependencies**: S1-T3

**Description**:
Create app theme and core reusable widgets.

**Acceptance Criteria**:
- [ ] Light and dark themes defined
- [ ] LoadingOverlay, ErrorView, OfflineBanner widgets
- [ ] App colors defined (black, red, blue for gameplay)

**Colors**:
```dart
class AppColors {
  static const Color black = Color(0xFF000000);      // Stationary
  static const Color red = Color(0xFFFF0000);        // Getting closer
  static const Color blue = Color(0xFF0000FF);       // Getting farther
  static const Color success = Color(0xFF4CAF50);    // Win
}
```

---

### S1-T9: Sentry Flutter Integration
**Type**: infrastructure
**Dependencies**: S1-T2

**Description**:
Configure Sentry for Flutter error tracking and performance monitoring from day one.

**Acceptance Criteria**:
- [ ] Sentry project created (Flutter platform)
- [ ] sentry_flutter package configured
- [ ] App wrapped with Sentry initialization
- [ ] Test error captured successfully
- [ ] Environment separation (dev/prod)

**Implementation**:
```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '', // Empty in dev = disabled
      );
      options.environment = const String.fromEnvironment(
        'ENV',
        defaultValue: 'development',
      );
      options.release = 'kash-kash@1.0.0'; // Update per release

      // Performance monitoring
      options.tracesSampleRate = 0.2; // 20% of transactions
      options.profilesSampleRate = 0.1; // 10% of traces get profiled

      // Only send in release mode
      options.beforeSend = (event, hint) {
        if (kDebugMode) return null; // Don't send in debug
        return event;
      };
    },
    appRunner: () => runApp(
      ProviderScope(child: const KashKashApp()),
    ),
  );
}

// lib/core/monitoring/sentry_service.dart
class SentryService {
  /// Set user context after login
  static void setUser(User user) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: user.id,
        email: user.email,
        username: user.displayName,
      ));
    });
  }

  /// Clear user on logout
  static void clearUser() {
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Add breadcrumb for debugging
  static void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  /// Tag current quest for error context
  static void setQuestContext(Quest quest) {
    Sentry.configureScope((scope) {
      scope.setTag('quest_id', quest.id);
      scope.setTag('quest_title', quest.title);
    });
  }

  /// Capture exception with context
  static Future<void> captureException(
    dynamic exception,
    StackTrace? stackTrace, {
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: extras != null
        ? (scope) {
            extras.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
        : null,
    );
  }
}
```

**Commands**:
```bash
# Test error capture
flutter run --dart-define=SENTRY_DSN=https://xxx@sentry.io/xxx
# Trigger test error in app, verify in Sentry dashboard
```

---

### S1-T10: Symfony Project Bootstrap
**Type**: infrastructure
**Dependencies**: None

**Description**:
Create Symfony project with Docker setup and required bundles.

**Acceptance Criteria**:
- [ ] Symfony 7 project created
- [ ] Docker Compose with PHP 8.3, PostgreSQL 16, Nginx
- [ ] API Platform installed and configured
- [ ] JWT authentication bundle installed
- [ ] OAuth2 client bundle installed
- [ ] Sentry bundle installed
- [ ] Project runs with `docker compose up`

**Commands**:
```bash
composer create-project symfony/skeleton backend
cd backend
composer require api
composer require lexik/jwt-authentication-bundle
composer require knpuniversity/oauth2-client-bundle
composer require league/oauth2-google
composer require doctrine/doctrine-bundle
composer require symfony/security-bundle
composer require sentry/sentry-symfony
```

**docker-compose.yml**:
```yaml
version: '3.8'
services:
  php:
    build: ./docker/php
    volumes:
      - ./:/var/www/html
    depends_on:
      - db

  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./:/var/www/html
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php

  db:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_DB: kashkash
      POSTGRES_USER: kashkash
      POSTGRES_PASSWORD: secret
    volumes:
      - db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  db_data:
```

---

### S1-T11: Symfony Entity Definitions
**Type**: feature
**Dependencies**: S1-T10 (Symfony Project Bootstrap)

**Description**:
Create Doctrine entities with API Platform attributes.

**Acceptance Criteria**:
- [ ] User, Quest, QuestAttempt, PathPoint, AnalyticsEvent entities
- [ ] API Platform annotations for automatic API generation
- [ ] Proper relationships defined
- [ ] Migrations generated and run

**User Entity**:
```php
#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
#[ApiResource(
    operations: [
        new Get(security: "is_granted('ROLE_USER') and object == user"),
        new GetCollection(security: "is_granted('ROLE_ADMIN')"),
    ]
)]
class User implements UserInterface
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid')]
    private Uuid $id;

    #[ORM\Column(length: 180, unique: true)]
    private string $email;

    #[ORM\Column(length: 255)]
    private string $displayName;

    #[ORM\Column(length: 255, nullable: true)]
    private ?string $avatarUrl = null;

    #[ORM\Column(type: 'json')]
    private array $roles = ['ROLE_USER'];

    #[ORM\Column]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column]
    private \DateTimeImmutable $updatedAt;
}
```

**Quest Entity**:
```php
#[ORM\Entity(repositoryClass: QuestRepository::class)]
#[ORM\Table(name: 'quests')]
#[ApiResource(
    operations: [
        new Get(),
        new GetCollection(),
        new Post(security: "is_granted('ROLE_ADMIN')"),
        new Put(security: "is_granted('ROLE_ADMIN')"),
        new Delete(security: "is_granted('ROLE_ADMIN')"),
    ]
)]
class Quest
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid')]
    private Uuid $id;

    #[ORM\Column(length: 255)]
    private string $title;

    #[ORM\Column(type: 'text', nullable: true)]
    private ?string $description = null;

    #[ORM\Column(type: 'float')]
    private float $latitude;

    #[ORM\Column(type: 'float')]
    private float $longitude;

    #[ORM\Column(type: 'float')]
    private float $radiusMeters = 3.0;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: false)]
    private User $createdBy;

    #[ORM\Column]
    private bool $published = false;

    #[ORM\Column(length: 20, nullable: true)]
    private ?string $difficulty = null;

    #[ORM\Column(length: 20, nullable: true)]
    private ?string $locationType = null;

    #[ORM\Column]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column]
    private \DateTimeImmutable $updatedAt;
}
```

**Commands**:
```bash
php bin/console make:migration
php bin/console doctrine:migrations:migrate
```

---

### S1-T12: Sentry Symfony Integration
**Type**: infrastructure
**Dependencies**: S1-T10

**Description**:
Configure Sentry for Symfony error tracking and performance monitoring.

**Acceptance Criteria**:
- [ ] Sentry project created (Symfony platform)
- [ ] sentry-symfony bundle configured
- [ ] Automatic error capture working
- [ ] Performance tracing enabled
- [ ] Environment separation (dev/prod)
- [ ] User context middleware added

**Configuration**:
```yaml
# config/packages/sentry.yaml
when@prod:
    sentry:
        dsn: '%env(SENTRY_DSN)%'
        register_error_listener: true
        register_error_handler: true
        options:
            environment: '%kernel.environment%'
            release: '%env(APP_VERSION)%'
            traces_sample_rate: 0.2
            profiles_sample_rate: 0.1
            send_default_pii: false

when@dev:
    sentry:
        dsn: '' # Disabled in dev
```

```yaml
# .env
SENTRY_DSN=https://xxx@sentry.io/xxx
APP_VERSION=1.0.0
```

**User Context Subscriber**:
```php
// src/EventSubscriber/SentryUserSubscriber.php
<?php

namespace App\EventSubscriber;

use Sentry\State\Scope;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\Security\Core\Authentication\Token\Storage\TokenStorageInterface;
use function Sentry\configureScope;

class SentryUserSubscriber implements EventSubscriberInterface
{
    public function __construct(
        private TokenStorageInterface $tokenStorage,
    ) {}

    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::REQUEST => ['onKernelRequest', 5],
        ];
    }

    public function onKernelRequest(RequestEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $token = $this->tokenStorage->getToken();
        if (!$token) {
            return;
        }

        $user = $token->getUser();
        if (!$user instanceof \App\Entity\User) {
            return;
        }

        configureScope(function (Scope $scope) use ($user): void {
            $scope->setUser([
                'id' => $user->getId(),
                'email' => $user->getEmail(),
                'username' => $user->getDisplayName(),
            ]);
        });
    }
}
```

**Performance Tracing** (automatic with sentry-symfony):
```yaml
# config/packages/sentry.yaml
sentry:
    tracing:
        enabled: true
        dbal:      # Doctrine queries
            enabled: true
        cache:     # Cache operations
            enabled: true
        twig:      # Template rendering
            enabled: true
        http_client: # Outgoing HTTP
            enabled: true
```

**Custom Span Example**:
```php
// For custom performance spans
use function Sentry\startTransaction;
use function Sentry\SentrySdk;

$transaction = startTransaction([
    'name' => 'POST /api/sync/push',
    'op' => 'http.server',
]);

SentrySdk::getCurrentHub()->setSpan($transaction);

// ... do work ...

$span = $transaction->startChild([
    'op' => 'db.query',
    'description' => 'Batch insert path points',
]);
// ... db work ...
$span->finish();

$transaction->finish();
```

**Commands**:
```bash
# Test error capture
php bin/console sentry:test
# Verify in Sentry dashboard
```

---

## Sprint 1 Validation

```bash
# Flutter
flutter test
flutter run --debug
flutter analyze

# Backend
docker compose up -d
docker compose exec php bin/console doctrine:migrations:migrate
curl http://localhost:8080/api

# Sentry verification
php bin/console sentry:test  # Backend
# Flutter: trigger test error in debug mode with SENTRY_DSN set
```

**Checklist**:
- [ ] Flutter app compiles and runs
- [ ] Can navigate between placeholder screens
- [ ] Drift database initializes without errors
- [ ] Symfony API responds at /api
- [ ] Database migrations run successfully
- [ ] No analyzer warnings
- [ ] Sentry captures test error from Symfony
- [ ] Sentry captures test error from Flutter

---

## Risk Notes

- Drift code generation may have compatibility issues with newest Flutter versions
- iOS configuration requires valid development team for device testing
- Docker setup may need adjustments for M1/M2 Macs
- PostGIS extension requires special Docker image
- Sentry free tier limited to 5K events/month - sufficient for development
