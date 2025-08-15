import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/performance_list.dart';
import '../repositories/performance_repository.dart';

/// Use case for fetching hot/featured performances
class GetHotPerformancesUseCase {
  final PerformanceRepository repository;

  const GetHotPerformancesUseCase(this.repository);

  /// Execute the use case to get hot performances
  Future<Either<Failure, List<PerformanceHot>>> call() async {
    return await repository.getHotPerformances();
  }
}