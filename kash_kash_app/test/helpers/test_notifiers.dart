import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/presentation/providers/active_quest_provider.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_form_provider.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_list_provider.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_history_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';

/// Test auth notifier that returns a fixed auth state without side effects.
class TestAuthNotifier extends AuthNotifier {
  final AuthState _state;

  TestAuthNotifier(this._state);

  @override
  AuthState build() => _state;
}

/// Test quest list notifier that returns a fixed state without GPS/network.
class TestQuestListNotifier extends QuestListNotifier {
  final QuestListState _state;

  TestQuestListNotifier(this._state);

  @override
  QuestListState build() => _state;
}

/// Test quest history notifier that returns a fixed state without DB calls.
class TestQuestHistoryNotifier extends QuestHistoryNotifier {
  final QuestHistoryState _state;

  TestQuestHistoryNotifier(this._state);

  @override
  FutureOr<QuestHistoryState> build() => _state;
}

/// Test distance filter notifier that returns a fixed filter.
class TestDistanceFilterNotifier extends DistanceFilterNotifier {
  final DistanceFilter _filter;

  TestDistanceFilterNotifier(this._filter);

  @override
  DistanceFilter build() => _filter;
}

/// Test history filter notifier that returns a fixed filter.
class TestHistoryFilterNotifier extends HistoryFilterNotifier {
  final HistoryFilter _filter;

  TestHistoryFilterNotifier(this._filter);

  @override
  HistoryFilter build() => _filter;
}

/// Test notifier for admin quest list that returns a fixed async state.
class TestAdminQuestListNotifier extends AdminQuestListNotifier {
  final AdminQuestListState _state;

  /// Tracks calls to [togglePublished].
  final List<Quest> togglePublishedCalls = [];

  /// Tracks calls to [deleteQuest].
  final List<String> deleteQuestCalls = [];

  TestAdminQuestListNotifier(this._state);

  @override
  FutureOr<AdminQuestListState> build() => _state;

  @override
  Future<void> togglePublished(Quest quest) async {
    togglePublishedCalls.add(quest);
  }

  @override
  Future<void> deleteQuest(String questId) async {
    deleteQuestCalls.add(questId);
  }
}

/// Test notifier for admin quest form that returns a fixed async state.
class TestAdminQuestFormNotifier extends AdminQuestFormNotifier {
  final AdminQuestFormState _state;

  /// Tracks calls to [save].
  int saveCalls = 0;

  /// Tracks calls to [clearError].
  int clearErrorCalls = 0;

  /// Result to return from [save]. Defaults to a validation failure.
  Either<Failure, Quest> saveResult =
      const Left(ValidationFailure('test'));

  TestAdminQuestFormNotifier(this._state);

  @override
  FutureOr<AdminQuestFormState> build(String? questId) => _state;

  @override
  Future<Either<Failure, Quest>> save() async {
    saveCalls++;
    return saveResult;
  }

  @override
  void clearError() {
    clearErrorCalls++;
  }
}

/// Test notifier for active quest that returns a fixed async state.
class TestActiveQuestNotifier extends ActiveQuestNotifier {
  final AsyncValue<ActiveQuestState> _state;

  TestActiveQuestNotifier(this._state);

  @override
  FutureOr<ActiveQuestState> build(String questId) => switch (_state) {
        AsyncData(:final value) => value,
        AsyncError(:final error) => throw error,
        _ => Completer<ActiveQuestState>().future,
      };
}
