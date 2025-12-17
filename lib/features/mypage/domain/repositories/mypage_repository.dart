import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/my_ticket.dart';
import '../entities/payment_history.dart';

/// MyPage 기능의 Repository 인터페이스
abstract class MyPageRepository {
  /// 내 티켓 목록 조회
  Future<Either<Failure, List<MyTicket>>> getOwnedTickets(
    int userId, {
    String? state,
  });

  /// 티켓 상세 정보 조회
  Future<Either<Failure, MyTicket>> getTicketDetail(String nftTicketId);

  /// 결제 내역 조회
  Future<Either<Failure, List<PaymentHistory>>> getPaymentHistory(
    int userId, {
    String? filter,
  });

  /// 구매한 티켓 목록 조회 (터치한 티켓)
  Future<Either<Failure, List<MyTicket>>> getTouchedTickets(int userId);
}