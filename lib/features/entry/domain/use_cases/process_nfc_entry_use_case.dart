import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/entry_result.dart';
import '../entities/ticket_entry_request.dart';
import '../repositories/entry_repository.dart';

/// NFC 티켓 입장 처리 Use Case
class ProcessNfcEntryUseCase {
  final EntryRepository repository;

  const ProcessNfcEntryUseCase(this.repository);

  Future<Either<Failure, EntryResult>> call(ProcessNfcEntryParams params) async {
    final request = TicketEntryRequest(
      ticketId: params.ticketId,
      userId: params.userId,
      entryMethod: 'nfc',
      nfcData: params.nfcData,
      requestTime: DateTime.now(),
    );
    
    return await repository.processNfcEntry(request);
  }
}

class ProcessNfcEntryParams {
  final String ticketId;
  final String userId;
  final String nfcData;

  const ProcessNfcEntryParams({
    required this.ticketId,
    required this.userId,
    required this.nfcData,
  });
}