import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/providers/api_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/transfer_provider.dart';
import '../../../transfer/data/models/transfer_models.dart';
import 'transfer_dialogs.dart';

class MyTransferManageScreen extends StatefulWidget {
  @override
  _MyTransferManageScreenState createState() => _MyTransferManageScreenState();
}

class _MyTransferManageScreenState extends State<MyTransferManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    print('🔥 DEBUG: _loadInitialData 시작');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );

    // AuthProvider에서 현재 사용자 ID 가져오기
    final currentUserId = authProvider.user?.userId;

    print('🔥 DEBUG: currentUserId = $currentUserId');

    if (currentUserId != null) {
      print('🔥 DEBUG: Future.wait 시작');
      await Future.wait([
        transferProvider.loadMyRegisteredTickets(
          userId: currentUserId,
          forceRefresh: true,
        ),
        transferProvider.loadMyTransferableTickets(
          userId: currentUserId,
          forceRefresh: true,
        ),
      ]);
    } else {
      // 로그인되지 않은 경우 처리
      print('❌ 로그인된 사용자가 없습니다');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인이 필요합니다'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '내 양도 관리',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: '양도 등록 내역'),
            Tab(text: '양도 가능 티켓'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTransferHistoryTab(), _buildAvailableTicketsTab()],
      ),
    );
  }

  Widget _buildTransferHistoryTab() {
    return Consumer<TransferProvider>(
      builder: (context, transferProvider, child) {
        // 로딩 상태
        if (transferProvider.isLoading &&
            transferProvider.myRegisteredTickets == null) {
          return _buildLoadingState('양도 등록 내역을 불러오는 중...');
        }

        // 에러 상태
        if (transferProvider.errorMessage != null) {
          return _buildErrorState(transferProvider.errorMessage!);
        }

        final registeredTickets = transferProvider.myRegisteredTickets ?? [];

        return Column(
          children: [
            _buildTransferSummary(registeredTickets),
            Expanded(
              child: registeredTickets.isEmpty
                  ? _buildEmptyState('등록된 양도 내역이 없습니다', '티켓을 양도 등록해보세요')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _refreshData,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: registeredTickets.length,
                        itemBuilder: (context, index) {
                          return _buildTransferHistoryCard(
                            registeredTickets[index],
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableTicketsTab() {
    return Consumer<TransferProvider>(
      builder: (context, transferProvider, child) {
        // 로딩 상태
        if (transferProvider.isLoading &&
            transferProvider.myTransferableTickets == null) {
          return _buildLoadingState('양도 가능한 티켓을 불러오는 중...');
        }

        // 에러 상태
        if (transferProvider.errorMessage != null) {
          return _buildErrorState(transferProvider.errorMessage!);
        }

        final transferableTickets =
            transferProvider.myTransferableTickets ?? [];

        return Column(
          children: [
            _buildTransferGuide(),
            Expanded(
              child: transferableTickets.isEmpty
                  ? _buildEmptyState('보유한 티켓이 없습니다', '티켓을 구매해보세요')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _refreshData,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: transferableTickets.length,
                        itemBuilder: (context, index) {
                          return _buildAvailableTicketCard(
                            transferableTickets[index],
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
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
              _refreshData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSummary(List<MyTransferTicket> tickets) {
    final activeCount = tickets
        .where((t) => t.transferStatus == 'pending')
        .length;
    final soldCount = tickets
        .where((t) => t.transferStatus == 'completed')
        .length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              '등록 중',
              activeCount.toString(),
              AppColors.warning,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _buildSummaryItem(
              '판매 완료',
              soldCount.toString(),
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTransferGuide() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                '양도 등록 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 모바일 신분증 인증 완료 후 양도 등록이 가능합니다\n• 공연 7일 전까지만 양도 등록할 수 있습니다\n• 양도 수수료는 10% 입니다',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferHistoryCard(MyTransferTicket ticket) {
    final sessionDate = DateTime.parse(ticket.sessionDatetime);
    final now = DateTime.now();
    final daysUntilSession = sessionDate.difference(now).inDays;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(ticket.transferStatus),
                Text(
                  '등록: ${_formatDateTime(DateTime.parse(ticket.createdDatetime))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 메인 콘텐츠
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // 포스터
                Container(
                  width: 60,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.gray300,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ticket.performanceMainImage != null
                        ? Image.network(
                            ticket.performanceMainImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.gray300,
                                child: Icon(
                                  Icons.broken_image,
                                  size: 20,
                                  color: AppColors.gray600,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.gray300,
                            child: Icon(
                              Icons.music_note,
                              size: 20,
                              color: AppColors.gray600,
                            ),
                          ),
                  ),
                ),

                SizedBox(width: 12),

                // 공연 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.performanceTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatSessionDateTime(sessionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${ticket.seatNumber} (${ticket.seatGrade})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(ticket.transferTicketPrice)}원',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ticket.canCancel)
            _buildActiveActions(ticket, daysUntilSession)
          else if (ticket.isCompleted)
            _buildSoldInfo(ticket),
        ],
      ),
    );
  }

  Widget _buildAvailableTicketCard(TransferableTicket ticket) {
    final sessionDate = DateTime.parse(ticket.sessionDatetime);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // 포스터
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.gray300,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ticket.performanceMainImage != null
                        ? Image.network(
                            ticket.performanceMainImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.gray300,
                                child: Icon(
                                  Icons.broken_image,
                                  size: 20,
                                  color: AppColors.gray600,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.gray300,
                            child: Icon(
                              Icons.music_note,
                              size: 20,
                              color: AppColors.gray600,
                            ),
                          ),
                  ),
                ),

                SizedBox(width: 12),

                // 공연 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.performanceTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatSessionDateTime(sessionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${ticket.seatNumber} (${ticket.seatGrade})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 가격
                Text(
                  '${_formatPrice(ticket.seatPrice)}원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ticket.isRegisterable
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showTransferOptions(ticket),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('양도 등록'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.block, size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.registerableStatusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = '등록 중';
        break;
      case 'in_progress':
        color = AppColors.secondary;
        text = '진행 중';
        break;
      case 'completed':
        color = AppColors.success;
        text = '판매 완료';
        break;
      case 'cancelled':
        color = AppColors.gray500;
        text = '취소됨';
        break;
      default:
        color = AppColors.gray500;
        text = '알 수 없음';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveActions(MyTransferTicket ticket, int daysUntilSession) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // 양도 방식 표시
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  ticket.isPublicTransfer ? Icons.public : Icons.lock,
                  size: 16,
                  color: ticket.isPublicTransfer
                      ? AppColors.primary
                      : AppColors.secondary,
                ),
                SizedBox(width: 8),
                Text(
                  ticket.transferTypeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!ticket.isPublicTransfer) ...[
                  Spacer(),
                  GestureDetector(
                    onTap: () => _showUniqueCode(ticket),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '고유번호 보기',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (daysUntilSession >= 0) ...[
                Icon(Icons.timer, size: 16, color: AppColors.warning),
                SizedBox(width: 4),
                Text(
                  daysUntilSession == 0 ? '오늘 공연' : '${daysUntilSession}일 후 공연',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
                Spacer(),
              ],

              TextButton(
                onPressed: () => _showEditDialog(ticket),
                child: Text(
                  '수정',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: () => _cancelTransfer(ticket),
                child: Text(
                  '취소',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoldInfo(MyTransferTicket ticket) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              ticket.finishedDatetime != null
                  ? '${_formatDateTime(DateTime.parse(ticket.finishedDatetime!))}에 판매 완료'
                  : '판매 완료',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  /// 고유번호 조회 및 표시
  Future<void> _showUniqueCode(MyTransferTicket ticket) async {
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );

    try {
      final uniqueCode = await transferProvider.getUniqueCode(
        ticket.transferTicketId,
      );

      if (uniqueCode != null && mounted) {
        TransferDialogs.showUniqueCodeDialog(
          context,
          uniqueCode.tempUniqueCode,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('고유번호를 불러오는데 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 양도 등록 옵션 표시
  void _showTransferOptions(TransferableTicket ticket) {
    // TODO: 실제 양도 등록 API 연결
    TransferDialogs.showTransferOptions(context, {
      'id': ticket.nftTicketId,
      'concertTitle': ticket.performanceTitle,
      'artist': ticket.performerName,
      'date': _formatSessionDateTime(DateTime.parse(ticket.sessionDatetime)),
      'seat': '${ticket.seatNumber} (${ticket.seatGrade})',
      'originalPrice': ticket.seatPrice,
    }, _registerTransfer);
  }

  /// 수정 다이얼로그 표시
  void _showEditDialog(MyTransferTicket ticket) {
    // TODO: 실제 수정 API 연결
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('수정 기능 준비 중입니다')));
  }

  /// 양도 등록 처리
  void _registerTransfer(
    Map<String, dynamic> ticket,
    String transferType,
    String? uniqueCode,
  ) {
    // TODO: 실제 양도 등록 API 호출
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('양도 등록이 완료되었습니다'),
        backgroundColor: AppColors.success,
      ),
    );

    // 데이터 새로고침
    _refreshData();
  }

  /// 양도 취소
  void _cancelTransfer(MyTransferTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('양도 취소'),
        content: Text('정말로 양도를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '아니요',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCancelTransfer(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('취소하기', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  /// 실제 양도 취소 수행
  Future<void> _performCancelTransfer(MyTransferTicket ticket) async {
    try {
      // TODO: 실제 양도 취소 API 호출
      // await transferService.cancelTransfer(ticket.transferTicketId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('양도가 취소되었습니다'),
          backgroundColor: AppColors.success,
        ),
      );

      // 데이터 새로고침
      await _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('양도 취소에 실패했습니다'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// 데이터 새로고침
  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );

    final currentUserId = authProvider.user?.userId;
    if (currentUserId != null) {
      await transferProvider.refreshData(userId: currentUserId);
    }
  }

  /// 시간 형식 변환
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 세션 날짜 시간 형식 변환
  String _formatSessionDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 가격 포맷팅
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
