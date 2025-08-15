import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/app_logger.dart';
import '../performance_service.dart';
import '../../domain/entities/performance.dart';
import '../../domain/entities/performance_list.dart';
import '../../domain/repositories/performance_repository.dart';
import '../mappers/performance_mapper.dart';

/// Implementation of PerformanceRepository
/// This class adapts between the data layer and domain layer
class PerformanceRepositoryImpl implements PerformanceRepository {
  final PerformanceService _performanceService;
  final PerformanceMapper _mapper;

  PerformanceRepositoryImpl(
    this._performanceService,
    this._mapper,
  );

  @override
  Future<Either<Failure, List<PerformanceHot>>> getHotPerformances() async {
    try {
      AppLogger.debug('Repository: Getting hot performances', 'PERFORMANCE_REPO');
      
      final result = await _performanceService.getHotPerformances();
      
      if (result.isSuccess) {
        final domainEntities = result.data!
            .map((model) => _mapper.hotItemToDomain(model))
            .toList();
        
        AppLogger.success('Repository: Hot performances mapped to domain', 'PERFORMANCE_REPO');
        return Right(domainEntities);
      } else {
        final failure = _mapApiResultToFailure(result);
        AppLogger.error('Repository: Failed to get hot performances', failure, null, 'PERFORMANCE_REPO');
        return Left(failure);
      }
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getHotPerformances', e, null, 'PERFORMANCE_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PerformanceAvailable>>> getAvailablePerformances() async {
    try {
      AppLogger.debug('Repository: Getting available performances', 'PERFORMANCE_REPO');
      
      final result = await _performanceService.getAvailablePerformances();
      
      if (result.isSuccess) {
        final domainEntities = result.data!
            .map((model) => _mapper.availableItemToDomain(model))
            .toList();
        
        AppLogger.success('Repository: Available performances mapped to domain', 'PERFORMANCE_REPO');
        return Right(domainEntities);
      } else {
        final failure = _mapApiResultToFailure(result);
        AppLogger.error('Repository: Failed to get available performances', failure, null, 'PERFORMANCE_REPO');
        return Left(failure);
      }
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getAvailablePerformances', e, null, 'PERFORMANCE_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, PerformanceList>> getAllPerformances({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug('Repository: Getting all performances (page: $page, limit: $limit)', 'PERFORMANCE_REPO');
      
      final result = await _performanceService.getAllPerformances(
        page: page,
        limit: limit,
      );
      
      if (result.isSuccess) {
        final domainEntity = _mapper.listResponseToDomain(result.data!);
        
        AppLogger.success('Repository: Performance list mapped to domain', 'PERFORMANCE_REPO');
        return Right(domainEntity);
      } else {
        final failure = _mapApiResultToFailure(result);
        AppLogger.error('Repository: Failed to get all performances', failure, null, 'PERFORMANCE_REPO');
        return Left(failure);
      }
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getAllPerformances', e, null, 'PERFORMANCE_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, PerformanceDetail>> getPerformanceDetail(int performanceId) async {
    try {
      AppLogger.debug('Repository: Getting performance detail (ID: $performanceId)', 'PERFORMANCE_REPO');
      
      final result = await _performanceService.getPerformanceDetail(performanceId);
      
      if (result.isSuccess) {
        final domainEntity = _mapper.detailToDomain(result.data!);
        
        AppLogger.success('Repository: Performance detail mapped to domain', 'PERFORMANCE_REPO');
        return Right(domainEntity);
      } else {
        final failure = _mapApiResultToFailure(result);
        AppLogger.error('Repository: Failed to get performance detail', failure, null, 'PERFORMANCE_REPO');
        return Left(failure);
      }
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getPerformanceDetail', e, null, 'PERFORMANCE_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Performance>>> getPerformancesByGenre(String genre) async {
    try {
      AppLogger.debug('Repository: Getting performances by genre: $genre', 'PERFORMANCE_REPO');
      
      final result = await _performanceService.getPerformancesByGenre(genre);
      
      if (result.isSuccess) {
        final domainEntities = result.data!
            .map((model) => _mapper.listItemToDomain(model))
            .toList();
        
        AppLogger.success('Repository: Genre-filtered performances mapped to domain', 'PERFORMANCE_REPO');
        return Right(domainEntities);
      } else {
        final failure = _mapApiResultToFailure(result);
        AppLogger.error('Repository: Failed to get performances by genre', failure, null, 'PERFORMANCE_REPO');
        return Left(failure);
      }
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getPerformancesByGenre', e, null, 'PERFORMANCE_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Performance>>> searchPerformances(String query) async {
    try {
      AppLogger.debug('Repository: Searching performances: $query', 'PERFORMANCE_REPO');
      
      // For now, we'll implement search as a filter on all performances
      // This can be optimized later with a dedicated search API
      final allPerformancesResult = await getAllPerformances();
      
      return allPerformancesResult.fold(
        (failure) => Left(failure),
        (performanceList) {
          final filteredPerformances = performanceList.performances
              .where((performance) {
                final searchQuery = query.toLowerCase();
                return performance.title.toLowerCase().contains(searchQuery) ||
                    performance.performerName.toLowerCase().contains(searchQuery) ||
                    performance.venueName.toLowerCase().contains(searchQuery);
              })
              .toList();
          
          AppLogger.success('Repository: Search completed, found ${filteredPerformances.length} results', 'PERFORMANCE_REPO');
          return Right(filteredPerformances);
        },
      );
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in searchPerformances', e, null, 'PERFORMANCE_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  /// Map ApiResult to Failure
  Failure _mapApiResultToFailure<T>(ApiResult<T> result) {
    switch (result.errorType) {
      case ApiErrorType.network:
        return NetworkFailure(message: result.errorMessage ?? '네트워크 오류가 발생했습니다');
      case ApiErrorType.authentication:
        return AuthFailure(message: result.errorMessage ?? '인증 오류가 발생했습니다');
      case ApiErrorType.validation:
        return ValidationFailure(message: result.errorMessage ?? '입력 값이 올바르지 않습니다');
      case ApiErrorType.server:
        return ServerFailure(message: result.errorMessage ?? '서버 오류가 발생했습니다');
      case ApiErrorType.timeout:
        return NetworkFailure(message: result.errorMessage ?? '요청 시간이 초과되었습니다');
      case ApiErrorType.unknown:
      default:
        return ServerFailure(message: result.errorMessage ?? '알 수 없는 오류가 발생했습니다');
    }
  }
}