import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../entities/seat.dart';

/// Repository interface for ticketing operations
/// This defines the contract for ticket data operations
abstract class TicketRepository {
  /// Get performance schedule for booking
  Future<Either<Failure, PerformanceSchedule>> getPerformanceSchedule(int performanceId);

  /// Get seat information for a specific session
  Future<Either<Failure, SeatLayout>> getSessionSeatInfo(
    int performanceId,
    int sessionId,
  );

  /// Book tickets for selected seats
  Future<Either<Failure, BookingResult>> bookTickets({
    required int performanceId,
    required int sessionId,
    required List<int> seatIds,
    required int userId,
  });

  /// Issue NFT ticket after successful payment
  Future<Either<Failure, Ticket>> issueNFTTicket({
    required int ticketId,
    required String transactionHash,
  });

  /// Get ticket by ID
  Future<Either<Failure, Ticket>> getTicketById(int ticketId);

  /// Get user's tickets
  Future<Either<Failure, List<Ticket>>> getUserTickets(int userId);

  /// Validate ticket for entry
  Future<Either<Failure, TicketValidationResult>> validateTicket({
    required String ticketCode,
    required int gateId,
  });
}

/// Domain entity for performance schedule
class PerformanceSchedule {
  final int performanceId;
  final String performanceTitle;
  final List<SessionInfo> availableSessions;
  final bool isBookable;

  const PerformanceSchedule({
    required this.performanceId,
    required this.performanceTitle,
    required this.availableSessions,
    required this.isBookable,
  });
}

/// Domain entity for session information
class SessionInfo {
  final int performanceSessionId;
  final DateTime sessionDateTime;
  final int availableSeats;
  final int totalSeats;
  final bool isBookable;

  const SessionInfo({
    required this.performanceSessionId,
    required this.sessionDateTime,
    required this.availableSeats,
    required this.totalSeats,
    required this.isBookable,
  });

  /// Get formatted session date and time
  String get sessionDateTimeFormatted {
    return '${sessionDateTime.year}.${sessionDateTime.month.toString().padLeft(2, '0')}.${sessionDateTime.day.toString().padLeft(2, '0')} ${sessionDateTime.hour.toString().padLeft(2, '0')}:${sessionDateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Check if session has available seats
  bool get hasAvailableSeats => availableSeats > 0;
}

/// Domain entity for seat layout
class SeatLayout {
  final int performanceId;
  final int sessionId;
  final List<SeatZone> zones;
  final Map<String, int> priceByGrade;

  const SeatLayout({
    required this.performanceId,
    required this.sessionId,
    required this.zones,
    required this.priceByGrade,
  });

  /// Get all available seats
  List<Seat> get availableSeats {
    return zones
        .expand((zone) => zone.seats)
        .where((seat) => seat.status == SeatReservationStatus.available)
        .toList();
  }

  /// Get total seat count
  int get totalSeats => zones.fold(0, (sum, zone) => sum + zone.seats.length);

  /// Get available seat count
  int get availableSeatCount => availableSeats.length;
}

/// Domain entity for seat zone
class SeatZone {
  final String zoneId;
  final String zoneName;
  final List<Seat> seats;
  final int minPrice;
  final int maxPrice;

  const SeatZone({
    required this.zoneId,
    required this.zoneName,
    required this.seats,
    required this.minPrice,
    required this.maxPrice,
  });
}

/// Domain entity for booking result
class BookingResult {
  final int bookingId;
  final List<int> ticketIds;
  final int totalAmount;
  final BookingStatus status;
  final DateTime expiresAt;
  final String paymentUrl;

  const BookingResult({
    required this.bookingId,
    required this.ticketIds,
    required this.totalAmount,
    required this.status,
    required this.expiresAt,
    required this.paymentUrl,
  });
}

/// Domain entity for ticket validation result
class TicketValidationResult {
  final bool isValid;
  final String message;
  final Ticket? ticket;
  final DateTime? entryTime;

  const TicketValidationResult({
    required this.isValid,
    required this.message,
    this.ticket,
    this.entryTime,
  });
}

/// Enum representing booking status
enum BookingStatus {
  pending('pending', '예약 대기'),
  confirmed('confirmed', '예약 확정'),
  paid('paid', '결제 완료'),
  cancelled('cancelled', '예약 취소'),
  expired('expired', '예약 만료');

  const BookingStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static BookingStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'paid':
        return BookingStatus.paid;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'expired':
        return BookingStatus.expired;
      default:
        return BookingStatus.pending;
    }
  }
}