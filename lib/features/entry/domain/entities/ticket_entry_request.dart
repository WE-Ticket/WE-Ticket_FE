/// Entry 도메인에서 사용하는 티켓 입장 요청 엔티티
class TicketEntryRequest {
  final String ticketId;
  final String userId;
  final String entryMethod; // nfc, manual
  final String? nfcData;
  final String? manualCode;
  final DateTime requestTime;

  const TicketEntryRequest({
    required this.ticketId,
    required this.userId,
    required this.entryMethod,
    required this.requestTime,
    this.nfcData,
    this.manualCode,
  });

  bool get isNfcEntry => entryMethod == 'nfc';
  bool get isManualEntry => entryMethod == 'manual';

  @override
  String toString() {
    return 'TicketEntryRequest(ticketId: $ticketId, method: $entryMethod)';
  }
}