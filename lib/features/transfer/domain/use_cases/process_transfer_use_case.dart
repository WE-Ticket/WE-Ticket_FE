import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/transfer_repository.dart';

/// Parameters for processing a transfer
class ProcessTransferParams {
  final int userId;
  final int transferTicketId;

  const ProcessTransferParams({
    required this.userId,
    required this.transferTicketId,
  });
}

/// Use case for processing a transfer (buying a transfer ticket)
class ProcessTransferUseCase {
  final TransferRepository repository;

  const ProcessTransferUseCase(this.repository);

  /// Execute the use case to process transfer
  Future<Either<Failure, void>> call(ProcessTransferParams params) async {
    // Validate parameters
    final validationFailure = _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.processTransfer(
      userId: params.userId,
      transferTicketId: params.transferTicketId,
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(ProcessTransferParams params) {
    if (params.userId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 사용자 ID입니다');
    }

    if (params.transferTicketId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 양도 티켓 ID입니다');
    }

    return null;
  }
}