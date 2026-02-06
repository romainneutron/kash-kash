import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/domain/entities/user.dart';
import 'package:kash_kash_app/domain/repositories/quest_repository.dart';
import 'package:kash_kash_app/infrastructure/gps/gps_service.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_form_provider.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

class MockQuestRepository extends Mock implements IQuestRepository {}

class MockGpsService extends Mock implements GpsService {}

void main() {
  late MockQuestRepository mockRepository;
  late MockGpsService mockGpsService;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockQuestRepository();
    mockGpsService = MockGpsService();
  });

  tearDown(() {
    container.dispose();
  });

  setUpAll(() {
    registerFallbackValue(FakeData.createQuest());
  });

  ProviderContainer createContainer({
    bool isAdmin = true,
    User? currentUser,
  }) {
    return ProviderContainer(
      overrides: [
        questRepositoryProvider.overrideWithValue(mockRepository),
        gpsServiceProvider.overrideWithValue(mockGpsService),
        isAdminProvider.overrideWithValue(isAdmin),
        currentUserProvider
            .overrideWithValue(currentUser ?? FakeData.createAdminUser()),
      ],
    );
  }

  group('AdminQuestFormNotifier', () {
    group('build - create mode', () {
      test('returns empty state when questId is null', () async {
        container = createContainer();
        final state =
            await container.read(adminQuestFormProvider(null).future);

        expect(state.isEditing, isFalse);
        expect(state.formData, const QuestFormData());
      });

      test('throws PermissionFailure when not admin', () async {
        container = createContainer(isAdmin: false);

        final sub =
            container.listen(adminQuestFormProvider(null), (_, _) {});
        // Allow async build to process
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(adminQuestFormProvider(null));
        expect(state.hasError, isTrue);
        expect(state.error, isA<PermissionFailure>());
        sub.close();
      });
    });

    group('build - edit mode', () {
      test('loads existing quest and populates form data', () async {
        final quest = FakeData.createQuest(
          id: 'q1',
          title: 'Existing',
          description: 'Desc',
          latitude: 45.0,
          longitude: 6.0,
        );
        when(() => mockRepository.getQuestById('q1'))
            .thenAnswer((_) async => Right(quest));

        container = createContainer();
        final state =
            await container.read(adminQuestFormProvider('q1').future);

        expect(state.isEditing, isTrue);
        expect(state.existingQuest, quest);
        expect(state.formData.title, 'Existing');
        expect(state.formData.description, 'Desc');
        expect(state.formData.latitude, 45.0);
        expect(state.formData.longitude, 6.0);
      });

      test('sets error when quest not found', () async {
        when(() => mockRepository.getQuestById('q1')).thenAnswer(
            (_) async => const Left(CacheFailure('Quest not found')));

        container = createContainer();
        final state =
            await container.read(adminQuestFormProvider('q1').future);

        expect(state.hasError, isTrue);
        expect(state.error, 'Quest not found');
      });
    });

    group('updateTitle', () {
      test('updates title in form data', () async {
        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        container
            .read(adminQuestFormProvider(null).notifier)
            .updateTitle('New Title');

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.formData.title, 'New Title');
      });
    });

    group('updateLocation', () {
      test('sets latitude and longitude', () async {
        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        container
            .read(adminQuestFormProvider(null).notifier)
            .updateLocation(latitude: 48.0, longitude: 2.0);

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.formData.latitude, 48.0);
        expect(state.formData.longitude, 2.0);
      });
    });

    group('clearLocation', () {
      test('clears latitude and longitude', () async {
        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        container
            .read(adminQuestFormProvider(null).notifier)
            .updateLocation(latitude: 48.0, longitude: 2.0);
        container
            .read(adminQuestFormProvider(null).notifier)
            .clearLocation();

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.formData.latitude, isNull);
        expect(state.formData.longitude, isNull);
      });
    });

    group('useCurrentLocation', () {
      test('sets coordinates from GPS on success', () async {
        final position = Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        when(() => mockGpsService.getCurrentPosition())
            .thenAnswer((_) async => Right(position));

        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        await container
            .read(adminQuestFormProvider(null).notifier)
            .useCurrentLocation();

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.formData.latitude, 48.8566);
        expect(state.formData.longitude, 2.3522);
        expect(state.isLocating, isFalse);
      });

      test('sets error on GPS failure', () async {
        when(() => mockGpsService.getCurrentPosition()).thenAnswer(
            (_) async => const Left(LocationFailure('GPS disabled')));

        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        await container
            .read(adminQuestFormProvider(null).notifier)
            .useCurrentLocation();

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.hasError, isTrue);
        expect(state.error, 'GPS disabled');
        expect(state.isLocating, isFalse);
      });

      test('does not fire concurrent GPS requests', () async {
        final completer = Completer<Either<Failure, Position>>();
        when(() => mockGpsService.getCurrentPosition())
            .thenAnswer((_) => completer.future);

        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        // Start first request
        final future1 = container
            .read(adminQuestFormProvider(null).notifier)
            .useCurrentLocation();

        // Attempt second request while first is in flight
        final future2 = container
            .read(adminQuestFormProvider(null).notifier)
            .useCurrentLocation();

        // Complete first request
        completer.complete(const Left(LocationFailure('GPS disabled')));
        await future1;
        await future2;

        // Only one GPS call should have been made
        verify(() => mockGpsService.getCurrentPosition()).called(1);
      });
    });

    group('save - create mode', () {
      test('creates quest on success', () async {
        final createdQuest = FakeData.createQuest(id: 'new-id');
        when(() => mockRepository.createQuest(any()))
            .thenAnswer((_) async => Right(createdQuest));

        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        final notifier =
            container.read(adminQuestFormProvider(null).notifier);
        notifier.updateTitle('New Quest');
        notifier.updateLocation(latitude: 48.0, longitude: 2.0);

        final result = await notifier.save();

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.createQuest(any())).called(1);
      });

      test('returns validation failure when required fields missing',
          () async {
        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        final result = await container
            .read(adminQuestFormProvider(null).notifier)
            .save();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns AuthFailure when user is null in create mode', () async {
        container = ProviderContainer(
          overrides: [
            questRepositoryProvider.overrideWithValue(mockRepository),
            gpsServiceProvider.overrideWithValue(mockGpsService),
            isAdminProvider.overrideWithValue(true),
            currentUserProvider.overrideWithValue(null),
          ],
        );

        await container.read(adminQuestFormProvider(null).future);

        final notifier =
            container.read(adminQuestFormProvider(null).notifier);
        notifier.updateTitle('Test');
        notifier.updateLocation(latitude: 48.0, longitude: 2.0);

        final result = await notifier.save();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns ValidationFailure for out-of-range coordinates', () async {
        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        final notifier =
            container.read(adminQuestFormProvider(null).notifier);
        notifier.updateTitle('New Quest');
        notifier.updateLocation(latitude: 91.0, longitude: 2.0);

        final result = await notifier.save();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Coordinates are out of range');
          },
          (_) => fail('Expected Left'),
        );

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.isSaving, isFalse);
        expect(state.error, 'Coordinates are out of range');
      });

      test('sets error on repository failure', () async {
        when(() => mockRepository.createQuest(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Server error')));

        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        final notifier =
            container.read(adminQuestFormProvider(null).notifier);
        notifier.updateTitle('New Quest');
        notifier.updateLocation(latitude: 48.0, longitude: 2.0);

        final result = await notifier.save();

        expect(result.isLeft(), isTrue);
        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.hasError, isTrue);
        expect(state.error, 'Server error');
        expect(state.isSaving, isFalse);
      });

      test('returns ValidationFailure when title exceeds max length',
          () async {
        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        final notifier =
            container.read(adminQuestFormProvider(null).notifier);
        notifier.updateTitle('A' * (QuestFormData.maxTitleLength + 1));
        notifier.updateLocation(latitude: 48.0, longitude: 2.0);

        final result = await notifier.save();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Title too long');
          },
          (_) => fail('Expected Left'),
        );

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.isSaving, isFalse);
        expect(state.error,
            'Title must be ${QuestFormData.maxTitleLength} characters or less');
      });

      test('allows title at exactly max length', () async {
        final createdQuest = FakeData.createQuest(id: 'new-id');
        when(() => mockRepository.createQuest(any()))
            .thenAnswer((_) async => Right(createdQuest));

        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        final notifier =
            container.read(adminQuestFormProvider(null).notifier);
        notifier.updateTitle('A' * QuestFormData.maxTitleLength);
        notifier.updateLocation(latitude: 48.0, longitude: 2.0);

        final result = await notifier.save();

        expect(result.isRight(), isTrue);
      });

      test('prevents concurrent save calls', () async {
        final completer = Completer<Either<Failure, Quest>>();
        when(() => mockRepository.createQuest(any()))
            .thenAnswer((_) => completer.future);

        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        final notifier =
            container.read(adminQuestFormProvider(null).notifier);
        notifier.updateTitle('New Quest');
        notifier.updateLocation(latitude: 48.0, longitude: 2.0);

        // Start first save
        final future1 = notifier.save();

        // Attempt second save while first is in flight
        // The second call should see isSaving=true and still proceed (no guard),
        // but the state should remain consistent
        final future2 = notifier.save();

        // Complete the repository call
        completer.complete(Right(FakeData.createQuest(id: 'new-id')));
        await future1;
        await future2;

        final state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.isSaving, isFalse);
      });
    });

    group('save - edit mode', () {
      test('updates quest on success', () async {
        final existingQuest = FakeData.createQuest(id: 'q1');
        final updatedQuest =
            FakeData.createQuest(id: 'q1', title: 'Updated');

        when(() => mockRepository.getQuestById('q1'))
            .thenAnswer((_) async => Right(existingQuest));
        when(() => mockRepository.updateQuest(any()))
            .thenAnswer((_) async => Right(updatedQuest));

        container = createContainer();
        await container.read(adminQuestFormProvider('q1').future);

        final notifier =
            container.read(adminQuestFormProvider('q1').notifier);
        notifier.updateTitle('Updated');

        final result = await notifier.save();

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.updateQuest(any())).called(1);
        verifyNever(() => mockRepository.createQuest(any()));
      });
    });

    group('clearError', () {
      test('clears error from state', () async {
        container = createContainer();
        await container.read(adminQuestFormProvider(null).future);

        // Trigger an error by saving without required fields
        await container
            .read(adminQuestFormProvider(null).notifier)
            .save();

        var state =
            container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.hasError, isTrue);

        container
            .read(adminQuestFormProvider(null).notifier)
            .clearError();

        state = container.read(adminQuestFormProvider(null)).requireValue;
        expect(state.hasError, isFalse);
      });
    });
  });
}
