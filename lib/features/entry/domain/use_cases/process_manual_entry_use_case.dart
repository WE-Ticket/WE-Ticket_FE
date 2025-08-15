import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/entry_result.dart';
import '../entities/ticket_entry_request.dart';
import '../repositories/entry_repository.dart';

/// 수동 티켓 입장 처리 Use Case
class ProcessManualEntryUseCase {
  final EntryRepository repository;

  const ProcessManualEntryUseCase(this.repository);

  Future<Either<Failure, EntryResult>> call(ProcessManualEntryParams params) async {
    final request = TicketEntryRequest(
      ticketId: params.ticketId,
      userId: params.userId,
      entryMethod: 'manual',
      manualCode: params.manualCode,
      requestTime: DateTime.now(),
    );
    
    return await repository.processManualEntry(request);
  }
}

class ProcessManualEntryParams {
  final String ticketId;
  final String userId;
  final String manualCode;

  const ProcessManualEntryParams({
    required this.ticketId,
    required this.userId,
    required this.manualCode,
  });
}