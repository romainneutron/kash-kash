# Test Implementation Plan

This document tracks the implementation of all test tasks from Sprints 1-5.

## Current State (Before Implementation)

- **Flutter Tests**: 1 file (`widget_test.dart`) with 2 basic tests
- **Symfony Tests**: 0 files (only `bootstrap.php` configuration)
- **Coverage**: ~0%

## Implementation Priority

We prioritize tests based on:
1. **Foundation tests** (entities, models, utilities) - no dependencies
2. **Data layer tests** (DAOs, repositories) - depend on foundation
3. **Infrastructure tests** (services, detectors) - depend on data layer
4. **Integration tests** (use cases, providers) - depend on all above
5. **Backend tests** - independent of Flutter

---

## Phase 1: Foundation (Sprint 1)

### S1-T13: Entity Unit Tests
**Status**: [ ] TODO
**Files**:
- `test/unit/domain/entities/user_test.dart`
- `test/unit/domain/entities/quest_test.dart`
- `test/unit/domain/entities/quest_attempt_test.dart`
- `test/unit/domain/entities/path_point_test.dart`

**Tests**:
- Entity creation with valid data
- `copyWith` creates correct copies
- Enum serialization/deserialization
- Entity equality

### S1-T14: Drift Database Tests
**Status**: [ ] TODO
**File**: `test/unit/data/datasources/local/database_test.dart`

**Tests**:
- Database opens without errors
- All tables created correctly
- Basic CRUD operations work
- In-memory database works for testing

### S1-T15: Failure Classes Tests
**Status**: [ ] TODO
**File**: `test/unit/core/errors/failures_test.dart`

**Tests**:
- All failure types instantiate with messages
- Sealed class hierarchy works correctly
- toString/equality behave as expected

---

## Phase 2: Core Utilities (Sprint 3)

### S3-T10: DistanceCalculator Tests
**Status**: [ ] TODO
**File**: `test/unit/core/utils/distance_calculator_test.dart`

**Tests**:
- Paris to London ≈ 343 km (within 1km tolerance)
- Same point = 0 meters exactly
- Short distance (10m) accurate within 0.1m
- Handles antipodal points
- Handles coordinates at poles
- Handles coordinates crossing date line

---

## Phase 3: Data Layer (Sprints 1-4)

### S3-T11: QuestModel Tests
**Status**: [ ] TODO
**File**: `test/unit/data/models/quest_model_test.dart`

**Tests**:
- fromJson parses all fields correctly
- toJson produces valid JSON
- toDomain creates correct Quest entity
- Handles nullable fields

### S2-T11: SecureStorage Tests
**Status**: [ ] TODO
**File**: `test/unit/data/datasources/local/secure_storage_test.dart`

**Tests**:
- Tokens saved and retrieved correctly
- User data cached and retrieved correctly
- clearAll removes all data
- Missing keys return null

### S3-T12: QuestDao Tests
**Status**: [ ] TODO
**File**: `test/unit/data/datasources/local/quest_dao_test.dart`

**Tests**:
- getAllPublished returns only published quests
- getById returns correct quest or null
- upsert inserts new quest
- upsert updates existing quest
- batchUpsert handles multiple quests
- watchAll stream emits on changes
- deleteById removes quest

### S4-T17: AttemptDao Tests
**Status**: [ ] TODO
**File**: `test/unit/data/datasources/local/attempt_dao_test.dart`

**Tests**:
- create inserts new attempt
- getActiveForUser returns in-progress attempt
- getActiveForUser returns null when no active
- getHistoryForUser returns completed/abandoned
- getHistoryForUser excludes in-progress

---

## Phase 4: Infrastructure (Sprint 4)

### S4-T13: MovementDetector Tests
**Status**: [ ] TODO
**File**: `test/unit/infrastructure/gps/movement_detector_test.dart`

**Tests**:
- Speed < 0.5 m/s → stationary
- Speed >= 0.5 m/s → moving
- Smoothing prevents single-reading flicker
- Requires 2+ of 3 readings to change state
- Reset clears reading history
- Custom threshold works

### S4-T14: DirectionDetector Tests
**Status**: [ ] TODO
**File**: `test/unit/infrastructure/gps/direction_detector_test.dart`

**Tests**:
- Moving toward target → gettingCloser
- Moving away from target → gettingFarther
- Movement < 2m → noChange
- First reading → noChange
- Reset clears previous distance

### S4-T15: GameStateManager Tests
**Status**: [ ] TODO
**File**: `test/unit/infrastructure/gps/game_state_manager_test.dart`

**Tests**:
- Starts in initializing state
- Transitions to stationary when not moving
- Transitions to gettingCloser when approaching
- Transitions to gettingFarther when moving away
- Transitions to won when within radius
- Handles GPS errors gracefully

---

## Phase 5: Repositories (Sprints 2-3)

### S2-T12: AuthInterceptor Tests
**Status**: [ ] TODO
**File**: `test/unit/data/datasources/remote/api/auth_interceptor_test.dart`

**Tests**:
- Adds Authorization header when token exists
- Does not add header when no token
- Triggers token refresh on 401
- Retries original request after refresh
- Propagates error when refresh fails

### S2-T13: AuthRepository Tests
**Status**: [ ] TODO
**File**: `test/unit/data/repositories/auth_repository_test.dart`

**Tests**:
- signInWithGoogle stores tokens on success
- signInWithGoogle returns AuthFailure on error
- signOut clears all stored data
- getCurrentUser returns remote user when online
- getCurrentUser returns cached user when offline
- Auth state stream emits correct values

### S3-T13: QuestRepository Tests
**Status**: [ ] TODO
**File**: `test/unit/data/repositories/quest_repository_test.dart`

**Tests**:
- Returns cached data immediately
- Fetches remote data when online
- Updates cache with remote data
- Returns cached data when offline
- Handles network errors gracefully

---

## Phase 6: Use Cases (Sprint 4)

### S4-T16: UseCase Tests
**Status**: [ ] TODO
**Files**:
- `test/unit/domain/usecases/start_quest_test.dart`
- `test/unit/domain/usecases/complete_quest_test.dart`
- `test/unit/domain/usecases/abandon_quest_test.dart`

**Tests**:
- StartQuestUseCase creates attempt
- StartQuestUseCase prevents double-start
- CompleteQuestUseCase updates status
- CompleteQuestUseCase calculates duration
- AbandonQuestUseCase updates status

---

## Phase 7: Backend Tests (Sprints 2-3)

### S2-T14: Symfony AuthController Tests
**Status**: [ ] TODO
**File**: `backend/tests/Functional/Controller/AuthControllerTest.php`

**Tests**:
- `/auth/google` redirects to Google OAuth
- `/auth/google/callback` creates user if not exists
- `/auth/google/callback` returns JWT tokens
- `/auth/token/refresh` issues new access token
- `/auth/token/refresh` rejects invalid token
- `/auth/me` returns current user data
- `/auth/me` returns 401 without token

### S3-T14: Symfony NearbyQuests Tests
**Status**: [ ] TODO
**File**: `backend/tests/Functional/Controller/QuestControllerTest.php`

**Tests**:
- Returns quests within radius
- Excludes quests outside radius
- Only returns published quests
- Results sorted by distance
- Returns calculated distance_km

---

## Test Utilities to Create

### Flutter Test Helpers
- `test/helpers/test_database.dart` - In-memory Drift database
- `test/helpers/mocks.dart` - Common mocks using mocktail
- `test/helpers/fakes.dart` - Fake implementations

### Symfony Test Helpers
- `tests/Factory/UserFactory.php` - User fixtures
- `tests/Factory/QuestFactory.php` - Quest fixtures

---

## Execution Plan

```bash
# 1. Create test directory structure
mkdir -p kash_kash_app/test/{unit,helpers}
mkdir -p kash_kash_app/test/unit/{domain,data,infrastructure,core}
mkdir -p kash_kash_app/test/unit/domain/{entities,usecases}
mkdir -p kash_kash_app/test/unit/data/{models,repositories,datasources}
mkdir -p kash_kash_app/test/unit/data/datasources/{local,remote}
mkdir -p kash_kash_app/test/unit/infrastructure/gps
mkdir -p kash_kash_app/test/unit/core/{utils,errors}

mkdir -p backend/tests/Functional/Controller
mkdir -p backend/tests/Factory

# 2. Run tests incrementally
cd kash_kash_app && flutter test

# 3. Generate coverage
flutter test --coverage
```

---

## Metrics Target

| Metric | Current | Target |
|--------|---------|--------|
| Flutter Test Files | 1 | 20+ |
| Flutter Test Count | 2 | 100+ |
| Flutter Coverage | ~0% | 70%+ |
| Symfony Test Files | 0 | 5+ |
| Symfony Test Count | 0 | 30+ |
| Symfony Coverage | 0% | 75%+ |
