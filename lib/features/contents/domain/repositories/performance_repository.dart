import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/performance.dart';
import '../entities/performance_list.dart';

/// Repository interface for performance operations
/// This defines the contract for performance data operations
abstract class PerformanceRepository {
  /// Get list of hot/featured performances
  Future<Either<Failure, List<PerformanceHot>>> getHotPerformances();

  /// Get list of available performances for booking
  Future<Either<Failure, List<PerformanceAvailable>>> getAvailablePerformances();

  /// Get paginated list of all performances
  Future<Either<Failure, PerformanceList>> getAllPerformances({
    int page = 1,
    int limit = 20,
  });

  /// Get detailed information about a specific performance
  Future<Either<Failure, PerformanceDetail>> getPerformanceDetail(int performanceId);

  /// Get performances filtered by genre
  Future<Either<Failure, List<Performance>>> getPerformancesByGenre(String genre);

  /// Search performances by query string
  Future<Either<Failure, List<Performance>>> searchPerformances(String query);
}