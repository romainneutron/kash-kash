// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_quest_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for admin quest form (create/edit)

@ProviderFor(AdminQuestFormNotifier)
final adminQuestFormProvider = AdminQuestFormNotifierFamily._();

/// Notifier for admin quest form (create/edit)
final class AdminQuestFormNotifierProvider
    extends
        $AsyncNotifierProvider<AdminQuestFormNotifier, AdminQuestFormState> {
  /// Notifier for admin quest form (create/edit)
  AdminQuestFormNotifierProvider._({
    required AdminQuestFormNotifierFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'adminQuestFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminQuestFormNotifierHash();

  @override
  String toString() {
    return r'adminQuestFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminQuestFormNotifier create() => AdminQuestFormNotifier();

  @override
  bool operator ==(Object other) {
    return other is AdminQuestFormNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminQuestFormNotifierHash() =>
    r'9b0290a348c9e1c1e789f2406cdada52f2590265';

/// Notifier for admin quest form (create/edit)

final class AdminQuestFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AdminQuestFormNotifier,
          AsyncValue<AdminQuestFormState>,
          AdminQuestFormState,
          FutureOr<AdminQuestFormState>,
          String?
        > {
  AdminQuestFormNotifierFamily._()
    : super(
        retry: null,
        name: r'adminQuestFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for admin quest form (create/edit)

  AdminQuestFormNotifierProvider call(String? questId) =>
      AdminQuestFormNotifierProvider._(argument: questId, from: this);

  @override
  String toString() => r'adminQuestFormProvider';
}

/// Notifier for admin quest form (create/edit)

abstract class _$AdminQuestFormNotifier
    extends $AsyncNotifier<AdminQuestFormState> {
  late final _$args = ref.$arg as String?;
  String? get questId => _$args;

  FutureOr<AdminQuestFormState> build(String? questId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AdminQuestFormState>, AdminQuestFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AdminQuestFormState>, AdminQuestFormState>,
              AsyncValue<AdminQuestFormState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
