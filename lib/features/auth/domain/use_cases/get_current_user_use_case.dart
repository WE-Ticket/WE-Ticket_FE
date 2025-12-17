import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting current user information
class GetCurrentUserUseCase {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  /// Execute get current user operation
  Future<Either<Failure, User?>> call() async {
    return await repository.getCurrentUser();
  }
}