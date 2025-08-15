import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_history.dart';
import '../repositories/mypage_repository.dart';

/// 결제 내역 조회 Use Case
class GetPaymentHistoryUseCase {
  final MyPageRepository repository;

  const GetPaymentHistoryUseCase(this.repository);

  Future<Either<Failure, List<PaymentHistory>>> call(GetPaymentHistoryParams params) async {
    return await repository.getPaymentHistory(
      params.userId,
      filter: params.filter,
    );
  }
}

class GetPaymentHistoryParams {
  final int userId;
  final String? filter;

  const GetPaymentHistoryParams({
    required this.userId,
    this.filter,
  });
}