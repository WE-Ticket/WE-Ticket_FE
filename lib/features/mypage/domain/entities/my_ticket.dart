/// MyPage 도메인에서 사용하는 티켓 엔티티
class MyTicket {
  final String nftTicketId;
  final String title;
  final String venue;
  final DateTime performanceDate;
  final DateTime purchaseDate;
  final String seatInfo;
  final int price;
  final String status;
  final String? imageUrl;

  const MyTicket({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyTicket &&
          runtimeType == other.runtimeType &&
          nftTicketId == other.nftTicketId;

  @override
  int get hashCode => nftTicketId.hashCode;

  @override
  String toString() {
    return 'MyTicket(nftTicketId: $nftTicketId, title: $title, venue: $venue)';
  }
}