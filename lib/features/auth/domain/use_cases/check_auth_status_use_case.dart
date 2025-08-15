import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking authentication status
class CheckAuthStatusUseCase {
  final AuthRepository repository;

  const CheckAuthStatusUseCase(this.repository);

  /// Execute auth status check operation
  /// Returns user if authenticated, null if not authenticated
  Future<Either<Failure, User?>> call() async {
    return await repository.checkAuthStatus();
  }
}