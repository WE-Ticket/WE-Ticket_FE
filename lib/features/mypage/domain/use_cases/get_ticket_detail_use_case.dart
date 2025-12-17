import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/my_ticket.dart';
import '../repositories/mypage_repository.dart';

/// 티켓 상세 정보 조회 Use Case
class GetTicketDetailUseCase {
  final MyPageRepository repository;

  const GetTicketDetailUseCase(this.repository);

  Future<Either<Failure, MyTicket>> call(GetTicketDetailParams params) async {
    return await repository.getTicketDetail(params.nftTicketId);
  }
}

class GetTicketDetailParams {
  final String nftTicketId;

  const GetTicketDetailParams({
    required this.nftTicketId,
  });
}