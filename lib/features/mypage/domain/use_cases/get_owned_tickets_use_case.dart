import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/my_ticket.dart';
import '../repositories/mypage_repository.dart';

/// 내 티켓 목록 조회 Use Case
class GetOwnedTicketsUseCase {
  final MyPageRepository repository;

  const GetOwnedTicketsUseCase(this.repository);

  Future<Either<Failure, List<MyTicket>>> call(GetOwnedTicketsParams params) async {
    return await repository.getOwnedTickets(
      params.userId,
      state: params.state,
    );
  }
}

class GetOwnedTicketsParams {
  final int userId;
  final String? state;

  const GetOwnedTicketsParams({
    required this.userId,
    this.state,
  });
}