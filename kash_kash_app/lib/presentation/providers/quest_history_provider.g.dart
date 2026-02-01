// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for history filter state

@ProviderFor(HistoryFilterNotifier)
final historyFilterProvider = HistoryFilterNotifierProvider._();

/// Provider for history filter state
final class HistoryFilterNotifierProvider
    extends $NotifierProvider<HistoryFilterNotifier, HistoryFilter> {
  /// Provider for history filter state
  HistoryFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyFilterNotifierHash();

  @$internal
  @override
  HistoryFilterNotifier create() => HistoryFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryFilter>(value),
    );
  }
}

String _$historyFilterNotifierHash() =>
    r'2f34f9efe56ca44b703e84c72118a458b300d760';

/// Provider for history filter state

abstract class _$HistoryFilterNotifier extends $Notifier<HistoryFilter> {
  HistoryFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistoryFilter, HistoryFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryFilter, HistoryFilter>,
              HistoryFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for quest history

@ProviderFor(QuestHistoryNotifier)
final questHistoryProvider = QuestHistoryNotifierProvider._();

/// Provider for quest history
final class QuestHistoryNotifierProvider
    extends $AsyncNotifierProvider<QuestHistoryNotifier, QuestHistoryState> {
  /// Provider for quest history
  QuestHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questHistoryNotifierHash();

  @$internal
  @override
  QuestHistoryNotifier create() => QuestHistoryNotifier();
}

String _$questHistoryNotifierHash() =>
    r'bae475c0f31d0168e81f30af1eba3d2ce2d323da';

/// Provider for quest history

abstract class _$QuestHistoryNotifier
    extends $AsyncNotifier<QuestHistoryState> {
  FutureOr<QuestHistoryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<QuestHistoryState>, QuestHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<QuestHistoryState>, QuestHistoryState>,
              AsyncValue<QuestHistoryState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
