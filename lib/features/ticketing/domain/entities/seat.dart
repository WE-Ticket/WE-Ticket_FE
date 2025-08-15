import 'package:equatable/equatable.dart';

/// Domain entity representing a seat
class Seat extends Equatable {
  final int id;
  final String zone;
  final String row;
  final int column;
  final String grade;
  final int price;
  final SeatReservationStatus status;

  const Seat({
    required this.id,
    required this.zone,
    required this.row,
    required this.column,
    required this.grade,
    required this.price,
    required this.status,
  });

  /// Create a copy of this seat with updated fields
  Seat copyWith({
    int? id,
    String? zone,
    String? row,
    int? column,
    String? grade,
    int? price,
    SeatReservationStatus? status,
  }) {
    return Seat(
      id: id ?? this.id,
      zone: zone ?? this.zone,
      row: row ?? this.row,
      column: column ?? this.column,
      grade: grade ?? this.grade,
      price: price ?? this.price,
      status: status ?? this.status,
    );
  }

  /// Get seat number (e.g., "A1")
  String get seatNumber => '$row$column';

  /// Get full seat identifier (e.g., "A구역 A1")
  String get fullIdentifier => '$zone $seatNumber';

  /// Get zone display name (e.g., "VIP (A구역)")
  String get zoneDisplayName => '$grade ($zone구역)';

  /// Get formatted price display
  String get priceDisplay {
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  /// Check if seat is available for booking
  bool get isAvailable => status == SeatReservationStatus.available;

  /// Check if seat is reserved
  bool get isReserved => status == SeatReservationStatus.reserved;

  /// Check if seat is sold
  bool get isSold => status == SeatReservationStatus.sold;

  /// Check if seat can be selected
  bool get canSelect => isAvailable;

  @override
  List<Object?> get props => [id, zone, row, column, grade, price, status];

  @override
  String toString() => 'Seat(id: $id, seat: $fullIdentifier, status: ${status.displayName})';
}

/// Enum representing seat reservation status
enum SeatReservationStatus {
  available('available', '선택 가능'),
  reserved('reserved', '예약됨'),
  sold('sold', '판매완료');

  const SeatReservationStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static SeatReservationStatus fromString(String value) {
    switch (value) {
      case 'available':
        return SeatReservationStatus.available;
      case 'reserved':
        return SeatReservationStatus.reserved;
      case 'sold':
        return SeatReservationStatus.sold;
      default:
        return SeatReservationStatus.available;
    }
  }
}

/// Domain entity representing seat layout for a performance session
class SeatLayout extends Equatable {
  final int performanceId;
  final int performanceSessionId;
  final String zone;
  final int price;
  final String maxRow;
  final int maxColumn;
  final List<List<Seat?>> layout; // 2D array representing seat arrangement

  const SeatLayout({
    required this.performanceId,
    required this.performanceSessionId,
    required this.zone,
    required this.price,
    required this.maxRow,
    required this.maxColumn,
    required this.layout,
  });

  /// Get all seats in the layout (flattened)
  List<Seat> get allSeats {
    return layout.expand((row) => row.where((seat) => seat != null).cast<Seat>()).toList();
  }

  /// Get all available seats
  List<Seat> get availableSeats {
    return allSeats.where((seat) => seat.isAvailable).toList();
  }

  /// Get all reserved seats
  List<Seat> get reservedSeats {
    return allSeats.where((seat) => seat.isReserved).toList();
  }

  /// Get all sold seats
  List<Seat> get soldSeats {
    return allSeats.where((seat) => seat.isSold).toList();
  }

  /// Get total number of seats
  int get totalSeats => allSeats.length;

  /// Get available seats count
  int get availableSeatsCount => availableSeats.length;

  /// Get formatted price display
  String get priceDisplay {
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  @override
  List<Object?> get props => [
        performanceId,
        performanceSessionId,
        zone,
        price,
        maxRow,
        maxColumn,
        layout,
      ];

  @override
  String toString() => 'SeatLayout(zone: $zone, totalSeats: $totalSeats, available: $availableSeatsCount)';
}

/// Domain entity representing seat pricing information by zone
class SeatPricingInfo extends Equatable {
  final String zone;
  final String grade;
  final int price;
  final int remainingSeats;

  const SeatPricingInfo({
    required this.zone,
    required this.grade,
    required this.price,
    required this.remainingSeats,
  });

  /// Get formatted price display
  String get priceDisplay {
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  /// Check if zone is sold out
  bool get isSoldOut => remainingSeats == 0;

  /// Check if zone is available
  bool get isAvailable => remainingSeats > 0;

  /// Get availability text
  String get availabilityText {
    if (isSoldOut) return '매진';
    if (remainingSeats < 10) return '잔여 ${remainingSeats}석';
    return '선택 가능';
  }

  /// Get zone display name
  String get zoneDisplayName => '$grade ($zone구역)';

  @override
  List<Object?> get props => [zone, grade, price, remainingSeats];

  @override
  String toString() => 'SeatPricingInfo(zone: $zoneDisplayName, remaining: $remainingSeats)';
}