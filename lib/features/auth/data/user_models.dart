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
  final String appId;
  final bool isNewInstall;

  LoginRequest({
    required this.loginId,
    required this.loginPassword,
    required this.appId,
    required this.isNewInstall,
  });

  Map<String, dynamic> toJson() {
    return {
      'login_id': loginId,
      'password': loginPassword,
      'app_id': appId,
      'is_new_install': isNewInstall,
    };
  }
}

/// 로그인 응답 모델
class LoginResponse {
  final String message;
  final int userId;
  final String loginId;
  final String userName;
  final String userAuthLevel;
  final String accessToken;
  final String refreshToken;

  LoginResponse({
    required this.message,
    required this.userId,
    required this.loginId,
    required this.userName,
    required this.userAuthLevel,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: JsonParserUtils.parseString(json['message']),
      userId: JsonParserUtils.parseInt(json['user_id']),
      loginId: JsonParserUtils.parseString(json['login_id']),
      userName: JsonParserUtils.parseString(json['full_name']),
      userAuthLevel: JsonParserUtils.parseString(json['verification_level']),
      accessToken: JsonParserUtils.parseString(json['access_token']),
      refreshToken: JsonParserUtils.parseString(json['refresh_token']),
    );
  }

  UserModel toUserModel() {
    return UserModel(
      userId: userId,
      loginId: loginId,
      userName: userName,
      userAuthLevel: userAuthLevel,
    );
  }

  bool get isSuccess => message.contains('성공');
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


/// 아이디 찾기 요청 모델
class FindIdRequest {
  final String phoneNumber;

  FindIdRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phone_number': phoneNumber};
  }
}

/// 아이디 찾기 응답 모델
class FindIdResponse {
  final String message;
  final String phoneNumber;
  final String? verificationCode;

  FindIdResponse({
    required this.message,
    required this.phoneNumber,
    this.verificationCode,
  });

  factory FindIdResponse.fromJson(Map<String, dynamic> json) {
    return FindIdResponse(
      message: JsonParserUtils.parseString(json['message']),
      phoneNumber: JsonParserUtils.parseString(json['phone_number']),
      verificationCode: json['verification_code'],
    );
  }
}

/// 아이디 확인 요청 모델
class VerifyIdRequest {
  final String phoneNumber;
  final String code;

  VerifyIdRequest({
    required this.phoneNumber,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'code': code,
    };
  }
}

/// 아이디 확인 응답 모델
class VerifyIdResponse {
  final String message;
  final String? loginId;

  VerifyIdResponse({
    required this.message,
    this.loginId,
  });

  factory VerifyIdResponse.fromJson(Map<String, dynamic> json) {
    return VerifyIdResponse(
      message: JsonParserUtils.parseString(json['message']),
      loginId: json['login_id'],
    );
  }

  bool get isSuccess => message.contains('성공');
}

/// 비밀번호 찾기 요청 모델
class FindPasswordRequest {
  final String phoneNumber;
  final String loginId;

  FindPasswordRequest({
    required this.phoneNumber,
    required this.loginId,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'login_id': loginId,
    };
  }
}

/// 비밀번호 찾기 응답 모델
class FindPasswordResponse {
  final String message;
  final String loginId;
  final String phoneNumber;
  final String? verificationCode;

  FindPasswordResponse({
    required this.message,
    required this.loginId,
    required this.phoneNumber,
    this.verificationCode,
  });

  factory FindPasswordResponse.fromJson(Map<String, dynamic> json) {
    return FindPasswordResponse(
      message: JsonParserUtils.parseString(json['message']),
      loginId: JsonParserUtils.parseString(json['login_id']),
      phoneNumber: JsonParserUtils.parseString(json['phone_number']),
      verificationCode: json['verification_code'],
    );
  }
}

/// 비밀번호 재설정 인증 요청 모델
class VerifyPasswordRequest {
  final String phoneNumber;
  final String loginId;
  final String code;

  VerifyPasswordRequest({
    required this.phoneNumber,
    required this.loginId,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'login_id': loginId,
      'code': code,
    };
  }
}

/// 비밀번호 재설정 인증 응답 모델
class VerifyPasswordResponse {
  final String message;
  final String loginId;
  final bool canResetPassword;

  VerifyPasswordResponse({
    required this.message,
    required this.loginId,
    required this.canResetPassword,
  });

  factory VerifyPasswordResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPasswordResponse(
      message: JsonParserUtils.parseString(json['message']),
      loginId: JsonParserUtils.parseString(json['login_id']),
      canResetPassword: JsonParserUtils.parseBool(json['can_reset_password']),
    );
  }

  bool get isSuccess => message.contains('성공');
}

/// 비밀번호 재설정 요청 모델
class ResetPasswordRequest {
  final String phoneNumber;
  final String loginId;
  final String newPassword;

  ResetPasswordRequest({
    required this.phoneNumber,
    required this.loginId,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'login_id': loginId,
      'new_password': newPassword,
    };
  }
}

/// 비밀번호 재설정 응답 모델
class ResetPasswordResponse {
  final String message;

  ResetPasswordResponse({required this.message});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: JsonParserUtils.parseString(json['message']),
    );
  }

  bool get isSuccess => message.contains('성공');
}

/// 전화번호 중복 확인 응답 모델
class PhoneNumberCheckResponse {
  final bool isDuplicate;

  PhoneNumberCheckResponse({required this.isDuplicate});

  factory PhoneNumberCheckResponse.fromJson(Map<String, dynamic> json) {
    return PhoneNumberCheckResponse(
      isDuplicate: JsonParserUtils.parseBool(json['is_duplicate']),
    );
  }
}

/// 로그인 아이디 중복 확인 응답 모델
class LoginIdCheckResponse {
  final bool isDuplicate;

  LoginIdCheckResponse({required this.isDuplicate});

  factory LoginIdCheckResponse.fromJson(Map<String, dynamic> json) {
    return LoginIdCheckResponse(
      isDuplicate: JsonParserUtils.parseBool(json['is_duplicate']),
    );
  }
}
