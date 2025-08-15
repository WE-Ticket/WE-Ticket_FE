import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_credentials.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login
class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  /// Execute login operation
  Future<Either<Failure, User>> call(AuthCredentials credentials) async {
    // Validate credentials
    final validationResult = _validateCredentials(credentials);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Perform login through repository
    return await repository.login(credentials);
  }

  /// Validate login credentials
  ValidationFailure? _validateCredentials(AuthCredentials credentials) {
    if (credentials.loginId.trim().isEmpty) {
      return const ValidationFailure(message: '로그인 ID를 입력해주세요');
    }

    if (credentials.password.trim().isEmpty) {
      return const ValidationFailure(message: '비밀번호를 입력해주세요');
    }

    if (credentials.loginId.length < 4) {
      return const ValidationFailure(message: '로그인 ID는 4자 이상이어야 합니다');
    }

    if (credentials.password.length < 6) {
      return const ValidationFailure(message: '비밀번호는 6자 이상이어야 합니다');
    }

    return null;
  }
}