import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/performance_list.dart';
import '../repositories/performance_repository.dart';

/// Use case for fetching available performances for booking
class GetAvailablePerformancesUseCase {
  final PerformanceRepository repository;

  const GetAvailablePerformancesUseCase(this.repository);

  /// Execute the use case to get available performances
  Future<Either<Failure, List<PerformanceAvailable>>> call() async {
    return await repository.getAvailablePerformances();
  }
}