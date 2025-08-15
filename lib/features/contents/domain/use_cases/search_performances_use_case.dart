import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/performance.dart';
import '../repositories/performance_repository.dart';

/// Use case for searching performances by query string
class SearchPerformancesUseCase {
  final PerformanceRepository repository;

  const SearchPerformancesUseCase(this.repository);

  /// Execute the use case to search performances
  Future<Either<Failure, List<Performance>>> call(String query) async {
    // Validate search query
    final validationFailure = _validateQuery(query);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.searchPerformances(query.trim());
  }

  /// Validate search query
  ValidationFailure? _validateQuery(String query) {
    if (query.trim().isEmpty) {
      return const ValidationFailure(message: '검색어를 입력해주세요');
    }

    if (query.trim().length < 2) {
      return const ValidationFailure(message: '검색어는 2자 이상 입력해주세요');
    }

    if (query.trim().length > 100) {
      return const ValidationFailure(message: '검색어는 100자 이하로 입력해주세요');
    }

    return null;
  }
}