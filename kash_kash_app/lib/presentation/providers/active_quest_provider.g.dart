// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_quest_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attemptDao)
final attemptDaoProvider = AttemptDaoProvider._();

final class AttemptDaoProvider
    extends $FunctionalProvider<AttemptDao, AttemptDao, AttemptDao>
    with $Provider<AttemptDao> {
  AttemptDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attemptDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attemptDaoHash();

  @$internal
  @override
  $ProviderElement<AttemptDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AttemptDao create(Ref ref) {
    return attemptDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttemptDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttemptDao>(value),
    );
  }
}

String _$attemptDaoHash() => r'cfcd66fa95ad4371c4c66091f3604c73222889e4';

@ProviderFor(pathPointDao)
final pathPointDaoProvider = PathPointDaoProvider._();

final class PathPointDaoProvider
    extends $FunctionalProvider<PathPointDao, PathPointDao, PathPointDao>
    with $Provider<PathPointDao> {
  PathPointDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pathPointDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pathPointDaoHash();

  @$internal
  @override
  $ProviderElement<PathPointDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PathPointDao create(Ref ref) {
    return pathPointDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PathPointDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PathPointDao>(value),
    );
  }
}

String _$pathPointDaoHash() => r'9f829d291c689a01a637e175e6981ddf5fb55a6b';

@ProviderFor(attemptRepository)
final attemptRepositoryProvider = AttemptRepositoryProvider._();

final class AttemptRepositoryProvider
    extends
        $FunctionalProvider<
          IAttemptRepository,
          IAttemptRepository,
          IAttemptRepository
        >
    with $Provider<IAttemptRepository> {
  AttemptRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attemptRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attemptRepositoryHash();

  @$internal
  @override
  $ProviderElement<IAttemptRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IAttemptRepository create(Ref ref) {
    return attemptRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAttemptRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAttemptRepository>(value),
    );
  }
}

String _$attemptRepositoryHash() => r'f38dbd6f7027c7e2038ef65e277069fa9140e9a7';

@ProviderFor(startQuestUseCase)
final startQuestUseCaseProvider = StartQuestUseCaseProvider._();

final class StartQuestUseCaseProvider
    extends
        $FunctionalProvider<
          StartQuestUseCase,
          StartQuestUseCase,
          StartQuestUseCase
        >
    with $Provider<StartQuestUseCase> {
  StartQuestUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startQuestUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startQuestUseCaseHash();

  @$internal
  @override
  $ProviderElement<StartQuestUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StartQuestUseCase create(Ref ref) {
    return startQuestUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartQuestUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartQuestUseCase>(value),
    );
  }
}

String _$startQuestUseCaseHash() => r'774d4e2d0f000f4eed6bfb5f377689a318b12581';

@ProviderFor(completeQuestUseCase)
final completeQuestUseCaseProvider = CompleteQuestUseCaseProvider._();

final class CompleteQuestUseCaseProvider
    extends
        $FunctionalProvider<
          CompleteQuestUseCase,
          CompleteQuestUseCase,
          CompleteQuestUseCase
        >
    with $Provider<CompleteQuestUseCase> {
  CompleteQuestUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completeQuestUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completeQuestUseCaseHash();

  @$internal
  @override
  $ProviderElement<CompleteQuestUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompleteQuestUseCase create(Ref ref) {
    return completeQuestUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompleteQuestUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompleteQuestUseCase>(value),
    );
  }
}

String _$completeQuestUseCaseHash() =>
    r'695f50fa7e92e45e886a3a9988c946d3adc970b2';

@ProviderFor(abandonQuestUseCase)
final abandonQuestUseCaseProvider = AbandonQuestUseCaseProvider._();

final class AbandonQuestUseCaseProvider
    extends
        $FunctionalProvider<
          AbandonQuestUseCase,
          AbandonQuestUseCase,
          AbandonQuestUseCase
        >
    with $Provider<AbandonQuestUseCase> {
  AbandonQuestUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'abandonQuestUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$abandonQuestUseCaseHash();

  @$internal
  @override
  $ProviderElement<AbandonQuestUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AbandonQuestUseCase create(Ref ref) {
    return abandonQuestUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AbandonQuestUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AbandonQuestUseCase>(value),
    );
  }
}

String _$abandonQuestUseCaseHash() =>
    r'72cf5a4f6a7a94b1a9d357d9426d78efce7f8b53';

/// Notifier for active quest gameplay.
///
/// Manages the gameplay loop including GPS tracking, state transitions,
/// path recording, and win/abandon handling.

@ProviderFor(ActiveQuestNotifier)
final activeQuestProvider = ActiveQuestNotifierFamily._();

/// Notifier for active quest gameplay.
///
/// Manages the gameplay loop including GPS tracking, state transitions,
/// path recording, and win/abandon handling.
final class ActiveQuestNotifierProvider
    extends $AsyncNotifierProvider<ActiveQuestNotifier, ActiveQuestState> {
  /// Notifier for active quest gameplay.
  ///
  /// Manages the gameplay loop including GPS tracking, state transitions,
  /// path recording, and win/abandon handling.
  ActiveQuestNotifierProvider._({
    required ActiveQuestNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeQuestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeQuestNotifierHash();

  @override
  String toString() {
    return r'activeQuestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveQuestNotifier create() => ActiveQuestNotifier();

  @override
  bool operator ==(Object other) {
    return other is ActiveQuestNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeQuestNotifierHash() =>
    r'5a139ceb5231ba88437ee3af10658c730cc39074';

/// Notifier for active quest gameplay.
///
/// Manages the gameplay loop including GPS tracking, state transitions,
/// path recording, and win/abandon handling.

final class ActiveQuestNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveQuestNotifier,
          AsyncValue<ActiveQuestState>,
          ActiveQuestState,
          FutureOr<ActiveQuestState>,
          String
        > {
  ActiveQuestNotifierFamily._()
    : super(
        retry: null,
        name: r'activeQuestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for active quest gameplay.
  ///
  /// Manages the gameplay loop including GPS tracking, state transitions,
  /// path recording, and win/abandon handling.

  ActiveQuestNotifierProvider call(String questId) =>
      ActiveQuestNotifierProvider._(argument: questId, from: this);

  @override
  String toString() => r'activeQuestProvider';
}

/// Notifier for active quest gameplay.
///
/// Manages the gameplay loop including GPS tracking, state transitions,
/// path recording, and win/abandon handling.

abstract class _$ActiveQuestNotifier extends $AsyncNotifier<ActiveQuestState> {
  late final _$args = ref.$arg as String;
  String get questId => _$args;

  FutureOr<ActiveQuestState> build(String questId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ActiveQuestState>, ActiveQuestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ActiveQuestState>, ActiveQuestState>,
              AsyncValue<ActiveQuestState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
