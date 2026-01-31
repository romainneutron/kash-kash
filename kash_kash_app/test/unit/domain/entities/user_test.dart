import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/domain/entities/user.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('User', () {
    group('creation', () {
      test('should create user with all required fields', () {
        final user = FakeData.createUser();

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
        expect(user.role, UserRole.user);
        expect(user.avatarUrl, isNull);
      });

      test('should create user with optional avatarUrl', () {
        final user = FakeData.createUser(
          avatarUrl: 'https://example.com/avatar.png',
        );

        expect(user.avatarUrl, 'https://example.com/avatar.png');
      });

      test('should create admin user', () {
        final admin = FakeData.createAdminUser();

        expect(admin.role, UserRole.admin);
        expect(admin.isAdmin, isTrue);
      });
    });

    group('isAdmin', () {
      test('should return true for admin role', () {
        final admin = FakeData.createUser(role: UserRole.admin);

        expect(admin.isAdmin, isTrue);
      });

      test('should return false for user role', () {
        final user = FakeData.createUser(role: UserRole.user);

        expect(user.isAdmin, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with modified email', () {
        final user = FakeData.createUser();
        final copy = user.copyWith(email: 'new@example.com');

        expect(copy.email, 'new@example.com');
        expect(copy.id, user.id);
        expect(copy.displayName, user.displayName);
      });

      test('should create copy with modified role', () {
        final user = FakeData.createUser(role: UserRole.user);
        final copy = user.copyWith(role: UserRole.admin);

        expect(copy.role, UserRole.admin);
        expect(copy.isAdmin, isTrue);
      });

      test('should preserve all fields when no changes', () {
        final user = FakeData.createUser(
          avatarUrl: 'https://example.com/avatar.png',
        );
        final copy = user.copyWith();

        expect(copy.id, user.id);
        expect(copy.email, user.email);
        expect(copy.displayName, user.displayName);
        expect(copy.avatarUrl, user.avatarUrl);
        expect(copy.role, user.role);
      });

      test('should allow setting avatarUrl to new value', () {
        final user = FakeData.createUser();
        final copy = user.copyWith(avatarUrl: 'https://new-avatar.com/img.png');

        expect(copy.avatarUrl, 'https://new-avatar.com/img.png');
      });
    });

    group('equality', () {
      test('should be equal when ids match', () {
        final user1 = FakeData.createUser(id: 'same-id');
        final user2 = FakeData.createUser(id: 'same-id', email: 'different@example.com');

        expect(user1, equals(user2));
      });

      test('should not be equal when ids differ', () {
        final user1 = FakeData.createUser(id: 'id-1');
        final user2 = FakeData.createUser(id: 'id-2');

        expect(user1, isNot(equals(user2)));
      });

      test('should have same hashCode for equal users', () {
        final user1 = FakeData.createUser(id: 'same-id');
        final user2 = FakeData.createUser(id: 'same-id');

        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('identical should return true for same instance', () {
        final user = FakeData.createUser();

        expect(identical(user, user), isTrue);
        expect(user == user, isTrue);
      });
    });
  });

  group('UserRole', () {
    test('should have user and admin values', () {
      expect(UserRole.values, containsAll([UserRole.user, UserRole.admin]));
      expect(UserRole.values.length, 2);
    });
  });
}
