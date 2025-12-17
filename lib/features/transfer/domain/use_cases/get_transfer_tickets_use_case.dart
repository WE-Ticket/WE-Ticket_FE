import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transfer_ticket.dart';
import '../repositories/transfer_repository.dart';

/// Parameters for getting transfer tickets
class GetTransferTicketsParams {
  final int? performanceId;
  final int page;
  final int limit;

  const GetTransferTicketsParams({
    this.performanceId,
    this.page = 1,
    this.limit = 20,
  });
}

/// Use case for fetching transfer tickets from the marketplace
class GetTransferTicketsUseCase {
  final TransferRepository repository;

  const GetTransferTicketsUseCase(this.repository);

  /// Execute the use case to get transfer tickets
  Future<Either<Failure, TransferList>> call(GetTransferTicketsParams params) async {
    // Validate parameters
    final validationFailure = _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.getTransferTicketList(
      performanceId: params.performanceId,
      page: params.page,
      limit: params.limit,
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(GetTransferTicketsParams params) {
    if (params.page < 1) {
      return const ValidationFailure(message: '페이지 번호는 1 이상이어야 합니다');
    }

    if (params.limit < 1 || params.limit > 100) {
      return const ValidationFailure(message: '페이지 크기는 1~100 사이여야 합니다');
    }

    if (params.performanceId != null && params.performanceId! <= 0) {
      return const ValidationFailure(message: '유효하지 않은 공연 ID입니다');
    }

    return null;
  }
}