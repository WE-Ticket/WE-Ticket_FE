import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ticket_repository.dart';

/// Parameters for booking tickets
class BookTicketsParams {
  final int performanceId;
  final int sessionId;
  final List<int> seatIds;
  final int userId;

  const BookTicketsParams({
    required this.performanceId,
    required this.sessionId,
    required this.seatIds,
    required this.userId,
  });
}

/// Use case for booking tickets
class BookTicketsUseCase {
  final TicketRepository repository;

  const BookTicketsUseCase(this.repository);

  /// Execute the use case to book tickets
  Future<Either<Failure, BookingResult>> call(BookTicketsParams params) async {
    // Validate parameters
    final validationFailure = _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    return await repository.bookTickets(
      performanceId: params.performanceId,
      sessionId: params.sessionId,
      seatIds: params.seatIds,
      userId: params.userId,
    );
  }

  /// Validate booking parameters
  ValidationFailure? _validateParams(BookTicketsParams params) {
    if (params.performanceId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 공연 ID입니다');
    }

    if (params.sessionId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 세션 ID입니다');
    }

    if (params.userId <= 0) {
      return const ValidationFailure(message: '유효하지 않은 사용자 ID입니다');
    }

    if (params.seatIds.isEmpty) {
      return const ValidationFailure(message: '좌석을 선택해주세요');
    }

    if (params.seatIds.length > 4) {
      return const ValidationFailure(message: '최대 4좌석까지 예매 가능합니다');
    }

    // Check for duplicate seat IDs
    if (params.seatIds.toSet().length != params.seatIds.length) {
      return const ValidationFailure(message: '중복된 좌석이 있습니다');
    }

    // Check for invalid seat IDs
    if (params.seatIds.any((id) => id <= 0)) {
      return const ValidationFailure(message: '유효하지 않은 좌석 ID가 있습니다');
    }

    return null;
  }
}