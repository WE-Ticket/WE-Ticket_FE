import '../../../../core/utils/json_parser.dart';

/// Entry에서 사용하는 입장 요청 모델
class EntryRequestModel {
  final String ticketId;
  final String userId;
  final String entryMethod;
  final String? nfcData;
  final String? manualCode;
  final DateTime requestTime;

  EntryRequestModel({
    required this.ticketId,
    required this.userId,
    required this.entryMethod,
    required this.requestTime,
    this.nfcData,
    this.manualCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'user_id': userId,
      'entry_method': entryMethod,
      'request_time': requestTime.toIso8601String(),
      if (nfcData != null) 'nfc_data': nfcData,
      if (manualCode != null) 'manual_code': manualCode,
    };
  }

  @override
  String toString() {
    return 'EntryRequestModel(ticketId: $ticketId, method: $entryMethod)';
  }
}

/// Entry에서 사용하는 입장 결과 모델
class EntryResultModel {
  final bool isSuccess;
  final String message;
  final String? ticketId;
  final String? performanceTitle;
  final String? seatInfo;
  final DateTime? entryTime;
  final String entryMethod;

  EntryResultModel({
    required this.isSuccess,
    required this.message,
    required this.entryMethod,
    this.ticketId,
    this.performanceTitle,
    this.seatInfo,
    this.entryTime,
  });

  factory EntryResultModel.fromJson(Map<String, dynamic> json) {
    return EntryResultModel(
      isSuccess: JsonParserUtils.parseBool(json['is_success']),
      message: JsonParserUtils.parseString(json['message']),
      entryMethod: JsonParserUtils.parseString(json['entry_method']),
      ticketId: json['ticket_id'],
      performanceTitle: json['performance_title'],
      seatInfo: json['seat_info'],
      entryTime: json['entry_time'] != null 
          ? DateTime.parse(json['entry_time']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_success': isSuccess,
      'message': message,
      'entry_method': entryMethod,
      'ticket_id': ticketId,
      'performance_title': performanceTitle,
      'seat_info': seatInfo,
      'entry_time': entryTime?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'EntryResultModel(isSuccess: $isSuccess, message: $message)';
  }
}

/// Entry 내역 모델
class EntryHistoryModel {
  final int id;
  final String ticketId;
  final String performanceTitle;
  final String seatInfo;
  final DateTime entryTime;
  final String entryMethod;
  final String status;

  EntryHistoryModel({
    required this.id,
    required this.ticketId,
    required this.performanceTitle,
    required this.seatInfo,
    required this.entryTime,
    required this.entryMethod,
    required this.status,
  });

  factory EntryHistoryModel.fromJson(Map<String, dynamic> json) {
    return EntryHistoryModel(
      id: JsonParserUtils.parseInt(json['id']),
      ticketId: JsonParserUtils.parseString(json['ticket_id']),
      performanceTitle: JsonParserUtils.parseString(json['performance_title']),
      seatInfo: JsonParserUtils.parseString(json['seat_info']),
      entryTime: DateTime.parse(JsonParserUtils.parseString(json['entry_time'])),
      entryMethod: JsonParserUtils.parseString(json['entry_method']),
      status: JsonParserUtils.parseString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'performance_title': performanceTitle,
      'seat_info': seatInfo,
      'entry_time': entryTime.toIso8601String(),
      'entry_method': entryMethod,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'EntryHistoryModel(id: $id, title: $performanceTitle)';
  }
}