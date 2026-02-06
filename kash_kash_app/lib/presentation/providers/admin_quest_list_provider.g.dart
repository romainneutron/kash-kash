// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_quest_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for admin quest list

@ProviderFor(AdminQuestListNotifier)
final adminQuestListProvider = AdminQuestListNotifierProvider._();

/// Notifier for admin quest list
final class AdminQuestListNotifierProvider
    extends
        $AsyncNotifierProvider<AdminQuestListNotifier, AdminQuestListState> {
  /// Notifier for admin quest list
  AdminQuestListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminQuestListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminQuestListNotifierHash();

  @$internal
  @override
  AdminQuestListNotifier create() => AdminQuestListNotifier();
}

String _$adminQuestListNotifierHash() =>
    r'4b4d5a34c5d23dd8cdc25f1ee173215d4b305794';

/// Notifier for admin quest list

abstract class _$AdminQuestListNotifier
    extends $AsyncNotifier<AdminQuestListState> {
  FutureOr<AdminQuestListState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AdminQuestListState>, AdminQuestListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AdminQuestListState>, AdminQuestListState>,
              AsyncValue<AdminQuestListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
