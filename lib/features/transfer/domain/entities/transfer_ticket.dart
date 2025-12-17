import 'package:equatable/equatable.dart';

/// Domain entity representing a transfer ticket in the marketplace
class TransferTicket extends Equatable {
  final int id;
  final int ticketId;
  final String performanceTitle;
  final String performerName;
  final String venueName;
  final DateTime sessionDateTime;
  final String seatZone;
  final String seatRow;
  final int seatColumn;
  final int originalPrice;
  final int transferPrice;
  final bool isPublicTransfer;
  final TransferStatus status;
  final DateTime createdAt;
  final String? tempUniqueCode;
  final String? imageUrl;

  const TransferTicket({
    required this.id,
    required this.ticketId,
    required this.performanceTitle,
    required this.performerName,
    required this.venueName,
    required this.sessionDateTime,
    required this.seatZone,
    required this.seatRow,
    required this.seatColumn,
    required this.originalPrice,
    required this.transferPrice,
    required this.isPublicTransfer,
    required this.status,
    required this.createdAt,
    this.tempUniqueCode,
    this.imageUrl,
  });

  /// Get full seat identifier (e.g., "A구역 A1")
  String get fullSeatIdentifier => '$seatZone $seatRow$seatColumn';

  /// Get seat number only (e.g., "A1")
  String get seatNumber => '$seatRow$seatColumn';

  /// Get formatted transfer price
  String get formattedTransferPrice {
    return '${transferPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]!},',
    )}원';
  }

  /// Get formatted session date and time
  String get sessionDateTimeFormatted {
    return '${sessionDateTime.year}.${sessionDateTime.month.toString().padLeft(2, '0')}.${sessionDateTime.day.toString().padLeft(2, '0')} ${sessionDateTime.hour.toString().padLeft(2, '0')}:${sessionDateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Check if ticket is available for transfer
  bool get isAvailableForTransfer => status == TransferStatus.available;

  /// Check if ticket is in progress
  bool get isInProgress => status == TransferStatus.inProgress;

  /// Check if ticket has been transferred
  bool get isCompleted => status == TransferStatus.completed;

  /// Check if ticket transfer has been cancelled
  bool get isCancelled => status == TransferStatus.cancelled;

  @override
  List<Object?> get props => [
        id,
        ticketId,
        performanceTitle,
        performerName,
        venueName,
        sessionDateTime,
        seatZone,
        seatRow,
        seatColumn,
        originalPrice,
        transferPrice,
        isPublicTransfer,
        status,
        createdAt,
        tempUniqueCode,
        imageUrl,
      ];

  @override
  String toString() => 'TransferTicket(id: $id, performance: $performanceTitle, seat: $fullSeatIdentifier)';
}

/// Domain entity for transfer ticket details
class TransferTicketDetail extends Equatable {
  final int id;
  final TransferTicket ticket;
  final String? description;
  final List<String> images;
  final DateTime? expiresAt;
  final TransferHistory? lastTransfer;

  const TransferTicketDetail({
    required this.id,
    required this.ticket,
    this.description,
    this.images = const [],
    this.expiresAt,
    this.lastTransfer,
  });

  /// Check if transfer is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [id, ticket, description, images, expiresAt, lastTransfer];
}

/// Domain entity for transfer history
class TransferHistory extends Equatable {
  final int id;
  final int fromUserId;
  final int toUserId;
  final DateTime transferredAt;
  final int finalPrice;
  final TransferType transferType;

  const TransferHistory({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.transferredAt,
    required this.finalPrice,
    required this.transferType,
  });

  @override
  List<Object?> get props => [id, fromUserId, toUserId, transferredAt, finalPrice, transferType];
}

/// Domain entity for transferable tickets (user's own tickets available for transfer)
class TransferableTicket extends Equatable {
  final String ticketId;
  final String performanceTitle;
  final String performerName;
  final DateTime sessionDateTime;
  final String seatZone;
  final String seatRow;
  final int seatColumn;
  final int originalPrice;
  final bool canTransfer;
  final String? imageUrl;

  const TransferableTicket({
    required this.ticketId,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDateTime,
    required this.seatZone,
    required this.seatRow,
    required this.seatColumn,
    required this.originalPrice,
    required this.canTransfer,
    this.imageUrl,
  });

  /// Get full seat identifier
  String get fullSeatIdentifier => '$seatZone $seatRow$seatColumn';

  /// Get formatted original price
  String get formattedOriginalPrice {
    return '${originalPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]!},',
    )}원';
  }

  @override
  List<Object?> get props => [
        ticketId,
        performanceTitle,
        performerName,
        sessionDateTime,
        seatZone,
        seatRow,
        seatColumn,
        originalPrice,
        canTransfer,
        imageUrl,
      ];
}

/// Domain entity for user's registered transfer tickets
class MyTransferTicket extends Equatable {
  final int transferTicketId;
  final String performanceTitle;
  final String performerName;
  final DateTime sessionDateTime;
  final String seatZone;
  final String seatRow;
  final int seatColumn;
  final int transferPrice;
  final bool isPublicTransfer;
  final TransferStatus status;
  final DateTime createdAt;
  final String? tempUniqueCode;

  const MyTransferTicket({
    required this.transferTicketId,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDateTime,
    required this.seatZone,
    required this.seatRow,
    required this.seatColumn,
    required this.transferPrice,
    required this.isPublicTransfer,
    required this.status,
    required this.createdAt,
    this.tempUniqueCode,
  });

  /// Get full seat identifier
  String get fullSeatIdentifier => '$seatZone $seatRow$seatColumn';

  @override
  List<Object?> get props => [
        transferTicketId,
        performanceTitle,
        performerName,
        sessionDateTime,
        seatZone,
        seatRow,
        seatColumn,
        transferPrice,
        isPublicTransfer,
        status,
        createdAt,
        tempUniqueCode,
      ];
}

/// Domain entity for transfer list with pagination
class TransferList extends Equatable {
  final List<TransferTicket> tickets;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const TransferList({
    required this.tickets,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Check if list is empty
  bool get isEmpty => tickets.isEmpty;

  /// Check if list is not empty
  bool get isNotEmpty => tickets.isNotEmpty;

  @override
  List<Object?> get props => [
        tickets,
        totalCount,
        currentPage,
        totalPages,
        hasNext,
        hasPrevious,
      ];
}

/// Enum representing transfer status
enum TransferStatus {
  available('available', '양도 대기'),
  inProgress('in_progress', '양도 진행 중'),
  completed('completed', '양도 완료'),
  cancelled('cancelled', '양도 취소'),
  expired('expired', '기간 만료');

  const TransferStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static TransferStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return TransferStatus.available;
      case 'in_progress':
        return TransferStatus.inProgress;
      case 'completed':
        return TransferStatus.completed;
      case 'cancelled':
        return TransferStatus.cancelled;
      case 'expired':
        return TransferStatus.expired;
      default:
        return TransferStatus.available;
    }
  }
}

/// Enum representing transfer type
enum TransferType {
  public('public', '공개 양도'),
  private('private', '비공개 양도');

  const TransferType(this.value, this.displayName);

  final String value;
  final String displayName;

  static TransferType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'public':
        return TransferType.public;
      case 'private':
        return TransferType.private;
      default:
        return TransferType.public;
    }
  }
}