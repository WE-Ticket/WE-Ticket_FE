import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/verification_result.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../auth_service.dart';

/// AuthRepository 구현체
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<Either<Failure, User>> login(AuthCredentials credentials) async {
    try {
      final result = await _authService.login(
        loginId: credentials.loginId,
        password: credentials.password,
      );

      if (result.isSuccess && result.data != null) {
        final loginResponse = result.data!;
        final user = User(
          id: loginResponse.userId,
          loginId: loginResponse.loginId,
          name: loginResponse.userName,
          authLevel: UserAuthLevel.fromString(loginResponse.userAuthLevel),
        );
        return Right(user);
      } else {
        return Left(AuthenticationFailure(message: result.errorMessage!));
      }
    } catch (e) {
      AppLogger.error('로그인 처리 오류', e, null, 'AUTH');
      return Left(TechnicalFailure(message: '로그인 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, void>> signup(SignupData signupData) async {
    try {
      final result = await _authService.signup(
        fullName: signupData.fullName,
        loginId: signupData.loginId,
        phoneNumber: signupData.phoneNumber,
        password: signupData.password,
        agreeTerms: signupData.agreeTerms,
        agreePrivacy: signupData.agreePrivacy,
      );

      if (result.isSuccess) {
        return const Right(null);
      } else {
        return Left(ValidationFailure(message: result.errorMessage!));
      }
    } catch (e) {
      AppLogger.error('회원가입 처리 오류', e, null, 'AUTH');
      return Left(TechnicalFailure(message: '회원가입 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _clearAuthData();
      return const Right(null);
    } catch (e) {
      AppLogger.error('로그아웃 처리 오류', e, null, 'AUTH');
      return Left(TechnicalFailure(message: '로그아웃 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (!isLoggedIn) {
        return const Right(null);
      }

      final userId = prefs.getInt('user_id');
      final loginId = prefs.getString('login_id');
      final userName = prefs.getString('user_name');
      final userAuthLevel = prefs.getString('user_auth_level');

      if (userId != null && loginId != null && userName != null && userAuthLevel != null) {
        final user = User(
          id: userId,
          loginId: loginId,
          name: userName,
          authLevel: UserAuthLevel.fromString(userAuthLevel),
        );
        return Right(user);
      } else {
        await _clearAuthData();
        return const Right(null);
      }
    } catch (e) {
      AppLogger.error('현재 사용자 조회 오류', e, null, 'AUTH');
      return Left(TechnicalFailure(message: '사용자 정보 조회 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      return Right(isLoggedIn);
    } catch (e) {
      return Left(TechnicalFailure(message: '로그인 상태 확인 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshTokens() async {
    // TODO: 토큰 갱신 로직 구현
    return Left(TechnicalFailure(message: '토큰 갱신 기능이 구현되지 않았습니다'));
  }

  @override
  Future<Either<Failure, UserAuthLevel>> recordIdentityVerification(
    domain.IdentityVerificationRequest request,
  ) async {
    try {
      final result = await _authService.recordIdentityVerification(
        userId: request.userId,
        nextVerificationLevel: request.nextVerificationLevel.value,
        isSuccess: request.isSuccess,
        verificationResult: request.verificationResult?.toString() ?? '',
      );

      if (result.isSuccess && result.data != null) {
        final response = result.data!;
        return Right(UserAuthLevel.fromString(response.newVerificationLevel ?? 'general'));
      } else {
        return Left(ValidationFailure(message: result.errorMessage!));
      }
    } catch (e) {
      AppLogger.error('본인인증 기록 오류', e, null, 'AUTH');
      return Left(TechnicalFailure(message: '본인인증 기록 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, User?>> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        await _clearAuthData();
        return const Right(null);
      }

      return await getCurrentUser();
    } catch (e) {
      AppLogger.error('인증 상태 확인 오류', e, null, 'AUTH');
      await _clearAuthData();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> clearAuthData() async {
    try {
      await _clearAuthData();
      return const Right(null);
    } catch (e) {
      return Left(TechnicalFailure(message: '인증 데이터 삭제 중 오류가 발생했습니다'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> loadUserAuthLevel(int userId) async {
    try {
      final result = await _authService.loadUserAuthLevel(userId);
      
      if (result.isSuccess && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(NetworkFailure(message: result.errorMessage!));
      }
    } catch (e) {
      AppLogger.error('인증 레벨 조회 오류', e, null, 'AUTH');
      return Left(TechnicalFailure(message: '인증 레벨 조회 중 오류가 발생했습니다'));
    }
  }

  /// 인증 데이터 완전 삭제
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    AppLogger.info('모든 인증 데이터 삭제 완료', 'AUTH');
  }

}