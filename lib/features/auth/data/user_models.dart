import '../../../core/utils/json_parser.dart';

/// 사용자 모델
class UserModel {
  final int userId;
  final String loginId;
  final String userName;
  final String userAuthLevel;

  UserModel({
    required this.userId,
    required this.loginId,
    required this.userName,
    required this.userAuthLevel,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: JsonParserUtils.parseInt(json['user_id']),
      loginId: JsonParserUtils.parseString(json['login_id']),
      userName: JsonParserUtils.parseString(json['full_name']),
      userAuthLevel: JsonParserUtils.parseString(json['verification_level']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'login_id': loginId,
      'full_name': userName,
      'verification_level': userAuthLevel,
    };
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, loginId: $loginId, userName: $userName, userAuthLevel: $userAuthLevel)';
  }
}

/// 로그인 요청 모델
class LoginRequest {
  final String loginId;
  final String loginPassword;

  LoginRequest({required this.loginId, required this.loginPassword});

  Map<String, dynamic> toJson() {
    return {'login_id': loginId, 'password': loginPassword};
  }
}

/// 로그인 응답 모델
class LoginResponse {
  final String message;
  final int userId;
  final String loginId;
  final String userName;
  final String userAuthLevel;

  LoginResponse({
    required this.message,
    required this.userId,
    required this.loginId,
    required this.userName,
    required this.userAuthLevel,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: JsonParserUtils.parseString(json['message']),
      userId: JsonParserUtils.parseInt(json['user_id']),
      loginId: JsonParserUtils.parseString(json['login_id']),
      userName: JsonParserUtils.parseString(json['full_name']),
      userAuthLevel: JsonParserUtils.parseString(json['verification_level']),
    );
  }

  bool get isSuccess => message.contains('성공');

  /// UserModel로 변환
  UserModel toUserModel() {
    return UserModel(
      userId: userId,
      loginId: loginId,
      userName: userName,
      userAuthLevel: userAuthLevel,
    );
  }
}

/// 회원가입 요청 모델
class SignupRequest {
  final String fullName;
  final String loginId;
  final String phoneNumber;
  final String password;
  final List<Agreement> agreements;

  SignupRequest({
    required this.fullName,
    required this.loginId,
    required this.phoneNumber,
    required this.password,
    required this.agreements,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'login_id': loginId,
      'phone_number': phoneNumber,
      'password': password,
      'agreements': agreements.map((agreement) => agreement.toJson()).toList(),
    };
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
      termType: JsonParserUtils.parseString(json['term_type']),
      agreed: JsonParserUtils.parseBool(json['agreed']),
      agreedAt: JsonParserUtils.parseString(json['agreed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'term_type': termType, 'agreed': agreed, 'agreed_at': agreedAt};
  }

  bool get isServiceTerms => termType == 'SERVICE_TERMS';
  bool get isPrivacyPolicy => termType == 'PRIVACY_POLICY';
}

/// 인증 결과 데이터 모델
class VerificationResult {
  final String? did;
  final String provider;
  final String name;
  final String phone;
  final String birthday;
  final String sex;

  VerificationResult({
    this.did,
    required this.provider,
    required this.name,
    required this.phone,
    required this.birthday,
    required this.sex,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      did: json['did'],
      provider: JsonParserUtils.parseString(json['provider']),
      name: JsonParserUtils.parseString(json['name']),
      phone: JsonParserUtils.parseString(json['phone']),
      birthday: JsonParserUtils.parseString(json['birthday']),
      sex: JsonParserUtils.parseString(json['sex']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'provider': provider,
      'name': name,
      'phone': phone,
      'birthday': birthday,
      'sex': sex,
    };
  }

  /// 성별 한국어 반환
  String get genderKr => sex == 'M' ? '남성' : '여성';

  /// 생년월일 포맷팅 (YYYY-MM-DD)
  String get formattedBirthday {
    if (birthday.length == 8) {
      return '${birthday.substring(0, 4)}-${birthday.substring(4, 6)}-${birthday.substring(6, 8)}';
    }
    return birthday;
  }

  /// 전화번호 포맷팅
  String get formattedPhone {
    if (phone.startsWith('010')) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  @override
  String toString() {
    return 'VerificationResult(did: $did, provider: $provider, name: $name, phone: $phone, birthday: $birthday, sex: $sex)';
  }
}

/// 본인인증 기록 요청 모델
class IdentityVerificationRequest {
  final int userId;
  final String nextVerificationLevel;
  final bool isSuccess;
  final String? verificationResult;

  IdentityVerificationRequest({
    required this.userId,
    required this.nextVerificationLevel,
    required this.isSuccess,
    required this.verificationResult,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'next_verification_level': nextVerificationLevel,
      'is_success': isSuccess,
      'verification_result': verificationResult.toString(),
    };
  }

  @override
  String toString() {
    return 'IdentityVerificationRequest(userId: $userId, method: $nextVerificationLevel, success: $isSuccess, result: $verificationResult)';
  }
}

/// 본인인증 기록 응답 모델
class IdentityVerificationResponse {
  final String message;
  final String? newVerificationLevel;

  IdentityVerificationResponse({
    required this.message,
    this.newVerificationLevel,
  });

  factory IdentityVerificationResponse.fromJson(Map<String, dynamic> json) {
    return IdentityVerificationResponse(
      message: JsonParserUtils.parseString(json['message']),
      newVerificationLevel: json['new_verification_level'],
    );
  }

  bool get isSuccess => message.contains('성공') || message.contains('완료');

  @override
  String toString() {
    return 'IdentityVerificationResponse(message: $message, newLevel: $newVerificationLevel)';
  }
}
