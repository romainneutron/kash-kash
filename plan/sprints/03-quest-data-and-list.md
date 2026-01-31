# Sprint 3: Quest Data & List

**Goal**: Implement quest data layer with offline-first sync and build the quest list screen with distance filtering.

**Deliverable**: Users can view a list of nearby quests filtered by distance, with full offline support.

**Prerequisites**: Sprint 2 completed (authentication working)

**Commit Convention**: All commits in this sprint MUST be prefixed with `sprint #3 - `

---

## Tasks

### S3-T1: Symfony Nearby Quests Endpoint
**Type**: feature
**Dependencies**: S1-T10

**Description**:
Create custom endpoint for fetching quests near a location using PostGIS.

**Acceptance Criteria**:
- [ ] `/api/quests/nearby` accepts lat, lng, radius parameters
- [ ] Uses PostGIS for efficient geospatial query
- [ ] Returns quests with calculated distance
- [ ] Only returns published quests
- [ ] Sorted by distance ascending

**Implementation**:
```php
// src/Repository/QuestRepository.php
public function findNearby(float $lat, float $lng, float $radiusKm): array
{
    $conn = $this->getEntityManager()->getConnection();

    $sql = "
        SELECT
            q.*,
            ST_DistanceSphere(
                ST_MakePoint(q.longitude, q.latitude),
                ST_MakePoint(:lng, :lat)
            ) / 1000.0 AS distance_km
        FROM quests q
        WHERE q.published = true
        AND ST_DistanceSphere(
            ST_MakePoint(q.longitude, q.latitude),
            ST_MakePoint(:lng, :lat)
        ) <= :radius_meters
        ORDER BY distance_km ASC
    ";

    return $conn->executeQuery($sql, [
        'lat' => $lat,
        'lng' => $lng,
        'radius_meters' => $radiusKm * 1000,
    ])->fetchAllAssociative();
}

// src/Controller/QuestController.php
#[Route('/api/quests/nearby', name: 'quests_nearby', methods: ['GET'])]
public function nearby(
    Request $request,
    QuestRepository $repository
): JsonResponse {
    $lat = (float) $request->query->get('lat');
    $lng = (float) $request->query->get('lng');
    $radius = (float) $request->query->get('radius', 5); // km

    $quests = $repository->findNearby($lat, $lng, $radius);

    return $this->json($quests, context: ['groups' => 'quest:read']);
}
```

---

### S3-T2: Flutter Quest Models
**Type**: feature
**Dependencies**: S1-T5, S1-T4

**Description**:
Create data layer models for Quest with mappers.

**Acceptance Criteria**:
- [x] QuestModel with fromJson/toJson
- [x] Mapper to/from domain entity
- [x] Mapper to/from Drift model
- [x] Handles nullable fields
- [x] Unit tests for mappers

**Implementation**:
```dart
class QuestModel {
  final String id;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String createdBy;
  final bool published;
  final String? difficulty;
  final String? locationType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceKm; // Transient, from API

  factory QuestModel.fromJson(Map<String, dynamic> json) => QuestModel(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 3.0,
    createdBy: json['created_by'],
    published: json['published'] ?? false,
    difficulty: json['difficulty'],
    locationType: json['location_type'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
  );

  Quest toDomain() => Quest(
    id: id,
    title: title,
    description: description,
    latitude: latitude,
    longitude: longitude,
    radiusMeters: radiusMeters,
    createdBy: createdBy,
    published: published,
    difficulty: difficulty != null
      ? QuestDifficulty.values.byName(difficulty!)
      : null,
    locationType: locationType != null
      ? LocationType.values.byName(locationType!)
      : null,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
```

---

### S3-T3: Flutter Quest Local Data Source
**Type**: feature
**Dependencies**: S3-T2, S1-T4

**Description**:
Implement Drift DAO for quests with CRUD and queries.

**Acceptance Criteria**:
- [x] Insert/update/delete quest
- [x] Get all published quests
- [x] Get quest by ID
- [x] Watch quests stream (reactive)
- [x] Batch upsert for sync
- [x] Unit tests with in-memory DB

**Implementation**:
```dart
@DriftAccessor(tables: [Quests])
class QuestDao extends DatabaseAccessor<AppDatabase> with _$QuestDaoMixin {
  QuestDao(AppDatabase db) : super(db);

  Future<List<QuestData>> getAllPublished() {
    return (select(quests)..where((q) => q.published.equals(true))).get();
  }

  Future<QuestData?> getById(String id) {
    return (select(quests)..where((q) => q.id.equals(id))).getSingleOrNull();
  }

  Stream<List<QuestData>> watchAll() {
    return (select(quests)..where((q) => q.published.equals(true))).watch();
  }

  Future<void> upsert(QuestData quest) {
    return into(quests).insertOnConflictUpdate(quest);
  }

  Future<void> batchUpsert(List<QuestData> questList) {
    return batch((batch) {
      for (final quest in questList) {
        batch.insert(quests, quest, onConflict: DoUpdate.withExcluded(
          (old, excluded) => QuestsCompanion.custom(
            title: excluded.title,
            description: excluded.description,
            latitude: excluded.latitude,
            longitude: excluded.longitude,
            published: excluded.published,
            updatedAt: excluded.updatedAt,
            syncedAt: Constant(DateTime.now()),
          ),
        ));
      }
    });
  }

  Future<void> deleteById(String id) {
    return (delete(quests)..where((q) => q.id.equals(id))).go();
  }
}
```

---

### S3-T4: Flutter Quest Remote Data Source
**Type**: feature
**Dependencies**: S3-T2, S2-T4

**Description**:
Implement API calls for quest operations.

**Acceptance Criteria**:
- [x] Fetch all published quests
- [x] Fetch nearby quests with distance
- [x] Proper error handling
- [x] Returns QuestModel list

**Implementation**:
```dart
class QuestRemoteDataSource {
  final ApiClient _apiClient;

  QuestRemoteDataSource(this._apiClient);

  Future<List<QuestModel>> getPublishedQuests() async {
    final response = await _apiClient.get('/api/quests');
    final List data = response.data['hydra:member'] ?? response.data;
    return data.map((json) => QuestModel.fromJson(json)).toList();
  }

  Future<List<QuestModel>> getNearbyQuests({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await _apiClient.get('/api/quests/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
      });
    final List data = response.data['data'];
    return data.map((json) => QuestModel.fromJson(json)).toList();
  }

  Future<QuestModel> getQuestById(String id) async {
    final response = await _apiClient.get('/api/quests/$id');
    return QuestModel.fromJson(response.data);
  }
}
```

---

### S3-T5: Flutter Quest Repository
**Type**: feature
**Dependencies**: S3-T3, S3-T4, S1-T6

**Description**:
Implement offline-first quest repository.

**Acceptance Criteria**:
- [x] Returns cached data immediately
- [x] Fetches from remote in background when online
- [x] Updates local cache with remote data
- [x] Handles offline gracefully
- [ ] Reactive stream of quests

**Implementation**:
```dart
class QuestRepositoryImpl implements IQuestRepository {
  final QuestLocalDataSource _local;
  final QuestRemoteDataSource _remote;
  final ConnectivityService _connectivity;

  @override
  Stream<List<Quest>> watchNearbyQuests({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async* {
    // Emit cached data first
    final cached = await _local.getAllPublished();
    final filtered = _filterByDistance(cached, lat, lng, radiusKm);
    yield filtered.map((q) => q.toDomain()).toList();

    // Fetch fresh data if online
    if (await _connectivity.isOnline) {
      try {
        final remote = await _remote.getNearbyQuests(
          lat: lat, lng: lng, radiusKm: radiusKm);
        await _local.batchUpsert(remote.map((q) => q.toDrift()).toList());
        yield remote.map((q) => q.toDomain()).toList();
      } catch (e) {
        // Already emitted cached, just log error
        debugPrint('Failed to fetch remote quests: $e');
      }
    }
  }

  @override
  Future<Either<Failure, Quest>> getQuestById(String id) async {
    // Try local first
    final local = await _local.getById(id);
    if (local != null) {
      return Right(local.toDomain());
    }

    // Try remote if online
    if (await _connectivity.isOnline) {
      try {
        final remote = await _remote.getQuestById(id);
        await _local.upsert(remote.toDrift());
        return Right(remote.toDomain());
      } catch (e) {
        return Left(NetworkFailure(e.toString()));
      }
    }

    return Left(CacheFailure('Quest not found'));
  }

  List<QuestData> _filterByDistance(
    List<QuestData> quests,
    double lat,
    double lng,
    double radiusKm
  ) {
    return quests.where((q) {
      final distance = DistanceCalculator.haversine(
        lat, lng, q.latitude, q.longitude);
      return distance <= radiusKm * 1000;
    }).toList();
  }
}
```

---

### S3-T6: Distance Calculator
**Type**: feature
**Dependencies**: S1-T3

**Description**:
Implement Haversine formula for GPS distance calculation.

**Acceptance Criteria**:
- [x] Returns distance in meters
- [x] Handles edge cases
- [x] Unit tests with known distances

**Implementation**:
```dart
class DistanceCalculator {
  static const double _earthRadiusMeters = 6371000;

  /// Calculate distance between two GPS coordinates in meters
  static double haversine(
    double lat1, double lng1,
    double lat2, double lng2
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
```

**Test cases**:
```dart
// Paris to London: ~343 km
expect(DistanceCalculator.haversine(48.8566, 2.3522, 51.5074, -0.1278),
  closeTo(343000, 1000));

// Same point: 0
expect(DistanceCalculator.haversine(48.8566, 2.3522, 48.8566, 2.3522),
  equals(0));
```

---

### S3-T7: GPS Service
**Type**: feature
**Dependencies**: S1-T2

**Description**:
Create GPS service wrapper with permission handling.

**Acceptance Criteria**:
- [x] Check location permissions
- [x] Request permissions
- [x] Get current location
- [x] Stream location updates
- [x] Handle GPS disabled

**Implementation**:
```dart
class GpsService {
  Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Stream<Position> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }
}
```

**Platform config**:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find quests near you</string>
```

---

### S3-T8: Quest List Provider
**Type**: feature
**Dependencies**: S3-T5, S3-T7

**Description**:
Create Riverpod provider for quest list state.

**Acceptance Criteria**:
- [x] Manages distance filter (2, 5, 10, 20 km)
- [x] Combines user location with quest data
- [x] Handles loading/error states
- [x] Shows offline indicator

**Implementation**:
```dart
enum DistanceFilter { km2, km5, km10, km20 }

extension DistanceFilterValue on DistanceFilter {
  double get kilometers => switch (this) {
    DistanceFilter.km2 => 2.0,
    DistanceFilter.km5 => 5.0,
    DistanceFilter.km10 => 10.0,
    DistanceFilter.km20 => 20.0,
  };
}

@riverpod
class QuestListNotifier extends _$QuestListNotifier {
  @override
  FutureOr<QuestListState> build() async {
    final position = await ref.watch(currentPositionProvider.future);
    final filter = ref.watch(distanceFilterNotifierProvider);

    final quests = await ref.watch(questRepositoryProvider)
      .getNearbyQuests(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: filter.kilometers,
      );

    return QuestListState(
      quests: quests,
      filter: filter,
      userPosition: position,
      isOffline: !await ref.read(connectivityProvider).isOnline,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}

@riverpod
class DistanceFilterNotifier extends _$DistanceFilterNotifier {
  @override
  DistanceFilter build() => DistanceFilter.km5;

  void setFilter(DistanceFilter filter) => state = filter;
}
```

---

### S3-T9: Quest List Screen
**Type**: feature
**Dependencies**: S3-T8, S1-T8

**Description**:
Build quest list screen with filter tabs and cards.

**Acceptance Criteria**:
- [x] Distance filter tabs (2, 5, 10, 20 km)
- [x] Quest cards with title, distance, difficulty
- [x] Pull-to-refresh
- [x] Empty state
- [x] Loading skeleton
- [x] Offline banner
- [x] Navigate to quest detail

**Implementation**:
```dart
class QuestListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questListNotifierProvider);
    final filter = ref.watch(distanceFilterNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Quests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (state.valueOrNull?.isOffline ?? false)
            const OfflineBanner(),

          // Filter tabs
          DistanceFilterTabs(
            selected: filter,
            onChanged: (f) => ref.read(distanceFilterNotifierProvider.notifier)
              .setFilter(f),
          ),

          // Quest list
          Expanded(
            child: state.when(
              loading: () => const QuestListSkeleton(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (data) => data.quests.isEmpty
                ? const EmptyQuestList()
                : RefreshIndicator(
                    onRefresh: () => ref.read(questListNotifierProvider.notifier)
                      .refresh(),
                    child: ListView.builder(
                      itemCount: data.quests.length,
                      itemBuilder: (_, i) => QuestCard(
                        quest: data.quests[i],
                        userPosition: data.userPosition,
                        onTap: () => context.push('/quest/${data.quests[i].id}/play'),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestCard extends StatelessWidget {
  final Quest quest;
  final Position userPosition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distance = DistanceCalculator.haversine(
      userPosition.latitude, userPosition.longitude,
      quest.latitude, quest.longitude,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(quest.title),
        subtitle: Text(_formatDistance(distance)),
        trailing: quest.difficulty != null
          ? DifficultyBadge(difficulty: quest.difficulty!)
          : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
```

---

## Testing & QA Tasks

### S3-T10: DistanceCalculator Tests
**Type**: test
**Dependencies**: S3-T6

**Description**:
Unit tests for Haversine distance calculation.

**Acceptance Criteria**:
- [x] Paris to London ≈ 343 km (within 1km tolerance)
- [x] Same point = 0 meters exactly
- [x] Short distance (10m) accurate within 0.1m
- [x] Handles antipodal points
- [x] Handles coordinates at poles
- [x] Handles coordinates crossing date line

**Test file**: `test/unit/core/utils/distance_calculator_test.dart`

**Example test cases**:
```dart
// Paris to London: ~343 km
expect(DistanceCalculator.haversine(48.8566, 2.3522, 51.5074, -0.1278),
  closeTo(343000, 1000));

// Same point: 0
expect(DistanceCalculator.haversine(48.8566, 2.3522, 48.8566, 2.3522),
  equals(0));

// 10 meters apart
expect(DistanceCalculator.haversine(48.8566, 2.3522, 48.8567, 2.3522),
  closeTo(10, 1));
```

---

### S3-T11: QuestModel Tests
**Type**: test
**Dependencies**: S3-T2

**Description**:
Test serialization and mapping for QuestModel.

**Acceptance Criteria**:
- [x] fromJson parses all fields correctly
- [x] toJson produces valid JSON
- [x] toDomain creates correct Quest entity
- [x] toDrift creates correct Drift companion
- [x] Handles nullable fields (description, difficulty, locationType)
- [x] Handles missing distance_km field from API

**Test file**: `test/unit/data/models/quest_model_test.dart`

---

### S3-T12: QuestDao Tests
**Type**: test
**Dependencies**: S3-T3

**Description**:
Test Drift DAO for quest operations with in-memory database.

**Acceptance Criteria**:
- [x] getAllPublished returns only published quests
- [x] getById returns correct quest or null
- [x] upsert inserts new quest
- [x] upsert updates existing quest
- [x] batchUpsert handles multiple quests
- [x] watchAll stream emits on changes
- [x] deleteById removes quest

**Test file**: `test/unit/data/datasources/local/quest_dao_test.dart`

---

### S3-T13: QuestRepository Tests
**Type**: test
**Dependencies**: S3-T5

**Description**:
Test offline-first quest repository behavior.

**Acceptance Criteria**:
- [x] Returns cached data immediately
- [x] Fetches remote data when online
- [x] Updates cache with remote data
- [x] Returns cached data when offline
- [x] Handles network errors gracefully
- [x] Stream emits cached then remote data

**Test file**: `test/unit/data/repositories/quest_repository_test.dart`

---

### S3-T14: Symfony NearbyQuests Tests
**Type**: test
**Dependencies**: S3-T1

**Description**:
Functional tests for the nearby quests endpoint.

**Acceptance Criteria**:
- [ ] Returns quests within specified radius
- [ ] Excludes quests outside radius
- [ ] Only returns published quests
- [ ] Results sorted by distance ascending
- [ ] Returns calculated distance_km for each quest
- [ ] Handles edge cases (no quests, very large radius)

**Test file**: `backend/tests/Functional/Controller/QuestControllerTest.php`

---

### S3-T15: Location Permission Test
**Type**: qa
**Dependencies**: S3-T7

**Description**:
Manually test location permission flows on both platforms.

**Acceptance Criteria**:
- [ ] First launch prompts for location permission
- [ ] Granting permission shows quest list with distances
- [ ] Denying permission shows appropriate error message
- [ ] "Don't ask again" (Android) / "Never" (iOS) shows settings guidance
- [ ] Opening settings and granting permission works

**Test on**:
- [ ] iOS (different permission model)
- [ ] Android 13+ (granular permissions)

---

### S3-T16: Quest List Manual Test
**Type**: qa
**Dependencies**: S3-T9

**Description**:
Manually verify quest list screen functionality.

**Acceptance Criteria**:
- [ ] Quest list loads with distance from user location
- [ ] Distance filter tabs work (2, 5, 10, 20 km)
- [ ] Pull-to-refresh fetches new data from server
- [ ] Empty state shows when no quests nearby
- [ ] Loading skeleton shows during initial fetch
- [ ] Quest card shows title, distance, difficulty badge

**Prerequisites**: Create 5+ test quests at various distances from test location.

---

### S3-T17: Offline Quest List Test
**Type**: qa
**Dependencies**: S3-T5

**Description**:
Verify quest list works offline with cached data.

**Acceptance Criteria**:
- [ ] Load quest list while online
- [ ] Enable airplane mode
- [ ] Kill and restart app
- [ ] Quest list shows cached quests
- [ ] Distances still displayed correctly
- [ ] Offline banner visible
- [ ] Pull-to-refresh shows offline error

---

### S3-T18: GPS Accuracy Test
**Type**: qa
**Dependencies**: S3-T7

**Description**:
Test GPS behavior in different environments.

**Acceptance Criteria**:
- [ ] Good accuracy outdoors in open area
- [ ] Reasonable accuracy in urban area with buildings
- [ ] Degraded but functional indoors
- [ ] Accuracy indicator (if shown) reflects reality

**Test locations**:
- [ ] Open park
- [ ] Urban street
- [ ] Inside building near window

---

### S3-T19: PostGIS Setup Verification
**Type**: infrastructure
**Dependencies**: S3-T1

**Description**:
Verify PostGIS works in Docker and CI environments.

**Acceptance Criteria**:
- [ ] PostGIS extension enabled in local Docker PostgreSQL
- [ ] PostGIS available in CI PostgreSQL service
- [ ] ST_DistanceSphere function works correctly
- [ ] Nearby query returns correct results

**Commands**:
```bash
# Verify in Docker
docker compose exec db psql -U kashkash -c "SELECT PostGIS_Version();"

# Test query
docker compose exec db psql -U kashkash -c "SELECT ST_DistanceSphere(ST_MakePoint(2.35, 48.85), ST_MakePoint(2.36, 48.86));"
```

---

## Sprint 3 Validation

```bash
# Backend
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/quests/nearby?lat=48.8566&lng=2.3522&radius=5"

# Flutter
flutter run --debug
# Grant location permission
# Verify quests display with distance
# Filter tabs work
# Pull-to-refresh updates list
# Turn off network - cached quests still shown
```

**Checklist**:
- [ ] PostGIS nearby query works
- [ ] Quests fetched and cached locally
- [ ] Distance calculated and displayed
- [ ] Filter tabs update list
- [ ] Works offline with cached data
- [ ] Empty state shows when no quests
- [ ] Location permission handling works

---

## Risk Notes

- GPS accuracy varies by device and environment
- First location fix can be slow
- PostGIS extension must be installed
- Distance calculation assumes spherical earth (good enough for <100km)
