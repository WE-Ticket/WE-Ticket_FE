import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/shared/data/models/patment_data.dart';
import 'package:we_ticket/shared/presentation/screens/payment_webview_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_guard.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/transfer_provider.dart';
import '../../data/transfer_models.dart';

class TransferDetailScreen extends StatefulWidget {
  final int transferTicketId;

  const TransferDetailScreen({Key? key, required this.transferTicketId})
    : super(key: key);

  @override
  _TransferDetailScreenState createState() => _TransferDetailScreenState();
}

class _TransferDetailScreenState extends State<TransferDetailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransferDetail();
    });
  }

  /// 양도 티켓 상세 정보 로드
  Future<void> _loadTransferDetail() async {
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );
    await transferProvider.loadPublicTransferDetail(widget.transferTicketId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TransferProvider>(
        builder: (context, transferProvider, child) {
          // 로딩 상태
          if (transferProvider.isLoading &&
              transferProvider.currentTransferDetail == null) {
            return _buildLoadingState();
          }

          // 에러 상태
          if (transferProvider.errorMessage != null) {
            return _buildErrorState(transferProvider.errorMessage!);
          }

          final ticketDetail = transferProvider.currentTransferDetail;
          if (ticketDetail == null) {
            return _buildErrorState('양도 티켓 정보를 찾을 수 없습니다.');
          }

          return _buildDetailContent(ticketDetail);
        },
      ),
      bottomNavigationBar: Consumer<TransferProvider>(
        builder: (context, transferProvider, child) {
          if (transferProvider.currentTransferDetail != null) {
            return _buildBottomButton();
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '양도 티켓 상세',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              '양도 티켓 정보를 불러오는 중...',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '양도 티켓 상세',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 16, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final transferProvider = Provider.of<TransferProvider>(
                  context,
                  listen: false,
                );
                transferProvider.clearError();
                _loadTransferDetail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(TransferTicketDetail ticketDetail) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.white),
              onPressed: _loadTransferDetail,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                ticketDetail.performanceMainImage != null
                    ? Image.network(
                        ticketDetail.performanceMainImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.gray300,
                            child: Icon(
                              Icons.broken_image,
                              size: 100,
                              color: AppColors.gray600,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.gray300,
                        child: Icon(
                          Icons.music_note,
                          size: 100,
                          color: AppColors.gray600,
                        ),
                      ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 내용
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildBasicInfoSection(ticketDetail),
              SizedBox(height: 12),
              _buildTransferInfoSection(ticketDetail),
              SizedBox(height: 12),
              _buildNoticeSection(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(TransferTicketDetail ticketDetail) {
    final sessionDate = DateTime.parse(ticketDetail.sessionDatetime);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticketDetail.performanceTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 8),

          Text(
            ticketDetail.performerName,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),

          SizedBox(height: 16),

          _buildDetailRow(
            Icons.calendar_today,
            '공연 일시',
            _formatSessionDateTime(sessionDate),
          ),
          _buildDetailRow(
            Icons.location_on,
            '공연 장소',
            '${ticketDetail.venueName}\n${ticketDetail.venueLocation}',
          ),
          _buildDetailRow(
            Icons.event_seat,
            '좌석 정보',
            '${ticketDetail.seatNumber} (${ticketDetail.seatGrade})',
          ),
          _buildDetailRow(
            Icons.access_time,
            '양도 등록',
            _formatTimeAgo(DateTime.parse(ticketDetail.createdDatetime)),
          ),

          // 비공개 양도인 경우 고유번호 정보 표시
          if (ticketDetail.isPrivateTransfer) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '비공개 양도',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        if (ticketDetail.codeExpiryDatetime != null)
                          Text(
                            '고유번호 만료: ${_formatDateTime(DateTime.parse(ticketDetail.codeExpiryDatetime!))}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferInfoSection(TransferTicketDetail ticketDetail) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Text(
                '양도 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            '${ticketDetail.seatNumber} (${ticketDetail.seatGrade})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.warningDark,
            ),
          ),

          SizedBox(height: 12),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '원가',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatPrice(ticketDetail.seatPrice),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '양도 가격',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ticketDetail.transferPriceDisplay,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Divider(color: AppColors.border),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '구매자 수수료 (10%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      ticketDetail.buyerFeeDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
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
                      '최종 결제 금액',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ticketDetail.totalPriceDisplay,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.secondaryDark,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '양도 구매 시 주의사항',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          _buildNoticeItem('• 모바일 신분증 인증이 완료된 사용자만 구매 가능합니다.'),
          _buildNoticeItem('• 양도 완료 후 티켓 소유권이 즉시 이전되며, 취소가 불가능합니다.'),
          _buildNoticeItem('• 구매자 수수료 10%가 별도로 부과됩니다.'),
          _buildNoticeItem('• 불법 양도 신고 시 영구 이용 제한될 수 있습니다.'),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Consumer<TransferProvider>(
      builder: (context, transferProvider, child) {
        final ticketDetail = transferProvider.currentTransferDetail;
        if (ticketDetail == null) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '최종 결제 금액',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        ticketDetail.totalPriceDisplay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: !_isLoading
                        ? () => _handlePurchase(ticketDetail)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '구매하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePurchase(TransferTicketDetail ticketDetail) {
    AuthGuard.requireAuth(
      context,
      onAuthenticated: () {
        setState(() {
          _isLoading = true;
        });
        print("티켓 데이타 : $ticketDetail");

        // TODO: DID 인증 상태 확인
        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            _isLoading = false;
          });

          // 현재 사용자 ID 가져오기
          final authProvider = context.read<AuthProvider>();
          final buyerUserId = authProvider.currentUserId ?? 0;

          // 새로운 PaymentData 모델 사용
          final paymentData = TransferPaymentData(
            merchantUid:
                'TRF_${ticketDetail.transferTicketId}_${DateTime.now().millisecondsSinceEpoch}',
            amount: ticketDetail.totalPrice,
            transferTicketId: ticketDetail.transferTicketId,
            performanceTitle: ticketDetail.performanceTitle,
            performerName: ticketDetail.performerName,
            sessionDatetime: ticketDetail.sessionDatetime,
            venueName: ticketDetail.venueName,
            seatNumber: ticketDetail.seatNumber,
            seatGrade: ticketDetail.seatGrade,
            transferPrice: ticketDetail.transferTicketPrice,
            buyerFee: ticketDetail.transferBuyerFee,
            totalPrice: ticketDetail.totalPrice,
            transferPriceDisplay: ticketDetail.transferPriceDisplay,
            buyerFeeDisplay: ticketDetail.buyerFeeDisplay,
            totalPriceDisplay: ticketDetail.totalPriceDisplay,
            isPrivateTransfer: ticketDetail.isPrivateTransfer,
            buyerUserId: buyerUserId,
          );

          print("페이먼트 데이타 : $paymentData");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentWebViewScreen(paymentData: paymentData),
            ),
          );
        });
      },
      message: '양도 티켓 구매는 로그인이 필요합니다',
    );
  }

  /// 시간 형식 변환
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  /// 세션 날짜 시간 형식 변환
  String _formatSessionDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 날짜 시간 형식 변환
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 가격 포맷팅
  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }
}
