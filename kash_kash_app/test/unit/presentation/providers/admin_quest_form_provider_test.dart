import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_form_provider.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('QuestFormData', () {
    group('hasRequiredFields', () {
      test('returns true when title and location are set', () {
        const data = QuestFormData(
          title: 'Test',
          latitude: 48.0,
          longitude: 2.0,
        );

        expect(data.hasRequiredFields, isTrue);
      });

      test('returns false when title is empty', () {
        const data = QuestFormData(
          title: '',
          latitude: 48.0,
          longitude: 2.0,
        );

        expect(data.hasRequiredFields, isFalse);
      });

      test('returns false when title is whitespace only', () {
        const data = QuestFormData(
          title: '   ',
          latitude: 48.0,
          longitude: 2.0,
        );

        expect(data.hasRequiredFields, isFalse);
      });

      test('returns false when latitude is null', () {
        const data = QuestFormData(
          title: 'Test',
          longitude: 2.0,
        );

        expect(data.hasRequiredFields, isFalse);
      });

      test('returns false when longitude is null', () {
        const data = QuestFormData(
          title: 'Test',
          latitude: 48.0,
        );

        expect(data.hasRequiredFields, isFalse);
      });
    });

    group('hasLocation', () {
      test('returns true when both lat and lng are set', () {
        const data = QuestFormData(latitude: 48.0, longitude: 2.0);

        expect(data.hasLocation, isTrue);
      });

      test('returns false when latitude is null', () {
        const data = QuestFormData(longitude: 2.0);

        expect(data.hasLocation, isFalse);
      });

      test('returns false when longitude is null', () {
        const data = QuestFormData(latitude: 48.0);

        expect(data.hasLocation, isFalse);
      });

      test('returns false when both are null', () {
        const data = QuestFormData();

        expect(data.hasLocation, isFalse);
      });
    });

    group('copyWith', () {
      test('clearLocation sets lat/lng to null', () {
        const data = QuestFormData(latitude: 48.0, longitude: 2.0);
        final copy = data.copyWith(clearLocation: true);

        expect(copy.latitude, isNull);
        expect(copy.longitude, isNull);
      });

      test('clearDifficulty sets difficulty to null', () {
        const data = QuestFormData(difficulty: QuestDifficulty.hard);
        final copy = data.copyWith(clearDifficulty: true);

        expect(copy.difficulty, isNull);
      });

      test('clearLocationType sets locationType to null', () {
        const data = QuestFormData(locationType: LocationType.forest);
        final copy = data.copyWith(clearLocationType: true);

        expect(copy.locationType, isNull);
      });

      test('preserves unmodified fields', () {
        const data = QuestFormData(
          title: 'Original',
          description: 'Desc',
          difficulty: QuestDifficulty.easy,
          locationType: LocationType.park,
          radiusMeters: 5.0,
          latitude: 48.0,
          longitude: 2.0,
        );
        final copy = data.copyWith(title: 'Updated');

        expect(copy.title, 'Updated');
        expect(copy.description, 'Desc');
        expect(copy.difficulty, QuestDifficulty.easy);
        expect(copy.locationType, LocationType.park);
        expect(copy.radiusMeters, 5.0);
        expect(copy.latitude, 48.0);
        expect(copy.longitude, 2.0);
      });
    });

    group('equality', () {
      test('equal data are equal', () {
        const a = QuestFormData(title: 'Test', latitude: 48.0, longitude: 2.0);
        const b = QuestFormData(title: 'Test', latitude: 48.0, longitude: 2.0);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different data are not equal', () {
        const a = QuestFormData(title: 'A');
        const b = QuestFormData(title: 'B');

        expect(a, isNot(b));
      });
    });
  });

  group('AdminQuestFormState', () {
    group('isEditing', () {
      test('returns true when existingQuest is set', () {
        final state = AdminQuestFormState(
          existingQuest: FakeData.createQuest(),
        );

        expect(state.isEditing, isTrue);
      });

      test('returns false when existingQuest is null', () {
        const state = AdminQuestFormState();

        expect(state.isEditing, isFalse);
      });
    });

    group('hasError', () {
      test('returns true when error is set', () {
        const state = AdminQuestFormState(error: 'Something went wrong');

        expect(state.hasError, isTrue);
      });

      test('returns false when error is null', () {
        const state = AdminQuestFormState();

        expect(state.hasError, isFalse);
      });
    });

    group('copyWith', () {
      test('clearError removes error', () {
        const state = AdminQuestFormState(error: 'err');
        final copy = state.copyWith(clearError: true);

        expect(copy.error, isNull);
      });

      test('clearExistingQuest removes existingQuest', () {
        final state = AdminQuestFormState(
          existingQuest: FakeData.createQuest(),
        );
        final copy = state.copyWith(clearExistingQuest: true);

        expect(copy.existingQuest, isNull);
        expect(copy.isEditing, isFalse);
      });

      test('preserves fields when no arguments provided', () {
        final quest = FakeData.createQuest();
        final state = AdminQuestFormState(
          existingQuest: quest,
          formData: const QuestFormData(title: 'Test'),
          isSaving: true,
          error: 'err',
        );
        final copy = state.copyWith();

        expect(copy.existingQuest, quest);
        expect(copy.formData.title, 'Test');
        expect(copy.isSaving, isTrue);
        expect(copy.error, 'err');
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        const a = AdminQuestFormState(
          formData: QuestFormData(title: 'Test'),
        );
        const b = AdminQuestFormState(
          formData: QuestFormData(title: 'Test'),
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different states are not equal', () {
        const a = AdminQuestFormState(isSaving: true);
        const b = AdminQuestFormState(isSaving: false);

        expect(a, isNot(b));
      });
    });
  });
}
