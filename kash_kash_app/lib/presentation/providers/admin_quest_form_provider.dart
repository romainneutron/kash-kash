import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/quest.dart';
import 'auth_provider.dart';
import 'quest_provider.dart';

part 'admin_quest_form_provider.g.dart';

const _uuid = Uuid();

/// Value class holding form data for quest creation/editing
class QuestFormData {
  final String title;
  final String description;
  final QuestDifficulty? difficulty;
  final LocationType? locationType;
  final double radiusMeters;
  final double? latitude;
  final double? longitude;

  const QuestFormData({
    this.title = '',
    this.description = '',
    this.difficulty,
    this.locationType,
    this.radiusMeters = 3.0,
    this.latitude,
    this.longitude,
  });

  bool get isValid => title.trim().isNotEmpty && hasLocation;
  bool get hasLocation => latitude != null && longitude != null;

  QuestFormData copyWith({
    String? title,
    String? description,
    QuestDifficulty? difficulty,
    bool clearDifficulty = false,
    LocationType? locationType,
    bool clearLocationType = false,
    double? radiusMeters,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
  }) {
    return QuestFormData(
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      locationType:
          clearLocationType ? null : (locationType ?? this.locationType),
      radiusMeters: radiusMeters ?? this.radiusMeters,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
    );
  }
}

/// State for the admin quest form screen
class AdminQuestFormState {
  final Quest? existingQuest;
  final QuestFormData formData;
  final bool isSaving;
  final String? error;

  const AdminQuestFormState({
    this.existingQuest,
    this.formData = const QuestFormData(),
    this.isSaving = false,
    this.error,
  });

  bool get isEditing => existingQuest != null;
  bool get hasError => error != null;

  AdminQuestFormState copyWith({
    Quest? existingQuest,
    QuestFormData? formData,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return AdminQuestFormState(
      existingQuest: existingQuest ?? this.existingQuest,
      formData: formData ?? this.formData,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for admin quest form (create/edit)
@riverpod
class AdminQuestFormNotifier extends _$AdminQuestFormNotifier {
  AdminQuestFormState? _getCurrentState() {
    return switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  @override
  FutureOr<AdminQuestFormState> build(String? questId) async {
    if (questId == null) {
      return const AdminQuestFormState();
    }

    // Load existing quest for edit mode
    final repository = ref.read(questRepositoryProvider);
    final result = await repository.getQuestById(questId);

    return result.fold(
      (failure) => AdminQuestFormState(error: failure.message),
      (quest) => AdminQuestFormState(
        existingQuest: quest,
        formData: QuestFormData(
          title: quest.title,
          description: quest.description ?? '',
          difficulty: quest.difficulty,
          locationType: quest.locationType,
          radiusMeters: quest.radiusMeters,
          latitude: quest.latitude,
          longitude: quest.longitude,
        ),
      ),
    );
  }

  void clearError() {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(clearError: true));
  }

  void updateTitle(String title) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: current.formData.copyWith(title: title),
      clearError: true,
    ));
  }

  void updateDescription(String description) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: current.formData.copyWith(description: description),
    ));
  }

  void updateDifficulty(QuestDifficulty? difficulty) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: difficulty == null
          ? current.formData.copyWith(clearDifficulty: true)
          : current.formData.copyWith(difficulty: difficulty),
    ));
  }

  void updateLocationType(LocationType? locationType) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: locationType == null
          ? current.formData.copyWith(clearLocationType: true)
          : current.formData.copyWith(locationType: locationType),
    ));
  }

  void updateRadius(double radiusMeters) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: current.formData.copyWith(radiusMeters: radiusMeters),
    ));
  }

  void updateLocation({required double latitude, required double longitude}) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: current.formData.copyWith(
        latitude: latitude,
        longitude: longitude,
      ),
    ));
  }

  Future<void> useCurrentLocation() async {
    if (_getCurrentState() == null) return;

    final gpsService = ref.read(gpsServiceProvider);
    final positionResult = await gpsService.getCurrentPosition();

    final latest = _getCurrentState();
    if (latest == null) return;

    positionResult.fold(
      (failure) {
        state = AsyncData(latest.copyWith(error: failure.message));
      },
      (position) {
        state = AsyncData(latest.copyWith(
          formData: latest.formData.copyWith(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          clearError: true,
        ));
      },
    );
  }

  Future<Either<Failure, Quest>> save() async {
    final current = _getCurrentState();
    if (current == null) {
      return left(const ServerFailure('Form state not available'));
    }

    if (!current.formData.isValid) {
      state = AsyncData(current.copyWith(
        error: 'Please fill in all required fields',
      ));
      return left(const ValidationFailure('Invalid form data'));
    }

    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    final repository = ref.read(questRepositoryProvider);
    final currentUser = ref.read(currentUserProvider);
    final now = DateTime.now();

    if (!current.isEditing && currentUser == null) {
      state = AsyncData(current.copyWith(
        isSaving: false,
        error: 'You must be logged in to create a quest',
      ));
      return left(const AuthFailure('User not authenticated'));
    }

    final quest = Quest(
      id: current.existingQuest?.id ?? _uuid.v4(),
      title: current.formData.title.trim(),
      description: current.formData.description.trim().isEmpty
          ? null
          : current.formData.description.trim(),
      latitude: current.formData.latitude!,
      longitude: current.formData.longitude!,
      radiusMeters: current.formData.radiusMeters,
      createdBy: current.existingQuest?.createdBy ?? currentUser!.id,
      published: current.existingQuest?.published ?? false,
      difficulty: current.formData.difficulty,
      locationType: current.formData.locationType,
      createdAt: current.existingQuest?.createdAt ?? now,
      updatedAt: now,
    );

    final Either<Failure, Quest> result;
    if (current.isEditing) {
      result = await repository.updateQuest(quest);
    } else {
      result = await repository.createQuest(quest);
    }

    final latest = _getCurrentState();
    if (latest == null) return result;

    result.fold(
      (failure) {
        state = AsyncData(latest.copyWith(
          isSaving: false,
          error: failure.message,
        ));
      },
      (_) {
        state = AsyncData(latest.copyWith(isSaving: false));
      },
    );

    return result;
  }
}
