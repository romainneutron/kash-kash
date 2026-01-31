import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/data/models/user_model.dart';
import 'package:kash_kash_app/domain/entities/user.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('UserModel', () {
    group('fromJson', () {
      test('should parse all fields correctly', () {
        final json = FakeData.createUserJson(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          avatarUrl: 'https://example.com/avatar.png',
          role: 'ROLE_USER',
        );

        final model = UserModel.fromJson(json);

        expect(model.id, 'user-123');
        expect(model.email, 'test@example.com');
        expect(model.displayName, 'Test User');
        expect(model.avatarUrl, 'https://example.com/avatar.png');
        expect(model.role, 'ROLE_USER');
      });

      test('should handle null avatarUrl', () {
        final json = FakeData.createUserJson(avatarUrl: null);

        final model = UserModel.fromJson(json);

        expect(model.avatarUrl, isNull);
      });

      test('should default role to ROLE_USER when missing', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'displayName': 'Test User',
        };

        final model = UserModel.fromJson(json);

        expect(model.role, 'ROLE_USER');
      });

      test('should parse admin role', () {
        final json = FakeData.createUserJson(role: 'ROLE_ADMIN');

        final model = UserModel.fromJson(json);

        expect(model.role, 'ROLE_ADMIN');
      });
    });

    group('toJson', () {
      test('should produce valid JSON with all fields', () {
        final model = FakeData.createUserModel(
          id: 'user-123',
          email: 'test@example.com',
          displayName: 'Test User',
          avatarUrl: 'https://example.com/avatar.png',
          role: 'ROLE_USER',
        );

        final json = model.toJson();

        expect(json['id'], 'user-123');
        expect(json['email'], 'test@example.com');
        expect(json['displayName'], 'Test User');
        expect(json['avatarUrl'], 'https://example.com/avatar.png');
        expect(json['role'], 'ROLE_USER');
      });

      test('should include null avatarUrl', () {
        final model = FakeData.createUserModel(avatarUrl: null);

        final json = model.toJson();

        expect(json.containsKey('avatarUrl'), isTrue);
        expect(json['avatarUrl'], isNull);
      });
    });

    group('toDomain', () {
      test('should convert to User entity for regular user', () {
        final model = FakeData.createUserModel(role: 'ROLE_USER');

        final user = model.toDomain();

        expect(user, isA<User>());
        expect(user.id, model.id);
        expect(user.email, model.email);
        expect(user.displayName, model.displayName);
        expect(user.avatarUrl, model.avatarUrl);
        expect(user.role, UserRole.user);
        expect(user.isAdmin, isFalse);
      });

      test('should convert to User entity for admin user', () {
        final model = FakeData.createUserModel(role: 'ROLE_ADMIN');

        final user = model.toDomain();

        expect(user.role, UserRole.admin);
        expect(user.isAdmin, isTrue);
      });

      test('should default unknown role to user', () {
        final model = UserModel(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test',
          role: 'ROLE_UNKNOWN',
        );

        final user = model.toDomain();

        expect(user.role, UserRole.user);
      });

      test('should set createdAt and updatedAt', () {
        final model = FakeData.createUserModel();

        final user = model.toDomain();

        expect(user.createdAt, isNotNull);
        expect(user.updatedAt, isNotNull);
      });
    });

    group('fromDomain', () {
      test('should convert from User entity for regular user', () {
        final user = FakeData.createUser(role: UserRole.user);

        final model = UserModel.fromDomain(user);

        expect(model.id, user.id);
        expect(model.email, user.email);
        expect(model.displayName, user.displayName);
        expect(model.avatarUrl, user.avatarUrl);
        expect(model.role, 'ROLE_USER');
      });

      test('should convert from User entity for admin user', () {
        final user = FakeData.createUser(role: UserRole.admin);

        final model = UserModel.fromDomain(user);

        expect(model.role, 'ROLE_ADMIN');
      });
    });

    group('round-trip serialization', () {
      test('should survive JSON round-trip', () {
        final original = FakeData.createUserModel(
          avatarUrl: 'https://example.com/avatar.png',
        );

        final json = original.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.displayName, original.displayName);
        expect(restored.avatarUrl, original.avatarUrl);
        expect(restored.role, original.role);
      });

      test('should survive domain round-trip', () {
        final original = FakeData.createUser();

        final model = UserModel.fromDomain(original);
        final restored = model.toDomain();

        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.displayName, original.displayName);
        expect(restored.avatarUrl, original.avatarUrl);
        expect(restored.role, original.role);
      });
    });
  });
}
