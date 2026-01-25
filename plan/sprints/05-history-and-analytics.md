# Sprint 5: History & Analytics

**Goal**: Implement quest history screen for users and privacy-first analytics with Aptabase.

**Deliverable**: Users can view their quest history. Product analytics tracked via Aptabase (no custom backend needed).

**Prerequisites**: Sprint 4 completed (core gameplay working)

---

## Tasks

### S5-T1: Aptabase Analytics Setup
**Type**: infrastructure
**Dependencies**: S1-T2

**Description**:
Initialize Aptabase for privacy-first product analytics.

**Acceptance Criteria**:
- [ ] Aptabase initialized in main.dart
- [ ] Analytics service wrapper created
- [ ] Events tracked: quest_started, quest_completed, quest_abandoned
- [ ] No user identifiers collected (privacy-first)

**Implementation**:
```dart
// lib/main.dart
import 'package:aptabase_flutter/aptabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Aptabase (get key from https://aptabase.com)
  await Aptabase.init(const String.fromEnvironment(
    'APTABASE_KEY',
    defaultValue: '', // Empty in debug mode
  ));

  // ... rest of initialization
}

// lib/core/analytics/analytics_service.dart
class AnalyticsService {
  /// Track quest started
  static void questStarted(String questId) {
    Aptabase.instance.trackEvent('quest_started', {
      'quest_id': questId,
    });
  }

  /// Track quest completed successfully
  static void questCompleted(String questId, int durationSeconds, double distanceWalked) {
    Aptabase.instance.trackEvent('quest_completed', {
      'quest_id': questId,
      'duration_seconds': durationSeconds,
      'distance_meters': distanceWalked.round(),
    });
  }

  /// Track quest abandoned
  static void questAbandoned(String questId, int durationSeconds) {
    Aptabase.instance.trackEvent('quest_abandoned', {
      'quest_id': questId,
      'duration_seconds': durationSeconds,
    });
  }

  /// Track screen view (optional)
  static void screenView(String screenName) {
    Aptabase.instance.trackEvent('screen_view', {
      'screen': screenName,
    });
  }
}
```

**Usage in gameplay (update S4-T9)**:
```dart
// In ActiveQuestNotifier
void _initGameplay(Quest quest, QuestAttempt attempt) {
  AnalyticsService.questStarted(quest.id);
  // ... existing code
}

void _onWin() {
  AnalyticsService.questCompleted(
    current.quest.id,
    current.elapsed.inSeconds,
    current.attempt.distanceWalked ?? 0,
  );
  // ... existing code
}

Future<void> abandon() {
  AnalyticsService.questAbandoned(
    current.quest.id,
    current.elapsed.inSeconds,
  );
  // ... existing code
}
```

---

### S5-T2: Attempt Repository Implementation
**Type**: feature
**Dependencies**: S4-T1

**Description**:
Complete attempt repository with offline-first approach.

**Acceptance Criteria**:
- [ ] Create attempt locally
- [ ] Update attempt locally
- [ ] Get user's attempt history
- [ ] Mark for sync
- [ ] Get unsynced attempts

**Implementation**:
```dart
class AttemptRepositoryImpl implements IAttemptRepository {
  final AttemptLocalDataSource _local;
  final AttemptRemoteDataSource _remote;

  @override
  Future<Either<Failure, QuestAttempt>> createAttempt(
    QuestAttempt attempt
  ) async {
    try {
      await _local.create(attempt.toData());
      return Right(attempt);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuestAttempt>> updateAttempt(
    QuestAttempt attempt
  ) async {
    try {
      final updated = attempt.copyWith(synced: false);
      await _local.update(updated.toData());
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<List<QuestAttempt>> getHistory(String userId) async {
    final data = await _local.getHistoryForUser(userId);
    return data.map((d) => d.toDomain()).toList();
  }

  @override
  Future<QuestAttempt?> getActiveAttempt(String userId) async {
    final data = await _local.getActiveForUser(userId);
    return data?.toDomain();
  }

  @override
  Future<List<QuestAttempt>> getUnsyncedAttempts() async {
    final data = await _local.getUnsynced();
    return data.map((d) => d.toDomain()).toList();
  }
}
```

---

### S5-T3: Quest History Provider
**Type**: feature
**Dependencies**: S5-T2

**Description**:
Riverpod provider for quest history screen.

**Acceptance Criteria**:
- [ ] List past attempts
- [ ] Filter by status (all, completed, abandoned)
- [ ] Include quest details
- [ ] Sort by date descending

**Implementation**:
```dart
enum HistoryFilter { all, completed, abandoned }

@riverpod
class QuestHistoryNotifier extends _$QuestHistoryNotifier {
  @override
  FutureOr<List<QuestAttemptWithQuest>> build() async {
    SentryService.addBreadcrumb('Loading quest history', category: 'navigation');
    final user = ref.read(currentUserProvider)!;
    final filter = ref.watch(historyFilterProvider);

    var attempts = await ref.read(attemptRepositoryProvider)
      .getHistory(user.id);

    // Apply filter
    if (filter != HistoryFilter.all) {
      attempts = attempts.where((a) {
        return filter == HistoryFilter.completed
          ? a.status == AttemptStatus.completed
          : a.status == AttemptStatus.abandoned;
      }).toList();
    }

    // Fetch quest details for each attempt
    final questRepo = ref.read(questRepositoryProvider);
    final withQuests = await Future.wait(attempts.map((a) async {
      final quest = await questRepo.getQuestById(a.questId);
      return QuestAttemptWithQuest(attempt: a, quest: quest.fold((_) => null, (q) => q));
    }));

    return withQuests.where((aq) => aq.quest != null).toList();
  }
}

@riverpod
class HistoryFilter extends _$HistoryFilter {
  @override
  HistoryFilter build() => HistoryFilter.all;

  void setFilter(HistoryFilter filter) => state = filter;
}

class QuestAttemptWithQuest {
  final QuestAttempt attempt;
  final Quest? quest;

  QuestAttemptWithQuest({required this.attempt, this.quest});
}
```

---

### S5-T4: Quest History Screen
**Type**: feature
**Dependencies**: S5-T3

**Description**:
Build quest history screen with filtering.

**Acceptance Criteria**:
- [ ] List of past attempts
- [ ] Quest title, date, status, duration, distance
- [ ] Filter chips (All, Completed, Abandoned)
- [ ] Empty state for new users
- [ ] Pull to refresh

**Implementation**:
```dart
class QuestHistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(questHistoryNotifierProvider);
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quest History')),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: HistoryFilter.values.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f.name.capitalize()),
                  selected: filter == f,
                  onSelected: (_) => ref.read(historyFilterProvider.notifier)
                    .setFilter(f),
                ),
              )).toList(),
            ),
          ),

          // History list
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (items) => items.isEmpty
                ? const EmptyHistoryView()
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(questHistoryNotifierProvider.future),
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) => HistoryCard(item: items[i]),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  final QuestAttemptWithQuest item;

  @override
  Widget build(BuildContext context) {
    final attempt = item.attempt;
    final quest = item.quest!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(quest.title,
                  style: Theme.of(context).textTheme.titleMedium),
                StatusBadge(status: attempt.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy • HH:mm').format(attempt.startedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (attempt.durationSeconds != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(_formatDuration(attempt.durationSeconds!)),
                  const SizedBox(width: 16),
                  if (attempt.distanceWalked != null) ...[
                    const Icon(Icons.directions_walk, size: 16),
                    const SizedBox(width: 4),
                    Text(_formatDistance(attempt.distanceWalked!)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

class StatusBadge extends StatelessWidget {
  final AttemptStatus status;

  Color get _color => switch (status) {
    AttemptStatus.completed => Colors.green,
    AttemptStatus.abandoned => Colors.orange,
    AttemptStatus.inProgress => Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.capitalize(),
        style: TextStyle(color: _color, fontSize: 12),
      ),
    );
  }
}
```

---

### S5-T5: Symfony Attempt Endpoints
**Type**: feature
**Dependencies**: S1-T10

**Description**:
Create endpoints for attempt sync.

**Acceptance Criteria**:
- [ ] POST `/api/attempts` creates attempt
- [ ] PUT `/api/attempts/{id}` updates attempt
- [ ] POST `/api/attempts/{id}/path` batch uploads path points
- [ ] GET `/api/attempts` lists user's attempts

**Implementation**:
```php
// src/Controller/AttemptController.php
#[Route('/api/attempts/{id}/path', name: 'attempt_path_batch', methods: ['POST'])]
public function batchPathPoints(
    string $id,
    Request $request,
    QuestAttemptRepository $attemptRepo,
    EntityManagerInterface $em
): JsonResponse {
    $attempt = $attemptRepo->find($id);
    if (!$attempt || $attempt->getUser() !== $this->getUser()) {
        throw $this->createNotFoundException();
    }

    $data = json_decode($request->getContent(), true);

    foreach ($data['points'] as $pointData) {
        $point = new PathPoint();
        $point->setId(Uuid::fromString($pointData['id']));
        $point->setAttempt($attempt);
        $point->setLatitude($pointData['latitude']);
        $point->setLongitude($pointData['longitude']);
        $point->setTimestamp(new \DateTimeImmutable($pointData['timestamp']));
        $point->setAccuracy($pointData['accuracy']);
        $point->setSpeed($pointData['speed']);

        $em->persist($point);
    }

    $em->flush();

    return $this->json(['status' => 'ok', 'count' => count($data['points'])]);
}
```

---

### S5-T6: Connect History to Navigation
**Type**: feature
**Dependencies**: S5-T4

**Description**:
Add history access from main navigation.

**Acceptance Criteria**:
- [ ] History icon in quest list app bar
- [ ] Navigation to history screen
- [ ] Back navigation works

**Implementation**:
Update quest list screen app bar:
```dart
AppBar(
  title: const Text('Nearby Quests'),
  actions: [
    IconButton(
      icon: const Icon(Icons.history),
      onPressed: () => context.push('/history'),
    ),
    if (ref.watch(isAdminProvider))
      IconButton(
        icon: const Icon(Icons.admin_panel_settings),
        onPressed: () => context.push('/admin/quests'),
      ),
  ],
)
```

---

## Sprint 5 Validation

```bash
# Flutter
flutter run --debug
# Complete a quest
# Go to history - verify it appears
# Filter by completed/abandoned
# Check analytics events in local DB

# Backend
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"events": [{"id": "...", "event_type": "quest_completed", "timestamp": "..."}]}' \
  http://localhost:8080/api/analytics
```

**Checklist**:
- [ ] Quest history shows past attempts
- [ ] Filter by status works
- [ ] Analytics events stored locally
- [ ] Backend accepts analytics batch
- [ ] Backend accepts path points batch
- [ ] Navigation between screens works

---

## Risk Notes

- History can grow large over time - consider pagination
- Analytics data can accumulate if user is offline long
- Path points especially can be large dataset
