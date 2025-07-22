import '../../../../core/utils/json_parser.dart';

/// 결제 이력 응답 모델
/// createdAt 백엔드로 인해 일단은 nullable이지만 추후 수정 필요
class PaymentHistory {
  final int paymentId;
  final String paymentType;
  final String paymentStatus;
  final String? createdAt;
  final int? ticketId;
  final int? transferTicketId;
  final int performanceId;
  final String performanceMainImage;
  final String performanceTitle;
  final String performerName;
  final String sessionDatetime;
  final String venueName;
  final String seatNumber;
  final String paymentNumber;
  final int price;
  final String method;
  final String paymentDatetime;
  final String? depositAccount;
  final String? depositDeadline;
  final String? transferFinishedDatetime;
  final String? cancelRequestDatetime;
  final String? cancelRequestReason;
  final String? refundFinishDatetime;

  PaymentHistory({
    required this.paymentId,
    required this.paymentType,
    required this.paymentStatus,
    required this.createdAt,
    this.ticketId,
    this.transferTicketId,
    required this.performanceId,
    required this.performanceMainImage,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDatetime,
    required this.venueName,
    required this.seatNumber,
    required this.paymentNumber,
    required this.price,
    required this.method,
    required this.paymentDatetime,
    this.depositAccount,
    this.depositDeadline,
    this.transferFinishedDatetime,
    this.cancelRequestDatetime,
    this.cancelRequestReason,
    this.refundFinishDatetime,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      paymentId: JsonParserUtils.parseInt(json['payment_id']),
      paymentType: JsonParserUtils.parseString(json['payment_type']),
      paymentStatus: JsonParserUtils.parseString(json['payment_status']),
      createdAt: JsonParserUtils.parseStringNullable(
        json['payment_created_at'],
      ),
      ticketId: JsonParserUtils.parseIntNullable(json['ticket_id']),
      transferTicketId: JsonParserUtils.parseIntNullable(
        json['transfer_ticket_id'],
      ),
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      performanceMainImage: JsonParserUtils.parseString(
        json['performance_main_image'],
      ),
      performanceTitle: JsonParserUtils.parseString(json['performance_title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      sessionDatetime: JsonParserUtils.parseString(json['session_datetime']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      seatNumber: JsonParserUtils.parseString(json['seat_number']),
      paymentNumber: JsonParserUtils.parseString(json['payment_number']),
      price: JsonParserUtils.parseInt(json['price']),
      method: JsonParserUtils.parseString(
        json['mothod'],
      ), // API 응답의 오타 'mothod'를 그대로 사용
      paymentDatetime: JsonParserUtils.parseString(json['payment_datetime']),
      depositAccount: JsonParserUtils.parseStringNullable(
        json['deposit_account'],
      ),
      depositDeadline: JsonParserUtils.parseStringNullable(
        json['deposit_deadline'],
      ),
      transferFinishedDatetime: JsonParserUtils.parseStringNullable(
        json['transfer_finished_datetime'],
      ),
      cancelRequestDatetime: JsonParserUtils.parseStringNullable(
        json['cancel_request_datetime'],
      ),
      cancelRequestReason: JsonParserUtils.parseStringNullable(
        json['cancel_request_reason'],
      ),
      refundFinishDatetime: JsonParserUtils.parseStringNullable(
        json['refund_finish_datetime'],
      ),
    );
  }

  /// 거래 타입별 분류 메서드 (새로운 TYPE_CHOICES 반영)
  bool get isPurchase => paymentType == 'buy_ticket';
  bool get isTransferBuy => paymentType == 'buy_transfer_ticket';
  bool get isTransferSell => paymentType == 'sell_transfer_ticket';
  bool get isCancel => paymentType == 'cancel_ticket';

  /// 상태별 분류 메서드 (새로운 STATUS_CHOICES 반영)
  bool get isCompleted => paymentStatus == 'completed';
  bool get isInProgress => paymentStatus == 'in_progress';

  /// 하위 호환성을 위한 별칭 (기존 코드에서 isPending 사용하는 경우)
  bool get isPending => isInProgress;

  /// UI 표시용 타입 텍스트
  String get typeDisplay {
    switch (paymentType) {
      case 'buy_ticket':
        return '티켓 구매';
      case 'cancel_ticket':
        return '티켓 취소';
      case 'buy_transfer_ticket':
        return '양도 구매';
      case 'sell_transfer_ticket':
        return '양도 판매';
      default:
        return paymentType;
    }
  }

  /// UI 표시용 상태 텍스트
  String get statusDisplay {
    switch (paymentStatus) {
      case 'completed':
        if (isPurchase || isTransferBuy) return '구매 완료';
        if (isTransferSell) return '판매 완료';
        if (isCancel) return '취소 완료';
        return '완료';
      case 'in_progress':
        if (depositAccount != null) return '입금 대기';
        if (isCancel) return '취소 처리 중';
        if (isTransferSell) return '판매 진행 중';
        return '대기 중';
      default:
        return paymentStatus;
    }
  }

  /// 가격 포맷팅
  String get priceDisplay {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  /// 날짜 포맷팅
  DateTime get sessionDate => JsonParserUtils.parseDateTime(sessionDatetime);
  DateTime get paymentDate => JsonParserUtils.parseDateTime(paymentDatetime);

  String get sessionDateDisplay {
    final date = sessionDate;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String get sessionTimeDisplay {
    final date = sessionDate;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get paymentDateDisplay {
    final date = paymentDate;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String get paymentTimeDisplay {
    final date = paymentDate;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 필터링을 위한 카테고리 (새로운 TYPE_CHOICES 반영)
  String get filterCategory {
    if (isPurchase || isTransferBuy) return '구매 내역';
    if (isTransferSell) return '판매 내역';
    if (isCancel) return '취소/환불';
    return '전체 거래';
  }

  /// 입금 마감일 확인 (in_progress 상태와 연동)
  bool get hasDepositDeadline =>
      isInProgress && depositAccount != null && depositDeadline != null;

  DateTime? get depositDeadlineDate {
    if (depositDeadline == null) return null;
    return JsonParserUtils.parseDateTime(depositDeadline!);
  }

  /// 취소/환불 관련 정보
  bool get hasCancelInfo => cancelRequestDatetime != null;
  bool get hasRefundInfo => refundFinishDatetime != null;

  DateTime? get cancelRequestDate {
    if (cancelRequestDatetime == null) return null;
    return JsonParserUtils.parseDateTime(cancelRequestDatetime!);
  }

  DateTime? get refundFinishDate {
    if (refundFinishDatetime == null) return null;
    return JsonParserUtils.parseDateTime(refundFinishDatetime!);
  }

  /// 양도 완료 정보
  bool get hasTransferInfo => transferFinishedDatetime != null;

  DateTime? get transferFinishDate {
    if (transferFinishedDatetime == null) return null;
    return JsonParserUtils.parseDateTime(transferFinishedDatetime!);
  }
}
