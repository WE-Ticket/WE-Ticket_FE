import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_level_entities.dart';
import '../entities/user.dart';
import '../entities/verification_result.dart';
import '../repositories/auth_repository.dart';

/// 인증 레벨 관리 Use Case
class ManageAuthLevelUseCase {
  final AuthRepository _authRepository;

  ManageAuthLevelUseCase(this._authRepository);

  /// 사용자 인증 레벨 조회
  Future<Either<Failure, AuthLevel>> getUserAuthLevel(int userId) async {
    try {
      final result = await _authRepository.loadUserAuthLevel(userId);
      return result.fold(
        (failure) => Left(failure),
        (data) {
          final levelString = data['verification_level'] as String? ?? 'none';
          return Right(AuthLevel.fromString(levelString));
        },
      );
    } catch (e) {
      return Left(TechnicalFailure(message: '인증 레벨 조회 중 오류가 발생했습니다'));
    }
  }

  /// 본인인증 결과 기록
  Future<Either<Failure, UserAuthLevel>> recordVerification({
    required int userId,
    required AuthLevel targetLevel,
    required bool isSuccess,
    required VerificationResult? verificationResult,
  }) async {
    final request = IdentityVerificationRequest(
      userId: userId,
      nextVerificationLevel: UserAuthLevel.fromString(targetLevel.value),
      isSuccess: isSuccess,
      verificationResult: verificationResult,
    );

    return await _authRepository.recordIdentityVerification(request);
  }

  /// 인증 업그레이드 옵션 가져오기
  AuthUpgradeOption? getUpgradeOption(AuthLevel currentLevel) {
    return AuthUpgradeOption.getNextUpgrade(currentLevel);
  }

  /// 사용자 권한 목록 가져오기
  List<UserPrivilege> getUserPrivileges(AuthLevel userLevel) {
    return UserPrivilege.getPrivilegesForLevel(userLevel);
  }

  /// 특정 권한 사용 가능 여부 확인
  bool canUsePrivilege(AuthLevel userLevel, AuthLevel requiredLevel) {
    return userLevel.isAtLeast(requiredLevel);
  }
}