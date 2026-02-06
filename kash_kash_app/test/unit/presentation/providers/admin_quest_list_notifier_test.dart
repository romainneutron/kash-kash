import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/domain/repositories/quest_repository.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_list_provider.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

class MockQuestRepository extends Mock implements IQuestRepository {}

void main() {
  late MockQuestRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockQuestRepository();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({
    bool isAdmin = true,
  }) {
    return ProviderContainer(
      overrides: [
        questRepositoryProvider.overrideWithValue(mockRepository),
        isAdminProvider.overrideWithValue(isAdmin),
      ],
    );
  }

  group('AdminQuestListNotifier', () {
    group('build', () {
      test('loads quests on build when admin', () async {
        final quests = [
          FakeData.createQuest(id: 'q1'),
          FakeData.createQuest(id: 'q2'),
        ];
        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => Right(quests));

        container = createContainer();
        final state = await container.read(adminQuestListProvider.future);

        expect(state.quests, quests);
        verify(() => mockRepository.getAllQuests()).called(1);
      });

      test('throws PermissionFailure when not admin', () async {
        container = createContainer(isAdmin: false);

        final sub = container.listen(adminQuestListProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(adminQuestListProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<PermissionFailure>());
        sub.close();
      });

      test('throws on repository failure', () async {
        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => const Left(ServerFailure('error')));

        container = createContainer();

        final sub = container.listen(adminQuestListProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(adminQuestListProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<ServerFailure>());
        sub.close();
      });
    });

    group('setSearchQuery', () {
      test('updates search query in state', () async {
        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => const Right([]));

        container = createContainer();
        await container.read(adminQuestListProvider.future);

        container
            .read(adminQuestListProvider.notifier)
            .setSearchQuery('forest');

        final state = container.read(adminQuestListProvider).requireValue;
        expect(state.searchQuery, 'forest');
      });
    });

    group('togglePublished', () {
      test('publishes unpublished quest', () async {
        final quest = FakeData.createQuest(id: 'q1', published: false);
        final publishedQuest = FakeData.createQuest(id: 'q1', published: true);

        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => Right([quest]));
        when(() => mockRepository.publishQuest('q1'))
            .thenAnswer((_) async => Right(publishedQuest));

        container = createContainer();
        await container.read(adminQuestListProvider.future);

        await container
            .read(adminQuestListProvider.notifier)
            .togglePublished(quest);

        final state = container.read(adminQuestListProvider).requireValue;
        expect(state.quests.first.published, isTrue);
        expect(state.isSaving, isFalse);
        verify(() => mockRepository.publishQuest('q1')).called(1);
      });

      test('unpublishes published quest', () async {
        final quest = FakeData.createQuest(id: 'q1', published: true);
        final unpublishedQuest =
            FakeData.createQuest(id: 'q1', published: false);

        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => Right([quest]));
        when(() => mockRepository.unpublishQuest('q1'))
            .thenAnswer((_) async => Right(unpublishedQuest));

        container = createContainer();
        await container.read(adminQuestListProvider.future);

        await container
            .read(adminQuestListProvider.notifier)
            .togglePublished(quest);

        final state = container.read(adminQuestListProvider).requireValue;
        expect(state.quests.first.published, isFalse);
        verify(() => mockRepository.unpublishQuest('q1')).called(1);
      });

      test('sets error on failure', () async {
        final quest = FakeData.createQuest(id: 'q1', published: false);

        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => Right([quest]));
        when(() => mockRepository.publishQuest('q1')).thenAnswer(
            (_) async => const Left(ServerFailure('Publish failed')));

        container = createContainer();
        await container.read(adminQuestListProvider.future);

        await container
            .read(adminQuestListProvider.notifier)
            .togglePublished(quest);

        final state = container.read(adminQuestListProvider).requireValue;
        expect(state.hasError, isTrue);
        expect(state.error, 'Publish failed');
        expect(state.isSaving, isFalse);
      });
    });

    group('deleteQuest', () {
      test('removes quest from state on success', () async {
        final quest = FakeData.createQuest(id: 'q1');

        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => Right([quest]));
        when(() => mockRepository.deleteQuest('q1'))
            .thenAnswer((_) async => const Right(unit));

        container = createContainer();
        await container.read(adminQuestListProvider.future);

        await container
            .read(adminQuestListProvider.notifier)
            .deleteQuest('q1');

        final state = container.read(adminQuestListProvider).requireValue;
        expect(state.quests, isEmpty);
        expect(state.isSaving, isFalse);
      });

      test('sets error on failure', () async {
        final quest = FakeData.createQuest(id: 'q1');

        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => Right([quest]));
        when(() => mockRepository.deleteQuest('q1')).thenAnswer(
            (_) async => const Left(ServerFailure('Delete failed')));

        container = createContainer();
        await container.read(adminQuestListProvider.future);

        await container
            .read(adminQuestListProvider.notifier)
            .deleteQuest('q1');

        final state = container.read(adminQuestListProvider).requireValue;
        expect(state.hasError, isTrue);
        expect(state.error, 'Delete failed');
        expect(state.quests, hasLength(1));
      });
    });

    group('refresh', () {
      test('reloads quests from repository', () async {
        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => const Right([]));

        container = createContainer();
        await container.read(adminQuestListProvider.future);

        final newQuests = [FakeData.createQuest(id: 'new-q1')];
        when(() => mockRepository.getAllQuests())
            .thenAnswer((_) async => Right(newQuests));

        await container.read(adminQuestListProvider.notifier).refresh();

        final state = container.read(adminQuestListProvider).requireValue;
        expect(state.quests, newQuests);
      });
    });
  });
}
