/// 인증 레벨 관련 도메인 엔티티들
enum AuthLevel {
  none,
  general,
  mobileId,
  mobileIdTotally;

  String get value {
    switch (this) {
      case AuthLevel.none:
        return 'none';
      case AuthLevel.general:
        return 'general';
      case AuthLevel.mobileId:
        return 'mobile_id';
      case AuthLevel.mobileIdTotally:
        return 'mobile_id_totally';
    }
  }

  String get displayName {
    switch (this) {
      case AuthLevel.none:
        return '미인증';
      case AuthLevel.general:
        return '일반 인증 회원';
      case AuthLevel.mobileId:
        return '모바일 신분증 인증 회원';
      case AuthLevel.mobileIdTotally:
        return '완전 인증 회원';
    }
  }

  String get description {
    switch (this) {
      case AuthLevel.none:
        return '서비스 이용을 위해 본인 인증이 필요합니다';
      case AuthLevel.general:
        return '휴대폰 또는 간편인증으로 기본 서비스 이용 가능';
      case AuthLevel.mobileId:
        return '모바일신분증 인증으로 강화된 보안 서비스 이용';
      case AuthLevel.mobileIdTotally:
        return '모든 서비스 이용 가능한 최고 등급';
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
      case AuthLevel.mobileIdTotally:
        return 3;
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
      case 'mobile_id_totally':
        return AuthLevel.mobileIdTotally;
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
        return AuthLevel.mobileIdTotally;
      case AuthLevel.mobileIdTotally:
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
          benefits: ['공연 예매', '3초 간편입장'],
          isAvailable: true,
        );
      case AuthLevel.general:
        return const AuthUpgradeOption(
          targetLevel: AuthLevel.mobileId,
          title: '모바일 신분증 인증 회원 되기',
          description: '모바일신분증으로 인증하고 3초 간편입장을 경험하세요',
          benefits: ['강화된 보안', '3초 간편입장'],
          isAvailable: true,
        );
      case AuthLevel.mobileId:
        return const AuthUpgradeOption(
          targetLevel: AuthLevel.mobileIdTotally,
          title: '완전 인증 회원 되기',
          description: '추가 인증으로 양도 거래를 통한 더 즐거운 공연을 누리세요',
          benefits: ['양도 거래', '법적 분쟁 보호'],
          isAvailable: true,
        );
      case AuthLevel.mobileIdTotally:
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
        name: '3초 간편입장',
        isAvailable: userLevel.isAtLeast(AuthLevel.mobileId),
        requiredLevel: AuthLevel.mobileId,
      ),
      UserPrivilege(
        name: '양도 거래',
        isAvailable: userLevel.isAtLeast(AuthLevel.mobileIdTotally),
        requiredLevel: AuthLevel.mobileIdTotally,
      ),
    ];
  }
}