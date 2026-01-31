# Sprint 4: Core Gameplay

**Goal**: Implement the core gameplay loop with GPS tracking, movement detection, and color feedback.

**Deliverable**: Users can start a quest and experience full gameplay with BLACK/RED/BLUE screen feedback and win detection.

**Prerequisites**: Sprint 3 completed (quest list working, GPS service working)

**Commit Convention**: All commits in this sprint MUST be prefixed with `sprint #4 - `

---

## Tasks

### S4-T1: Quest Attempt Data Layer
**Type**: feature
**Dependencies**: S1-T4, S1-T5

**Description**:
Create models and data layer for quest attempts.

**Acceptance Criteria**:
- [ ] QuestAttemptModel with serialization
- [ ] Drift DAO for attempts
- [ ] Create, update, get operations
- [ ] Get active attempt for user
- [ ] Get attempts history

**Implementation**:
```dart
@DriftAccessor(tables: [QuestAttempts])
class AttemptDao extends DatabaseAccessor<AppDatabase> with _$AttemptDaoMixin {

  Future<QuestAttemptData?> getActiveForUser(String userId) {
    return (select(questAttempts)
      ..where((a) => a.userId.equals(userId))
      ..where((a) => a.status.equals(AttemptStatus.inProgress.index))
    ).getSingleOrNull();
  }

  Future<List<QuestAttemptData>> getHistoryForUser(String userId) {
    return (select(questAttempts)
      ..where((a) => a.userId.equals(userId))
      ..where((a) => a.status.isNotValue(AttemptStatus.inProgress.index))
      ..orderBy([(a) => OrderingTerm.desc(a.startedAt)])
    ).get();
  }

  Future<void> create(QuestAttemptData attempt) {
    return into(questAttempts).insert(attempt);
  }

  Future<void> update(QuestAttemptData attempt) {
    return (update(questAttempts)
      ..where((a) => a.id.equals(attempt.id))
    ).write(attempt);
  }
}
```

---

### S4-T2: Path Point Data Layer
**Type**: feature
**Dependencies**: S4-T1

**Description**:
Implement path point storage for recording user movement.

**Acceptance Criteria**:
- [ ] PathPointModel with serialization
- [ ] Drift DAO for path points
- [ ] Add path point with attempt ID
- [ ] Get all points for attempt
- [ ] Calculate total distance from path
- [ ] Batch insert for performance

**Implementation**:
```dart
@DriftAccessor(tables: [PathPoints])
class PathPointDao extends DatabaseAccessor<AppDatabase> with _$PathPointDaoMixin {

  Future<void> add(PathPointData point) {
    return into(pathPoints).insert(point);
  }

  Future<void> addBatch(List<PathPointData> points) {
    return batch((b) => b.insertAll(pathPoints, points));
  }

  Future<List<PathPointData>> getForAttempt(String attemptId) {
    return (select(pathPoints)
      ..where((p) => p.attemptId.equals(attemptId))
      ..orderBy([(p) => OrderingTerm.asc(p.timestamp)])
    ).get();
  }

  Future<double> calculateTotalDistance(String attemptId) async {
    final points = await getForAttempt(attemptId);
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += DistanceCalculator.haversine(
        points[i - 1].latitude, points[i - 1].longitude,
        points[i].latitude, points[i].longitude,
      );
    }
    return total;
  }
}
```

---

### S4-T3: Movement Detector
**Type**: feature
**Dependencies**: S3-T7

**Description**:
Detect if user is moving or stationary based on GPS speed.

**Acceptance Criteria**:
- [ ] Detect stationary (speed < threshold)
- [ ] Detect moving (speed >= threshold)
- [ ] Configurable threshold (default 0.5 m/s)
- [ ] Smoothing to avoid flickering
- [ ] Expose as stream

**Implementation**:
```dart
enum MovementState { stationary, moving }

class MovementDetector {
  // 0.5 m/s = slow walking speed (normal walking is ~1.4 m/s)
  // Lower threshold catches intentional movement while filtering GPS drift
  static const double defaultThreshold = 0.5;

  // Require 3 consecutive readings to change state
  // Prevents flickering from momentary GPS glitches
  static const int smoothingCount = 3;

  final double threshold;
  final List<bool> _recentReadings = [];

  MovementDetector({this.threshold = defaultThreshold});

  MovementState detect(double speed) {
    final isMoving = speed >= threshold;
    _recentReadings.add(isMoving);

    if (_recentReadings.length > smoothingCount) {
      _recentReadings.removeAt(0);
    }

    // Require majority of recent readings to agree
    final movingCount = _recentReadings.where((r) => r).length;
    return movingCount > _recentReadings.length / 2
      ? MovementState.moving
      : MovementState.stationary;
  }

  void reset() => _recentReadings.clear();
}

// As a stream transformer
class MovementDetectorTransformer
    extends StreamTransformerBase<Position, MovementState> {
  final MovementDetector _detector;

  MovementDetectorTransformer({double threshold = 0.5})
    : _detector = MovementDetector(threshold: threshold);

  @override
  Stream<MovementState> bind(Stream<Position> stream) {
    return stream.map((pos) => _detector.detect(pos.speed));
  }
}
```

---

### S4-T4: Direction Detector
**Type**: feature
**Dependencies**: S3-T6

**Description**:
Detect if user is getting closer or farther from target.

**Acceptance Criteria**:
- [ ] Compare current vs previous distance
- [ ] Return gettingCloser or gettingFarther
- [ ] Handle equal distance (no change)
- [ ] Minimum movement threshold (2m)

**Implementation**:
```dart
enum DirectionState { gettingCloser, gettingFarther, noChange }

class DirectionDetector {
  static const double minMovementMeters = 2.0;

  final double targetLat;
  final double targetLng;
  double? _previousDistance;

  DirectionDetector({
    required this.targetLat,
    required this.targetLng,
  });

  DirectionState detect(double currentLat, double currentLng) {
    final currentDistance = DistanceCalculator.haversine(
      currentLat, currentLng,
      targetLat, targetLng,
    );

    if (_previousDistance == null) {
      _previousDistance = currentDistance;
      return DirectionState.noChange;
    }

    final difference = _previousDistance! - currentDistance;

    // Require minimum movement to register change
    if (difference.abs() < minMovementMeters) {
      return DirectionState.noChange;
    }

    _previousDistance = currentDistance;

    return difference > 0
      ? DirectionState.gettingCloser
      : DirectionState.gettingFarther;
  }

  double get currentDistance => _previousDistance ?? double.infinity;

  void reset() => _previousDistance = null;
}
```

---

### S4-T5: Gameplay State Manager
**Type**: feature
**Dependencies**: S4-T3, S4-T4, S3-T6, S3-T7

**Description**:
Central state manager orchestrating all gameplay logic.

**Acceptance Criteria**:
- [ ] Manages GameplayState enum
- [ ] Consumes GPS, movement, direction
- [ ] Emits state changes as stream
- [ ] Detects win condition (within radius)
- [ ] Clean lifecycle management

**Implementation**:
```dart
enum GameplayState {
  initializing,
  stationary,
  gettingCloser,
  gettingFarther,
  won,
  error,
}

class GameStateManager {
  final Quest quest;
  final GpsService _gpsService;
  final MovementDetector _movementDetector;
  late final DirectionDetector _directionDetector;

  final _stateController = StreamController<GameplayState>.broadcast();
  StreamSubscription<Position>? _positionSubscription;

  GameplayState _currentState = GameplayState.initializing;
  Position? _currentPosition;

  GameStateManager({
    required this.quest,
    required GpsService gpsService,
  }) : _gpsService = gpsService,
       _movementDetector = MovementDetector() {
    _directionDetector = DirectionDetector(
      targetLat: quest.latitude,
      targetLng: quest.longitude,
    );
  }

  Stream<GameplayState> get stateStream => _stateController.stream;
  GameplayState get currentState => _currentState;
  Position? get currentPosition => _currentPosition;
  double get distanceToTarget => _directionDetector.currentDistance;

  void start() {
    SentryService.addBreadcrumb('GPS tracking started', category: 'gameplay');
    _positionSubscription = _gpsService.watchPosition(
      distanceFilter: 1, // Update every 1 meter
    ).listen(_onPositionUpdate, onError: _onError);
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;

    // Check win condition first
    // If GPS accuracy is poor, expand effective radius to prevent impossible wins
    // (e.g., 10m accuracy means we can't reliably detect 3m radius)
    final effectiveRadius = max(quest.radiusMeters, position.accuracy * 0.8);
    final distance = DistanceCalculator.haversine(
      position.latitude, position.longitude,
      quest.latitude, quest.longitude,
    );

    if (distance <= effectiveRadius) {
      _updateState(GameplayState.won);
      return;
    }

    // Check movement
    final movement = _movementDetector.detect(position.speed);
    if (movement == MovementState.stationary) {
      _updateState(GameplayState.stationary);
      return;
    }

    // Check direction
    final direction = _directionDetector.detect(
      position.latitude, position.longitude);

    switch (direction) {
      case DirectionState.gettingCloser:
        _updateState(GameplayState.gettingCloser);
      case DirectionState.gettingFarther:
        _updateState(GameplayState.gettingFarther);
      case DirectionState.noChange:
        // Keep previous state or default to stationary
        if (_currentState == GameplayState.initializing) {
          _updateState(GameplayState.stationary);
        }
    }
  }

  void _onError(Object error, [StackTrace? stackTrace]) {
    _updateState(GameplayState.error);
    SentryService.captureException(error, stackTrace, extras: {
      'quest_id': quest.id,
      'current_state': _currentState.name,
    });
    SentryService.addBreadcrumb('GPS error during gameplay', category: 'gameplay', data: {
      'error': error.toString(),
    });
  }

  void _updateState(GameplayState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
    }
  }

  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _stateController.close();
  }
}
```

---

### S4-T6: Start Quest Use Case
**Type**: feature
**Dependencies**: S4-T1

**Description**:
Use case for starting a new quest attempt.

**Acceptance Criteria**:
- [ ] Creates new QuestAttempt
- [ ] Sets status to inProgress
- [ ] Records start time
- [ ] Prevents double-start

**Implementation**:
```dart
class StartQuestUseCase {
  final IAttemptRepository _repository;
  final IAnalyticsRepository _analytics;

  Future<Either<Failure, QuestAttempt>> call({
    required String questId,
    required String userId,
  }) async {
    // Check for existing active attempt
    final existing = await _repository.getActiveAttempt(userId);
    if (existing != null) {
      return Left(ValidationFailure('Already have an active quest'));
    }

    final attempt = QuestAttempt(
      id: const Uuid().v4(),
      questId: questId,
      userId: userId,
      startedAt: DateTime.now(),
      status: AttemptStatus.inProgress,
    );

    final result = await _repository.createAttempt(attempt);

    // Track analytics
    await _analytics.trackEvent(AnalyticsEvent(
      id: const Uuid().v4(),
      userId: userId,
      eventType: AnalyticsEventType.questStarted,
      eventData: {'quest_id': questId},
      timestamp: DateTime.now(),
    ));

    return result;
  }
}
```

---

### S4-T7: Complete Quest Use Case
**Type**: feature
**Dependencies**: S4-T1, S4-T2

**Description**:
Use case for successfully completing a quest.

**Acceptance Criteria**:
- [ ] Updates status to completed
- [ ] Records completion time
- [ ] Calculates duration
- [ ] Calculates distance walked
- [ ] Triggers analytics event

**Implementation**:
```dart
class CompleteQuestUseCase {
  final IAttemptRepository _attemptRepo;
  final IPathPointRepository _pathRepo;
  final IAnalyticsRepository _analytics;

  Future<Either<Failure, QuestAttempt>> call(String attemptId) async {
    final attempt = await _attemptRepo.getById(attemptId);
    if (attempt == null) {
      return Left(ValidationFailure('Attempt not found'));
    }

    final completedAt = DateTime.now();
    final duration = completedAt.difference(attempt.startedAt).inSeconds;
    final distanceWalked = await _pathRepo.calculateTotalDistance(attemptId);

    final updated = attempt.copyWith(
      status: AttemptStatus.completed,
      completedAt: completedAt,
      durationSeconds: duration,
      distanceWalked: distanceWalked,
    );

    final result = await _attemptRepo.updateAttempt(updated);

    await _analytics.trackEvent(AnalyticsEvent(
      id: const Uuid().v4(),
      userId: attempt.userId,
      eventType: AnalyticsEventType.questCompleted,
      eventData: {
        'quest_id': attempt.questId,
        'duration_seconds': duration,
        'distance_walked': distanceWalked,
      },
      timestamp: DateTime.now(),
    ));

    return result;
  }
}
```

---

### S4-T8: Abandon Quest Use Case
**Type**: feature
**Dependencies**: S4-T1

**Description**:
Use case for abandoning an in-progress quest.

**Acceptance Criteria**:
- [ ] Updates status to abandoned
- [ ] Records abandonment time
- [ ] Calculates partial duration
- [ ] Triggers analytics

**Implementation**:
```dart
class AbandonQuestUseCase {
  final IAttemptRepository _repository;
  final IAnalyticsRepository _analytics;

  Future<Either<Failure, void>> call(String attemptId) async {
    final attempt = await _repository.getById(attemptId);
    if (attempt == null) {
      return Left(ValidationFailure('Attempt not found'));
    }

    final abandonedAt = DateTime.now();
    final duration = abandonedAt.difference(attempt.startedAt).inSeconds;

    final updated = attempt.copyWith(
      status: AttemptStatus.abandoned,
      abandonedAt: abandonedAt,
      durationSeconds: duration,
    );

    await _repository.updateAttempt(updated);

    await _analytics.trackEvent(AnalyticsEvent(
      id: const Uuid().v4(),
      userId: attempt.userId,
      eventType: AnalyticsEventType.questAbandoned,
      eventData: {
        'quest_id': attempt.questId,
        'duration_seconds': duration,
      },
      timestamp: DateTime.now(),
    ));

    return const Right(null);
  }
}
```

---

### S4-T9: Active Quest Provider
**Type**: feature
**Dependencies**: S4-T5, S4-T6, S4-T7, S4-T8

**Description**:
Riverpod provider for active quest screen state.

**Acceptance Criteria**:
- [ ] Initializes quest and attempt
- [ ] Exposes gameplay state
- [ ] Exposes elapsed time
- [ ] Handles start/abandon/win
- [ ] Records path points
- [ ] Sets Sentry context for quest/attempt

**Implementation**:
```dart
@riverpod
class ActiveQuestNotifier extends _$ActiveQuestNotifier {
  GameStateManager? _gameManager;
  Timer? _elapsedTimer;
  Timer? _pathRecordingTimer;

  @override
  FutureOr<ActiveQuestState> build(String questId) async {
    ref.onDispose(_dispose);

    final quest = await ref.read(questRepositoryProvider)
      .getQuestById(questId);
    final user = ref.read(currentUserProvider)!;

    // Start attempt
    final attemptResult = await ref.read(startQuestUseCaseProvider)
      .call(questId: questId, userId: user.id);

    return attemptResult.fold(
      (failure) => throw failure,
      (attempt) {
        // Set Sentry context for this quest session
        SentryService.setQuestContext(quest);
        SentryService.addBreadcrumb('Quest started', category: 'gameplay', data: {
          'quest_id': quest.id,
          'quest_title': quest.title,
          'attempt_id': attempt.id,
        });

        _initGameplay(quest, attempt);
        return ActiveQuestState(
          quest: quest,
          attempt: attempt,
          gameplayState: GameplayState.initializing,
          elapsed: Duration.zero,
        );
      },
    );
  }

  void _initGameplay(Quest quest, QuestAttempt attempt) {
    _gameManager = GameStateManager(
      quest: quest,
      gpsService: ref.read(gpsServiceProvider),
    );

    _gameManager!.stateStream.listen((gameState) {
      final current = state.valueOrNull;
      if (current == null) return;

      state = AsyncData(current.copyWith(gameplayState: gameState));

      if (gameState == GameplayState.won) {
        _onWin();
      }
    });

    _gameManager!.start();

    // Start elapsed timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(current.copyWith(
        elapsed: DateTime.now().difference(current.attempt.startedAt),
      ));
    });

    // Start path recording (every 5 seconds)
    _pathRecordingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _recordPathPoint(attempt.id);
    });
  }

  void _recordPathPoint(String attemptId) async {
    final position = _gameManager?.currentPosition;
    if (position == null) return;

    await ref.read(pathPointRepositoryProvider).addPoint(
      PathPoint(
        id: const Uuid().v4(),
        attemptId: attemptId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
      ),
    );
  }

  void _onWin() async {
    _elapsedTimer?.cancel();
    _pathRecordingTimer?.cancel();

    final current = state.valueOrNull;
    if (current == null) return;

    SentryService.addBreadcrumb('Quest won!', category: 'gameplay', data: {
      'elapsed_seconds': current.elapsed.inSeconds,
      'quest_id': current.quest.id,
    });

    await ref.read(completeQuestUseCaseProvider).call(current.attempt.id);
  }

  Future<void> abandon() async {
    final current = state.valueOrNull;
    if (current == null) return;

    SentryService.addBreadcrumb('Quest abandoned', category: 'gameplay', data: {
      'quest_id': current.quest.id,
      'elapsed_seconds': current.elapsed.inSeconds,
      'attempt_id': current.attempt.id,
    });

    await ref.read(abandonQuestUseCaseProvider).call(current.attempt.id);
  }

  void _dispose() {
    _gameManager?.dispose();
    _elapsedTimer?.cancel();
    _pathRecordingTimer?.cancel();
  }
}
```

---

### S4-T10: Game Background Widget
**Type**: feature
**Dependencies**: S1-T8

**Description**:
Full-screen animated color background for gameplay.

**Acceptance Criteria**:
- [ ] BLACK for stationary
- [ ] RED for getting closer
- [ ] BLUE for getting farther
- [ ] Smooth color transitions
- [ ] Full screen, no chrome

**Implementation**:
```dart
class GameBackground extends StatelessWidget {
  final GameplayState state;

  Color get _color => switch (state) {
    GameplayState.stationary => AppColors.black,
    GameplayState.gettingCloser => AppColors.red,
    GameplayState.gettingFarther => AppColors.blue,
    GameplayState.won => AppColors.success,
    GameplayState.initializing => AppColors.black,
    GameplayState.error => AppColors.black,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      color: _color,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
```

---

### S4-T11: Win Overlay Widget
**Type**: feature
**Dependencies**: S1-T8

**Description**:
Celebration overlay when user wins.

**Acceptance Criteria**:
- [ ] Celebratory animation
- [ ] "You Found It!" message
- [ ] Stats display (time, distance)
- [ ] Done button

**Implementation**:
```dart
class WinOverlay extends StatelessWidget {
  final Duration elapsed;
  final double distanceWalked;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration,
                  size: 64, color: AppColors.success),
                const SizedBox(height: 16),
                Text('You Found It!',
                  style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                Text('Time: ${_formatDuration(elapsed)}'),
                Text('Distance: ${_formatDistance(distanceWalked)}'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
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

### S4-T12: Active Quest Screen
**Type**: feature
**Dependencies**: S4-T9, S4-T10, S4-T11

**Description**:
Complete active quest screen combining all components.

**Acceptance Criteria**:
- [ ] Full-screen game background
- [ ] Subtle back/abandon button
- [ ] Optional elapsed time
- [ ] Win overlay on completion
- [ ] GPS error handling
- [ ] Prevent screen sleep
- [ ] Confirmation for abandon

**Implementation**:
```dart
class ActiveQuestScreen extends ConsumerStatefulWidget {
  final String questId;

  @override
  ConsumerState<ActiveQuestScreen> createState() => _ActiveQuestScreenState();
}

class _ActiveQuestScreenState extends ConsumerState<ActiveQuestScreen> {
  @override
  void initState() {
    super.initState();
    // Prevent screen sleep
    WakelockPlus.enable();
    // Hide status bar for immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeQuestNotifierProvider(widget.questId));

    return Scaffold(
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (data) => Stack(
          children: [
            // Full-screen colored background
            GameBackground(state: data.gameplayState),

            // Subtle controls
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Abandon button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => _confirmAbandon(context),
                    ),
                    // Elapsed time
                    Text(
                      _formatDuration(data.elapsed),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Win overlay
            if (data.gameplayState == GameplayState.won)
              WinOverlay(
                elapsed: data.elapsed,
                distanceWalked: data.attempt.distanceWalked ?? 0,
                onDone: () => context.go('/quests'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Quest?'),
        content: const Text('Your progress will be saved but marked as abandoned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(activeQuestNotifierProvider(widget.questId).notifier)
        .abandon();
      if (mounted) context.go('/quests');
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
```

---

## Testing & QA Tasks

### S4-T13: MovementDetector Tests
**Type**: test
**Dependencies**: S4-T3

**Description**:
Unit tests for movement detection logic.

**Acceptance Criteria**:
- [ ] Speed < 0.5 m/s → stationary
- [ ] Speed >= 0.5 m/s → moving
- [ ] Smoothing prevents single-reading state flicker
- [ ] Requires 2+ of 3 readings to change state
- [ ] Reset clears reading history
- [ ] Custom threshold works correctly

**Test file**: `test/unit/infrastructure/gps/movement_detector_test.dart`

---

### S4-T14: DirectionDetector Tests
**Type**: test
**Dependencies**: S4-T4

**Description**:
Unit tests for direction detection logic.

**Acceptance Criteria**:
- [ ] Moving toward target → gettingCloser
- [ ] Moving away from target → gettingFarther
- [ ] Movement < 2m → noChange (within threshold)
- [ ] First reading → noChange (no previous distance)
- [ ] Reset clears previous distance
- [ ] currentDistance property returns correct value

**Test file**: `test/unit/infrastructure/gps/direction_detector_test.dart`

---

### S4-T15: GameStateManager Tests
**Type**: test
**Dependencies**: S4-T5

**Description**:
Integration tests for the game state orchestrator.

**Acceptance Criteria**:
- [ ] Starts in initializing state
- [ ] Transitions to stationary when not moving
- [ ] Transitions to gettingCloser when approaching target
- [ ] Transitions to gettingFarther when moving away
- [ ] Transitions to won when within radius
- [ ] Expands effective radius when GPS accuracy is poor
- [ ] Handles GPS errors gracefully (transitions to error state)
- [ ] dispose cancels GPS subscription

**Test file**: `test/unit/infrastructure/gps/game_state_manager_test.dart`

**Mock setup**:
```dart
final mockGpsService = MockGpsService();
when(() => mockGpsService.watchPosition()).thenAnswer(
  (_) => Stream.fromIterable([
    FakePosition(lat: 48.8566, lng: 2.3522, speed: 0),
    FakePosition(lat: 48.8567, lng: 2.3523, speed: 1.5),
  ]),
);
```

---

### S4-T16: UseCase Tests
**Type**: test
**Dependencies**: S4-T6, S4-T7, S4-T8

**Description**:
Unit tests for gameplay use cases.

**Acceptance Criteria**:
- [ ] StartQuestUseCase creates attempt with inProgress status
- [ ] StartQuestUseCase prevents double-start (returns error)
- [ ] CompleteQuestUseCase updates status to completed
- [ ] CompleteQuestUseCase calculates duration correctly
- [ ] CompleteQuestUseCase calculates distance walked
- [ ] AbandonQuestUseCase updates status to abandoned
- [ ] All use cases track analytics events

**Test files**:
```
test/unit/domain/usecases/
├── start_quest_test.dart
├── complete_quest_test.dart
└── abandon_quest_test.dart
```

---

### S4-T17: AttemptDao Tests
**Type**: test
**Dependencies**: S4-T1

**Description**:
Test Drift DAO for attempt operations.

**Acceptance Criteria**:
- [ ] create inserts new attempt
- [ ] getActiveForUser returns in-progress attempt
- [ ] getActiveForUser returns null when no active attempt
- [ ] getHistoryForUser returns completed/abandoned attempts
- [ ] getHistoryForUser excludes in-progress attempts
- [ ] update modifies existing attempt

**Test file**: `test/unit/data/datasources/local/attempt_dao_test.dart`

---

### S4-T18: Outdoor Gameplay Test
**Type**: qa
**Dependencies**: S4-T12

**Description**:
Full gameplay test outdoors with real GPS.

**Acceptance Criteria**:
- [ ] Create a test quest at a known outdoor location
- [ ] Start quest from ~100m away
- [ ] Walk toward target - screen turns RED
- [ ] Walk away from target - screen turns BLUE
- [ ] Stop moving - screen turns BLACK (within 2-3 seconds)
- [ ] Reach target - win overlay appears
- [ ] Stats (time, distance) are reasonable and accurate

**Test locations**:
- [ ] Open park (good GPS accuracy)
- [ ] Urban area (building interference)
- [ ] Near trees (partial GPS obstruction)

---

### S4-T19: Color Feedback Test
**Type**: qa
**Dependencies**: S4-T10

**Description**:
Verify color transitions are visually clear.

**Acceptance Criteria**:
- [ ] BLACK is pure black (#000000)
- [ ] RED is clearly red (not orange/pink)
- [ ] BLUE is clearly blue (not purple/cyan)
- [ ] Color transitions are smooth (300ms animation)
- [ ] Colors visible in bright sunlight
- [ ] No color flashing/flickering during normal movement

---

### S4-T20: Win Detection Test
**Type**: qa
**Dependencies**: S4-T5

**Description**:
Test win detection at target location.

**Acceptance Criteria**:
- [ ] Win triggers when within ~3m of target
- [ ] Win overlay appears immediately
- [ ] Celebration animation plays
- [ ] Stats displayed correctly
- [ ] "Done" button navigates to quest list
- [ ] GPS tracking stops after win

---

### S4-T21: Abandon Flow Test
**Type**: qa
**Dependencies**: S4-T12

**Description**:
Test quest abandonment flow.

**Acceptance Criteria**:
- [ ] Abandon button visible during gameplay
- [ ] Tapping abandon shows confirmation dialog
- [ ] Canceling returns to gameplay
- [ ] Confirming navigates to quest list
- [ ] Abandoned quest appears in history
- [ ] Partial duration recorded

---

### S4-T22: Battery/Performance Test
**Type**: qa
**Dependencies**: S4-T12

**Description**:
Monitor battery and performance during gameplay.

**Acceptance Criteria**:
- [ ] Play 15-minute quest, note battery drain
- [ ] Battery drain < 5% for 15 minutes (acceptable)
- [ ] No jank during color transitions (maintain 60fps)
- [ ] Memory usage stable over time (no leaks)
- [ ] App doesn't crash during extended play
- [ ] No excessive heat generation

**Tools**: Flutter DevTools, Android Profiler, Xcode Instruments

---

### S4-T23: Screen Wake Test
**Type**: qa
**Dependencies**: S4-T12

**Description**:
Verify screen stays on during active gameplay.

**Acceptance Criteria**:
- [ ] Screen doesn't dim during gameplay
- [ ] Screen doesn't turn off during gameplay
- [ ] Wakelock releases when leaving gameplay screen
- [ ] Wakelock releases when app goes to background

---

## Sprint 4 Validation

```bash
flutter run --debug
# Select quest from list
# Verify black screen when stationary
# Walk around - screen changes color
# Verify red when closer, blue when farther
# Approach target - verify win overlay
# Test abandon with confirmation
# Works fully offline
```

**Checklist**:
- [ ] Gameplay starts with black screen
- [ ] Color changes based on movement
- [ ] Color is red when getting closer
- [ ] Color is blue when getting farther
- [ ] Win detected within 3m radius
- [ ] Stats shown on win
- [ ] Abandon works with confirmation
- [ ] Path points recorded locally
- [ ] Screen stays awake during gameplay

---

## Risk Notes

- GPS accuracy of 3m may be challenging indoors
- Speed-based movement detection can be noisy
- Battery consumption needs monitoring
- iOS background GPS has restrictions
