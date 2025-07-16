import '../../../../core/utils/json_parser.dart';

/// 양도 마켓 리스트 페이지네이션 응답 모델
class TransferListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<TransferTicketItem> results;

  TransferListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TransferListResponse.fromJson(Map<String, dynamic> json) {
    return TransferListResponse(
      count: JsonParserUtils.parseInt(json['count']),
      next: json['next'],
      previous: json['previous'],
      results:
          (json['results'] as List<dynamic>?)
              ?.map((item) => TransferTicketItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// 양도 마켓 리스트 개별 아이템 모델
class TransferTicketItem {
  final int transferTicketId;
  final int performanceId;
  final String? performanceMainImage;
  final String performanceTitle;
  final String performerName;
  final String sessionDatetime;
  final String venueName;
  final String seatNumber;
  final int transferTicketPrice;
  final String createdDatetime;

  TransferTicketItem({
    required this.transferTicketId,
    required this.performanceId,
    this.performanceMainImage,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDatetime,
    required this.venueName,
    required this.seatNumber,
    required this.transferTicketPrice,
    required this.createdDatetime,
  });

  factory TransferTicketItem.fromJson(Map<String, dynamic> json) {
    return TransferTicketItem(
      transferTicketId: JsonParserUtils.parseInt(json['transfer_ticket_id']),
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      performanceMainImage: json['performance_main_image'],
      performanceTitle: JsonParserUtils.parseString(json['performance_title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      seatNumber: JsonParserUtils.parseString(json['seat_number']),
      transferTicketPrice: JsonParserUtils.parseInt(
        json['transfer_ticket_price'],
      ),
      createdDatetime: JsonParserUtils.parseString(json['created_datetime']),
    );
  }

  /// 가격 포맷팅
  String get priceDisplay =>
      '${transferTicketPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

  /// 세션 날짜/시간 파싱
  DateTime get sessionDateTime => DateTime.parse(sessionDatetime);
}

/// 양도 티켓 상세 모델 (공개/비공개 공통)
class TransferTicketDetail {
  final int transferTicketId;
  final int performanceId;
  final String? performanceMainImage;
  final String performanceTitle;
  final String performerName;
  final String sessionDatetime;
  final String venueName;
  final String venueLocation;
  final String seatNumber;
  final String seatGrade;
  final int seatPrice;
  final int transferTicketPrice;
  final int transferBuyerFee;
  final int totalPrice;
  final String createdDatetime;

  // 비공개 티켓 전용 필드
  final String? codeCreatedDatetime;
  final String? codeExpiryDatetime;

  TransferTicketDetail({
    required this.transferTicketId,
    required this.performanceId,
    this.performanceMainImage,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDatetime,
    required this.venueName,
    required this.venueLocation,
    required this.seatNumber,
    required this.seatGrade,
    required this.seatPrice,
    required this.transferTicketPrice,
    required this.transferBuyerFee,
    required this.totalPrice,
    required this.createdDatetime,
    this.codeCreatedDatetime,
    this.codeExpiryDatetime,
  });

  factory TransferTicketDetail.fromJson(Map<String, dynamic> json) {
    return TransferTicketDetail(
      transferTicketId: JsonParserUtils.parseInt(json['transfer_ticket_id']),
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      performanceMainImage: json['performance_main_image'],
      performanceTitle: JsonParserUtils.parseString(json['performance_title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      venueLocation: JsonParserUtils.parseString(json['venue_location']),
      seatNumber: JsonParserUtils.parseString(json['seat_number']),
      seatGrade: JsonParserUtils.parseString(json['seat_grade']),
      seatPrice: JsonParserUtils.parseInt(json['seat_price']),
      transferTicketPrice: JsonParserUtils.parseInt(
        json['transfer_ticket_price'],
      ),
      transferBuyerFee: JsonParserUtils.parseInt(json['transfer_buyer_fee']),
      totalPrice: JsonParserUtils.parseInt(json['total_price']),
      createdDatetime: JsonParserUtils.parseString(json['created_datetime']),
      codeCreatedDatetime: json['code_created_datetime'],
      codeExpiryDatetime: json['code_expiry_datetime'],
    );
  }

  /// 가격 포맷팅
  String get transferPriceDisplay =>
      '${transferTicketPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

  String get totalPriceDisplay =>
      '${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

  String get buyerFeeDisplay =>
      '${transferBuyerFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

  /// 비공개 티켓 여부 확인
  bool get isPrivateTransfer => codeCreatedDatetime != null;

  /// 고유번호 만료 여부 확인
  bool get isCodeExpired {
    if (codeExpiryDatetime == null) return false;
    return DateTime.parse(codeExpiryDatetime!).isBefore(DateTime.now());
  }
}

/// 고유번호 관련 모델
class TransferUniqueCode {
  final int transferTicket;
  final String tempUniqueCode;
  final String createdDatetime;
  final String expiryDatetime;

  TransferUniqueCode({
    required this.transferTicket,
    required this.tempUniqueCode,
    required this.createdDatetime,
    required this.expiryDatetime,
  });

  factory TransferUniqueCode.fromJson(Map<String, dynamic> json) {
    return TransferUniqueCode(
      transferTicket: JsonParserUtils.parseInt(json['transfer_ticket']),
      tempUniqueCode: JsonParserUtils.parseString(json['temp_unique_code']),
      createdDatetime: JsonParserUtils.parseString(json['created_datetime']),
      expiryDatetime: JsonParserUtils.parseString(json['expiry_datetime']),
    );
  }

  /// 만료 여부 확인
  bool get isExpired => DateTime.parse(expiryDatetime).isBefore(DateTime.now());

  /// 만료까지 남은 시간
  Duration get timeUntilExpiry =>
      DateTime.parse(expiryDatetime).difference(DateTime.now());
}

/// 내 양도 등록 티켓 모델
class MyTransferTicket {
  final int transferTicketId;
  final int performanceId;
  final String? performanceMainImage;
  final String performanceTitle;
  final String performerName;
  final String sessionDatetime;
  final String venueName;
  final String venueLocation;
  final String seatNumber;
  final String seatGrade;
  final int seatPrice;
  final int transferTicketPrice;
  final int transferSellerFee;
  final String createdDatetime;
  final bool isPublicTransfer;
  final String transferStatus;
  final String? finishedDatetime;

  MyTransferTicket({
    required this.transferTicketId,
    required this.performanceId,
    this.performanceMainImage,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDatetime,
    required this.venueName,
    required this.venueLocation,
    required this.seatNumber,
    required this.seatGrade,
    required this.seatPrice,
    required this.transferTicketPrice,
    required this.transferSellerFee,
    required this.createdDatetime,
    required this.isPublicTransfer,
    required this.transferStatus,
    this.finishedDatetime,
  });

  factory MyTransferTicket.fromJson(Map<String, dynamic> json) {
    return MyTransferTicket(
      transferTicketId: JsonParserUtils.parseInt(json['transfer_ticket_id']),
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      performanceMainImage: json['performance_main_image'],
      performanceTitle: JsonParserUtils.parseString(json['performance_title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      venueLocation: JsonParserUtils.parseString(json['venue_location']),
      seatNumber: JsonParserUtils.parseString(json['seat_number']),
      seatGrade: JsonParserUtils.parseString(json['seat_grade']),
      seatPrice: JsonParserUtils.parseInt(json['seat_price']),
      transferTicketPrice: JsonParserUtils.parseInt(
        json['transfer_ticket_price'],
      ),
      transferSellerFee: JsonParserUtils.parseInt(json['transfer_seller_fee']),
      createdDatetime: JsonParserUtils.parseString(json['created_datetime']),
      isPublicTransfer: JsonParserUtils.parseBool(json['is_public_transfer']),
      transferStatus: JsonParserUtils.parseString(json['transfer_status']),
      finishedDatetime: json['finished_datetime'],
    );
  }

  /// 양도 상태 텍스트
  String get statusText {
    switch (transferStatus) {
      case 'pending':
        return '양도 대기';
      case 'in_progress':
        return '양도 진행중';
      case 'completed':
        return '양도 완료';
      case 'cancelled':
        return '양도 취소';
      default:
        return '알 수 없음';
    }
  }

  /// 양도 방식 텍스트
  String get transferTypeText => isPublicTransfer ? '공개 양도' : '비공개 양도';

  /// 완료 여부
  bool get isCompleted => transferStatus == 'completed';

  /// 취소 가능 여부
  bool get canCancel => transferStatus == 'pending';
}

/// 양도 가능한 티켓 모델
class TransferableTicket {
  final String nftTicketId;
  final int performanceId;
  final String? performanceMainImage;
  final String performanceTitle;
  final String performerName;
  final String sessionDatetime;
  final String venueName;
  final String venueLocation;
  final String seatNumber;
  final String seatGrade;
  final int seatPrice;
  final bool isRegisterable;

  TransferableTicket({
    required this.nftTicketId,
    required this.performanceId,
    this.performanceMainImage,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDatetime,
    required this.venueName,
    required this.venueLocation,
    required this.seatNumber,
    required this.seatGrade,
    required this.seatPrice,
    required this.isRegisterable,
  });

  factory TransferableTicket.fromJson(Map<String, dynamic> json) {
    return TransferableTicket(
      nftTicketId: JsonParserUtils.parseString(json['nft_ticket_id']),
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      performanceMainImage: json['performance_main_image'],
      performanceTitle: JsonParserUtils.parseString(json['performance_title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      venueLocation: JsonParserUtils.parseString(json['venue_location']),
      seatNumber: JsonParserUtils.parseString(json['seat_number']),
      seatGrade: JsonParserUtils.parseString(json['seat_grade']),
      seatPrice: JsonParserUtils.parseInt(json['seat_price']),
      isRegisterable: JsonParserUtils.parseBool(json['is_registerable']),
    );
  }

  /// 등록 불가 사유
  String get registerableStatusText {
    if (isRegisterable) return '등록 가능';

    // 공연 7일 전부터는 등록 불가
    final sessionDate = DateTime.parse(sessionDatetime);
    final daysUntilPerformance = sessionDate.difference(DateTime.now()).inDays;

    if (daysUntilPerformance <= 7) {
      return '공연 7일 전부터 등록 불가';
    }

    return '등록 불가';
  }
}

/// API 에러 응답 모델
class TransferApiError {
  final String error;
  final bool? isPublicTransfer;
  final String? transferStatus;
  final String? expiryDatetime;
  final bool? replacedByNewCode;
  final String? transferTicketId;

  TransferApiError({
    required this.error,
    this.isPublicTransfer,
    this.transferStatus,
    this.expiryDatetime,
    this.replacedByNewCode,
    this.transferTicketId,
  });

  factory TransferApiError.fromJson(Map<String, dynamic> json) {
    return TransferApiError(
      error: JsonParserUtils.parseString(json['error']),
      isPublicTransfer: json['is_public_transfer'],
      transferStatus: json['transfer_status'],
      expiryDatetime: json['expiry_datetime'],
      replacedByNewCode: json['replaced_by_new_code'],
      transferTicketId: json['transfer_ticket_id'],
    );
  }
}
