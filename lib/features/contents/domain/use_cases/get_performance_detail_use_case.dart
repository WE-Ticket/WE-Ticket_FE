import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/performance_list.dart';
import '../repositories/performance_repository.dart';

/// Use case for fetching detailed information about a specific performance
class GetPerformanceDetailUseCase {
  final PerformanceRepository repository;

  const GetPerformanceDetailUseCase(this.repository);

  /// Execute the use case to get performance details
  Future<Either<Failure, PerformanceDetail>> call(int performanceId) async {
    // Validate performance ID
    final validationFailure = _validatePerformanceId(performanceId);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.getPerformanceDetail(performanceId);
  }

  /// Validate performance ID
  ValidationFailure? _validatePerformanceId(int performanceId) {
    if (performanceId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 공연 ID입니다');
    }

    return null;
  }
}