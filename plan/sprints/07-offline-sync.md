# Sprint 7: Offline Sync

**Goal**: Implement bidirectional sync engine for reliable offline-first operation.

**Deliverable**: App syncs data reliably when connection is restored, handles conflicts, and provides sync status feedback.

**Prerequisites**: Sprint 6 completed (all features working locally)

---

## Tasks

### S7-T1: Connectivity Monitor
**Type**: infrastructure
**Dependencies**: S1-T2

**Description**:
Create service to monitor network connectivity state.

**Acceptance Criteria**:
- [ ] Check if online/offline
- [ ] Stream connectivity changes
- [ ] Handle WiFi vs cellular
- [ ] Debounce rapid changes

**Implementation**:
```dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<bool> get onlineStream {
    return _connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none))
      .distinct();
  }
}

@riverpod
ConnectivityService connectivityService(ConnectivityServiceRef ref) {
  return ConnectivityService();
}

@riverpod
Stream<bool> isOnline(IsOnlineRef ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
}
```

---

### S7-T2: Sync Queue Manager
**Type**: feature
**Dependencies**: S1-T4

**Description**:
Manage queue of pending sync operations.

**Acceptance Criteria**:
- [ ] Add operations to queue
- [ ] Get pending operations
- [ ] Mark operations processed
- [ ] Retry failed operations
- [ ] Clear old processed items

**Implementation**:
```dart
enum SyncOperation { insert, update, delete }

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {

  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) {
    return into(syncQueue).insert(SyncQueueCompanion.insert(
      tableName: tableName,
      recordId: recordId,
      operation: operation.name,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    ));
  }

  Future<List<SyncQueueData>> getPending({int limit = 50}) {
    return (select(syncQueue)
      ..where((q) => q.processed.equals(false))
      ..orderBy([(q) => OrderingTerm.asc(q.createdAt)])
      ..limit(limit)
    ).get();
  }

  Future<void> markProcessed(int id) {
    return (update(syncQueue)..where((q) => q.id.equals(id)))
      .write(const SyncQueueCompanion(processed: Value(true)));
  }

  Future<void> markFailed(int id, String error) {
    // Keep in queue for retry, could add retry count
    return (update(syncQueue)..where((q) => q.id.equals(id)))
      .write(SyncQueueCompanion(
        // Add error field if needed
      ));
  }

  Future<void> cleanupOld({Duration maxAge = const Duration(days: 7)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    return (delete(syncQueue)
      ..where((q) => q.processed.equals(true))
      ..where((q) => q.createdAt.isSmallerThanValue(cutoff))
    ).go();
  }
}
```

---

### S7-T3: Symfony Sync Endpoints
**Type**: feature
**Dependencies**: S1-T10

**Description**:
Create sync endpoints for pull/push operations.

**Acceptance Criteria**:
- [ ] POST `/api/sync/pull` returns records updated since timestamp
- [ ] POST `/api/sync/push` accepts batch of changes
- [ ] Returns sync results with conflicts
- [ ] Handles all entity types

**Implementation**:
```php
// src/Controller/SyncController.php
#[Route('/api/sync')]
class SyncController extends AbstractController
{
    #[Route('/pull', name: 'sync_pull', methods: ['POST'])]
    public function pull(
        Request $request,
        QuestRepository $questRepo,
        EntityManagerInterface $em
    ): JsonResponse {
        $data = json_decode($request->getContent(), true);
        $since = new \DateTimeImmutable($data['since'] ?? '1970-01-01');
        $user = $this->getUser();

        // Get updated quests (published only for regular users)
        $quests = $questRepo->findUpdatedSince($since);

        // Get user's attempts updated since
        $attempts = $em->getRepository(QuestAttempt::class)
            ->findBy([
                'user' => $user,
                // 'updatedAt >= $since' - custom query needed
            ]);

        return $this->json([
            'quests' => $quests,
            'attempts' => $attempts,
            'sync_timestamp' => (new \DateTimeImmutable())->format('c'),
        ]);
    }

    #[Route('/push', name: 'sync_push', methods: ['POST'])]
    public function push(
        Request $request,
        EntityManagerInterface $em
    ): JsonResponse {
        $data = json_decode($request->getContent(), true);
        $user = $this->getUser();
        $results = [];

        // Process attempts
        foreach ($data['attempts'] ?? [] as $attemptData) {
            try {
                $existing = $em->find(QuestAttempt::class, $attemptData['id']);

                if ($existing) {
                    // Conflict resolution: last-write-wins by timestamp
                    $localUpdated = new \DateTimeImmutable($attemptData['updated_at']);
                    if ($localUpdated > $existing->getUpdatedAt()) {
                        $this->updateAttempt($existing, $attemptData);
                    }
                    $results['attempts'][] = [
                        'id' => $attemptData['id'],
                        'status' => 'merged'
                    ];
                } else {
                    $attempt = $this->createAttempt($attemptData, $user, $em);
                    $em->persist($attempt);
                    $results['attempts'][] = [
                        'id' => $attemptData['id'],
                        'status' => 'created'
                    ];
                }
            } catch (\Exception $e) {
                $results['attempts'][] = [
                    'id' => $attemptData['id'],
                    'status' => 'error',
                    'message' => $e->getMessage()
                ];
            }
        }

        // Process analytics events
        foreach ($data['analytics'] ?? [] as $eventData) {
            try {
                $event = new AnalyticsEvent();
                $event->setId(Uuid::fromString($eventData['id']));
                $event->setUser($user);
                $event->setEventType($eventData['event_type']);
                $event->setEventData($eventData['event_data']);
                $event->setTimestamp(new \DateTimeImmutable($eventData['timestamp']));
                $em->persist($event);
                $results['analytics'][] = ['id' => $eventData['id'], 'status' => 'ok'];
            } catch (\Exception $e) {
                $results['analytics'][] = [
                    'id' => $eventData['id'],
                    'status' => 'error',
                    'message' => $e->getMessage()
                ];
            }
        }

        // Process path points
        foreach ($data['path_points'] ?? [] as $pointData) {
            try {
                $point = new PathPoint();
                $point->setId(Uuid::fromString($pointData['id']));
                $point->setAttempt($em->getReference(
                    QuestAttempt::class, $pointData['attempt_id']));
                $point->setLatitude($pointData['latitude']);
                $point->setLongitude($pointData['longitude']);
                $point->setTimestamp(new \DateTimeImmutable($pointData['timestamp']));
                $point->setAccuracy($pointData['accuracy']);
                $point->setSpeed($pointData['speed']);
                $em->persist($point);
                $results['path_points'][] = ['id' => $pointData['id'], 'status' => 'ok'];
            } catch (\Exception $e) {
                // Ignore duplicate path points
            }
        }

        $em->flush();

        return $this->json([
            'results' => $results,
            'sync_timestamp' => (new \DateTimeImmutable())->format('c'),
        ]);
    }
}
```

---

### S7-T4: Sync Engine
**Type**: feature
**Dependencies**: S7-T1, S7-T2, S7-T3

**Description**:
Create main sync engine orchestrating all sync operations.

**Acceptance Criteria**:
- [ ] Pull new data from server
- [ ] Push pending local changes
- [ ] Handle conflicts (last-write-wins)
- [ ] Update local sync status
- [ ] Retry on failure
- [ ] Expose sync state

**Implementation**:
```dart
enum SyncState { idle, syncing, error }

class SyncEngine {
  final ApiClient _apiClient;
  final AppDatabase _database;
  final ConnectivityService _connectivity;

  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateController.stream;

  DateTime? _lastSyncTime;
  Timer? _periodicSync;

  SyncEngine({
    required ApiClient apiClient,
    required AppDatabase database,
    required ConnectivityService connectivity,
  }) : _apiClient = apiClient,
       _database = database,
       _connectivity = connectivity;

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSync?.cancel();
    _periodicSync = Timer.periodic(interval, (_) => sync());

    // Also sync when coming online
    _connectivity.onlineStream.listen((online) {
      if (online) {
        SentryService.addBreadcrumb('Network restored, triggering sync', category: 'sync');
        sync();
      }
    });
  }

  Future<void> sync() async {
    if (!await _connectivity.isOnline) return;

    _stateController.add(SyncState.syncing);
    SentryService.addBreadcrumb('Sync started', category: 'sync');

    try {
      await _push();
      await _pull();
      _lastSyncTime = DateTime.now();
      _stateController.add(SyncState.idle);
      SentryService.addBreadcrumb('Sync completed successfully', category: 'sync');
    } catch (e, stackTrace) {
      debugPrint('Sync error: $e');
      _stateController.add(SyncState.error);
      await SentryService.captureException(e, stackTrace, extras: {
        'last_sync_time': _lastSyncTime?.toIso8601String(),
        'sync_phase': 'unknown',
      });
      SentryService.addBreadcrumb('Sync failed', category: 'sync', data: {
        'error': e.toString(),
      });
    }
  }

  Future<void> _push() async {
    // Get unsynced attempts
    final attempts = await _database.attemptDao.getUnsynced();
    final analytics = await _database.analyticsDao.getUnsynced();
    final pathPoints = await _database.pathPointDao.getUnsynced();

    if (attempts.isEmpty && analytics.isEmpty && pathPoints.isEmpty) {
      return;
    }

    final response = await _apiClient.post('/api/sync/push', data: {
      'attempts': attempts.map((a) => a.toJson()).toList(),
      'analytics': analytics.map((e) => e.toJson()).toList(),
      'path_points': pathPoints.map((p) => p.toJson()).toList(),
    });

    final results = response.data['results'] as Map<String, dynamic>;

    // Mark synced items
    for (final result in results['attempts'] ?? []) {
      if (result['status'] == 'created' || result['status'] == 'merged') {
        await _database.attemptDao.markSynced(result['id']);
      }
    }

    for (final result in results['analytics'] ?? []) {
      if (result['status'] == 'ok') {
        await _database.analyticsDao.markSynced([result['id']]);
      }
    }

    for (final result in results['path_points'] ?? []) {
      if (result['status'] == 'ok') {
        await _database.pathPointDao.markSynced(result['id']);
      }
    }
  }

  Future<void> _pull() async {
    final since = _lastSyncTime?.toIso8601String() ?? '1970-01-01T00:00:00Z';

    final response = await _apiClient.post('/api/sync/pull', data: {
      'since': since,
    });

    // Update local quests
    final quests = (response.data['quests'] as List)
      .map((json) => QuestModel.fromJson(json))
      .toList();

    await _database.questDao.batchUpsert(
      quests.map((q) => q.toDrift()).toList());

    // Note: attempts are local-first, no pull needed typically
  }

  void dispose() {
    _periodicSync?.cancel();
    _stateController.close();
  }
}
```

---

### S7-T5: Sync Provider
**Type**: feature
**Dependencies**: S7-T4

**Description**:
Riverpod provider for sync state.

**Acceptance Criteria**:
- [ ] Initialize sync engine on app start
- [ ] Expose sync state
- [ ] Manual sync trigger
- [ ] Show last sync time

**Implementation**:
```dart
@riverpod
SyncEngine syncEngine(SyncEngineRef ref) {
  final engine = SyncEngine(
    apiClient: ref.watch(apiClientProvider),
    database: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );

  engine.startPeriodicSync();

  ref.onDispose(engine.dispose);

  return engine;
}

@riverpod
Stream<SyncState> syncState(SyncStateRef ref) {
  return ref.watch(syncEngineProvider).stateStream;
}

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  SyncInfo build() {
    return SyncInfo(
      state: SyncState.idle,
      lastSync: null,
    );
  }

  Future<void> syncNow() async {
    state = state.copyWith(state: SyncState.syncing);
    await ref.read(syncEngineProvider).sync();
    state = SyncInfo(
      state: SyncState.idle,
      lastSync: DateTime.now(),
    );
  }
}

class SyncInfo {
  final SyncState state;
  final DateTime? lastSync;

  SyncInfo({required this.state, this.lastSync});

  SyncInfo copyWith({SyncState? state, DateTime? lastSync}) =>
    SyncInfo(state: state ?? this.state, lastSync: lastSync ?? this.lastSync);
}
```

---

### S7-T6: Sync Status UI
**Type**: feature
**Dependencies**: S7-T5

**Description**:
Add sync status indicator to UI.

**Acceptance Criteria**:
- [ ] Show sync icon in app bar
- [ ] Animate during sync
- [ ] Show error state
- [ ] Tap to manual sync
- [ ] Show last sync time on long press

**Implementation**:
```dart
class SyncStatusButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildIcon(syncState.state),
      ),
      onPressed: syncState.state == SyncState.syncing
        ? null
        : () => ref.read(syncNotifierProvider.notifier).syncNow(),
      onLongPress: () => _showLastSync(context, syncState.lastSync),
    );
  }

  Widget _buildIcon(SyncState state) {
    switch (state) {
      case SyncState.idle:
        return const Icon(Icons.cloud_done, key: ValueKey('idle'));
      case SyncState.syncing:
        return const SizedBox(
          key: ValueKey('syncing'),
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncState.error:
        return const Icon(Icons.cloud_off, key: ValueKey('error'),
          color: Colors.orange);
    }
  }

  void _showLastSync(BuildContext context, DateTime? lastSync) {
    final message = lastSync != null
      ? 'Last synced: ${DateFormat('MMM d, HH:mm').format(lastSync)}'
      : 'Never synced';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

Add to quest list screen:
```dart
AppBar(
  title: const Text('Nearby Quests'),
  actions: [
    const SyncStatusButton(),
    // ... other actions
  ],
)
```

---

### S7-T7: Background Sync Service
**Type**: feature
**Dependencies**: S7-T4

**Description**:
Enable sync when app is in background.

**Acceptance Criteria**:
- [ ] Register background task
- [ ] Sync on significant location change
- [ ] Respect battery optimization
- [ ] Works on both iOS and Android

**Implementation**:
```dart
// Using workmanager package
class BackgroundSyncService {
  static const _syncTaskName = 'kashkash_sync';

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    // Periodic sync every 15 minutes (minimum on Android)
    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_syncTaskName);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Sentry for background context
      await SentryFlutter.init((options) {
        options.dsn = const String.fromEnvironment('SENTRY_DSN');
        options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
      });

      SentryService.addBreadcrumb('Background sync started', category: 'sync');

      // Initialize dependencies
      final database = await initDatabase();
      final apiClient = await initApiClient();
      final connectivity = ConnectivityService();

      final syncEngine = SyncEngine(
        apiClient: apiClient,
        database: database,
        connectivity: connectivity,
      );

      await syncEngine.sync();
      SentryService.addBreadcrumb('Background sync completed', category: 'sync');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Background sync failed: $e');
      await SentryService.captureException(e, stackTrace, extras: {
        'context': 'background_sync',
        'task': task,
      });
      return false;
    }
  });
}
```

---

### S7-T8: Conflict Resolution UI
**Type**: feature
**Dependencies**: S7-T4

**Description**:
Handle and display sync conflicts to user (optional).

**Acceptance Criteria**:
- [ ] Detect conflicts during sync
- [ ] Log conflicts for debugging
- [ ] Auto-resolve with last-write-wins
- [ ] (Optional) UI to show conflicts

For MVP, auto-resolution is fine. Manual conflict resolution can be added later.

**Implementation**:
```dart
class ConflictResolver {
  /// Resolves conflict using last-write-wins strategy
  /// Returns the winning version
  T resolve<T extends SyncableEntity>(T local, T remote) {
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local;
    }
    return remote;
  }
}

abstract class SyncableEntity {
  DateTime get updatedAt;
}
```

---

### S7-T9: Sync Tests
**Type**: test
**Dependencies**: S7-T4

**Description**:
Integration tests for sync functionality.

**Acceptance Criteria**:
- [ ] Test push when online
- [ ] Test pull updates local data
- [ ] Test offline queue
- [ ] Test conflict resolution
- [ ] Test retry on failure

**Implementation**:
```dart
void main() {
  group('SyncEngine', () {
    late SyncEngine syncEngine;
    late MockApiClient mockApi;
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase.forTesting();
      mockApi = MockApiClient();
      syncEngine = SyncEngine(
        apiClient: mockApi,
        database: database,
        connectivity: MockConnectivity(online: true),
      );
    });

    test('pushes unsynced attempts', () async {
      // Add unsynced attempt
      await database.attemptDao.create(testAttempt.copyWith(synced: false));

      when(() => mockApi.post(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response(
          data: {'results': {'attempts': [{'id': testAttempt.id, 'status': 'created'}]}},
          statusCode: 200,
        ));

      await syncEngine.sync();

      // Verify marked as synced
      final attempt = await database.attemptDao.getById(testAttempt.id);
      expect(attempt?.synced, isTrue);
    });

    test('queues operations when offline', () async {
      syncEngine = SyncEngine(
        apiClient: mockApi,
        database: database,
        connectivity: MockConnectivity(online: false),
      );

      await database.attemptDao.create(testAttempt.copyWith(synced: false));
      await syncEngine.sync();

      // Should not have called API
      verifyNever(() => mockApi.post(any(), data: any(named: 'data')));
    });
  });
}
```

---

### S7-T10: ConnectivityService Tests
**Type**: test
**Dependencies**: S7-T1

**Description**:
Test connectivity monitoring service.

**Acceptance Criteria**:
- [ ] isOnline returns true when connected
- [ ] isOnline returns false when no connection
- [ ] onlineStream emits on connectivity change
- [ ] Stream debounces rapid changes
- [ ] Handles WiFi and cellular correctly

**Test file**: `test/unit/infrastructure/sync/connectivity_service_test.dart`

---

### S7-T11: SyncQueueDao Tests
**Type**: test
**Dependencies**: S7-T2

**Description**:
Test sync queue database operations.

**Acceptance Criteria**:
- [ ] enqueue adds operation to queue
- [ ] getPending returns unprocessed items
- [ ] getPending respects limit
- [ ] markProcessed updates item status
- [ ] cleanupOld removes old processed items
- [ ] Items returned in FIFO order

**Test file**: `test/unit/data/datasources/local/sync_queue_dao_test.dart`

---

### S7-T12: Symfony Sync Endpoints Tests
**Type**: test
**Dependencies**: S7-T3

**Description**:
Functional tests for sync API endpoints.

**Acceptance Criteria**:
- [ ] POST /api/sync/pull returns records since timestamp
- [ ] Pull only returns published quests to regular users
- [ ] POST /api/sync/push creates new records
- [ ] Push merges existing records (last-write-wins)
- [ ] Batch path points insertion works
- [ ] Returns correct status for each record
- [ ] Handles partial failures gracefully

**Test file**: `backend/tests/Functional/Controller/SyncControllerTest.php`

---

### S7-T13: Offline Gameplay Test
**Type**: qa
**Dependencies**: S7-T4

**Description**:
Test complete offline gameplay and sync cycle.

**Acceptance Criteria**:
- [ ] Start app online, load quest list
- [ ] Enable airplane mode
- [ ] Start and complete a quest
- [ ] Quest appears in history (local)
- [ ] Disable airplane mode
- [ ] Sync icon animates
- [ ] Verify data appears on server (check via API or admin panel)
- [ ] No data lost

---

### S7-T14: Sync Status UI Test
**Type**: qa
**Dependencies**: S7-T6

**Description**:
Test sync status indicator in UI.

**Acceptance Criteria**:
- [ ] Idle state shows cloud-done icon
- [ ] Syncing state shows spinner
- [ ] Error state shows cloud-off icon with color
- [ ] Tap to manual sync works
- [ ] Long press shows last sync time
- [ ] States transition correctly

---

### S7-T15: Conflict Scenario Test
**Type**: qa
**Dependencies**: S7-T4

**Description**:
Test conflict resolution with last-write-wins.

**Acceptance Criteria**:
- [ ] Create attempt on device A
- [ ] Go offline on device A
- [ ] Modify same attempt on server (simulate device B)
- [ ] Come online on device A
- [ ] Verify last-write-wins (latest timestamp wins)
- [ ] No data corruption

**Note**: Requires server access or second device to create conflict.

---

### S7-T16: Background Sync Test
**Type**: qa
**Dependencies**: S7-T7

**Description**:
Test sync when app is in background.

**Acceptance Criteria**:
- [ ] Complete quest while online
- [ ] Put app in background
- [ ] Wait for background sync interval (15+ min on Android)
- [ ] Check server for synced data
- [ ] App doesn't crash from background execution

**Note**: iOS background sync is limited. Focus on Android testing.

---

### S7-T17: Network Interruption Test
**Type**: qa
**Dependencies**: S7-T4

**Description**:
Test sync behavior when network is interrupted.

**Acceptance Criteria**:
- [ ] Start sync with pending data
- [ ] Disable network mid-sync
- [ ] Sync shows error state
- [ ] Re-enable network
- [ ] Sync retries automatically (or on manual trigger)
- [ ] All data eventually syncs
- [ ] No data lost or duplicated

---

## Sprint 7 Validation

```bash
# Test offline behavior
flutter run --debug
# Turn off network
# Complete a quest
# Verify data saved locally
# Turn on network
# Verify sync icon animates
# Verify data appears on server

# Test background sync
# Put app in background
# Wait 15+ minutes
# Check server for synced data
```

**Checklist**:
- [ ] Data syncs when coming online
- [ ] Sync status shown in UI
- [ ] Manual sync button works
- [ ] Push includes attempts, analytics, path points
- [ ] Pull updates local quests
- [ ] Background sync works
- [ ] Conflicts resolved automatically

---

## Risk Notes

- Background sync has OS-imposed limitations (especially iOS)
- Workmanager minimum interval is 15 minutes on Android
- Large datasets may need chunked sync
- Network errors need retry with exponential backoff
