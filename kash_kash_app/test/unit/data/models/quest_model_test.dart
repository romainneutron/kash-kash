import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart' as db;
import 'package:kash_kash_app/data/models/quest_model.dart';
import 'package:kash_kash_app/domain/entities/quest.dart' as domain;

void main() {
  group('QuestModel', () {
    final now = DateTime.now();
    final testJson = {
      'id': 'quest-123',
      'title': 'Test Quest',
      'description': 'A test quest description',
      'latitude': 48.8566,
      'longitude': 2.3522,
      'radius_meters': 5.0,
      'created_by': 'user-456',
      'published': true,
      'difficulty': 'medium',
      'location_type': 'park',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'distance_km': 1.5,
    };

    group('fromJson', () {
      test('should parse all fields correctly', () {
        final model = QuestModel.fromJson(testJson);

        expect(model.id, 'quest-123');
        expect(model.title, 'Test Quest');
        expect(model.description, 'A test quest description');
        expect(model.latitude, 48.8566);
        expect(model.longitude, 2.3522);
        expect(model.radiusMeters, 5.0);
        expect(model.createdBy, 'user-456');
        expect(model.published, true);
        expect(model.difficulty, 'medium');
        expect(model.locationType, 'park');
        expect(model.distanceKm, 1.5);
      });

      test('should handle nullable fields', () {
        final minimalJson = {
          'id': 'quest-123',
          'title': 'Test Quest',
          'latitude': 48.8566,
          'longitude': 2.3522,
          'created_by': 'user-456',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final model = QuestModel.fromJson(minimalJson);

        expect(model.description, isNull);
        expect(model.difficulty, isNull);
        expect(model.locationType, isNull);
        expect(model.distanceKm, isNull);
        expect(model.syncedAt, isNull);
      });

      test('should default radiusMeters to 3.0 when missing', () {
        final jsonWithoutRadius = Map<String, dynamic>.from(testJson);
        jsonWithoutRadius.remove('radius_meters');

        final model = QuestModel.fromJson(jsonWithoutRadius);

        expect(model.radiusMeters, 3.0);
      });

      test('should default published to false when missing', () {
        final jsonWithoutPublished = Map<String, dynamic>.from(testJson);
        jsonWithoutPublished.remove('published');

        final model = QuestModel.fromJson(jsonWithoutPublished);

        expect(model.published, false);
      });
    });

    group('toJson', () {
      test('should produce valid JSON with all fields', () {
        final model = QuestModel.fromJson(testJson);
        final json = model.toJson();

        expect(json['id'], 'quest-123');
        expect(json['title'], 'Test Quest');
        expect(json['description'], 'A test quest description');
        expect(json['latitude'], 48.8566);
        expect(json['longitude'], 2.3522);
        expect(json['radius_meters'], 5.0);
        expect(json['created_by'], 'user-456');
        expect(json['published'], true);
        expect(json['difficulty'], 'medium');
        expect(json['location_type'], 'park');
        expect(json['distance_km'], 1.5);
      });

      test('should omit syncedAt when null', () {
        final model = QuestModel.fromJson(testJson);
        final json = model.toJson();

        expect(json.containsKey('synced_at'), false);
      });

      test('should omit distanceKm when null', () {
        final jsonWithoutDistance = Map<String, dynamic>.from(testJson);
        jsonWithoutDistance.remove('distance_km');

        final model = QuestModel.fromJson(jsonWithoutDistance);
        final json = model.toJson();

        expect(json.containsKey('distance_km'), false);
      });
    });

    group('toDomain', () {
      test('should convert to Quest entity correctly', () {
        final model = QuestModel.fromJson(testJson);
        final quest = model.toDomain();

        expect(quest.id, 'quest-123');
        expect(quest.title, 'Test Quest');
        expect(quest.description, 'A test quest description');
        expect(quest.latitude, 48.8566);
        expect(quest.longitude, 2.3522);
        expect(quest.radiusMeters, 5.0);
        expect(quest.createdBy, 'user-456');
        expect(quest.published, true);
        expect(quest.difficulty, domain.QuestDifficulty.medium);
        expect(quest.locationType, domain.LocationType.park);
      });

      test('should handle null difficulty and locationType', () {
        final jsonWithNulls = Map<String, dynamic>.from(testJson);
        jsonWithNulls['difficulty'] = null;
        jsonWithNulls['location_type'] = null;

        final model = QuestModel.fromJson(jsonWithNulls);
        final quest = model.toDomain();

        expect(quest.difficulty, isNull);
        expect(quest.locationType, isNull);
      });
    });

    group('fromDomain', () {
      test('should convert from Quest entity correctly', () {
        final quest = domain.Quest(
          id: 'quest-123',
          title: 'Test Quest',
          description: 'A test quest description',
          latitude: 48.8566,
          longitude: 2.3522,
          radiusMeters: 5.0,
          createdBy: 'user-456',
          published: true,
          difficulty: domain.QuestDifficulty.hard,
          locationType: domain.LocationType.forest,
          createdAt: now,
          updatedAt: now,
        );

        final model = QuestModel.fromDomain(quest);

        expect(model.id, 'quest-123');
        expect(model.title, 'Test Quest');
        expect(model.difficulty, 'hard');
        expect(model.locationType, 'forest');
      });

      test('should handle null difficulty and locationType', () {
        final quest = domain.Quest(
          id: 'quest-123',
          title: 'Test Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-456',
          createdAt: now,
          updatedAt: now,
        );

        final model = QuestModel.fromDomain(quest);

        expect(model.difficulty, isNull);
        expect(model.locationType, isNull);
      });
    });

    group('toDrift', () {
      test('should convert to Drift Quest data class', () {
        final model = QuestModel.fromJson(testJson);
        final driftQuest = model.toDrift();

        expect(driftQuest.id, 'quest-123');
        expect(driftQuest.title, 'Test Quest');
        expect(driftQuest.latitude, 48.8566);
        expect(driftQuest.longitude, 2.3522);
        expect(driftQuest.difficulty, db.QuestDifficulty.medium);
        expect(driftQuest.locationType, db.LocationType.park);
      });
    });

    group('fromDrift', () {
      test('should convert from Drift Quest data class', () {
        final driftQuest = db.Quest(
          id: 'quest-123',
          title: 'Test Quest',
          description: 'A test quest description',
          latitude: 48.8566,
          longitude: 2.3522,
          radiusMeters: 5.0,
          createdBy: 'user-456',
          published: true,
          difficulty: db.QuestDifficulty.expert,
          locationType: db.LocationType.mountain,
          createdAt: now,
          updatedAt: now,
        );

        final model = QuestModel.fromDrift(driftQuest);

        expect(model.id, 'quest-123');
        expect(model.title, 'Test Quest');
        expect(model.difficulty, 'expert');
        expect(model.locationType, 'mountain');
      });
    });

    group('round-trip serialization', () {
      test('should survive JSON round-trip', () {
        final original = QuestModel.fromJson(testJson);
        final json = original.toJson();
        final restored = QuestModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.latitude, original.latitude);
        expect(restored.longitude, original.longitude);
        expect(restored.difficulty, original.difficulty);
        expect(restored.locationType, original.locationType);
      });

      test('should survive domain round-trip', () {
        final original = QuestModel.fromJson(testJson);
        final domainQuest = original.toDomain();
        final restored = QuestModel.fromDomain(domainQuest);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.latitude, original.latitude);
        expect(restored.longitude, original.longitude);
        expect(restored.difficulty, original.difficulty);
        expect(restored.locationType, original.locationType);
      });
    });

    group('copyWith', () {
      test('should create copy with modified fields', () {
        final original = QuestModel.fromJson(testJson);
        final copy = original.copyWith(title: 'New Title', published: false);

        expect(copy.title, 'New Title');
        expect(copy.published, false);
        expect(copy.id, original.id);
        expect(copy.latitude, original.latitude);
      });

      test('should preserve all fields when no changes', () {
        final original = QuestModel.fromJson(testJson);
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.description, original.description);
        expect(copy.latitude, original.latitude);
        expect(copy.longitude, original.longitude);
        expect(copy.radiusMeters, original.radiusMeters);
        expect(copy.createdBy, original.createdBy);
        expect(copy.published, original.published);
        expect(copy.difficulty, original.difficulty);
        expect(copy.locationType, original.locationType);
        expect(copy.distanceKm, original.distanceKm);
      });
    });
  });
}
