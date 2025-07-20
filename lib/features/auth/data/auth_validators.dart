/// 인증 관련 유효성 검사를 담당하는 클래스
class AuthValidators {
  // UI 검증 (즉시 피드백용 - Form Validator)

  /// 이름 유효성 검사
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.trim().length < 2 || value.trim().length > 20) {
      return '이름은 2-20자로 입력해주세요';
    }
    return null;
  }

  /// 아이디 유효성 검사
  static String? validateLoginId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '아이디를 입력해주세요';
    }
    if (value.length < 4 || value.length > 20) {
      return '아이디는 4-20자로 입력해주세요';
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return '아이디는 영문, 숫자만 사용 가능합니다';
    }
    return null;
  }

  /// 휴대폰 번호 유효성 검사
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '휴대폰 번호를 입력해주세요';
    }
    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(value)) {
      return '올바른 휴대폰 번호를 입력해주세요';
    }
    return null;
  }

  /// 비밀번호 유효성 검사
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 4) {
      return '비밀번호는 4자 이상 입력해주세요';
    }
    return null;
  }

  /// 비밀번호 확인 유효성 검사
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return '비밀번호를 다시 입력해주세요';
    }
    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  // 비즈니스 로직 검증 (제출 시)

  /// 회원가입 데이터 전체 검증
  static AuthValidationResult validateSignupData({
    required String fullName,
    required String loginId,
    required String phoneNumber,
    required String password,
    required bool agreeTerms,
    required bool agreePrivacy,
  }) {
    final errors = <String>[];

    // 각 필드 개별 검증
    final nameError = validateName(fullName);
    if (nameError != null) errors.add(nameError);

    final idError = validateLoginId(loginId);
    if (idError != null) errors.add(idError);

    final phoneError = validatePhoneNumber(phoneNumber);
    if (phoneError != null) errors.add(phoneError);

    final passwordError = validatePassword(password);
    if (passwordError != null) errors.add(passwordError);

    // 약관 동의 검증
    if (!agreeTerms) {
      errors.add('서비스 이용약관에 동의해주세요');
    }
    if (!agreePrivacy) {
      errors.add('개인정보처리방침에 동의해주세요');
    }

    return AuthValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// 로그인 데이터 검증
  static AuthValidationResult validateLoginData({
    required String loginId,
    required String password,
  }) {
    final errors = <String>[];

    if (loginId.trim().isEmpty) {
      errors.add('아이디를 입력해주세요');
    }
    if (password.trim().isEmpty) {
      errors.add('비밀번호를 입력해주세요');
    }

    return AuthValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // 개별 필드 검증 (static 메서드로 어디서든 사용 가능)

  /// 아이디 형식 검증 (boolean)
  static bool isValidLoginId(String loginId) {
    return loginId.length >= 4 &&
        loginId.length <= 20 &&
        RegExp(r'^[a-zA-Z0-9]+$').hasMatch(loginId);
  }

  /// 비밀번호 형식 검증 (boolean)
  static bool isValidPassword(String password) {
    return password.length >= 4 && password.length <= 50;
  }

  /// 휴대폰 번호 형식 검증 (boolean)
  static bool isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^01[0-9]{8,9}$').hasMatch(phoneNumber);
  }

  /// 이름 형식 검증 (boolean)
  static bool isValidFullName(String fullName) {
    return fullName.trim().isNotEmpty &&
        fullName.trim().length >= 2 &&
        fullName.trim().length <= 20;
  }
}

/// 유효성 검사 결과 클래스
class AuthValidationResult {
  final bool isValid;
  final List<String> errors;

  AuthValidationResult({required this.isValid, required this.errors});

  /// 첫 번째 에러 메시지 반환
  String? get firstError => errors.isNotEmpty ? errors.first : null;

  /// 모든 에러 메시지를 하나의 문자열로 반환
  String get allErrors => errors.join('\n');

  /// 에러 개수 반환
  int get errorCount => errors.length;

  @override
  String toString() {
    return 'AuthValidationResult(isValid: $isValid, errors: $errors)';
  }
}
