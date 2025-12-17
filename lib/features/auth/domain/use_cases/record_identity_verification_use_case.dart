import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../entities/verification_result.dart';
import '../repositories/auth_repository.dart';

/// Use case for recording identity verification
class RecordIdentityVerificationUseCase {
  final AuthRepository repository;

  const RecordIdentityVerificationUseCase(this.repository);

  /// Execute identity verification recording
  Future<Either<Failure, UserAuthLevel>> call(
    IdentityVerificationRequest request,
  ) async {
    // Validate verification request
    final validationResult = _validateVerificationRequest(request);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Record verification through repository
    return await repository.recordIdentityVerification(request);
  }

  /// Validate identity verification request
  ValidationFailure? _validateVerificationRequest(
    IdentityVerificationRequest request,
  ) {
    if (request.userId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 사용자 ID입니다');
    }

    if (request.isSuccess && request.verificationResult == null) {
      return const ValidationFailure(message: '성공한 인증의 경우 인증 결과가 필요합니다');
    }

    if (request.verificationResult != null) {
      final result = request.verificationResult!;
      
      if (result.name.trim().isEmpty) {
        return const ValidationFailure(message: '인증 결과에 이름이 누락되었습니다');
      }

      if (result.phone.trim().isEmpty) {
        return const ValidationFailure(message: '인증 결과에 휴대폰 번호가 누락되었습니다');
      }

      if (result.birthday.trim().isEmpty) {
        return const ValidationFailure(message: '인증 결과에 생년월일이 누락되었습니다');
      }
    }

    return null;
  }
}