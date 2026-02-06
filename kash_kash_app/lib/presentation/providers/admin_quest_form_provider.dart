import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/coordinate_validators.dart';
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

  static const int maxTitleLength = 255;

  bool get hasRequiredFields => title.trim().isNotEmpty && hasLocation;
  bool get hasLocation => latitude != null && longitude != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestFormData &&
        other.title == title &&
        other.description == description &&
        other.difficulty == difficulty &&
        other.locationType == locationType &&
        other.radiusMeters == radiusMeters &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(
        title,
        description,
        difficulty,
        locationType,
        radiusMeters,
        latitude,
        longitude,
      );

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
  final bool isLocating;
  final String? error;

  const AdminQuestFormState({
    this.existingQuest,
    this.formData = const QuestFormData(),
    this.isSaving = false,
    this.isLocating = false,
    this.error,
  });

  bool get isEditing => existingQuest != null;
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminQuestFormState &&
        other.existingQuest == existingQuest &&
        other.formData == formData &&
        other.isSaving == isSaving &&
        other.isLocating == isLocating &&
        other.error == error;
  }

  @override
  int get hashCode =>
      Object.hash(existingQuest, formData, isSaving, isLocating, error);

  AdminQuestFormState copyWith({
    Quest? existingQuest,
    bool clearExistingQuest = false,
    QuestFormData? formData,
    bool? isSaving,
    bool? isLocating,
    String? error,
    bool clearError = false,
  }) {
    return AdminQuestFormState(
      existingQuest:
          clearExistingQuest ? null : (existingQuest ?? this.existingQuest),
      formData: formData ?? this.formData,
      isSaving: isSaving ?? this.isSaving,
      isLocating: isLocating ?? this.isLocating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for admin quest form (create/edit)
@riverpod
class AdminQuestFormNotifier extends _$AdminQuestFormNotifier {
  bool _mounted = true;

  AdminQuestFormState? _getCurrentState() {
    if (!_mounted) return null;
    return switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  void _setStateIfMounted(AsyncData<AdminQuestFormState> newState) {
    if (_mounted) state = newState;
  }

  @override
  FutureOr<AdminQuestFormState> build(String? questId) async {
    _mounted = true;
    ref.onDispose(() => _mounted = false);

    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) throw const PermissionFailure('Admin access required');

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
      formData: current.formData.copyWith(
        difficulty: difficulty,
        clearDifficulty: difficulty == null,
      ),
    ));
  }

  void updateLocationType(LocationType? locationType) {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: current.formData.copyWith(
        locationType: locationType,
        clearLocationType: locationType == null,
      ),
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

  void clearLocation() {
    final current = _getCurrentState();
    if (current == null) return;
    state = AsyncData(current.copyWith(
      formData: current.formData.copyWith(clearLocation: true),
    ));
  }

  Future<void> useCurrentLocation() async {
    final current = _getCurrentState();
    if (current == null || current.isLocating) return;

    state = AsyncData(current.copyWith(isLocating: true));

    final gpsService = ref.read(gpsServiceProvider);
    final positionResult = await gpsService.getCurrentPosition();

    final latest = _getCurrentState();
    if (latest == null) return;

    positionResult.fold(
      (failure) {
        _setStateIfMounted(AsyncData(latest.copyWith(
          isLocating: false,
          error: failure.message,
        )));
      },
      (position) {
        _setStateIfMounted(AsyncData(latest.copyWith(
          formData: latest.formData.copyWith(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          isLocating: false,
          clearError: true,
        )));
      },
    );
  }

  Future<Either<Failure, Quest>> save() async {
    final current = _getCurrentState();
    if (current == null) {
      return left(const ServerFailure('Form state not available'));
    }

    if (!current.formData.hasRequiredFields) {
      state = AsyncData(current.copyWith(
        error: 'Please fill in all required fields',
      ));
      return left(const ValidationFailure('Invalid form data'));
    }

    if (current.formData.title.trim().length > QuestFormData.maxTitleLength) {
      state = AsyncData(current.copyWith(
        error: 'Title must be ${QuestFormData.maxTitleLength} characters or less',
      ));
      return left(const ValidationFailure('Title too long'));
    }

    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    // Re-read state after setting isSaving to avoid stale references
    final saving = _getCurrentState()!;

    final repository = ref.read(questRepositoryProvider);
    final currentUser = ref.read(currentUserProvider);
    final now = DateTime.now();

    if (!saving.isEditing && currentUser == null) {
      state = AsyncData(saving.copyWith(
        isSaving: false,
        error: 'You must be logged in to create a quest',
      ));
      return left(const AuthFailure('User not authenticated'));
    }

    if (!CoordinateValidators.areCoordinatesInRange(
      saving.formData.latitude!,
      saving.formData.longitude!,
    )) {
      state = AsyncData(saving.copyWith(
        isSaving: false,
        error: 'Coordinates are out of range',
      ));
      return left(const ValidationFailure('Coordinates are out of range'));
    }

    final quest = Quest(
      id: saving.existingQuest?.id ?? _uuid.v4(),
      title: saving.formData.title.trim(),
      description: saving.formData.description.trim().isEmpty
          ? null
          : saving.formData.description.trim(),
      latitude: saving.formData.latitude!,
      longitude: saving.formData.longitude!,
      radiusMeters: saving.formData.radiusMeters,
      createdBy: saving.existingQuest?.createdBy ?? currentUser!.id,
      published: saving.existingQuest?.published ?? false,
      difficulty: saving.formData.difficulty,
      locationType: saving.formData.locationType,
      createdAt: saving.existingQuest?.createdAt ?? now,
      updatedAt: now,
    );

    final Either<Failure, Quest> result;
    if (saving.isEditing) {
      result = await repository.updateQuest(quest);
    } else {
      result = await repository.createQuest(quest);
    }

    final latest = _getCurrentState();
    if (latest == null) return result;

    result.fold(
      (failure) {
        _setStateIfMounted(AsyncData(latest.copyWith(
          isSaving: false,
          error: failure.message,
        )));
      },
      (_) {
        _setStateIfMounted(AsyncData(latest.copyWith(isSaving: false)));
      },
    );

    return result;
  }
}
