import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/analytics/analytics_service.dart';
import '../../data/datasources/local/attempt_dao.dart';
import '../../data/datasources/local/path_point_dao.dart';
import '../../data/repositories/attempt_repository_impl.dart';
import '../../domain/entities/path_point.dart';
import '../../domain/entities/quest.dart';
import '../../domain/entities/quest_attempt.dart';
import '../../domain/repositories/attempt_repository.dart';
import '../../domain/usecases/abandon_quest_use_case.dart';
import '../../domain/usecases/complete_quest_use_case.dart';
import '../../domain/usecases/start_quest_use_case.dart';
import '../../infrastructure/gps/game_state_manager.dart';
import '../../presentation/widgets/game_background.dart';
import 'auth_provider.dart';
import 'quest_provider.dart';

part 'active_quest_provider.g.dart';

// ---------- Infrastructure Providers ----------

@Riverpod(keepAlive: true)
AttemptDao attemptDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.attemptDao;
}

@Riverpod(keepAlive: true)
PathPointDao pathPointDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.pathPointDao;
}

@Riverpod(keepAlive: true)
IAttemptRepository attemptRepository(Ref ref) {
  final attemptDao = ref.watch(attemptDaoProvider);
  final pathPointDao = ref.watch(pathPointDaoProvider);

  return AttemptRepositoryImpl(
    attemptDao: attemptDao,
    pathPointDao: pathPointDao,
  );
}

// ---------- Use Case Providers ----------

@riverpod
StartQuestUseCase startQuestUseCase(Ref ref) {
  final repository = ref.watch(attemptRepositoryProvider);
  return StartQuestUseCase(repository);
}

@riverpod
CompleteQuestUseCase completeQuestUseCase(Ref ref) {
  final repository = ref.watch(attemptRepositoryProvider);
  return CompleteQuestUseCase(repository);
}

@riverpod
AbandonQuestUseCase abandonQuestUseCase(Ref ref) {
  final repository = ref.watch(attemptRepositoryProvider);
  return AbandonQuestUseCase(repository);
}

// ---------- Active Quest State ----------

/// State for the active quest screen.
class ActiveQuestState {
  final Quest quest;
  final QuestAttempt attempt;
  final GameplayState gameplayState;
  final Duration elapsed;
  final double distanceToTarget;
  final String? error;

  const ActiveQuestState({
    required this.quest,
    required this.attempt,
    required this.gameplayState,
    required this.elapsed,
    this.distanceToTarget = double.infinity,
    this.error,
  });

  bool get hasWon => gameplayState == GameplayState.won;
  bool get hasError => error != null || gameplayState == GameplayState.error;

  ActiveQuestState copyWith({
    Quest? quest,
    QuestAttempt? attempt,
    GameplayState? gameplayState,
    Duration? elapsed,
    double? distanceToTarget,
    String? error,
    bool clearError = false,
  }) {
    return ActiveQuestState(
      quest: quest ?? this.quest,
      attempt: attempt ?? this.attempt,
      gameplayState: gameplayState ?? this.gameplayState,
      elapsed: elapsed ?? this.elapsed,
      distanceToTarget: distanceToTarget ?? this.distanceToTarget,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for active quest gameplay.
///
/// Manages the gameplay loop including GPS tracking, state transitions,
/// path recording, and win/abandon handling.
@riverpod
class ActiveQuestNotifier extends _$ActiveQuestNotifier {
  GameStateManager? _gameManager;
  Timer? _elapsedTimer;
  Timer? _pathRecordingTimer;
  StreamSubscription<GameplayState>? _stateSubscription;
  bool _winHandled = false;

  static const _uuid = Uuid();

  /// Maximum GPS accuracy (in meters) for recording path points.
  /// Points with worse accuracy are skipped to avoid skewing distance calculation.
  static const double _maxPathPointAccuracy = 50.0;

  /// Safely get current state if available.
  ActiveQuestState? _getCurrentState() {
    return switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  @override
  FutureOr<ActiveQuestState> build(String questId) async {
    ref.onDispose(_dispose);

    // Get the quest
    final questRepository = ref.read(questRepositoryProvider);
    final questResult = await questRepository.getQuestById(questId);

    if (questResult.isLeft()) {
      throw Exception(
          questResult.getLeft().toNullable()?.message ?? 'Quest not found');
    }

    final quest = questResult.getRight().toNullable()!;

    // Get user ID from auth provider
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('User must be authenticated to start a quest');
    }
    final userId = user.id;

    // Start the attempt
    final startUseCase = ref.read(startQuestUseCaseProvider);
    final attemptResult = await startUseCase(questId: questId, userId: userId);

    if (attemptResult.isLeft()) {
      throw Exception(attemptResult.getLeft().toNullable()?.message ??
          'Failed to start quest');
    }

    final attempt = attemptResult.getRight().toNullable()!;

    // Initialize gameplay
    _initGameplay(quest, attempt);

    return ActiveQuestState(
      quest: quest,
      attempt: attempt,
      gameplayState: GameplayState.initializing,
      elapsed: Duration.zero,
    );
  }

  void _initGameplay(Quest quest, QuestAttempt attempt) {
    // Track quest started
    AnalyticsService.questStarted(questId: quest.id);

    final gpsService = ref.read(gpsServiceProvider);

    _gameManager = GameStateManager(
      quest: quest,
      gpsService: gpsService,
    );

    // Listen to gameplay state changes
    _stateSubscription = _gameManager!.stateStream.listen((gameState) {
      final current = _getCurrentState();
      if (current == null) return;

      state = AsyncData(current.copyWith(
        gameplayState: gameState,
        distanceToTarget: _gameManager!.distanceToTarget,
      ));

      if (gameState == GameplayState.won && !_winHandled) {
        _winHandled = true;
        _onWin();
      }
    });

    _gameManager!.start();

    // Start elapsed timer (updates every second)
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = _getCurrentState();
      if (current == null) return;

      state = AsyncData(current.copyWith(
        elapsed: DateTime.now().difference(current.attempt.startedAt),
        distanceToTarget: _gameManager?.distanceToTarget ?? double.infinity,
      ));
    });

    // Start path recording (every 5 seconds)
    _pathRecordingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _recordPathPoint(attempt.id);
    });
  }

  Future<void> _recordPathPoint(String attemptId) async {
    // Don't record path points if game is over
    final current = _getCurrentState();
    if (current == null || current.hasWon) return;

    final position = _gameManager?.currentPosition;
    if (position == null) return;

    // Skip poor GPS readings to avoid skewing distance calculation
    if (position.accuracy > _maxPathPointAccuracy) return;

    final repository = ref.read(attemptRepositoryProvider);
    await repository.addPathPoint(
      PathPoint(
        id: _uuid.v4(),
        attemptId: attemptId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed < 0 ? 0 : position.speed,
      ),
    );
  }

  Future<void> _onWin() async {
    _stopTimers();

    final current = _getCurrentState();
    if (current == null) return;

    final completeUseCase = ref.read(completeQuestUseCaseProvider);
    final result = await completeUseCase(current.attempt.id);

    result.fold(
      (failure) => state = AsyncData(current.copyWith(error: failure.message)),
      (updatedAttempt) {
        // Track quest completed
        AnalyticsService.questCompleted(
          questId: current.quest.id,
          durationSeconds: current.elapsed.inSeconds,
          distanceWalked: updatedAttempt.distanceWalked ?? 0,
        );
        state = AsyncData(current.copyWith(attempt: updatedAttempt));
      },
    );
  }

  /// Abandon the current quest.
  Future<void> abandon() async {
    _stopTimers();

    final current = _getCurrentState();
    if (current == null) return;

    final abandonUseCase = ref.read(abandonQuestUseCaseProvider);
    final result = await abandonUseCase(current.attempt.id);

    result.fold(
      (failure) => state = AsyncData(current.copyWith(error: failure.message)),
      (updatedAttempt) {
        // Track quest abandoned
        AnalyticsService.questAbandoned(
          questId: current.quest.id,
          durationSeconds: current.elapsed.inSeconds,
        );
        state = AsyncData(current.copyWith(
          attempt: updatedAttempt,
          gameplayState: GameplayState.abandoned,
        ));
      },
    );
  }

  void _stopTimers() {
    _elapsedTimer?.cancel();
    _pathRecordingTimer?.cancel();
  }

  void _dispose() {
    _stateSubscription?.cancel();
    _gameManager?.dispose();
    _elapsedTimer?.cancel();
    _pathRecordingTimer?.cancel();
  }
}
