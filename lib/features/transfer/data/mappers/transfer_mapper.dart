import '../transfer_models.dart' as data_models;
import '../../domain/entities/transfer_ticket.dart' as domain;

/// Mapper class to convert between transfer data models and domain entities
class TransferMapper {
  /// Convert TransferListResponse to domain TransferList
  domain.TransferList transferListResponseToDomain(data_models.TransferListResponse model) {
    final tickets = model.results
        .map((item) => transferTicketItemToDomain(item))
        .toList();

    return domain.TransferList(
      tickets: tickets,
      totalCount: model.count,
      currentPage: 1,
      totalPages: (model.count / 20).ceil(),
      hasNext: model.next != null,
      hasPrevious: model.previous != null,
    );
  }

  /// Convert TransferTicketItem to domain TransferTicket
  domain.TransferTicket transferTicketItemToDomain(data_models.TransferTicketItem model) {
    final seatInfo = _parseSeatNumber(model.seatNumber);
    
    return domain.TransferTicket(
      id: model.transferTicketId,
      ticketId: model.performanceId,
      performanceTitle: model.performanceTitle,
      performerName: model.performerName,
      venueName: model.venueName,
      sessionDateTime: _parseDateTime(model.sessionDatetime),
      seatZone: seatInfo['zone']!,
      seatRow: seatInfo['row']!,
      seatColumn: int.parse(seatInfo['column']!),
      originalPrice: model.transferTicketPrice,
      transferPrice: model.transferTicketPrice,
      isPublicTransfer: true,
      status: domain.TransferStatus.available,
      createdAt: _parseDateTime(model.createdDatetime),
      tempUniqueCode: null,
      imageUrl: model.performanceMainImage,
    );
  }

  /// Convert transfer detail to map
  Map<String, dynamic> transferDetailToMap(Map<String, dynamic> model) {
    return {
      'id': model['transfer_ticket_id'] ?? 0,
      'performanceTitle': model['performance_title'] ?? 'Unknown',
      'performerName': model['performer_name'] ?? 'Unknown',
      'venueName': model['venue_name'] ?? 'Unknown',
      'transferPrice': model['transfer_ticket_price'] ?? 0,
      'seatNumber': model['seat_number'] ?? 'Unknown',
      'sessionDatetime': model['session_datetime'] ?? '',
      'imageUrl': model['performance_main_image'] ?? '',
    };
  }

  /// Convert transferable ticket to map
  Map<String, dynamic> transferableTicketToMap(data_models.TransferableTicket model) {
    return {
      'ticketId': model.ticketId,
      'performanceTitle': model.performanceTitle,
      'performerName': model.performerName,
      'sessionDateTime': _parseDateTime(model.sessionDatetime),
      'seatNumber': model.seatNumber,
      'seatGrade': model.seatGrade,
      'seatPrice': model.seatPrice,
      'imageUrl': model.performanceMainImage,
      'isRegisterable': model.isRegisterable,
    };
  }

  /// Convert my transfer ticket to map
  Map<String, dynamic> myTransferTicketToMap(data_models.MyTransferTicket model) {
    return {
      'transferTicketId': model.transferTicketId,
      'performanceTitle': model.performanceTitle,
      'performerName': model.performerName,
      'sessionDateTime': _parseDateTime(model.sessionDatetime),
      'seatNumber': model.seatNumber,
      'seatGrade': model.seatGrade,
      'transferTicketPrice': model.transferTicketPrice,
      'isPublicTransfer': model.isPublicTransfer,
      'transferStatus': model.transferStatus,
      'createdDatetime': _parseDateTime(model.createdDatetime),
    };
  }

  /// Helper method to parse date string to DateTime
  DateTime _parseDateTime(String dateStr) {
    try {
      // Assuming date format is YYYY-MM-DD HH:MM:SS or similar
      return DateTime.parse(dateStr);
    } catch (e) {
      // Return current date as fallback
      return DateTime.now();
    }
  }

  /// Helper method to parse seat number into zone, row, and column
  Map<String, String> _parseSeatNumber(String seatNumber) {
    try {
      // Extract row (letters) and column (numbers) from seat number like "A1", "B12", etc.
      final match = RegExp(r'([A-Za-z]+)(\d+)').firstMatch(seatNumber);
      if (match != null) {
        final row = match.group(1) ?? 'A';
        final column = match.group(2) ?? '1';
        return {
          'zone': '$row구역', // Add "구역" for Korean
          'row': row,
          'column': column,
        };
      }
    } catch (e) {
      // Fallback for parsing errors
    }
    
    // Default fallback
    return {
      'zone': 'A구역',
      'row': 'A',
      'column': '1',
    };
  }
}