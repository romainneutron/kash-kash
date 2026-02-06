import 'package:flutter/foundation.dart' show listEquals;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/quest.dart';
import 'auth_provider.dart';
import 'quest_provider.dart';

part 'admin_quest_list_provider.g.dart';

/// State for the admin quest list screen
class AdminQuestListState {
  final List<Quest> quests;
  final String searchQuery;
  final bool isSaving;
  final String? error;

  const AdminQuestListState({
    this.quests = const [],
    this.searchQuery = '',
    this.isSaving = false,
    this.error,
  });

  List<Quest> get filteredQuests {
    if (searchQuery.isEmpty) return quests;
    final query = searchQuery.toLowerCase();
    return quests.where((q) => q.title.toLowerCase().contains(query)).toList();
  }

  bool get isFilteredEmpty => filteredQuests.isEmpty;
  bool get hasNoQuests => quests.isEmpty;
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminQuestListState &&
        listEquals(other.quests, quests) &&
        other.searchQuery == searchQuery &&
        other.isSaving == isSaving &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(quests),
        searchQuery,
        isSaving,
        error,
      );

  AdminQuestListState copyWith({
    List<Quest>? quests,
    String? searchQuery,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return AdminQuestListState(
      quests: quests ?? this.quests,
      searchQuery: searchQuery ?? this.searchQuery,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for admin quest list
@riverpod
class AdminQuestListNotifier extends _$AdminQuestListNotifier {
  bool _mounted = true;

  AdminQuestListState? _getCurrentState() {
    if (!_mounted) return null;
    return switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  void _setStateIfMounted(AsyncData<AdminQuestListState> newState) {
    if (_mounted) state = newState;
  }

  @override
  FutureOr<AdminQuestListState> build() async {
    _mounted = true;
    ref.onDispose(() => _mounted = false);

    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) throw const PermissionFailure('Admin access required');

    final repository = ref.read(questRepositoryProvider);
    final result = await repository.getAllQuests();

    return result.fold(
      (failure) => throw failure,
      (quests) => AdminQuestListState(quests: quests),
    );
  }

  void clearError() {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(clearError: true));
  }

  void setSearchQuery(String query) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }

  Future<void> togglePublished(Quest quest) async {
    final current = _getCurrentState();
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    final repository = ref.read(questRepositoryProvider);
    final result = quest.published
        ? await repository.unpublishQuest(quest.id)
        : await repository.publishQuest(quest.id);

    final latest = _getCurrentState();
    if (latest == null) return;

    result.fold(
      (failure) {
        _setStateIfMounted(AsyncData(latest.copyWith(
          isSaving: false,
          error: failure.message,
        )));
      },
      (updatedQuest) {
        final updatedQuests = [
          for (final q in latest.quests)
            if (q.id == quest.id) updatedQuest else q,
        ];
        _setStateIfMounted(AsyncData(latest.copyWith(
          quests: updatedQuests,
          isSaving: false,
        )));
      },
    );
  }

  Future<void> deleteQuest(String questId) async {
    final current = _getCurrentState();
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    final repository = ref.read(questRepositoryProvider);
    final result = await repository.deleteQuest(questId);

    final latest = _getCurrentState();
    if (latest == null) return;

    result.fold(
      (failure) {
        _setStateIfMounted(AsyncData(latest.copyWith(
          isSaving: false,
          error: failure.message,
        )));
      },
      (_) {
        final updatedQuests =
            latest.quests.where((q) => q.id != questId).toList();
        _setStateIfMounted(AsyncData(latest.copyWith(
          quests: updatedQuests,
          isSaving: false,
        )));
      },
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
