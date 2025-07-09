import 'package:flutter/material.dart';
import 'package:we_ticket/screens/mypage/ticket_detail_screen.dart';
import '../../utils/app_colors.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  _PurchaseHistoryScreenState createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  String _selectedFilter = '전체 거래';

  final List<String> _filterOptions = [
    '전체 거래',
    '구매 내역', // 예매 + 양도구매
    '판매 내역', // 양도판매 완료만
    '취소/환불',
  ];

  // FIXME: 더미 데이터 - 실제로는 API에서 가져올 예정
  final List<Map<String, dynamic>> _purchaseHistory = [
    // 티켓 예매 - 결제 완료 (구매 내역)
    {
      'id': 'order_001',
      'ticketId': 'ticket_1',
      'title': '2025 RIIZE CONCERT TOUR',
      'artist': 'RIIZE',
      'date': '2025.07.04',
      'time': '20:00',
      'venue': 'KSPO DOME',
      'seat': 'S석 1층 A구역 3열 15번',
      'poster':
          'https://talkimg.imbc.com/TVianUpload/tvian/TViews/image/2025/05/22/0be8f4e2-5e79-4a67-b80c-b14654cf908c.jpg',
      'purchaseDate': '2025.06.20',
      'purchaseTime': '14:30',
      'price': 154000,
      'paymentMethod': '카카오페이',
      'type': 'purchase',
      'status':
          'payment_completed', // payment_pending, payment_completed, used, transferred
      'orderNumber': 'ORD202506201430001',
    },

    // 무통장 입금 - 입금 대기 중 (구매 내역)
    {
      'id': 'order_002',
      'ticketId': 'ticket_2',
      'title': 'NewJeans Fan Meeting',
      'artist': 'NewJeans',
      'date': '2025.07.25',
      'time': '19:00',
      'venue': '올림픽공원 체조경기장',
      'seat': 'VIP석 1층 B구역 5열 8번',
      'poster':
          'https://img4.yna.co.kr/etc/inner/KR/2024/06/25/AKR20240625045000005_01_i_P4.jpg',
      'purchaseDate': '2025.06.15',
      'purchaseTime': '10:45',
      'price': 88000,
      'paymentMethod': '무통장입금',
      'type': 'purchase',
      'status': 'payment_pending',
      'orderNumber': 'ORD202506151045002',
      'depositAccount': '신한은행 100-123-456789',
      'depositDeadline': '2025.06.17 23:59',
    },

    // 양도 구매 - 완료 (구매 내역)
    {
      'id': 'order_003',
      'ticketId': 'ticket_3',
      'title': 'aespa MY WORLD TOUR',
      'artist': 'aespa',
      'date': '2025.08.10',
      'time': '19:00',
      'venue': 'KSPO DOME',
      'seat': 'VIP석 1층 B구역 2열 10번',
      'poster': 'https://example.com/aespa_poster.jpg',
      'purchaseDate': '2025.06.25',
      'purchaseTime': '16:20',
      'price': 165000,
      'paymentMethod': '신용카드',
      'type': 'transfer_buy',
      'status': 'payment_completed',
      'orderNumber': 'TRF202506251620003',
    },

    // 양도 판매 - 완료 (판매 내역)
    {
      'id': 'order_004',
      'ticketId': 'ticket_4',
      'title': 'SEVENTEEN CONCERT',
      'artist': 'SEVENTEEN',
      'date': '2025.05.10',
      'time': '18:00',
      'venue': 'KSPO DOME',
      'seat': 'R석 2층 C구역 10열 20번',
      'poster': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
      'purchaseDate': '2025.04.01',
      'purchaseTime': '09:00',
      'transferDate': '2025.04.25',
      'transferTime': '15:30',
      'price': 132000,
      'paymentMethod': '네이버페이',
      'type': 'transfer_sell',
      'status': 'transferred',
      'orderNumber': 'ORD202504010900004',
      'transferOrderNumber': 'TRF202504251530004',
    },

    // 취소/환불 - 환불 완료
    {
      'id': 'order_005',
      'ticketId': 'ticket_5',
      'title': 'IU CONCERT 2025',
      'artist': 'IU',
      'date': '2025.08.15',
      'time': '19:00',
      'venue': '잠실실내체육관',
      'seat': 'VIP석 1층 A구역 1열 5번',
      'poster': 'https://example.com/iu_poster.jpg',
      'purchaseDate': '2025.06.01',
      'purchaseTime': '11:00',
      'cancelDate': '2025.06.10',
      'cancelTime': '16:20',
      'refundDate': '2025.06.12',
      'refundTime': '14:30',
      'price': 220000,
      'refundAmount': 198000,
      'paymentMethod': '신용카드',
      'type': 'cancel',
      'status': 'refund_completed', // refund_pending, refund_completed
      'orderNumber': 'ORD202506011100005',
      'cancelReason': '개인 사정',
    },

    // 취소/환불 - 환불 대기 중
    {
      'id': 'order_006',
      'ticketId': 'ticket_6',
      'title': 'BTS CONCERT 2025',
      'artist': 'BTS',
      'date': '2025.09.20',
      'time': '19:00',
      'venue': '월드컵경기장',
      'seat': 'S석 1층 A구역 5열 12번',
      'poster': 'https://example.com/bts_poster.jpg',
      'purchaseDate': '2025.06.05',
      'purchaseTime': '15:20',
      'cancelDate': '2025.06.22',
      'cancelTime': '10:15',
      'price': 280000,
      'refundAmount': 252000,
      'paymentMethod': '신용카드',
      'type': 'cancel',
      'status': 'refund_pending',
      'orderNumber': 'ORD202506051520006',
      'cancelReason': '일정 변경',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '구매 이력',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),

          // 구매 이력 리스트
          Expanded(
            child: _filteredHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final purchase = _filteredHistory[index];
                      return _buildPurchaseCard(purchase);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            bool isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredHistory {
    switch (_selectedFilter) {
      case '구매 내역':
        return _purchaseHistory
            .where(
              (item) =>
                  item['type'] == 'purchase' || item['type'] == 'transfer_buy',
            )
            .toList();
      case '판매 내역':
        return _purchaseHistory
            .where((item) => item['type'] == 'transfer_sell')
            .toList();
      case '취소/환불':
        return _purchaseHistory
            .where((item) => item['type'] == 'cancel')
            .toList();
      default: // 전체 거래
        return _purchaseHistory;
    }
  }

  Widget _buildPurchaseCard(Map<String, dynamic> purchase) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 공연 정보
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(purchase['poster']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4),

                      Text(
                        purchase['artist'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${purchase['date']} ${purchase['time']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              purchase['venue'],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildTransactionStatusBadge(
                  purchase['status'],
                  purchase['type'],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // 하단: 거래 정보
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '주문번호',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      purchase['orderNumber'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                if (purchase['type'] != 'cancel') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '좌석 정보',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        purchase['seat'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getPriceLabel(purchase['status']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getFormattedPrice(purchase),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '결제 방법',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      purchase['paymentMethod'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getDateLabel(purchase['status']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getFormattedDate(purchase),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // 거래 상태별 추가 정보
                ..._buildAdditionalInfo(purchase),

                SizedBox(height: 16),

                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTransactionDetail(purchase),
                        icon: Icon(Icons.receipt_long, size: 16),
                        label: Text('거래 상세', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    if (purchase['type'] == 'purchase' ||
                        purchase['type'] == 'transfer_buy')
                      if (purchase['status'] == 'payment_completed')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showTicketDetail(purchase),
                            icon: Icon(Icons.confirmation_number, size: 16),
                            label: Text(
                              '티켓 보기',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        )
                      else if (purchase['status'] == 'payment_pending')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDepositInfo(purchase),
                            icon: Icon(Icons.account_balance, size: 16),
                            label: Text(
                              '입금 안내',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStatusBadge(String status, String type) {
    Color backgroundColor;
    String text;
    IconData icon;

    // 상태별 배지 설정
    switch (status) {
      case 'payment_pending':
        backgroundColor = AppColors.warning;
        text = '입금 대기';
        icon = Icons.schedule;
        break;
      case 'payment_completed':
        backgroundColor = AppColors.success;
        text = type == 'purchase'
            ? '예매 완료'
            : type == 'transfer_buy'
            ? '양도구매 완료'
            : '완료';
        icon = Icons.check_circle;
        break;
      case 'used':
        backgroundColor = AppColors.primary;
        text = '사용 완료';
        icon = Icons.confirmation_number;
        break;
      case 'transferred':
        backgroundColor = AppColors.info;
        text = '양도 완료';
        icon = Icons.swap_horiz;
        break;
      case 'refund_pending':
        backgroundColor = AppColors.warning;
        text = '환불 대기';
        icon = Icons.hourglass_empty;
        break;
      case 'refund_completed':
        backgroundColor = AppColors.error;
        text = '환불 완료';
        icon = Icons.money_off;
        break;
      default:
        backgroundColor = AppColors.gray400;
        text = '알 수 없음';
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdditionalInfo(Map<String, dynamic> purchase) {
    List<Widget> widgets = [];

    switch (purchase['status']) {
      case 'payment_pending':
        if (purchase['depositAccount'] != null &&
            purchase['depositDeadline'] != null) {
          widgets.addAll([
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '입금 계좌',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  purchase['depositAccount'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '입금 마감',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  purchase['depositDeadline'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ]);
        }
        break;

      case 'transferred':
        if (purchase['transferDate'] != null) {
          widgets.addAll([
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '양도 완료일',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${purchase['transferDate']} ${purchase['transferTime']}',
                  style: TextStyle(fontSize: 12, color: AppColors.info),
                ),
              ],
            ),
            if (purchase['transferOrderNumber'] != null) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '양도 주문번호',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    purchase['transferOrderNumber'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ]);
        }
        break;

      case 'refund_pending':
        if (purchase['cancelDate'] != null) {
          widgets.addAll([
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '취소 신청일',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${purchase['cancelDate']} ${purchase['cancelTime']}',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '처리 상태',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '환불 처리 중',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ]);
        }
        break;

      case 'refund_completed':
        if (purchase['cancelDate'] != null && purchase['refundDate'] != null) {
          widgets.addAll([
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '취소 신청일',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${purchase['cancelDate']} ${purchase['cancelTime']}',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '환불 완료일',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${purchase['refundDate']} ${purchase['refundTime']}',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ]);
        }
        if (purchase['cancelReason'] != null) {
          widgets.addAll([
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '취소 사유',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  purchase['cancelReason'],
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ],
            ),
          ]);
        }
        break;
    }

    return widgets;
  }

  String _getPriceLabel(String status) {
    switch (status) {
      case 'transferred':
        return '판매 금액';
      case 'refund_pending':
      case 'refund_completed':
        return '환불 금액';
      default:
        return '결제 금액';
    }
  }

  String _getFormattedPrice(Map<String, dynamic> purchase) {
    int amount;
    if ((purchase['status'] == 'refund_pending' ||
            purchase['status'] == 'refund_completed') &&
        purchase['refundAmount'] != null) {
      amount = purchase['refundAmount'];
    } else {
      amount = purchase['price'];
    }
    return '${_formatPrice(amount)}원';
  }

  String _getDateLabel(String status) {
    switch (status) {
      case 'transferred':
        return '원 구매일';
      case 'refund_pending':
      case 'refund_completed':
        return '구매일';
      default:
        return '거래일';
    }
  }

  String _getFormattedDate(Map<String, dynamic> purchase) {
    return '${purchase['purchaseDate']} ${purchase['purchaseTime']}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.gray400),

          SizedBox(height: 16),

          Text(
            '$_selectedFilter 내역이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 8),

          Text(
            '새로운 공연을 예매해보세요!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),

          SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.shopping_cart),
            label: Text('티켓 구매하러 가기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showTransactionDetail(Map<String, dynamic> purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '거래 상세 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('공연 정보', [
                        _buildDetailRow('공연명', purchase['title']),
                        _buildDetailRow('아티스트', purchase['artist']),
                        _buildDetailRow(
                          '공연 일시',
                          '${purchase['date']} ${purchase['time']}',
                        ),
                        _buildDetailRow('공연 장소', purchase['venue']),
                        if (purchase['type'] != 'cancel')
                          _buildDetailRow('좌석 정보', purchase['seat']),
                      ]),

                      SizedBox(height: 24),

                      _buildDetailSection('거래 정보', [
                        _buildDetailRow(
                          '거래 상태',
                          _getTransactionStatusText(
                            purchase['status'],
                            purchase['type'],
                          ),
                        ),
                        _buildDetailRow('주문번호', purchase['orderNumber']),
                        _buildDetailRow(
                          _getPriceLabel(purchase['status']),
                          _getFormattedPrice(purchase),
                        ),
                        _buildDetailRow('결제 방법', purchase['paymentMethod']),
                        _buildDetailRow(
                          _getDateLabel(purchase['status']),
                          _getFormattedDate(purchase),
                        ),
                        ..._buildDetailAdditionalInfo(purchase),
                      ]),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailAdditionalInfo(Map<String, dynamic> purchase) {
    List<Widget> widgets = [];

    switch (purchase['status']) {
      case 'payment_pending':
        if (purchase['depositAccount'] != null) {
          widgets.addAll([
            _buildDetailRow('입금 계좌', purchase['depositAccount']),
            _buildDetailRow('입금 마감', purchase['depositDeadline']),
          ]);
        }
        break;

      case 'transferred':
        if (purchase['transferDate'] != null) {
          widgets.addAll([
            _buildDetailRow(
              '양도 완료일',
              '${purchase['transferDate']} ${purchase['transferTime']}',
            ),
            if (purchase['transferOrderNumber'] != null)
              _buildDetailRow('양도 주문번호', purchase['transferOrderNumber']),
          ]);
        }
        break;

      case 'refund_pending':
        if (purchase['cancelDate'] != null) {
          widgets.addAll([
            _buildDetailRow(
              '취소 신청일',
              '${purchase['cancelDate']} ${purchase['cancelTime']}',
            ),
            _buildDetailRow('처리 상태', '환불 처리 중'),
            if (purchase['cancelReason'] != null)
              _buildDetailRow('취소 사유', purchase['cancelReason']),
          ]);
        }
        break;

      case 'refund_completed':
        if (purchase['cancelDate'] != null) {
          widgets.addAll([
            _buildDetailRow(
              '취소 신청일',
              '${purchase['cancelDate']} ${purchase['cancelTime']}',
            ),
            if (purchase['refundDate'] != null)
              _buildDetailRow(
                '환불 완료일',
                '${purchase['refundDate']} ${purchase['refundTime']}',
              ),
            if (purchase['cancelReason'] != null)
              _buildDetailRow('취소 사유', purchase['cancelReason']),
            _buildDetailRow('원 결제금액', '${_formatPrice(purchase['price'])}원'),
          ]);
        }
        break;
    }

    return widgets;
  }

  String _getTransactionStatusText(String status, String type) {
    switch (status) {
      case 'payment_pending':
        return '입금 대기 중';
      case 'payment_completed':
        return type == 'purchase'
            ? '티켓 예매'
            : type == 'transfer_buy'
            ? '양도 구매'
            : '거래 완료';
      case 'used':
        return '티켓 사용 완료';
      case 'transferred':
        return '양도 판매 완료';
      case 'refund_pending':
        return '환불 처리 중';
      case 'refund_completed':
        return '취소/환불 완료';
      default:
        return '알 수 없음';
    }
  }

  void _showDepositInfo(Map<String, dynamic> purchase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.warning, size: 24),
                SizedBox(width: 12),
                Text(
                  '입금 안내',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '입금 정보',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '입금 계좌',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        purchase['depositAccount'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '입금 금액',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_formatPrice(purchase['price'])}원',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '입금 마감',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        purchase['depositDeadline'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '입금 마감 시간 내에 정확한 금액을 입금해주세요.\n입금자명은 예매자명과 동일해야 합니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTicketDetail(Map<String, dynamic> purchase) {
    // 티켓 상세 화면으로 이동
    final ticketData = {
      'id': purchase['ticketId'],
      'title': purchase['title'],
      'artist': purchase['artist'],
      'date': purchase['date'],
      'time': purchase['time'],
      'venue': purchase['venue'],
      'seat': purchase['seat'],
      'poster': purchase['poster'],
      'status': 'upcoming',
      'price': '${_formatPrice(purchase['price'])}원',
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticketData)),
    );
  }
}
