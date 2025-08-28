import 'package:equatable/equatable.dart';

/// Domain entity representing authentication credentials
class AuthCredentials extends Equatable {
  final String loginId;
  final String password;
  final String appId;
  final bool isNewInstall;

  const AuthCredentials({
    required this.loginId,
    required this.password,
    required this.appId,
    required this.isNewInstall,
  });

  @override
  List<Object?> get props => [loginId, password, appId, isNewInstall];

  @override
  String toString() => 'AuthCredentials(loginId: $loginId, appId: $appId, isNewInstall: $isNewInstall)';
}

/// Domain entity representing signup data
class SignupData extends Equatable {
  final String fullName;
  final String loginId;
  final String phoneNumber;
  final String password;
  final List<TermsAgreement> agreements;

  const SignupData({
    required this.fullName,
    required this.loginId,
    required this.phoneNumber,
    required this.password,
    required this.agreements,
  });

  bool get agreeTerms => agreements.any((a) => a.termType == TermType.serviceTerms && a.agreed);
  bool get agreePrivacy => agreements.any((a) => a.termType == TermType.privacyPolicy && a.agreed);

  @override
  List<Object?> get props => [fullName, loginId, phoneNumber, password, agreements];

  @override
  String toString() => 'SignupData(fullName: $fullName, loginId: $loginId, phoneNumber: $phoneNumber)';
}

/// Domain entity representing terms agreement
class TermsAgreement extends Equatable {
  final TermType termType;
  final bool agreed;
  final DateTime agreedAt;

  const TermsAgreement({
    required this.termType,
    required this.agreed,
    required this.agreedAt,
  });

  @override
  List<Object?> get props => [termType, agreed, agreedAt];

  @override
  String toString() => 'TermsAgreement(termType: $termType, agreed: $agreed)';
}

/// Enum representing different types of terms
enum TermType {
  serviceTerms('SERVICE_TERMS', '서비스 이용약관'),
  privacyPolicy('PRIVACY_POLICY', '개인정보 처리방침');

  const TermType(this.value, this.displayName);

  final String value;
  final String displayName;

  static TermType fromString(String value) {
    switch (value) {
      case 'SERVICE_TERMS':
        return TermType.serviceTerms;
      case 'PRIVACY_POLICY':
        return TermType.privacyPolicy;
      default:
        return TermType.serviceTerms;
    }
  }
}

/// Domain entity representing authentication tokens
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken];

  @override
  String toString() => 'AuthTokens(accessToken: ${accessToken.substring(0, 10)}...)';
}