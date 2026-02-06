import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/quest.dart';
import 'quest_provider.dart';

part 'admin_quest_list_provider.g.dart';

/// State for the admin quest list screen
class AdminQuestListState {
  final List<Quest> quests;
  final String searchQuery;
  final bool isSaving;
  final String? error;
  List<Quest> get filteredQuests => _computeFilteredQuests();

  AdminQuestListState({
    this.quests = const [],
    this.searchQuery = '',
    this.isSaving = false,
    this.error,
  });

  bool get isEmpty => filteredQuests.isEmpty;
  bool get hasError => error != null;

  List<Quest> _computeFilteredQuests() {
    if (searchQuery.isEmpty) return quests;
    final query = searchQuery.toLowerCase();
    return quests.where((q) => q.title.toLowerCase().contains(query)).toList();
  }

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
  AdminQuestListState? _getCurrentState() {
    return switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  @override
  FutureOr<AdminQuestListState> build() async {
    final repository = ref.read(questRepositoryProvider);
    final result = await repository.getAllQuests();

    return result.fold(
      (failure) => AdminQuestListState(error: failure.message),
      (quests) => AdminQuestListState(quests: quests),
    );
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
        state = AsyncData(latest.copyWith(
          isSaving: false,
          error: failure.message,
        ));
      },
      (updatedQuest) {
        final updatedQuests = latest.quests.map((q) {
          if (q.id == quest.id) return updatedQuest;
          return q;
        }).toList();

        state = AsyncData(latest.copyWith(
          quests: updatedQuests,
          isSaving: false,
        ));
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
        state = AsyncData(latest.copyWith(
          isSaving: false,
          error: failure.message,
        ));
      },
      (_) {
        final updatedQuests =
            latest.quests.where((q) => q.id != questId).toList();
        state = AsyncData(latest.copyWith(
          quests: updatedQuests,
          isSaving: false,
        ));
      },
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
