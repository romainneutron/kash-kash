// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'448adad5717e7b1c0b3ca3ca7e03d0b2116237af';

@ProviderFor(questDao)
final questDaoProvider = QuestDaoProvider._();

final class QuestDaoProvider
    extends $FunctionalProvider<QuestDao, QuestDao, QuestDao>
    with $Provider<QuestDao> {
  QuestDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questDaoHash();

  @$internal
  @override
  $ProviderElement<QuestDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuestDao create(Ref ref) {
    return questDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestDao>(value),
    );
  }
}

String _$questDaoHash() => r'45fb3efda95850f572455234d83723c6f6b7d9c3';

@ProviderFor(questRemoteDataSource)
final questRemoteDataSourceProvider = QuestRemoteDataSourceProvider._();

final class QuestRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          QuestRemoteDataSource,
          QuestRemoteDataSource,
          QuestRemoteDataSource
        >
    with $Provider<QuestRemoteDataSource> {
  QuestRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<QuestRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QuestRemoteDataSource create(Ref ref) {
    return questRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestRemoteDataSource>(value),
    );
  }
}

String _$questRemoteDataSourceHash() =>
    r'db2bb691173b3610a29f7eae1bb16281851c7c40';

@ProviderFor(gpsService)
final gpsServiceProvider = GpsServiceProvider._();

final class GpsServiceProvider
    extends $FunctionalProvider<GpsService, GpsService, GpsService>
    with $Provider<GpsService> {
  GpsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gpsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gpsServiceHash();

  @$internal
  @override
  $ProviderElement<GpsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GpsService create(Ref ref) {
    return gpsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GpsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GpsService>(value),
    );
  }
}

String _$gpsServiceHash() => r'0ba352c3b46fa9ffe34b5577e60bdd7dc9ee5192';

/// Reactive connectivity provider that watches for network changes.
///
/// Uses AsyncNotifier to properly handle initial connectivity check.

@ProviderFor(ConnectivityNotifier)
final connectivityProvider = ConnectivityNotifierProvider._();

/// Reactive connectivity provider that watches for network changes.
///
/// Uses AsyncNotifier to properly handle initial connectivity check.
final class ConnectivityNotifierProvider
    extends $AsyncNotifierProvider<ConnectivityNotifier, bool> {
  /// Reactive connectivity provider that watches for network changes.
  ///
  /// Uses AsyncNotifier to properly handle initial connectivity check.
  ConnectivityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityNotifierHash();

  @$internal
  @override
  ConnectivityNotifier create() => ConnectivityNotifier();
}

String _$connectivityNotifierHash() =>
    r'4d296b012be0bc9cadb08a0e7f29adcbf1aedacd';

/// Reactive connectivity provider that watches for network changes.
///
/// Uses AsyncNotifier to properly handle initial connectivity check.

abstract class _$ConnectivityNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Legacy provider for backwards compatibility.

@ProviderFor(isOnline)
final isOnlineProvider = IsOnlineProvider._();

/// Legacy provider for backwards compatibility.

final class IsOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Legacy provider for backwards compatibility.
  IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isOnline(ref);
  }
}

String _$isOnlineHash() => r'6d2d491257bd62104d36382d09daad75d9ffa90d';

@ProviderFor(questRepository)
final questRepositoryProvider = QuestRepositoryProvider._();

final class QuestRepositoryProvider
    extends
        $FunctionalProvider<
          IQuestRepository,
          IQuestRepository,
          IQuestRepository
        >
    with $Provider<IQuestRepository> {
  QuestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questRepositoryHash();

  @$internal
  @override
  $ProviderElement<IQuestRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IQuestRepository create(Ref ref) {
    return questRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IQuestRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IQuestRepository>(value),
    );
  }
}

String _$questRepositoryHash() => r'd2e198d2641ec3a634ac511d709f10ef0c0c0075';

@ProviderFor(DistanceFilterNotifier)
final distanceFilterProvider = DistanceFilterNotifierProvider._();

final class DistanceFilterNotifierProvider
    extends $NotifierProvider<DistanceFilterNotifier, DistanceFilter> {
  DistanceFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'distanceFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$distanceFilterNotifierHash();

  @$internal
  @override
  DistanceFilterNotifier create() => DistanceFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DistanceFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DistanceFilter>(value),
    );
  }
}

String _$distanceFilterNotifierHash() =>
    r'4b19370be9b6dfcde7677abb40a1142f453a25be';

abstract class _$DistanceFilterNotifier extends $Notifier<DistanceFilter> {
  DistanceFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DistanceFilter, DistanceFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DistanceFilter, DistanceFilter>,
              DistanceFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(currentPosition)
final currentPositionProvider = CurrentPositionProvider._();

final class CurrentPositionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Either<Failure, Position>>,
          Either<Failure, Position>,
          FutureOr<Either<Failure, Position>>
        >
    with
        $FutureModifier<Either<Failure, Position>>,
        $FutureProvider<Either<Failure, Position>> {
  CurrentPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPositionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPositionHash();

  @$internal
  @override
  $FutureProviderElement<Either<Failure, Position>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Either<Failure, Position>> create(Ref ref) {
    return currentPosition(ref);
  }
}

String _$currentPositionHash() => r'525b156b36c165c3707d6c69509a630142ac074d';

@ProviderFor(QuestListNotifier)
final questListProvider = QuestListNotifierProvider._();

final class QuestListNotifierProvider
    extends $NotifierProvider<QuestListNotifier, QuestListState> {
  QuestListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questListNotifierHash();

  @$internal
  @override
  QuestListNotifier create() => QuestListNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestListState>(value),
    );
  }
}

String _$questListNotifierHash() => r'48959a12f0b05ebfb67c9f7cb79c90cac92bafb5';

abstract class _$QuestListNotifier extends $Notifier<QuestListState> {
  QuestListState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QuestListState, QuestListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuestListState, QuestListState>,
              QuestListState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
