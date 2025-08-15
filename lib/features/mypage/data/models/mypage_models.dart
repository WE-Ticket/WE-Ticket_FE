import '../../../../core/utils/json_parser.dart';

/// MyPage에서 사용하는 티켓 모델
class MyTicketModel {
  final String nftTicketId;
  final String title;
  final String venue;
  final DateTime performanceDate;
  final DateTime purchaseDate;
  final String seatInfo;
  final int price;
  final String status;
  final String? imageUrl;

  MyTicketModel({
    required this.nftTicketId,
    required this.title,
    required this.venue,
    required this.performanceDate,
    required this.purchaseDate,
    required this.seatInfo,
    required this.price,
    required this.status,
    this.imageUrl,
  });

  factory MyTicketModel.fromJson(Map<String, dynamic> json) {
    return MyTicketModel(
      nftTicketId: JsonParserUtils.parseString(json['nft_ticket_id']),
      title: JsonParserUtils.parseString(json['title']),
      venue: JsonParserUtils.parseString(json['venue']),
      performanceDate: DateTime.parse(JsonParserUtils.parseString(json['performance_date'])),
      purchaseDate: DateTime.parse(JsonParserUtils.parseString(json['purchase_date'])),
      seatInfo: JsonParserUtils.parseString(json['seat_info']),
      price: JsonParserUtils.parseInt(json['price']),
      status: JsonParserUtils.parseString(json['status']),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nft_ticket_id': nftTicketId,
      'title': title,
      'venue': venue,
      'performance_date': performanceDate.toIso8601String(),
      'purchase_date': purchaseDate.toIso8601String(),
      'seat_info': seatInfo,
      'price': price,
      'status': status,
      'image_url': imageUrl,
    };
  }

  @override
  String toString() {
    return 'MyTicketModel(nftTicketId: $nftTicketId, title: $title)';
  }
}

/// MyPage에서 사용하는 결제 내역 모델
class PaymentHistoryModel {
  final int id;
  final String transactionId;
  final String type;
  final String title;
  final int price;
  final DateTime paymentDate;
  final String status;
  final String? performanceDate;
  final String? seatInfo;

  PaymentHistoryModel({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.title,
    required this.price,
    required this.paymentDate,
    required this.status,
    this.performanceDate,
    this.seatInfo,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: JsonParserUtils.parseInt(json['id']),
      transactionId: JsonParserUtils.parseString(json['transaction_id']),
      type: JsonParserUtils.parseString(json['type']),
      title: JsonParserUtils.parseString(json['title']),
      price: JsonParserUtils.parseInt(json['price']),
      paymentDate: DateTime.parse(JsonParserUtils.parseString(json['payment_date'])),
      status: JsonParserUtils.parseString(json['status']),
      performanceDate: json['performance_date'],
      seatInfo: json['seat_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'type': type,
      'title': title,
      'price': price,
      'payment_date': paymentDate.toIso8601String(),
      'status': status,
      'performance_date': performanceDate,
      'seat_info': seatInfo,
    };
  }

  @override
  String toString() {
    return 'PaymentHistoryModel(id: $id, type: $type, title: $title)';
  }
}