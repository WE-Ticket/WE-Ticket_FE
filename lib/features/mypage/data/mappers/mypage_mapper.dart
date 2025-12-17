import '../../domain/entities/my_ticket.dart';
import '../../domain/entities/payment_history.dart';
import '../models/mypage_models.dart';
import '../../../../core/utils/app_logger.dart';

/// MyPage 도메인과 데이터 계층 간의 매핑을 담당하는 클래스
class MyPageMapper {
  /// MyTicketModel을 MyTicket 엔티티로 변환
  MyTicket mapToMyTicket(MyTicketModel model) {
    try {
      return MyTicket(
        nftTicketId: model.nftTicketId,
        title: model.title,
        venue: model.venue,
        performanceDate: model.performanceDate,
        purchaseDate: model.purchaseDate,
        seatInfo: model.seatInfo,
        price: model.price,
        status: model.status,
        imageUrl: model.imageUrl,
      );
    } catch (e) {
      AppLogger.error('MyTicket 매핑 오류', e, null, 'MYPAGE_MAPPER');
      rethrow;
    }
  }

  /// PaymentHistoryModel을 PaymentHistory 엔티티로 변환
  PaymentHistory mapToPaymentHistory(PaymentHistoryModel model) {
    try {
      return PaymentHistory(
        id: model.id,
        transactionId: model.transactionId,
        type: model.type,
        title: model.title,
        price: model.price,
        paymentDate: model.paymentDate,
        status: model.status,
        performanceDate: model.performanceDate,
        seatInfo: model.seatInfo,
      );
    } catch (e) {
      AppLogger.error('PaymentHistory 매핑 오류', e, null, 'MYPAGE_MAPPER');
      rethrow;
    }
  }

  /// MyTicket 엔티티를 MyTicketModel로 변환 (필요한 경우)
  MyTicketModel mapFromMyTicket(MyTicket entity) {
    try {
      return MyTicketModel(
        nftTicketId: entity.nftTicketId,
        title: entity.title,
        venue: entity.venue,
        performanceDate: entity.performanceDate,
        purchaseDate: entity.purchaseDate,
        seatInfo: entity.seatInfo,
        price: entity.price,
        status: entity.status,
        imageUrl: entity.imageUrl,
      );
    } catch (e) {
      AppLogger.error('MyTicket 역매핑 오류', e, null, 'MYPAGE_MAPPER');
      rethrow;
    }
  }

  /// PaymentHistory 엔티티를 PaymentHistoryModel로 변환 (필요한 경우)
  PaymentHistoryModel mapFromPaymentHistory(PaymentHistory entity) {
    try {
      return PaymentHistoryModel(
        id: entity.id,
        transactionId: entity.transactionId,
        type: entity.type,
        title: entity.title,
        price: entity.price,
        paymentDate: entity.paymentDate,
        status: entity.status,
        performanceDate: entity.performanceDate,
        seatInfo: entity.seatInfo,
      );
    } catch (e) {
      AppLogger.error('PaymentHistory 역매핑 오류', e, null, 'MYPAGE_MAPPER');
      rethrow;
    }
  }
}