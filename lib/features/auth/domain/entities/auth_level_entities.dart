/// 인증 레벨 관련 도메인 엔티티들
enum AuthLevel {
  none,
  general,
  mobileId;

  String get value {
    switch (this) {
      case AuthLevel.none:
        return 'none';
      case AuthLevel.general:
        return 'general';
      case AuthLevel.mobileId:
        return 'mobile_id';
    }
  }

  String get displayName {
    switch (this) {
      case AuthLevel.none:
        return '미인증';
      case AuthLevel.general:
        return '일반 인증';
      case AuthLevel.mobileId:
        return '안전 인증';
    }
  }

  String get description {
    switch (this) {
      case AuthLevel.none:
        return '서비스 이용을 위해 본인 인증이 필요합니다';
      case AuthLevel.general:
        return '간편인증 또는 모바일신분증으로 기본 서비스 이용 가능';
      case AuthLevel.mobileId:
        return '모바일신분증 추가 인증으로 강화된 보안 및 양도 거래';
    }
  }

  int get order {
    switch (this) {
      case AuthLevel.none:
        return 0;
      case AuthLevel.general:
        return 1;
      case AuthLevel.mobileId:
        return 2;
    }
  }

  static AuthLevel fromString(String value) {
    switch (value) {
      case 'none':
        return AuthLevel.none;
      case 'general':
        return AuthLevel.general;
      case 'mobile_id':
        return AuthLevel.mobileId;
      default:
        return AuthLevel.none;
    }
  }

  bool isAtLeast(AuthLevel required) {
    return order >= required.order;
  }

  AuthLevel? get nextLevel {
    switch (this) {
      case AuthLevel.none:
        return AuthLevel.general;
      case AuthLevel.general:
        return AuthLevel.mobileId;
      case AuthLevel.mobileId:
        return null;
    }
  }
}

class AuthUpgradeOption {
  final AuthLevel targetLevel;
  final String title;
  final String description;
  final List<String> benefits;
  final bool isAvailable;

  const AuthUpgradeOption({
    required this.targetLevel,
    required this.title,
    required this.description,
    required this.benefits,
    required this.isAvailable,
  });

  static AuthUpgradeOption? getNextUpgrade(AuthLevel currentLevel) {
    switch (currentLevel) {
      case AuthLevel.none:
        return const AuthUpgradeOption(
          targetLevel: AuthLevel.general,
          title: '본인 인증하러 가기',
          description: '간편인증 또는 모바일 신분증으로 안전하게 인증하세요',
          benefits: ['공연 예매', '1초 간편입장'],
          isAvailable: true,
        );
      case AuthLevel.general:
        return const AuthUpgradeOption(
          targetLevel: AuthLevel.mobileId,
          title: '안전 인증 회원 되기',
          description: '모바일신분증 추가 인증으로 양도 거래까지 안전하게',
          benefits: ['양도 거래', '강화된 보안'],
          isAvailable: true,
        );
      case AuthLevel.mobileId:
        return null;
    }
  }
}

class UserPrivilege {
  final String name;
  final bool isAvailable;
  final AuthLevel requiredLevel;

  const UserPrivilege({
    required this.name,
    required this.isAvailable,
    required this.requiredLevel,
  });

  static List<UserPrivilege> getPrivilegesForLevel(AuthLevel userLevel) {
    return [
      UserPrivilege(
        name: '공연 예매',
        isAvailable: userLevel.isAtLeast(AuthLevel.general),
        requiredLevel: AuthLevel.general,
      ),
      UserPrivilege(
        name: '1초 간편입장',
        isAvailable: userLevel.isAtLeast(AuthLevel.general),
        requiredLevel: AuthLevel.general,
      ),
      UserPrivilege(
        name: '양도 거래',
        isAvailable: userLevel.isAtLeast(AuthLevel.mobileId),
        requiredLevel: AuthLevel.mobileId,
      ),
    ];
  }
}
