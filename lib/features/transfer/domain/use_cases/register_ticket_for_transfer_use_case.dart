import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/transfer_repository.dart';

/// Parameters for registering ticket for transfer
class RegisterTicketForTransferParams {
  final userId;
  final String ticketId;
  final bool isPublicTransfer;
  final int? transferTicketPrice;

  const RegisterTicketForTransferParams({
    required this.userId,
    required this.ticketId,
    required this.isPublicTransfer,
    this.transferTicketPrice,
  });
}

/// Use case for registering a ticket for transfer
class RegisterTicketForTransferUseCase {
  final TransferRepository repository;

  const RegisterTicketForTransferUseCase(this.repository);

  /// Execute the use case to register ticket for transfer
  Future<Either<Failure, void>> call(
    RegisterTicketForTransferParams params,
  ) async {
    // Validate parameters
    final validationFailure = _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.registerTicketForTransfer(
      userId: params.userId,
      ticketId: params.ticketId,
      isPublicTransfer: params.isPublicTransfer,
      transferTicketPrice: params.transferTicketPrice,
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(RegisterTicketForTransferParams params) {
    if (params.ticketId.trim().isEmpty) {
      return const ValidationFailure(message: '티켓 ID를 입력해주세요');
    }

    if (params.transferTicketPrice != null && params.transferTicketPrice! < 0) {
      return const ValidationFailure(message: '양도 가격은 0 이상이어야 합니다');
    }

    if (params.transferTicketPrice != null &&
        params.transferTicketPrice! > 10000000) {
      return const ValidationFailure(message: '양도 가격이 너무 높습니다');
    }

    return null;
  }
}
