import 'package:kash_kash_app/data/models/user_model.dart';
import 'package:kash_kash_app/domain/entities/path_point.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/domain/entities/quest_attempt.dart';
import 'package:kash_kash_app/domain/entities/user.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// Test data generators for unit tests

class FakeData {
  static User createUser({
    String id = 'user-123',
    String email = 'test@example.com',
    String displayName = 'Test User',
    String? avatarUrl,
    UserRole role = UserRole.user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );
  }

  static User createAdminUser({
    String id = 'admin-123',
    String email = 'admin@example.com',
    String displayName = 'Admin User',
  }) {
    return createUser(
      id: id,
      email: email,
      displayName: displayName,
      role: UserRole.admin,
    );
  }

  static Quest createQuest({
    String id = 'quest-123',
    String title = 'Test Quest',
    String? description = 'A test quest',
    double latitude = 48.8566,
    double longitude = 2.3522,
    double radiusMeters = 3.0,
    String createdBy = 'user-123',
    bool published = true,
    QuestDifficulty? difficulty = QuestDifficulty.medium,
    LocationType? locationType = LocationType.city,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return Quest(
      id: id,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      createdBy: createdBy,
      published: published,
      difficulty: difficulty,
      locationType: locationType,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
      syncedAt: syncedAt,
    );
  }

  static QuestAttempt createQuestAttempt({
    String id = 'attempt-123',
    String questId = 'quest-123',
    String userId = 'user-123',
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? abandonedAt,
    AttemptStatus status = AttemptStatus.inProgress,
    int? durationSeconds,
    double? distanceWalked,
    bool synced = false,
  }) {
    return QuestAttempt(
      id: id,
      questId: questId,
      userId: userId,
      startedAt: startedAt ?? DateTime(2024, 1, 1, 10, 0),
      completedAt: completedAt,
      abandonedAt: abandonedAt,
      status: status,
      durationSeconds: durationSeconds,
      distanceWalked: distanceWalked,
      synced: synced,
    );
  }

  static QuestAttempt createCompletedAttempt({
    String id = 'attempt-completed',
    String questId = 'quest-123',
    String userId = 'user-123',
    int durationSeconds = 300,
    double distanceWalked = 150.0,
  }) {
    final startedAt = DateTime(2024, 1, 1, 10, 0);
    return createQuestAttempt(
      id: id,
      questId: questId,
      userId: userId,
      startedAt: startedAt,
      completedAt: startedAt.add(Duration(seconds: durationSeconds)),
      status: AttemptStatus.completed,
      durationSeconds: durationSeconds,
      distanceWalked: distanceWalked,
      synced: true,
    );
  }

  static PathPoint createPathPoint({
    String id = 'point-123',
    String attemptId = 'attempt-123',
    double latitude = 48.8566,
    double longitude = 2.3522,
    DateTime? timestamp,
    double accuracy = 5.0,
    double speed = 1.5,
    bool synced = false,
  }) {
    return PathPoint(
      id: id,
      attemptId: attemptId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime(2024, 1, 1, 10, 0),
      accuracy: accuracy,
      speed: speed,
      synced: synced,
    );
  }

  static UserModel createUserModel({
    String id = 'user-123',
    String email = 'test@example.com',
    String displayName = 'Test User',
    String? avatarUrl,
    String role = 'ROLE_USER',
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role,
    );
  }

  static Map<String, dynamic> createUserJson({
    String id = 'user-123',
    String email = 'test@example.com',
    String displayName = 'Test User',
    String? avatarUrl,
    String role = 'ROLE_USER',
  }) {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role,
    };
  }
}

/// No-op wakelock implementation for tests.
class FakeWakelockPlatform extends WakelockPlusPlatformInterface {
  bool _enabled = false;

  @override
  Future<void> toggle({required bool enable}) async {
    _enabled = enable;
  }

  @override
  Future<bool> get enabled async => _enabled;
}

/// Common auth states for testing.
class TestAuthStates {
  static const unauthenticated = AuthState(
    status: AuthStatus.unauthenticated,
  );

  static final authenticated = AuthState(
    status: AuthStatus.authenticated,
    user: FakeData.createUser(),
  );

  static final authenticatedAdmin = AuthState(
    status: AuthStatus.authenticated,
    user: FakeData.createAdminUser(),
  );

  static const loading = AuthState(
    status: AuthStatus.loading,
  );

  static const error = AuthState(
    status: AuthStatus.error,
    error: 'Authentication failed',
  );
}
