import 'package:equatable/equatable.dart';

/// Domain entity representing a user in the system
/// This is a pure business object with no dependencies on external frameworks
class User extends Equatable {
  final int id;
  final String loginId;
  final String name;
  final UserAuthLevel authLevel;

  const User({
    required this.id,
    required this.loginId,
    required this.name,
    required this.authLevel,
  });

  /// Create a copy of this user with updated fields
  User copyWith({
    int? id,
    String? loginId,
    String? name,
    UserAuthLevel? authLevel,
  }) {
    return User(
      id: id ?? this.id,
      loginId: loginId ?? this.loginId,
      name: name ?? this.name,
      authLevel: authLevel ?? this.authLevel,
    );
  }

  @override
  List<Object?> get props => [id, loginId, name, authLevel];

  @override
  String toString() => 'User(id: $id, loginId: $loginId, name: $name, authLevel: $authLevel)';
}

/// Enum representing different levels of user authentication
enum UserAuthLevel {
  none('none', '미인증'),
  general('general', '일반 인증'),
  mobileId('mobile_id', '모바일 신분증 인증'),
  mobileIdTotally('mobile_id_totally', '안전 인증');

  const UserAuthLevel(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Create UserAuthLevel from string value
  static UserAuthLevel fromString(String value) {
    switch (value) {
      case 'none':
        return UserAuthLevel.none;
      case 'general':
        return UserAuthLevel.general;
      case 'mobile_id':
        return UserAuthLevel.mobileId;
      case 'mobile_id_totally':
        return UserAuthLevel.mobileIdTotally;
      default:
        return UserAuthLevel.none;
    }
  }

  /// Get the order/level of authentication (higher = more secure)
  int get level {
    switch (this) {
      case UserAuthLevel.none:
        return 0;
      case UserAuthLevel.general:
        return 1;
      case UserAuthLevel.mobileId:
        return 2;
      case UserAuthLevel.mobileIdTotally:
        return 3;
    }
  }

  /// Check if this auth level is at least the specified level
  bool isAtLeast(UserAuthLevel other) => level >= other.level;
}