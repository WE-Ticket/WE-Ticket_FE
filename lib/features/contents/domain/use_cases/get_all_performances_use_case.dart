import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/performance_list.dart';
import '../repositories/performance_repository.dart';

/// Parameters for getting all performances
class GetAllPerformancesParams {
  final int page;
  final int limit;

  const GetAllPerformancesParams({
    this.page = 1,
    this.limit = 20,
  });
}

/// Use case for fetching paginated list of all performances
class GetAllPerformancesUseCase {
  final PerformanceRepository repository;

  const GetAllPerformancesUseCase(this.repository);

  /// Execute the use case to get all performances
  Future<Either<Failure, PerformanceList>> call(GetAllPerformancesParams params) async {
    // Validate parameters
    final validationFailure = _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.getAllPerformances(
      page: params.page,
      limit: params.limit,
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(GetAllPerformancesParams params) {
    if (params.page < 1) {
      return const ValidationFailure(message: '페이지 번호는 1 이상이어야 합니다');
    }

    if (params.limit < 1 || params.limit > 100) {
      return const ValidationFailure(message: '페이지 크기는 1~100 사이여야 합니다');
    }

    return null;
  }
}