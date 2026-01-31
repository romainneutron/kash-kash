import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart' show AppDatabase;
import 'package:kash_kash_app/data/datasources/local/quest_dao.dart';
import 'package:kash_kash_app/data/datasources/remote/quest_remote_data_source.dart';
import 'package:kash_kash_app/data/repositories/quest_repository_impl.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/infrastructure/gps/gps_service.dart';
import 'package:kash_kash_app/presentation/providers/api_provider.dart';

part 'quest_provider.g.dart';

// ---------- Infrastructure Providers ----------

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

@Riverpod(keepAlive: true)
QuestDao questDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.questDao;
}

@Riverpod(keepAlive: true)
QuestRemoteDataSource questRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuestRemoteDataSource(apiClient: apiClient);
}

@Riverpod(keepAlive: true)
GpsService gpsService(Ref ref) {
  return GpsService();
}

@riverpod
Future<bool> isOnline(Ref ref) async {
  final result = await Connectivity().checkConnectivity();
  return !result.contains(ConnectivityResult.none);
}

@Riverpod(keepAlive: true)
QuestRepositoryImpl questRepository(Ref ref) {
  final questDao = ref.watch(questDaoProvider);
  final remoteDataSource = ref.watch(questRemoteDataSourceProvider);

  return QuestRepositoryImpl(
    questDao: questDao,
    remoteDataSource: remoteDataSource,
    isOnline: () => ref.read(isOnlineProvider.future),
  );
}

// ---------- Distance Filter ----------

enum DistanceFilter { km2, km5, km10, km20 }

extension DistanceFilterValue on DistanceFilter {
  double get kilometers => switch (this) {
        DistanceFilter.km2 => 2.0,
        DistanceFilter.km5 => 5.0,
        DistanceFilter.km10 => 10.0,
        DistanceFilter.km20 => 20.0,
      };

  String get label => switch (this) {
        DistanceFilter.km2 => '2 km',
        DistanceFilter.km5 => '5 km',
        DistanceFilter.km10 => '10 km',
        DistanceFilter.km20 => '20 km',
      };
}

@riverpod
class DistanceFilterNotifier extends _$DistanceFilterNotifier {
  @override
  DistanceFilter build() => DistanceFilter.km5;

  void setFilter(DistanceFilter filter) => state = filter;
}

// ---------- Location Providers ----------

@riverpod
Future<Either<Failure, Position>> currentPosition(Ref ref) async {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.getCurrentPosition();
}

// ---------- Quest List State ----------

/// State for the quest list screen.
///
/// Uses a sentinel value pattern for nullable field clearing.
class QuestListState {
  final List<Quest> quests;
  final Position? userPosition;
  final DistanceFilter filter;
  final bool isOffline;
  final bool isLoading;
  final String? error;

  const QuestListState({
    this.quests = const [],
    this.userPosition,
    this.filter = DistanceFilter.km5,
    this.isOffline = false,
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty => quests.isEmpty;
  bool get hasError => error != null;

  /// Creates a copy with the specified fields replaced.
  ///
  /// To explicitly clear nullable fields:
  /// - Use [clearError] = true to set error to null
  /// - Use [clearUserPosition] = true to set userPosition to null
  QuestListState copyWith({
    List<Quest>? quests,
    Position? userPosition,
    bool clearUserPosition = false,
    DistanceFilter? filter,
    bool? isOffline,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return QuestListState(
      quests: quests ?? this.quests,
      userPosition:
          clearUserPosition ? null : (userPosition ?? this.userPosition),
      filter: filter ?? this.filter,
      isOffline: isOffline ?? this.isOffline,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class QuestListNotifier extends _$QuestListNotifier {
  /// Sequence number to prevent race conditions when multiple loads occur.
  int _loadSequence = 0;

  @override
  QuestListState build() {
    _loadQuests();
    return const QuestListState(isLoading: true);
  }

  Future<void> _loadQuests() async {
    final currentSequence = ++_loadSequence;
    state = state.copyWith(isLoading: true, clearError: true);

    final gpsService = ref.read(gpsServiceProvider);
    final repository = ref.read(questRepositoryProvider);
    final filter = ref.read(distanceFilterProvider);
    final isOnline = await ref.read(isOnlineProvider.future);

    // Abort if a newer request has started
    if (currentSequence != _loadSequence) return;

    // Get current position
    final positionResult = await gpsService.getCurrentPosition();

    // Abort if a newer request has started
    if (currentSequence != _loadSequence) return;

    // Handle position result using pattern matching for proper async handling
    if (positionResult.isLeft()) {
      final failure = positionResult.getLeft().toNullable()!;
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
        isOffline: !isOnline,
      );
      return;
    }

    final position = positionResult.getRight().toNullable()!;

    // Fetch nearby quests
    final questsResult = await repository.getNearbyQuests(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: filter.kilometers,
    );

    // Abort if a newer request has started
    if (currentSequence != _loadSequence) return;

    if (questsResult.isLeft()) {
      final failure = questsResult.getLeft().toNullable()!;
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
        userPosition: position,
        isOffline: !isOnline,
      );
    } else {
      final quests = questsResult.getRight().toNullable()!;
      state = state.copyWith(
        quests: quests,
        userPosition: position,
        filter: filter,
        isOffline: !isOnline,
        isLoading: false,
      );
    }
  }

  Future<void> refresh() async {
    await _loadQuests();
  }

  void setFilter(DistanceFilter filter) {
    ref.read(distanceFilterProvider.notifier).setFilter(filter);
    _loadQuests();
  }
}

