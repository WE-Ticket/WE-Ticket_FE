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
    return {'login_id': loginId, 'login_password': loginPassword};
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
