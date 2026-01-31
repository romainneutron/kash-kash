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

String _$appDatabaseHash() => r'8c69eb46d45206533c176c88a926608e79ca927d';

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

@ProviderFor(isOnline)
final isOnlineProvider = IsOnlineProvider._();

final class IsOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
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

String _$isOnlineHash() => r'b993bbadf15b5af8a838ce3333fedb3e51d90a6a';

@ProviderFor(questRepository)
final questRepositoryProvider = QuestRepositoryProvider._();

final class QuestRepositoryProvider
    extends
        $FunctionalProvider<
          QuestRepositoryImpl,
          QuestRepositoryImpl,
          QuestRepositoryImpl
        >
    with $Provider<QuestRepositoryImpl> {
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
  $ProviderElement<QuestRepositoryImpl> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QuestRepositoryImpl create(Ref ref) {
    return questRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestRepositoryImpl>(value),
    );
  }
}

String _$questRepositoryHash() => r'9e850e4d463bc09b29cdc28c7cf0c4f6cc1564d2';

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
        isAutoDispose: true,
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
    r'8ffd7bb93ee4a1dbc83eb37d4fee65920832c9ac';

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

String _$questListNotifierHash() => r'f8d7394825b4659fe6f03af445a99479ce80f573';

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
