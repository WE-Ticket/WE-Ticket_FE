import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/app_logger.dart';
import '../transfer_service.dart';
import '../../domain/entities/transfer_ticket.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../mappers/transfer_mapper.dart';

/// Implementation of TransferRepository
/// This class adapts between the data layer and domain layer
class TransferRepositoryImpl implements TransferRepository {
  final TransferService _transferService;
  final TransferMapper _mapper;

  TransferRepositoryImpl(
    this._transferService,
    this._mapper,
  );

  @override
  Future<Either<Failure, TransferList>> getTransferTicketList({
    int? performanceId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug('Repository: Getting transfer ticket list', 'TRANSFER_REPO');
      
      final result = await _transferService.getTransferTicketList(
        performanceId: performanceId,
        page: page,
        limit: limit,
      );
      
      if (result.isSuccess) {
        final domainEntity = _mapper.transferListResponseToDomain(result.data!);
        
        AppLogger.success('Repository: Transfer list mapped to domain', 'TRANSFER_REPO');
        return Right(domainEntity);
      } else {
        final failure = _mapApiResultToFailure(result);
        AppLogger.error('Repository: Failed to get transfer list', failure, null, 'TRANSFER_REPO');
        return Left(failure);
      }
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getTransferTicketList', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, TransferTicketDetail>> getTransferTicketDetail(int transferTicketId) async {
    try {
      AppLogger.debug('Repository: Getting transfer ticket detail (ID: $transferTicketId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      // For now, we'll create a placeholder implementation
      return Left(ServerFailure(message: 'Transfer detail API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getTransferTicketDetail', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getUniqueCode(int transferTicketId) async {
    try {
      AppLogger.debug('Repository: Getting unique code (ID: $transferTicketId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Get unique code API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getUniqueCode', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> regenerateUniqueCode(int transferTicketId) async {
    try {
      AppLogger.debug('Repository: Regenerating unique code (ID: $transferTicketId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Regenerate unique code API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in regenerateUniqueCode', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> lookupPrivateTicket(String code) async {
    try {
      AppLogger.debug('Repository: Looking up private ticket (code: $code)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Lookup private ticket API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in lookupPrivateTicket', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleTransferType(int transferTicketId) async {
    try {
      AppLogger.debug('Repository: Toggling transfer type (ID: $transferTicketId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Toggle transfer type API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in toggleTransferType', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTransfer(int transferTicketId) async {
    try {
      AppLogger.debug('Repository: Cancelling transfer (ID: $transferTicketId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Cancel transfer API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in cancelTransfer', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MyTransferTicket>>> getMyRegisteredTickets({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      AppLogger.debug('Repository: Getting user registered tickets (ID: $userId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Get my registered tickets API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getMyRegisteredTickets', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransferableTicket>>> getMyTransferableTickets({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      AppLogger.debug('Repository: Getting user transferable tickets (ID: $userId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Get my transferable tickets API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getMyTransferableTickets', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> registerTicketForTransfer({
    required String ticketId,
    required bool isPublicTransfer,
    int? transferTicketPrice,
  }) async {
    try {
      AppLogger.debug('Repository: Registering ticket for transfer (ID: $ticketId)', 'TRANSFER_REPO');
      
      final result = await _transferService.postTransferTicketRegister(
        ticketId: ticketId,
        isPublicTransfer: isPublicTransfer,
        transferTicketPrice: transferTicketPrice,
      );
      
      if (result.isSuccess) {
        AppLogger.success('Repository: Ticket registered for transfer', 'TRANSFER_REPO');
        return const Right(null);
      } else {
        final failure = _mapApiResultToFailure(result);
        AppLogger.error('Repository: Failed to register ticket for transfer', failure, null, 'TRANSFER_REPO');
        return Left(failure);
      }
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in registerTicketForTransfer', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> processTransfer({
    required int userId,
    required int transferTicketId,
  }) async {
    try {
      AppLogger.debug('Repository: Processing transfer (User: $userId, Ticket: $transferTicketId)', 'TRANSFER_REPO');
      
      // Note: This method would need to be updated in TransferService to use ApiResult
      return Left(ServerFailure(message: 'Process transfer API not migrated to ApiResult yet'));
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in processTransfer', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransferTicket>>> getTransferTicketsByPerformance(int performanceId) async {
    try {
      AppLogger.debug('Repository: Getting transfer tickets by performance (ID: $performanceId)', 'TRANSFER_REPO');
      
      final listResult = await getTransferTicketList(performanceId: performanceId);
      
      return listResult.fold(
        (failure) => Left(failure),
        (transferList) => Right(transferList.tickets),
      );
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getTransferTicketsByPerformance', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransferTicket>>> getTransferTicketsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.debug('Repository: Getting transfer tickets by date range', 'TRANSFER_REPO');
      
      // Get all tickets and filter locally
      final listResult = await getTransferTicketList();
      
      return listResult.fold(
        (failure) => Left(failure),
        (transferList) {
          final filteredTickets = transferList.tickets.where((ticket) {
            return ticket.sessionDateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
                ticket.sessionDateTime.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();
          
          AppLogger.success('Repository: Date-filtered tickets: ${filteredTickets.length}', 'TRANSFER_REPO');
          return Right(filteredTickets);
        },
      );
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in getTransferTicketsByDateRange', e, null, 'TRANSFER_REPO');
      return Left(ServerFailure(message: '알 수 없는 오류가 발생했습니다: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransferTicket>>> searchTransferTickets(String query) async {
    try {
      AppLogger.debug('Repository: Searching transfer tickets: $query', 'TRANSFER_REPO');
      
      // Get all tickets and filter locally
      final listResult = await getTransferTicketList();
      
      return listResult.fold(
        (failure) => Left(failure),
        (transferList) {
          final searchQuery = query.toLowerCase();
          final filteredTickets = transferList.tickets.where((ticket) {
            return ticket.performanceTitle.toLowerCase().contains(searchQuery) ||
                ticket.performerName.toLowerCase().contains(searchQuery) ||
                ticket.venueName.toLowerCase().contains(searchQuery);
          }).toList();
          
          AppLogger.success('Repository: Search results: ${filteredTickets.length}', 'TRANSFER_REPO');
          return Right(filteredTickets);
        },
      );
    } catch (e) {
      AppLogger.error('Repository: Unexpected error in searchTransferTickets', e, null, 'TRANSFER_REPO');
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