import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/quest.dart';
import '../../domain/entities/quest_attempt.dart';
import 'active_quest_provider.dart';
import 'auth_provider.dart';
import 'quest_provider.dart';

part 'quest_history_provider.g.dart';

/// Filter for history list
enum HistoryFilter { all, completed, abandoned }

/// A quest attempt paired with its quest details
class QuestAttemptWithQuest {
  final QuestAttempt attempt;
  final Quest? quest;

  const QuestAttemptWithQuest({
    required this.attempt,
    this.quest,
  });
}

/// State for quest history screen
class QuestHistoryState {
  final List<QuestAttemptWithQuest> attempts;
  final HistoryFilter filter;
  final bool isLoading;
  final String? error;

  const QuestHistoryState({
    this.attempts = const [],
    this.filter = HistoryFilter.all,
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty => attempts.isEmpty;
  bool get hasError => error != null;

  QuestHistoryState copyWith({
    List<QuestAttemptWithQuest>? attempts,
    HistoryFilter? filter,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return QuestHistoryState(
      attempts: attempts ?? this.attempts,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for history filter state
@riverpod
class HistoryFilterNotifier extends _$HistoryFilterNotifier {
  @override
  HistoryFilter build() => HistoryFilter.all;

  void setFilter(HistoryFilter filter) => state = filter;
}

/// Provider for quest history
@riverpod
class QuestHistoryNotifier extends _$QuestHistoryNotifier {
  @override
  FutureOr<QuestHistoryState> build() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return const QuestHistoryState(error: 'User not authenticated');
    }

    final filter = ref.watch(historyFilterProvider);

    // Get user's attempt history
    final attemptRepository = ref.read(attemptRepositoryProvider);
    final attemptsResult = await attemptRepository.getUserAttempts(user.id);

    if (attemptsResult.isLeft()) {
      final error =
          attemptsResult.getLeft().toNullable()?.message ?? 'Unknown error';
      return QuestHistoryState(error: error, filter: filter);
    }

    var attempts = attemptsResult.getRight().toNullable() ?? [];

    // Apply filter
    if (filter != HistoryFilter.all) {
      attempts = attempts.where((a) {
        return filter == HistoryFilter.completed
            ? a.status == AttemptStatus.completed
            : a.status == AttemptStatus.abandoned;
      }).toList();
    }

    // Fetch quest details for each attempt
    final questRepository = ref.read(questRepositoryProvider);
    final attemptsWithQuests = await Future.wait(
      attempts.map((attempt) async {
        final questResult = await questRepository.getQuestById(attempt.questId);
        return QuestAttemptWithQuest(
          attempt: attempt,
          quest: questResult.fold((_) => null, (q) => q),
        );
      }),
    );

    return QuestHistoryState(
      attempts: attemptsWithQuests,
      filter: filter,
    );
  }

  /// Refresh the history list
  Future<void> refresh() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}
