import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transfer_ticket.dart';
import '../repositories/transfer_repository.dart';

/// Parameters for getting user's transfer tickets
class GetMyTransferTicketsParams {
  final int userId;
  final String? startDate;
  final String? endDate;

  const GetMyTransferTicketsParams({
    required this.userId,
    this.startDate,
    this.endDate,
  });
}

/// Use case for fetching user's registered and transferable tickets
class GetMyTransferTicketsUseCase {
  final TransferRepository repository;

  const GetMyTransferTicketsUseCase(this.repository);

  /// Execute the use case to get registered transfer tickets
  Future<Either<Failure, List<MyTransferTicket>>> getRegisteredTickets(
    GetMyTransferTicketsParams params,
  ) async {
    // Validate parameters
    final validationFailure = _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.getMyRegisteredTickets(
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }

  /// Execute the use case to get transferable tickets
  Future<Either<Failure, List<TransferableTicket>>> getTransferableTickets(
    GetMyTransferTicketsParams params,
  ) async {
    // Validate parameters
    final validationFailure = _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.getMyTransferableTickets(
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(GetMyTransferTicketsParams params) {
    if (params.userId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 사용자 ID입니다');
    }

    // Validate date format if provided
    if (params.startDate != null && params.startDate!.isNotEmpty) {
      try {
        DateTime.parse(params.startDate!);
      } catch (e) {
        return const ValidationFailure(message: '시작 날짜 형식이 올바르지 않습니다');
      }
    }

    if (params.endDate != null && params.endDate!.isNotEmpty) {
      try {
        DateTime.parse(params.endDate!);
      } catch (e) {
        return const ValidationFailure(message: '종료 날짜 형식이 올바르지 않습니다');
      }
    }

    // Validate date range
    if (params.startDate != null && params.endDate != null) {
      final startDate = DateTime.parse(params.startDate!);
      final endDate = DateTime.parse(params.endDate!);
      
      if (startDate.isAfter(endDate)) {
        return const ValidationFailure(message: '시작 날짜가 종료 날짜보다 늦을 수 없습니다');
      }
    }

    return null;
  }
}