import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/payment_history.dart';
import '../../domain/repositories/mypage_repository.dart';
import '../mappers/mypage_mapper.dart';
import '../services/mypage_service.dart';

/// MyPage Repository 구현체
class MyPageRepositoryImpl implements MyPageRepository {
  final MyPageService _service;
  final MyPageMapper _mapper;

  const MyPageRepositoryImpl({
    required MyPageService service,
    required MyPageMapper mapper,
  }) : _service = service,
       _mapper = mapper;

  @override
  Future<Either<Failure, List<MyTicket>>> getOwnedTickets(
    int userId, {
    String? state,
  }) async {
    try {
      debugPrint('내 티켓 목록 조회 시작 (userId: $userId, state: $state)');

      final result = await _service.getOwnedTickets(userId, state: state);

      if (result.isSuccess) {
        final tickets = result.data!.map(_mapper.mapToMyTicket).toList();
        debugPrint('내 티켓 목록 조회 성공: ${tickets.length}개');
        return Right(tickets);
      } else {
        debugPrint('내 티켓 목록 조회 실패: ${result.errorMessage}');
        return Left(
          ServerFailure(message: result.errorMessage ?? '내 티켓 목록 조회 실패'),
        );
      }
    } catch (e) {
      debugPrint('내 티켓 목록 조회 예외: $e');
      return Left(ServerFailure(message: '내 티켓 목록 조회 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, MyTicket>> getTicketDetail(String nftTicketId) async {
    try {
      debugPrint('티켓 상세 정보 조회 시작 (nftTicketId: $nftTicketId)');

      final result = await _service.getTicketDetail(nftTicketId);

      if (result.isSuccess) {
        final ticket = _mapper.mapToMyTicket(result.data!);
        debugPrint('티켓 상세 정보 조회 성공: ${ticket.title}');
        return Right(ticket);
      } else {
        debugPrint('티켓 상세 정보 조회 실패: ${result.errorMessage}');
        return Left(
          ServerFailure(message: result.errorMessage ?? '티켓 상세 정보 조회 실패'),
        );
      }
    } catch (e) {
      debugPrint('티켓 상세 정보 조회 예외: $e');
      return Left(ServerFailure(message: '티켓 상세 정보 조회 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, List<PaymentHistory>>> getPaymentHistory(
    int userId, {
    String? filter,
  }) async {
    try {
      debugPrint('결제 내역 조회 시작 (userId: $userId, filter: $filter)');

      final result = await _service.getPaymentHistory(userId, filter: filter);

      if (result.isSuccess) {
        final histories = result.data!
            .map(_mapper.mapToPaymentHistory)
            .toList();
        debugPrint('결제 내역 조회 성공: ${histories.length}개');
        return Right(histories);
      } else {
        debugPrint('결제 내역 조회 실패: ${result.errorMessage}');
        return Left(
          ServerFailure(message: result.errorMessage ?? '결제 내역 조회 실패'),
        );
      }
    } catch (e) {
      debugPrint('결제 내역 조회 예외: $e');
      return Left(ServerFailure(message: '결제 내역 조회 중 오류가 발생했습니다'));
    }
  }

  @override
  Future<Either<Failure, List<MyTicket>>> getTouchedTickets(int userId) async {
    try {
      debugPrint('구매한 티켓 목록 조회 시작 (userId: $userId)');

      final result = await _service.getTouchedTickets(userId);

      if (result.isSuccess) {
        final tickets = result.data!.map(_mapper.mapToMyTicket).toList();
        debugPrint('구매한 티켓 목록 조회 성공: ${tickets.length}개');
        return Right(tickets);
      } else {
        debugPrint('구매한 티켓 목록 조회 실패: ${result.errorMessage}');
        return Left(
          ServerFailure(message: result.errorMessage ?? '구매한 티켓 목록 조회 실패'),
        );
      }
    } catch (e) {
      debugPrint('구매한 티켓 목록 조회 예외: $e');
      return Left(ServerFailure(message: '구매한 티켓 목록 조회 중 오류가 발생했습니다'));
    }
  }
}
