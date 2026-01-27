import 'package:kash_kash_app/domain/entities/user.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'ROLE_USER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role,
    };
  }

  User toDomain() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: _parseRole(role),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static UserRole _parseRole(String role) {
    switch (role) {
      case 'ROLE_ADMIN':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      role: user.role == UserRole.admin ? 'ROLE_ADMIN' : 'ROLE_USER',
    );
  }
}
