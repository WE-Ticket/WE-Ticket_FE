/// MyPage 도메인에서 사용하는 결제 내역 엔티티
class PaymentHistory {
  final int id;
  final String transactionId;
  final String type; // purchase, transfer_sell, transfer_buy, cancel
  final String title;
  final int price;
  final DateTime paymentDate;
  final String status;
  final String? performanceDate;
  final String? seatInfo;

  const PaymentHistory({
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

  bool get isPurchase => type == 'purchase';
  bool get isTransferSell => type == 'transfer_sell';
  bool get isTransferBuy => type == 'transfer_buy';
  bool get isCancel => type == 'cancel';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentHistory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentHistory(id: $id, type: $type, title: $title, price: $price)';
  }
}