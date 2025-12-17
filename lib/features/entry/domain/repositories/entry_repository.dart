import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/entry_result.dart';
import '../entities/ticket_entry_request.dart';

/// Entry 기능의 Repository 인터페이스
abstract class EntryRepository {
  /// NFC를 통한 티켓 입장
  Future<Either<Failure, EntryResult>> processNfcEntry(
    TicketEntryRequest request,
  );

  /// 수동 코드를 통한 티켓 입장
  Future<Either<Failure, EntryResult>> processManualEntry(
    TicketEntryRequest request,
  );

  /// 입장 내역 조회
  Future<Either<Failure, List<EntryResult>>> getEntryHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });
}