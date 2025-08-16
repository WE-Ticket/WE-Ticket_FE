import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/mypage/data/payment_history_model.dart';
import 'package:we_ticket/shared/presentation/screens/ticket_detail_screen.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';
import '../../../../core/constants/app_colors.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  _PurchaseHistoryScreenState createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PaymentHistory> _paymentHistories = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _filterOptions = [
    '전체 거래',
    '구매 내역', // 예매 + 양도구매
    '판매 내역', // 양도판매 완료만
    '취소/환불',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // 탭이 변경될 때 데이터 리로드
      _loadPaymentHistoryForTab(_tabController.index);
    }
  }

  /// 결제 이력 로드
  Future<void> _loadPaymentHistory() async {
    await _loadPaymentHistoryForTab(_tabController.index);
  }

  /// 특정 탭에 대한 결제 이력 로드
  Future<void> _loadPaymentHistoryForTab(int tabIndex) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiProvider = Provider.of<ApiProvider>(context, listen: false);

      // 현재 사용자 ID 가져오기
      final userId = authProvider.currentUserId;
      if (userId == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final selectedFilter = _filterOptions[tabIndex];
      // API에서 결제 이력 가져오기
      final histories = await apiProvider.apiService.myTicket
          .getFilteredPaymentHistory(userId, selectedFilter);

      setState(() {
        _paymentHistories = histories;
        _isLoading = false;
      });

      print('✅ 결제 이력 로드 완료: ${histories.length}개');
    } catch (e) {
      setState(() {
        _errorMessage = '결제 이력을 불러올 수 없습니다: $e';
        _isLoading = false;
      });
      print('❌ 결제 이력 로드 실패: $e');
    }
  }


  /// 새로고침
  Future<void> _refreshData() async {
    await _loadPaymentHistory();
  }

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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _filterOptions.asMap().entries.map((entry) {
                return _buildContent();
              }).toList(),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              '결제 이력을 불러오는 중...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh),
              label: Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_paymentHistories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _paymentHistories.length,
        itemBuilder: (context, index) {
          final history = _paymentHistories[index];
          return _buildPaymentCard(history);
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        tabs: _filterOptions.map((filter) => Tab(
          child: Text(
            filter,
            style: TextStyle(fontSize: 14),
          ),
        )).toList(),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        isScrollable: false,
      ),
    );
  }

  Widget _buildPaymentCard(PaymentHistory history) {
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
                      image: NetworkImage(history.performanceMainImage),
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
                        history.performanceTitle,
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
                        history.performerName,
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
                            '${history.sessionDateDisplay} ${history.sessionTimeDisplay}',
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
                              history.venueName,
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

                _buildTransactionStatusBadge(history),
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
                      history.paymentNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                if (!history.isCancel) ...[
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
                        history.seatNumber,
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
                      _getPriceLabel(history),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      history.priceDisplay,
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
                      history.method,
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
                      _getDateLabel(history),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${history.paymentDateDisplay} ${history.paymentTimeDisplay}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // 거래 상태별 추가 정보
                ..._buildAdditionalInfo(history),

                SizedBox(height: 16),

                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTransactionDetail(history),
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

                    if (history.isPurchase || history.isTransferBuy)
                      if (history.isCompleted)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showTicketDetail(history),
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
                      else if (history.isInProgress &&
                          history.hasDepositDeadline)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDepositInfo(history),
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

  Widget _buildTransactionStatusBadge(PaymentHistory history) {
    Color backgroundColor;
    IconData icon;

    // 새로운 STATUS_CHOICES에 따른 상태별 배지 설정
    if (history.isCompleted) {
      backgroundColor = AppColors.success;
      icon = Icons.check_circle;
    } else if (history.isInProgress) {
      backgroundColor = AppColors.warning;
      icon = history.hasDepositDeadline
          ? Icons.schedule
          : Icons.hourglass_empty;
    } else {
      backgroundColor = AppColors.gray400;
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
            history.statusDisplay,
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

  List<Widget> _buildAdditionalInfo(PaymentHistory history) {
    List<Widget> widgets = [];

    // 입금 대기 상태 (isInProgress로 수정)
    if (history.isInProgress && history.hasDepositDeadline) {
      widgets.addAll([
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '입금 계좌',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              history.depositAccount!,
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
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              history.depositDeadline!,
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

    // 양도 완료 상태
    if (history.isTransferSell && history.hasTransferInfo) {
      widgets.addAll([
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '양도 완료일',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              history.transferFinishedDatetime!,
              style: TextStyle(fontSize: 12, color: AppColors.info),
            ),
          ],
        ),
      ]);
    }

    // 취소/환불 정보
    if (history.isCancel) {
      if (history.hasCancelInfo) {
        widgets.addAll([
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '취소 신청일',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                history.cancelRequestDatetime!,
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
        ]);

        if (history.cancelRequestReason != null) {
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
                  history.cancelRequestReason!,
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ],
            ),
          ]);
        }
      }

      if (history.hasRefundInfo) {
        widgets.addAll([
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '환불 완료일',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                history.refundFinishDatetime!, // 올바른 필드명 사용
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
          ),
        ]);
      }
    }

    return widgets;
  }

  String _getPriceLabel(PaymentHistory history) {
    if (history.isTransferSell) return '판매 금액';
    if (history.isCancel) return '환불 금액';
    return '결제 금액';
  }

  String _getDateLabel(PaymentHistory history) {
    if (history.isTransferSell) return '원 구매일';
    if (history.isCancel) return '구매일';
    return '거래일';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.gray400),

          SizedBox(height: 16),

          Text(
            '${_filterOptions[_tabController.index]} 내역이 없습니다',
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

  void _showTransactionDetail(PaymentHistory history) {
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
                        _buildDetailRow('공연명', history.performanceTitle),
                        _buildDetailRow('아티스트', history.performerName),
                        _buildDetailRow(
                          '공연 일시',
                          '${history.sessionDateDisplay} ${history.sessionTimeDisplay}',
                        ),
                        _buildDetailRow('공연 장소', history.venueName),
                        if (!history.isCancel)
                          _buildDetailRow('좌석 정보', history.seatNumber),
                      ]),

                      SizedBox(height: 24),

                      _buildDetailSection('거래 정보', [
                        _buildDetailRow('거래 상태', history.statusDisplay),
                        _buildDetailRow('거래 유형', history.typeDisplay),
                        _buildDetailRow('주문번호', history.paymentNumber),
                        _buildDetailRow('결제 금액', history.priceDisplay),
                        _buildDetailRow('결제 방법', history.method),
                        _buildDetailRow(
                          '결제일',
                          '${history.paymentDateDisplay} ${history.paymentTimeDisplay}',
                        ),
                        ..._buildDetailAdditionalInfo(history),
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

  List<Widget> _buildDetailAdditionalInfo(PaymentHistory history) {
    List<Widget> widgets = [];

    // 입금 정보
    if (history.hasDepositDeadline) {
      widgets.addAll([
        _buildDetailRow('입금 계좌', history.depositAccount!),
        _buildDetailRow('입금 마감', history.depositDeadline!),
      ]);
    }

    // 양도 정보
    if (history.hasTransferInfo) {
      widgets.add(_buildDetailRow('양도 완료일', history.transferFinishedDatetime!));
    }

    // 취소/환불 정보
    if (history.hasCancelInfo) {
      widgets.add(_buildDetailRow('취소 신청일', history.cancelRequestDatetime!));
      if (history.cancelRequestReason != null) {
        widgets.add(_buildDetailRow('취소 사유', history.cancelRequestReason!));
      }
    }

    if (history.hasRefundInfo) {
      widgets.add(
        _buildDetailRow('환불 완료일', history.refundFinishDatetime!), // 올바른 필드명 사용
      );
    }

    return widgets;
  }

  void _showDepositInfo(PaymentHistory history) {
    if (!history.hasDepositDeadline) return;

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
                        history.depositAccount!,
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
                        history.priceDisplay,
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
                        history.depositDeadline!,
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

  void _showTicketDetail(PaymentHistory history) {
    if (history.ticketId == null) return;

    // 티켓 상세 화면으로 이동
    final ticketData = {
      'id': history.ticketId.toString(),
      'title': history.performanceTitle,
      'artist': history.performerName,
      'date': history.sessionDateDisplay,
      'time': history.sessionTimeDisplay,
      'venue': history.venueName,
      'seat': history.seatNumber,
      'poster': history.performanceMainImage,
      'status': 'upcoming',
      'price': history.priceDisplay,
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticketData)),
    );
  }
}
