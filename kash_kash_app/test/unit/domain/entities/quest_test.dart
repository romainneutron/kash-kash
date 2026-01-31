import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('Quest', () {
    group('creation', () {
      test('should create quest with all required fields', () {
        final quest = FakeData.createQuest();

        expect(quest.id, 'quest-123');
        expect(quest.title, 'Test Quest');
        expect(quest.latitude, 48.8566);
        expect(quest.longitude, 2.3522);
        expect(quest.radiusMeters, 3.0);
        expect(quest.createdBy, 'user-123');
        expect(quest.published, isTrue);
      });

      test('should create quest with default radiusMeters', () {
        final quest = Quest(
          id: 'q1',
          title: 'Default Radius Quest',
          latitude: 0,
          longitude: 0,
          createdBy: 'user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(quest.radiusMeters, 3.0);
      });

      test('should create quest with optional fields', () {
        final quest = FakeData.createQuest(
          description: 'A detailed description',
          difficulty: QuestDifficulty.hard,
          locationType: LocationType.forest,
        );

        expect(quest.description, 'A detailed description');
        expect(quest.difficulty, QuestDifficulty.hard);
        expect(quest.locationType, LocationType.forest);
      });

      test('should allow null optional fields', () {
        final quest = Quest(
          id: 'q1',
          title: 'Minimal Quest',
          latitude: 0,
          longitude: 0,
          createdBy: 'user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(quest.description, isNull);
        expect(quest.difficulty, isNull);
        expect(quest.locationType, isNull);
        expect(quest.syncedAt, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with modified title', () {
        final quest = FakeData.createQuest();
        final copy = quest.copyWith(title: 'New Title');

        expect(copy.title, 'New Title');
        expect(copy.id, quest.id);
        expect(copy.latitude, quest.latitude);
      });

      test('should create copy with modified coordinates', () {
        final quest = FakeData.createQuest();
        final copy = quest.copyWith(
          latitude: 51.5074,
          longitude: -0.1278,
        );

        expect(copy.latitude, 51.5074);
        expect(copy.longitude, -0.1278);
      });

      test('should create copy with modified published status', () {
        final quest = FakeData.createQuest(published: false);
        final copy = quest.copyWith(published: true);

        expect(copy.published, isTrue);
      });

      test('should preserve all fields when no changes', () {
        final quest = FakeData.createQuest();
        final copy = quest.copyWith();

        expect(copy.id, quest.id);
        expect(copy.title, quest.title);
        expect(copy.description, quest.description);
        expect(copy.latitude, quest.latitude);
        expect(copy.longitude, quest.longitude);
        expect(copy.difficulty, quest.difficulty);
        expect(copy.locationType, quest.locationType);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final quest1 = FakeData.createQuest(id: 'same-id');
        final quest2 = FakeData.createQuest(id: 'same-id');

        expect(quest1, equals(quest2));
      });

      test('should not be equal when ids match but other fields differ', () {
        final quest1 = FakeData.createQuest(id: 'same-id');
        final quest2 = FakeData.createQuest(id: 'same-id', title: 'Different');

        expect(quest1, isNot(equals(quest2)));
      });

      test('should not be equal when ids differ', () {
        final quest1 = FakeData.createQuest(id: 'id-1');
        final quest2 = FakeData.createQuest(id: 'id-2');

        expect(quest1, isNot(equals(quest2)));
      });

      test('should have same hashCode for equal quests', () {
        final quest1 = FakeData.createQuest(id: 'same-id');
        final quest2 = FakeData.createQuest(id: 'same-id');

        expect(quest1.hashCode, equals(quest2.hashCode));
      });
    });
  });

  group('QuestDifficulty', () {
    test('should have all expected values', () {
      expect(
        QuestDifficulty.values,
        containsAll([
          QuestDifficulty.easy,
          QuestDifficulty.medium,
          QuestDifficulty.hard,
          QuestDifficulty.expert,
        ]),
      );
      expect(QuestDifficulty.values.length, 4);
    });
  });

  group('LocationType', () {
    test('should have all expected values', () {
      expect(
        LocationType.values,
        containsAll([
          LocationType.city,
          LocationType.forest,
          LocationType.park,
          LocationType.water,
          LocationType.mountain,
          LocationType.indoor,
        ]),
      );
      expect(LocationType.values.length, 6);
    });
  });
}
