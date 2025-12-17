import 'package:equatable/equatable.dart';

/// Domain entity representing a ticket
class Ticket extends Equatable {
  final int id;
  final int performanceSessionId;
  final int seatId;
  final int userId;
  final NftStatus nftStatus;
  final String? transactionHash;
  final int nftTokenId;
  final String contractAddress;
  final String blockchainNetwork;
  final DateTime issuedAt;
  final VerificationLevel verificationLevel;

  // Performance information
  final String performanceTitle;
  final String performerName;
  final DateTime sessionDateTime;
  final String venueName;

  // Seat information
  final String seatZone;
  final String seatRow;
  final int seatColumn;
  final String seatGrade;

  const Ticket({
    required this.id,
    required this.performanceSessionId,
    required this.seatId,
    required this.userId,
    required this.nftStatus,
    this.transactionHash,
    required this.nftTokenId,
    required this.contractAddress,
    required this.blockchainNetwork,
    required this.issuedAt,
    required this.verificationLevel,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDateTime,
    required this.venueName,
    required this.seatZone,
    required this.seatRow,
    required this.seatColumn,
    required this.seatGrade,
  });

  /// Create a copy of this ticket with updated fields
  Ticket copyWith({
    int? id,
    int? performanceSessionId,
    int? seatId,
    int? userId,
    NftStatus? nftStatus,
    String? transactionHash,
    int? nftTokenId,
    String? contractAddress,
    String? blockchainNetwork,
    DateTime? issuedAt,
    VerificationLevel? verificationLevel,
    String? performanceTitle,
    String? performerName,
    DateTime? sessionDateTime,
    String? venueName,
    String? seatZone,
    String? seatRow,
    int? seatColumn,
    String? seatGrade,
  }) {
    return Ticket(
      id: id ?? this.id,
      performanceSessionId: performanceSessionId ?? this.performanceSessionId,
      seatId: seatId ?? this.seatId,
      userId: userId ?? this.userId,
      nftStatus: nftStatus ?? this.nftStatus,
      transactionHash: transactionHash ?? this.transactionHash,
      nftTokenId: nftTokenId ?? this.nftTokenId,
      contractAddress: contractAddress ?? this.contractAddress,
      blockchainNetwork: blockchainNetwork ?? this.blockchainNetwork,
      issuedAt: issuedAt ?? this.issuedAt,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      performanceTitle: performanceTitle ?? this.performanceTitle,
      performerName: performerName ?? this.performerName,
      sessionDateTime: sessionDateTime ?? this.sessionDateTime,
      venueName: venueName ?? this.venueName,
      seatZone: seatZone ?? this.seatZone,
      seatRow: seatRow ?? this.seatRow,
      seatColumn: seatColumn ?? this.seatColumn,
      seatGrade: seatGrade ?? this.seatGrade,
    );
  }

  /// Get full seat identifier (e.g., "A구역 A1")
  String get fullSeatIdentifier => '$seatZone $seatRow$seatColumn';

  /// Get seat number only (e.g., "A1")
  String get seatNumber => '$seatRow$seatColumn';

  /// Get formatted session date
  String get sessionDateFormatted {
    return '${sessionDateTime.year}.${sessionDateTime.month.toString().padLeft(2, '0')}.${sessionDateTime.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted session time
  String get sessionTimeFormatted {
    return '${sessionDateTime.hour.toString().padLeft(2, '0')}:${sessionDateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get full session datetime formatted
  String get sessionDateTimeFormatted => '$sessionDateFormatted $sessionTimeFormatted';

  /// Check if ticket is ready for use
  bool get isReady => nftStatus == NftStatus.issued;

  /// Check if ticket is pending issuance
  bool get isPending => nftStatus == NftStatus.pending;

  /// Check if ticket issuance failed
  bool get hasFailed => nftStatus == NftStatus.failed;

  @override
  List<Object?> get props => [
        id,
        performanceSessionId,
        seatId,
        userId,
        nftStatus,
        transactionHash,
        nftTokenId,
        contractAddress,
        blockchainNetwork,
        issuedAt,
        verificationLevel,
        performanceTitle,
        performerName,
        sessionDateTime,
        venueName,
        seatZone,
        seatRow,
        seatColumn,
        seatGrade,
      ];

  @override
  String toString() => 'Ticket(id: $id, performance: $performanceTitle, seat: $fullSeatIdentifier)';
}

/// Enum representing NFT status
enum NftStatus {
  pending('pending', '발행 중'),
  issued('issued', '발행 완료'),
  failed('failed', '발행 실패');

  const NftStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static NftStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return NftStatus.pending;
      case 'issued':
        return NftStatus.issued;
      case 'failed':
        return NftStatus.failed;
      default:
        return NftStatus.pending;
    }
  }
}

/// Enum representing verification levels
enum VerificationLevel {
  basic('basic', '기본 인증'),
  enhanced('enhanced', '강화 인증'),
  premium('premium', '프리미엄 인증');

  const VerificationLevel(this.value, this.displayName);

  final String value;
  final String displayName;

  static VerificationLevel fromString(String value) {
    switch (value) {
      case 'basic':
        return VerificationLevel.basic;
      case 'enhanced':
        return VerificationLevel.enhanced;
      case 'premium':
        return VerificationLevel.premium;
      default:
        return VerificationLevel.basic;
    }
  }
}