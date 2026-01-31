// Database tests require libsqlite3.so on Linux.
// Skip these tests if SQLite is not available.
// To run: apt-get install libsqlite3-dev
@TestOn('vm')
@Skip('Requires libsqlite3.so - run with: apt-get install libsqlite3-dev')

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart';
import 'package:kash_kash_app/data/datasources/local/quest_dao.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late QuestDao questDao;

  final now = DateTime.now();

  Quest createTestQuest({
    required String id,
    String title = 'Test Quest',
    bool published = true,
    double latitude = 48.8566,
    double longitude = 2.3522,
  }) {
    return Quest(
      id: id,
      title: title,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: 3.0,
      createdBy: 'user-1',
      published: published,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    db = createTestDatabase();
    questDao = db.questDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('QuestDao', () {
    group('getAllPublished', () {
      test('should return only published quests', () async {
        await questDao.upsert(createTestQuest(id: 'pub-1', published: true));
        await questDao.upsert(createTestQuest(id: 'pub-2', published: true));
        await questDao.upsert(createTestQuest(id: 'unpub-1', published: false));

        final published = await questDao.getAllPublished();

        expect(published.length, 2);
        expect(published.every((q) => q.published), true);
      });

      test('should return empty list when no published quests', () async {
        await questDao.upsert(createTestQuest(id: 'unpub-1', published: false));

        final published = await questDao.getAllPublished();

        expect(published, isEmpty);
      });
    });

    group('getAll', () {
      test('should return all quests including unpublished', () async {
        await questDao.upsert(createTestQuest(id: 'pub-1', published: true));
        await questDao.upsert(createTestQuest(id: 'unpub-1', published: false));

        final all = await questDao.getAll();

        expect(all.length, 2);
      });
    });

    group('getById', () {
      test('should return quest when found', () async {
        await questDao.upsert(createTestQuest(id: 'quest-1', title: 'Found Me'));

        final quest = await questDao.getById('quest-1');

        expect(quest, isNotNull);
        expect(quest!.title, 'Found Me');
      });

      test('should return null when not found', () async {
        final quest = await questDao.getById('nonexistent');

        expect(quest, isNull);
      });
    });

    group('upsert', () {
      test('should insert new quest', () async {
        await questDao.upsert(createTestQuest(id: 'new-quest'));

        final quest = await questDao.getById('new-quest');
        expect(quest, isNotNull);
      });

      test('should update existing quest', () async {
        await questDao.upsert(createTestQuest(id: 'quest-1', title: 'Original'));

        await questDao.upsert(Quest(
          id: 'quest-1',
          title: 'Updated',
          latitude: 48.8566,
          longitude: 2.3522,
          radiusMeters: 3.0,
          createdBy: 'user-1',
          published: true,
          createdAt: now,
          updatedAt: now,
        ));

        final quest = await questDao.getById('quest-1');
        expect(quest!.title, 'Updated');
      });
    });

    group('batchUpsert', () {
      test('should insert multiple new quests', () async {
        await questDao.batchUpsert([
          createTestQuest(id: 'quest-1'),
          createTestQuest(id: 'quest-2'),
          createTestQuest(id: 'quest-3'),
        ]);

        final all = await questDao.getAll();
        expect(all.length, 3);
      });

      test('should update existing quests in batch', () async {
        await questDao.upsert(createTestQuest(id: 'quest-1', title: 'Original'));

        await questDao.batchUpsert([
          Quest(
            id: 'quest-1',
            title: 'Batch Updated',
            latitude: 48.8566,
            longitude: 2.3522,
            radiusMeters: 3.0,
            createdBy: 'user-1',
            published: true,
            createdAt: now,
            updatedAt: now,
          ),
        ]);

        final quest = await questDao.getById('quest-1');
        expect(quest!.title, 'Batch Updated');
      });

      test('should handle empty list', () async {
        await questDao.batchUpsert([]);

        final all = await questDao.getAll();
        expect(all, isEmpty);
      });
    });

    group('deleteById', () {
      test('should remove quest', () async {
        await questDao.upsert(createTestQuest(id: 'quest-1'));

        final deletedCount = await questDao.deleteById('quest-1');

        expect(deletedCount, 1);
        expect(await questDao.getById('quest-1'), isNull);
      });

      test('should return 0 when quest does not exist', () async {
        final deletedCount = await questDao.deleteById('nonexistent');

        expect(deletedCount, 0);
      });
    });

    group('deleteAll', () {
      test('should remove all quests', () async {
        await questDao.upsert(createTestQuest(id: 'quest-1'));
        await questDao.upsert(createTestQuest(id: 'quest-2'));

        await questDao.deleteAll();

        final all = await questDao.getAll();
        expect(all, isEmpty);
      });
    });

    group('getByCreator', () {
      test('should return quests by specific user', () async {
        await questDao.upsert(Quest(
          id: 'quest-1',
          title: 'User 1 Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          radiusMeters: 3.0,
          createdBy: 'user-1',
          published: true,
          createdAt: now,
          updatedAt: now,
        ));
        await questDao.upsert(Quest(
          id: 'quest-2',
          title: 'User 2 Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          radiusMeters: 3.0,
          createdBy: 'user-2',
          published: true,
          createdAt: now,
          updatedAt: now,
        ));

        final user1Quests = await questDao.getByCreator('user-1');

        expect(user1Quests.length, 1);
        expect(user1Quests.first.createdBy, 'user-1');
      });
    });

    group('count', () {
      test('should return total quest count', () async {
        await questDao.upsert(createTestQuest(id: 'quest-1', published: true));
        await questDao.upsert(createTestQuest(id: 'quest-2', published: false));

        final count = await questDao.count();

        expect(count, 2);
      });
    });

    group('countPublished', () {
      test('should return only published quest count', () async {
        await questDao.upsert(createTestQuest(id: 'pub-1', published: true));
        await questDao.upsert(createTestQuest(id: 'pub-2', published: true));
        await questDao.upsert(createTestQuest(id: 'unpub-1', published: false));

        final count = await questDao.countPublished();

        expect(count, 2);
      });
    });

    group('watchAllPublished', () {
      test('should emit on changes', () async {
        final emissions = <List<Quest>>[];
        final subscription = questDao.watchAllPublished().listen(emissions.add);

        // Wait for initial emission
        await Future.delayed(const Duration(milliseconds: 50));
        expect(emissions.isNotEmpty, true);
        expect(emissions.last, isEmpty);

        // Add a quest
        await questDao.upsert(createTestQuest(id: 'quest-1', published: true));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emissions.last.length, 1);

        await subscription.cancel();
      });
    });

    group('markSynced', () {
      test('should set syncedAt timestamp', () async {
        await questDao.upsert(createTestQuest(id: 'quest-1'));

        final marked = await questDao.markSynced('quest-1');

        expect(marked, true);
        final quest = await questDao.getById('quest-1');
        expect(quest!.syncedAt, isNotNull);
      });

      test('should return false for nonexistent quest', () async {
        final marked = await questDao.markSynced('nonexistent');

        expect(marked, false);
      });
    });

    group('getUnsyncedQuests', () {
      test('should return quests with null syncedAt', () async {
        await questDao.upsert(createTestQuest(id: 'unsynced-1'));
        await questDao.upsert(createTestQuest(id: 'synced-1'));
        await questDao.markSynced('synced-1');

        final unsynced = await questDao.getUnsyncedQuests();

        expect(unsynced.length, 1);
        expect(unsynced.first.id, 'unsynced-1');
      });
    });
  });
}
