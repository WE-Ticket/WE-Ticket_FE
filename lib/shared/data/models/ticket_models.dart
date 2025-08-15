import '../../../../core/utils/json_parser.dart';

/// 공연 스케줄 응답 모델
class PerformanceSchedule {
  final int performanceId;
  final String title;
  final String performerName;
  final String venueName;
  final List<SeatPricing> seatPricings;
  final List<PerformanceSession> sessions;

  PerformanceSchedule({
    required this.performanceId,
    required this.title,
    required this.performerName,
    required this.venueName,
    required this.seatPricings,
    required this.sessions,
  });

  factory PerformanceSchedule.fromJson(Map<String, dynamic> json) {
    return PerformanceSchedule(
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      title: JsonParserUtils.parseString(json['title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      seatPricings:
          (json['seat_pricings'] as List<dynamic>?)
              ?.map((item) => SeatPricing.fromJson(item))
              .toList() ??
          [],
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((item) => PerformanceSession.fromJson(item))
              .toList() ??
          [],
    );
  }

  List<PerformanceSession> get availableSessions =>
      sessions.where((session) => session.remainingSeats > 0).toList();

  List<PerformanceSession> get soldOutSessions =>
      sessions.where((session) => session.remainingSeats == 0).toList();

  int get minPrice => seatPricings.isNotEmpty
      ? seatPricings.map((p) => p.price).reduce((a, b) => a < b ? a : b)
      : 0;

  int get maxPrice => seatPricings.isNotEmpty
      ? seatPricings.map((p) => p.price).reduce((a, b) => a > b ? a : b)
      : 0;
}

/// 좌석 등급 및 가격 정보 모델
class SeatPricing {
  final String seatGrade;
  final int price;

  SeatPricing({required this.seatGrade, required this.price});

  factory SeatPricing.fromJson(Map<String, dynamic> json) {
    return SeatPricing(
      seatGrade: JsonParserUtils.parseString(json['seat_grade']),
      price: JsonParserUtils.parseInt(json['price']),
    );
  }

  String get priceDisplay =>
      '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
}

/// 공연 세션 정보 모델
class PerformanceSession {
  final int performanceSessionId;
  final String sessionDatetime;
  final int remainingSeats;
  final bool isAvailable;

  PerformanceSession({
    required this.performanceSessionId,
    required this.sessionDatetime,
    required this.remainingSeats,
    required this.isAvailable,
  });

  factory PerformanceSession.fromJson(Map<String, dynamic> json) {
    return PerformanceSession(
      performanceSessionId: JsonParserUtils.parseInt(
        json['performance_session_id'],
      ),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      remainingSeats: JsonParserUtils.parseInt(json['remaining_seats']),
      isAvailable: JsonParserUtils.parseBool(json['is_available']),
    );
  }

  DateTime get sessionDateTime =>
      JsonParserUtils.parseDateTime(sessionDatetime);

  String get dateDisplay {
    final dateTime = sessionDateTime;
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  String get timeDisplay {
    final dateTime = sessionDateTime;
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get dateTimeDisplay => '$dateDisplay $timeDisplay';

  bool get isSoldOut => remainingSeats == 0;

  String get availabilityText {
    if (isSoldOut) return '매진';
    if (remainingSeats < 10) return '잔여 ${remainingSeats}석';
    return '예매 가능';
  }
}

/// 세션별 좌석 상세 정보 응답 모델
class SessionSeatInfo {
  final int performanceId;
  final String title;
  final String performerName;
  final String venueName;
  final String sessionDatetime;
  final List<SeatPricingInfo> seatPricingInfo;

  SessionSeatInfo({
    required this.performanceId,
    required this.title,
    required this.performerName,
    required this.venueName,
    required this.sessionDatetime,
    required this.seatPricingInfo,
  });

  factory SessionSeatInfo.fromJson(Map<String, dynamic> json) {
    return SessionSeatInfo(
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      title: JsonParserUtils.parseString(json['title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      seatPricingInfo:
          (json['seat_pricing_info'] as List<dynamic>?)
              ?.map((item) => SeatPricingInfo.fromJson(item))
              .toList() ??
          [],
    );
  }

  DateTime get sessionDateTime =>
      JsonParserUtils.parseDateTime(sessionDatetime);

  List<SeatPricingInfo> get availableZones =>
      seatPricingInfo.where((zone) => zone.remainingSeats > 0).toList();

  List<SeatPricingInfo> get soldOutZones =>
      seatPricingInfo.where((zone) => zone.remainingSeats == 0).toList();

  int get totalRemainingSeats =>
      seatPricingInfo.fold(0, (sum, zone) => sum + zone.remainingSeats);
}

class SeatPricingInfo {
  final String seatZone;
  final String seatGrade;
  final int price;
  final int remainingSeats;

  SeatPricingInfo({
    required this.seatZone,
    required this.seatGrade,
    required this.price,
    required this.remainingSeats,
  });

  factory SeatPricingInfo.fromJson(Map<String, dynamic> json) {
    return SeatPricingInfo(
      seatZone: JsonParserUtils.parseString(json['seat_zone']),
      seatGrade: JsonParserUtils.parseString(json['seat_grade']),
      price: JsonParserUtils.parseInt(json['price']),
      remainingSeats: JsonParserUtils.parseInt(json['remaining_seats']),
    );
  }

  String get priceDisplay =>
      '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

  bool get isSoldOut => remainingSeats == 0;
  bool get isAvailable => remainingSeats > 0;

  String get availabilityText {
    if (isSoldOut) return '매진';
    if (remainingSeats < 10) return '잔여 ${remainingSeats}석';
    return '선택 가능';
  }

  String get zoneDisplayName => '$seatGrade ($seatZone구역)';
}

/// 좌석 배치 정보 응답 모델
class SeatLayout {
  final int performanceId;
  final int performanceSessionId;
  final String seatZone;
  final int price;
  final String maxRow;
  final int maxCol;
  final List<SeatRow> seatLayout;

  SeatLayout({
    required this.performanceId,
    required this.performanceSessionId,
    required this.seatZone,
    required this.price,
    required this.maxRow,
    required this.maxCol,
    required this.seatLayout,
  });

  factory SeatLayout.fromJson(Map<String, dynamic> json) {
    return SeatLayout(
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      performanceSessionId: JsonParserUtils.parseInt(
        json['performance_session_id'],
      ),
      seatZone: JsonParserUtils.parseString(json['seat_zone']),
      price: JsonParserUtils.parseInt(json['price']),
      maxRow: JsonParserUtils.parseString(json['max_row']),
      maxCol: JsonParserUtils.parseInt(json['max_col']),
      seatLayout:
          (json['seat_layout'] as List<dynamic>?)
              ?.map((item) => SeatRow.fromJson(item))
              .toList() ??
          [],
    );
  }

  String get priceDisplay =>
      '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

  List<Seat> get allSeats => seatLayout.expand((row) => row.seats).toList();

  List<Seat> get availableSeats =>
      allSeats.where((seat) => seat.isAvailable).toList();

  List<Seat> get reservedSeats =>
      allSeats.where((seat) => seat.isReserved).toList();

  List<Seat> get soldSeats => allSeats.where((seat) => seat.isSold).toList();

  int get totalSeats => allSeats.length;
  int get availableSeatsCount => availableSeats.length;
}

/// 좌석 행 정보 모델
class SeatRow {
  final String row;
  final List<Seat> seats;

  SeatRow({required this.row, required this.seats});

  factory SeatRow.fromJson(Map<String, dynamic> json) {
    return SeatRow(
      row: JsonParserUtils.parseString(json['row']),
      seats:
          (json['seats'] as List<dynamic>?)
              ?.map((item) => Seat.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// 개별 좌석 정보 모델 (새 API 응답 형태에 맞게 수정)
class Seat {
  final int seatId;
  final String seatRow;
  final int seatCol;
  final String reservationStatus;

  Seat({
    required this.seatId,
    required this.seatRow,
    required this.seatCol,
    required this.reservationStatus,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      seatId: JsonParserUtils.parseInt(json['seat_id']),
      seatRow: JsonParserUtils.parseString(json['seat_row']),
      seatCol: JsonParserUtils.parseInt(json['seat_column']),
      reservationStatus: JsonParserUtils.parseString(
        json['reservation_status'],
      ),
    );
  }

  // 편의 메서드들
  bool get isAvailable => reservationStatus == 'available';
  bool get isReserved => reservationStatus == 'reserved';
  bool get isSold => reservationStatus == 'sold';

  String get statusDisplay {
    switch (reservationStatus) {
      case 'available':
        return '선택 가능';
      case 'reserved':
        return '예약됨';
      case 'sold':
        return '판매완료';
      default:
        return '알 수 없음';
    }
  }

  // 좌석 번호 (A1, B2 형태)
  String get seatNumber => '$seatRow$seatCol';

  // 기존 코드와의 호환성을 위한 getter들
  String get row => seatRow;
  int get column => seatCol;
}

// FIXME 모델 위치 고민
/// 티켓 생성 요청 모델
class CreateTicketRequest {
  final int performanceSessionId;
  final int seatId;
  final int userId;

  CreateTicketRequest({
    required this.performanceSessionId,
    required this.seatId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'performance_session_id': performanceSessionId,
      'seat_id': seatId,
      'user_id': userId,
    };
  }
}

/// 티켓 생성 응답 모델
/// 티켓 생성 응답 모델 (개선된 버전)
class CreateTicketResponse {
  // 기본 티켓 정보
  final int ticketId;
  final String nftStatus;
  final String? transactionHash;
  final int nftTokenId;

  // 공연 정보
  final String performanceTitle;
  final String performerName;
  final String sessionDatetime;
  final String venueName;

  // 좌석 정보
  final String seatZone;
  final String seatRow;
  final int seatColumn;
  final String seatGrade;

  // 블록체인 정보
  final String contractAddress;
  final String blockchainNetwork;
  final String issuedAt;
  final String verificationLevel;

  CreateTicketResponse({
    required this.ticketId,
    required this.nftStatus,
    this.transactionHash,
    required this.nftTokenId,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDatetime,
    required this.venueName,
    required this.seatZone,
    required this.seatRow,
    required this.seatColumn,
    required this.seatGrade,
    required this.contractAddress,
    required this.blockchainNetwork,
    required this.issuedAt,
    required this.verificationLevel,
  });

  factory CreateTicketResponse.fromJson(Map<String, dynamic> json) {
    return CreateTicketResponse(
      ticketId: JsonParserUtils.parseInt(json['ticket_id']),
      nftStatus: JsonParserUtils.parseString(json['nft_status']),
      transactionHash: json['transaction_hash'],
      nftTokenId: JsonParserUtils.parseInt(json['nft_token_id']),
      performanceTitle: JsonParserUtils.parseString(json['performance_title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      seatZone: JsonParserUtils.parseString(json['seat_zone']),
      seatRow: JsonParserUtils.parseString(json['seat_row']),
      seatColumn: JsonParserUtils.parseInt(json['seat_column']),
      seatGrade: JsonParserUtils.parseString(json['seat_grade']),
      contractAddress: JsonParserUtils.parseString(json['contract_address']),
      blockchainNetwork: JsonParserUtils.parseString(
        json['blockchain_network'],
      ),
      issuedAt: JsonParserUtils.parseString(json['issued_at']),
      verificationLevel: JsonParserUtils.parseString(
        json['verification_level'],
      ),
    );
  }

  // 편의 메서드들
  bool get isPending => nftStatus == 'pending';
  bool get isIssued => nftStatus == 'issued';
  bool get isFailed => nftStatus == 'failed';

  String get statusDisplay {
    switch (nftStatus) {
      case 'pending':
        return '발행 중';
      case 'issued':
        return '발행 완료';
      case 'failed':
        return '발행 실패';
      default:
        return nftStatus;
    }
  }

  // Complete 화면용 데이터 변환
  Map<String, dynamic> toCompleteScreenData() {
    return {
      // NFT 기본 정보
      'ticketId': ticketId,
      'nftStatus': nftStatus,
      'tokenId': nftTokenId.toString(),
      'transactionHash': transactionHash,
      'contractAddress': contractAddress,
      'blockchainNetwork': blockchainNetwork,
      'issuedAt': issuedAt,
      'verificationLevel': verificationLevel,
      'type': 'ticketing',

      // 공연 정보 (Complete 화면 형식에 맞게)
      'concertInfo': {
        'title': performanceTitle,
        'artist': performerName,
        'venue': venueName,
      },
      'performanceTitle': performanceTitle,
      'performerName': performerName,
      'venueName': venueName,

      // 스케줄 정보
      'selectedSchedule': {
        'date': _formatDate(sessionDatetime),
        'time': _formatTime(sessionDatetime),
        'datetime': sessionDatetime,
      },

      // 좌석 정보 (Complete 화면 형식에 맞게)
      'selectedSeat': {'row': seatRow, 'col': seatColumn},
      'selectedZone': seatZone,
      'seatGrade': seatGrade,
      'seatInfo': {
        'zone': seatZone,
        'row': seatRow,
        'column': seatColumn,
        'grade': seatGrade,
      },
    };
  }

  String _formatDate(String datetime) {
    try {
      final dt = DateTime.parse(datetime);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return datetime.split(' ').first;
    }
  }

  String _formatTime(String datetime) {
    try {
      final dt = DateTime.parse(datetime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return datetime.split(' ').last;
    }
  }
}
