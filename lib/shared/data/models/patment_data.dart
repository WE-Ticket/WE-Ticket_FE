// payment_data.dart
abstract class PaymentData {
  final String paymentType;
  final String merchantUid;
  final int amount;
  final String? paymentMethod;
  final Map<String, dynamic>? apiResponse;

  const PaymentData({
    required this.paymentType,
    required this.merchantUid,
    required this.amount,
    this.paymentMethod,
    this.apiResponse,
  });

  Map<String, dynamic> toMap();
  String get displayTitle;
  String get processTitle;
  String get completeTitle;

  // API 응답 데이터를 추가한 새로운 인스턴스 생성
  PaymentData copyWithApiResponse(Map<String, dynamic> response);
}

class TicketingPaymentData extends PaymentData {
  // 기본 공연 정보
  final Map<String, dynamic> concertInfo;
  final Map<String, dynamic> selectedSession;

  // API에서 받은 실제 데이터
  final int performanceId;
  final int performanceSessionId;
  final Map<String, dynamic> sessionSeatInfo;

  // 좌석 정보
  final String selectedZone;
  final Map<String, dynamic> selectedSeat;
  final String seatGrade;
  final int price;
  final String priceDisplay;

  // 좌석 배치 정보
  final Map<String, dynamic> seatLayout;

  const TicketingPaymentData({
    required String merchantUid,
    required int amount,
    String? paymentMethod,
    Map<String, dynamic>? apiResponse,
    required this.concertInfo,
    required this.selectedSession,
    required this.performanceId,
    required this.performanceSessionId,
    required this.sessionSeatInfo,
    required this.selectedZone,
    required this.selectedSeat,
    required this.seatGrade,
    required this.price,
    required this.priceDisplay,
    required this.seatLayout,
  }) : super(
         paymentType: 'ticketing',
         merchantUid: merchantUid,
         amount: amount,
         paymentMethod: paymentMethod,
         apiResponse: apiResponse,
       );

  @override
  String get displayTitle =>
      sessionSeatInfo['title'] ?? concertInfo['title'] ?? '공연 티켓';

  @override
  String get processTitle => 'NFT 티켓 발행 중';

  @override
  String get completeTitle => '예매 완료!';

  @override
  Map<String, dynamic> toMap() {
    return {
      'paymentType': paymentType,
      'merchantUid': merchantUid,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'apiResponse': apiResponse,
      'concertInfo': concertInfo,
      'selectedSession': selectedSession,
      'performanceId': performanceId,
      'performanceSessionId': performanceSessionId,
      'sessionSeatInfo': sessionSeatInfo,
      'selectedZone': selectedZone,
      'selectedSeat': selectedSeat,
      'seatGrade': seatGrade,
      'price': price,
      'priceDisplay': priceDisplay,
      'seatLayout': seatLayout,
    };
  }

  @override
  TicketingPaymentData copyWithApiResponse(Map<String, dynamic> response) {
    return TicketingPaymentData(
      merchantUid: merchantUid,
      amount: amount,
      paymentMethod: paymentMethod,
      apiResponse: response,
      concertInfo: concertInfo,
      selectedSession: selectedSession,
      performanceId: performanceId,
      performanceSessionId: performanceSessionId,
      sessionSeatInfo: sessionSeatInfo,
      selectedZone: selectedZone,
      selectedSeat: selectedSeat,
      seatGrade: seatGrade,
      price: price,
      priceDisplay: priceDisplay,
      seatLayout: seatLayout,
    );
  }

  factory TicketingPaymentData.fromMap(Map<String, dynamic> map) {
    return TicketingPaymentData(
      merchantUid: map['merchantUid'] ?? map['merchant_uid'] ?? 'unknown',
      amount: map['amount'] ?? map['price'] ?? 0,
      paymentMethod: map['paymentMethod'],
      apiResponse: map['apiResponse'],
      concertInfo: map['concertInfo'] ?? {},
      selectedSession: map['selectedSession'] ?? {},
      performanceId: map['performanceId'] ?? 0,
      performanceSessionId: map['performanceSessionId'] ?? 0,
      sessionSeatInfo: map['sessionSeatInfo'] ?? {},
      selectedZone: map['selectedZone'] ?? '',
      selectedSeat: map['selectedSeat'] ?? {},
      seatGrade: map['seatGrade'] ?? '',
      price: map['price'] ?? 0,
      priceDisplay: map['priceDisplay'] ?? '${map['price'] ?? 0}원',
      seatLayout: map['seatLayout'] ?? {},
    );
  }
}

class TransferPaymentData extends PaymentData {
  // 양도 티켓 정보
  final int transferTicketId;
  final String performanceTitle;
  final String performerName;
  final String sessionDatetime;
  final String venueName;
  final String seatNumber;
  final String seatGrade;

  // 가격 정보
  final int transferPrice;
  final int buyerFee;
  final int totalPrice;
  final String transferPriceDisplay;
  final String buyerFeeDisplay;
  final String totalPriceDisplay;

  // 양도 방식
  final bool isPrivateTransfer;

  // 구매자 정보 (API 호출용)
  final int buyerUserId;

  const TransferPaymentData({
    required String merchantUid,
    required int amount,
    String? paymentMethod,
    Map<String, dynamic>? apiResponse,
    required this.transferTicketId,
    required this.performanceTitle,
    required this.performerName,
    required this.sessionDatetime,
    required this.venueName,
    required this.seatNumber,
    required this.seatGrade,
    required this.transferPrice,
    required this.buyerFee,
    required this.totalPrice,
    required this.transferPriceDisplay,
    required this.buyerFeeDisplay,
    required this.totalPriceDisplay,
    required this.isPrivateTransfer,
    required this.buyerUserId,
  }) : super(
         paymentType: 'transfer',
         merchantUid: merchantUid,
         amount: amount,
         paymentMethod: paymentMethod,
         apiResponse: apiResponse,
       );

  @override
  String get displayTitle => 'Ticketing : $performanceTitle';

  @override
  String get processTitle => '양도 이행 중';

  @override
  String get completeTitle => '양도 구매 완료!';

  @override
  Map<String, dynamic> toMap() {
    return {
      'paymentType': paymentType,
      'merchantUid': merchantUid,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'apiResponse': apiResponse,
      'transferTicketId': transferTicketId,
      'performanceTitle': performanceTitle,
      'performerName': performerName,
      'sessionDatetime': sessionDatetime,
      'venueName': venueName,
      'seatNumber': seatNumber,
      'seatGrade': seatGrade,
      'transferPrice': transferPrice,
      'buyerFee': buyerFee,
      'totalPrice': totalPrice,
      'transferPriceDisplay': transferPriceDisplay,
      'buyerFeeDisplay': buyerFeeDisplay,
      'totalPriceDisplay': totalPriceDisplay,
      'isPrivateTransfer': isPrivateTransfer,
      'buyerUserId': buyerUserId,
    };
  }

  @override
  TransferPaymentData copyWithApiResponse(Map<String, dynamic> response) {
    return TransferPaymentData(
      merchantUid: merchantUid,
      amount: amount,
      paymentMethod: paymentMethod,
      apiResponse: response,
      transferTicketId: transferTicketId,
      performanceTitle: performanceTitle,
      performerName: performerName,
      sessionDatetime: sessionDatetime,
      venueName: venueName,
      seatNumber: seatNumber,
      seatGrade: seatGrade,
      transferPrice: transferPrice,
      buyerFee: buyerFee,
      totalPrice: totalPrice,
      transferPriceDisplay: transferPriceDisplay,
      buyerFeeDisplay: buyerFeeDisplay,
      totalPriceDisplay: totalPriceDisplay,
      isPrivateTransfer: isPrivateTransfer,
      buyerUserId: buyerUserId,
    );
  }

  factory TransferPaymentData.fromMap(Map<String, dynamic> map) {
    return TransferPaymentData(
      merchantUid:
          map['merchantUid'] ??
          map['merchant_uid'] ??
          'TRF_${DateTime.now().millisecondsSinceEpoch}',
      amount: map['amount'] ?? map['totalPrice'] ?? 0,
      paymentMethod: map['paymentMethod'],
      apiResponse: map['apiResponse'],
      transferTicketId: map['transferTicketId'] ?? 0,
      performanceTitle: map['performanceTitle'] ?? '',
      performerName: map['performerName'] ?? '',
      sessionDatetime: map['sessionDatetime'] ?? '',
      venueName: map['venueName'] ?? '',
      seatNumber: map['seatNumber'] ?? '',
      seatGrade: map['seatGrade'] ?? '',
      transferPrice: map['transferPrice'] ?? 0,
      buyerFee: map['buyerFee'] ?? 0,
      totalPrice: map['totalPrice'] ?? 0,
      transferPriceDisplay:
          map['transferPriceDisplay'] ?? '${map['transferPrice'] ?? 0}원',
      buyerFeeDisplay: map['buyerFeeDisplay'] ?? '${map['buyerFee'] ?? 0}원',
      totalPriceDisplay:
          map['totalPriceDisplay'] ?? '${map['totalPrice'] ?? 0}원',
      isPrivateTransfer: map['isPrivateTransfer'] ?? false,
      buyerUserId: map['buyerUserId'] ?? 0,
    );
  }

  // 양도 API 호출용 데이터
  Map<String, dynamic> toTransferApiRequest() {
    return {
      'transfer_ticket_id': transferTicketId,
      'buyer_user_id': buyerUserId,
    };
  }
}

// 결제 데이터 팩토리
class PaymentDataFactory {
  static PaymentData fromMap(Map<String, dynamic> map) {
    final paymentType = map['paymentType'] as String?;

    switch (paymentType) {
      case 'transfer':
        return TransferPaymentData.fromMap(map);
      case 'ticketing':
      default:
        return TicketingPaymentData.fromMap(map);
    }
  }

  // 기존 코드와의 호환성을 위한 헬퍼 메서드
  static Map<String, dynamic> toLegacyMap(PaymentData paymentData) {
    return paymentData.toMap();
  }
}
