import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../entities/auth_credentials.dart';
import '../repositories/auth_repository.dart';

/// Use case for user signup
class SignupUseCase {
  final AuthRepository repository;

  const SignupUseCase(this.repository);

  /// Execute signup operation
  Future<Either<Failure, void>> call(SignupData signupData) async {
    // Validate signup data
    final validationResult = _validateSignupData(signupData);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Perform signup through repository
    return await repository.signup(signupData);
  }

  /// Validate signup data
  ValidationFailure? _validateSignupData(SignupData signupData) {
    // Validate full name
    if (signupData.fullName.trim().isEmpty) {
      return const ValidationFailure(message: '이름을 입력해주세요');
    }

    if (!signupData.fullName.isValidKoreanName) {
      return const ValidationFailure(message: '올바른 한국어 이름을 입력해주세요');
    }

    // Validate login ID
    if (signupData.loginId.trim().isEmpty) {
      return const ValidationFailure(message: '로그인 ID를 입력해주세요');
    }

    if (signupData.loginId.length < 4 || signupData.loginId.length > 20) {
      return const ValidationFailure(message: '로그인 ID는 4자 이상 20자 이하여야 합니다');
    }

    if (!signupData.loginId.isValidLoginId) {
      return const ValidationFailure(message: '로그인 ID는 영문자, 숫자, 언더스코어만 사용 가능합니다');
    }

    // Validate phone number
    if (signupData.phoneNumber.trim().isEmpty) {
      return const ValidationFailure(message: '휴대폰 번호를 입력해주세요');
    }

    if (!signupData.phoneNumber.isValidKoreanPhone) {
      return const ValidationFailure(message: '올바른 휴대폰 번호를 입력해주세요');
    }

    // Validate password
    if (signupData.password.trim().isEmpty) {
      return const ValidationFailure(message: '비밀번호를 입력해주세요');
    }

    if (!signupData.password.isValidPassword) {
      return const ValidationFailure(message: '비밀번호는 8자 이상이며, 영문자와 숫자 조합이어야 합니다');
    }

    // Validate agreements
    final hasServiceTerms = signupData.agreements.any(
      (agreement) => agreement.termType == TermType.serviceTerms && agreement.agreed,
    );
    final hasPrivacyPolicy = signupData.agreements.any(
      (agreement) => agreement.termType == TermType.privacyPolicy && agreement.agreed,
    );

    if (!hasServiceTerms) {
      return const ValidationFailure(message: '서비스 이용약관에 동의해주세요');
    }

    if (!hasPrivacyPolicy) {
      return const ValidationFailure(message: '개인정보 처리방침에 동의해주세요');
    }

    return null;
  }
}