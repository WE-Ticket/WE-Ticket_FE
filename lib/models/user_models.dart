import '../utils/json_parser.dart';

/// 로그인 요청 모델
class LoginRequest {
  final String loginId;
  final String loginPassword;

  LoginRequest({required this.loginId, required this.loginPassword});

  Map<String, dynamic> toJson() {
    return {'login_id': loginId, 'login_password': loginPassword};
  }
}

/// 로그인 응답 모델
/// FIXME 로그인 실패 응답에 대한 정보
class LoginResponse {
  final String message;
  final int userId;

  LoginResponse({required this.message, required this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: JsonParserUtils.parseString(json['message']),
      userId: JsonParserUtils.parseInt(json['user_id']),
    );
  }

  bool get isSuccess => message.contains('성공');
}

/// 약관 동의 정보 모델
class Agreement {
  final String termType;
  final bool agreed;
  final String agreedAt;

  Agreement({
    required this.termType,
    required this.agreed,
    required this.agreedAt,
  });

  factory Agreement.fromJson(Map<String, dynamic> json) {
    return Agreement(
      termType: JsonParserUtils.parseString(json['termType']),
      agreed: JsonParserUtils.parseBool(json['agreed']),
      agreedAt: JsonParserUtils.parseString(json['agreedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'termType': termType, 'agreed': agreed, 'agreedAt': agreedAt};
  }

  bool get isServiceTerms => termType == 'SERVICE_TERMS';
  bool get isPrivacyPolicy => termType == 'PRIVACY_POLICY';

  String get termTypeDisplay {
    switch (termType) {
      case 'SERVICE_TERMS':
        return '서비스 이용약관';
      case 'PRIVACY_POLICY':
        return '개인정보처리방침';
      default:
        return termType;
    }
  }
}

/// 회원가입 요청 모델
class SignupRequest {
  final String fullName;
  final String loginId;
  final String phoneNumber;
  final String loginPassword;
  final List<Agreement> agreements;

  SignupRequest({
    required this.fullName,
    required this.loginId,
    required this.phoneNumber,
    required this.loginPassword,
    required this.agreements,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'login_id': loginId,
      'phone_number': phoneNumber,
      'login_password': loginPassword,
      'agreements': agreements.map((agreement) => agreement.toJson()).toList(),
    };
  }

  bool get hasServiceTermsAgreement => agreements.any(
    (agreement) => agreement.isServiceTerms && agreement.agreed,
  );

  bool get hasPrivacyPolicyAgreement => agreements.any(
    (agreement) => agreement.isPrivacyPolicy && agreement.agreed,
  );

  bool get hasAllRequiredAgreements =>
      hasServiceTermsAgreement && hasPrivacyPolicyAgreement;

  // FIXME 유효성 검사 -> 이건 추후 프론트 딴에서 검사 예정
  bool get isValidLoginId => loginId.length >= 4 && loginId.length <= 20;
  bool get isValidPassword => loginPassword.length >= 4;
  bool get isValidPhoneNumber =>
      RegExp(r'^01[0-9]{8,9}$').hasMatch(phoneNumber);
  bool get isValidFullName => fullName.trim().isNotEmpty;

  bool get isValid =>
      isValidLoginId &&
      isValidPassword &&
      isValidPhoneNumber &&
      isValidFullName &&
      hasAllRequiredAgreements;

  String? get validationError {
    if (!isValidFullName) return '이름을 입력해주세요.';
    if (!isValidLoginId) return '아이디는 4-20자로 입력해주세요.';
    if (!isValidPhoneNumber) return '올바른 휴대폰 번호를 입력해주세요.';
    if (!isValidPassword) return '비밀번호는 4자 이상 입력해주세요.';
    if (!hasAllRequiredAgreements) return '필수 약관에 모두 동의해주세요.';
    return null;
  }
}

/// 회원가입 응답 모델
class SignupResponse {
  final String message;

  SignupResponse({required this.message});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      message: JsonParserUtils.parseString(json['message']),
    );
  }

  bool get isSuccess => message.contains('완료');
}
