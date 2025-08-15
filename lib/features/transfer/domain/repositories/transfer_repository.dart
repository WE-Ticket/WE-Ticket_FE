import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transfer_ticket.dart';

/// Repository interface for transfer operations
/// This defines the contract for transfer data operations
abstract class TransferRepository {
  /// Get list of transfer tickets available in the marketplace
  Future<Either<Failure, TransferList>> getTransferTicketList({
    int? performanceId,
    int page = 1,
    int limit = 20,
  });

  /// Get detailed information about a specific transfer ticket
  Future<Either<Failure, TransferTicketDetail>> getTransferTicketDetail(int transferTicketId);

  /// Get unique code for private transfer
  Future<Either<Failure, String>> getUniqueCode(int transferTicketId);

  /// Regenerate unique code for private transfer
  Future<Either<Failure, String>> regenerateUniqueCode(int transferTicketId);

  /// Lookup private transfer ticket by unique code
  Future<Either<Failure, int>> lookupPrivateTicket(String code);

  /// Toggle transfer type between public and private
  Future<Either<Failure, void>> toggleTransferType(int transferTicketId);

  /// Cancel a transfer
  Future<Either<Failure, void>> cancelTransfer(int transferTicketId);

  /// Get user's registered transfer tickets
  Future<Either<Failure, List<MyTransferTicket>>> getMyRegisteredTickets({
    required int userId,
    String? startDate,
    String? endDate,
  });

  /// Get user's transferable tickets
  Future<Either<Failure, List<TransferableTicket>>> getMyTransferableTickets({
    required int userId,
    String? startDate,
    String? endDate,
  });

  /// Register a ticket for transfer
  Future<Either<Failure, void>> registerTicketForTransfer({
    required String ticketId,
    required bool isPublicTransfer,
    int? transferTicketPrice,
  });

  /// Process a transfer (buy a transfer ticket)
  Future<Either<Failure, void>> processTransfer({
    required int userId,
    required int transferTicketId,
  });

  /// Filter transfer tickets by performance
  Future<Either<Failure, List<TransferTicket>>> getTransferTicketsByPerformance(int performanceId);

  /// Filter transfer tickets by date range
  Future<Either<Failure, List<TransferTicket>>> getTransferTicketsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Search transfer tickets by query
  Future<Either<Failure, List<TransferTicket>>> searchTransferTickets(String query);
}