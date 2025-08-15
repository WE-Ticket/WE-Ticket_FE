import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/performance.dart';
import '../repositories/performance_repository.dart';

/// Use case for fetching performances filtered by genre
class GetPerformancesByGenreUseCase {
  final PerformanceRepository repository;

  const GetPerformancesByGenreUseCase(this.repository);

  /// Execute the use case to get performances by genre
  Future<Either<Failure, List<Performance>>> call(String genre) async {
    // Validate genre
    final validationFailure = _validateGenre(genre);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.getPerformancesByGenre(genre.trim().toLowerCase());
  }

  /// Validate genre parameter
  ValidationFailure? _validateGenre(String genre) {
    if (genre.trim().isEmpty) {
      return const ValidationFailure(message: '장르를 입력해주세요');
    }

    // Check if genre is valid
    final validGenres = [
      'musical',
      'concert',
      'classic',
      'opera',
      'dance',
      'theater',
      'family',
      'exhibition',
      'other',
    ];

    if (!validGenres.contains(genre.trim().toLowerCase())) {
      return const ValidationFailure(message: '지원하지 않는 장르입니다');
    }

    return null;
  }
}