/// Entry 도메인에서 사용하는 입장 결과 엔티티
class EntryResult {
  final bool isSuccess;
  final String message;
  final String? ticketId;
  final String? performanceTitle;
  final String? seatInfo;
  final DateTime? entryTime;
  final String entryMethod; // nfc, manual

  const EntryResult({
    required this.isSuccess,
    required this.message,
    required this.entryMethod,
    this.ticketId,
    this.performanceTitle,
    this.seatInfo,
    this.entryTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryResult &&
          runtimeType == other.runtimeType &&
          ticketId == other.ticketId &&
          entryTime == other.entryTime;

  @override
  int get hashCode => ticketId.hashCode ^ entryTime.hashCode;

  @override
  String toString() {
    return 'EntryResult(isSuccess: $isSuccess, message: $message, method: $entryMethod)';
  }
}