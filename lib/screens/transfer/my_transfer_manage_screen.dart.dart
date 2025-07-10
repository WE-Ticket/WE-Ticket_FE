import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import 'transfer_dialogs.dart';

class MyTransferManageScreen extends StatefulWidget {
  @override
  _MyTransferManageScreenState createState() => _MyTransferManageScreenState();
}

class _MyTransferManageScreenState extends State<MyTransferManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 더미 데이터 - 양도 등록 내역
  final List<Map<String, dynamic>> _myTransferTickets = [
    {
      'id': 'my_transfer_001',
      'concertTitle': 'IVE SHOW WHAT I HAVE',
      'artist': 'IVE',
      'date': '2025.07.28',
      'time': '18:00',
      'venue': '잠실실내체육관',
      'seat': 'R석 2층 B구역 5열 20번',
      'originalPrice': 132000,
      'transferPrice': 132000,
      'poster':
          'https://talkimg.imbc.com/TVianUpload/tvian/TViews/image/2025/05/22/0be8f4e2-5e79-4a67-b80c-b14654cf908c.jpg',
      'registeredAt': '2025.06.15 14:30',
      'status': 'active',
      'transferType': 'public',
      'uniqueCode': 'ABCD-1234-EFGH-5678',
      'viewCount': 15,
      'daysLeft': 12,
    },
    {
      'id': 'my_transfer_002',
      'concertTitle': 'SEVENTEEN GOD OF MUSIC',
      'artist': 'SEVENTEEN',
      'date': '2025.09.10',
      'time': '19:00',
      'venue': '고척스카이돔',
      'seat': 'VIP석 1층 C구역 1열 8번',
      'originalPrice': 165000,
      'transferPrice': 165000,
      'poster': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
      'registeredAt': '2025.06.20 09:15',
      'status': 'sold',
      'transferType': 'private',
      'soldAt': '2025.06.22 16:45',
      'buyerId': 'buyer123',
      'viewCount': 28,
      'uniqueCode': 'SOLD-5678-PRIV-9012',
    },
  ];

  // 더미 데이터 - 양도 가능한 티켓
  final List<Map<String, dynamic>> _availableTickets = [
    {
      'id': 'available_001',
      'concertTitle': 'NewJeans Get Up Concert',
      'artist': 'NewJeans',
      'date': '2025.08.15',
      'time': '19:00',
      'venue': 'KSPO DOME',
      'seat': 'VIP석 1층 A구역 2열 15번',
      'originalPrice': 154000,
      'poster':
          'https://tkfile.yes24.com/upload2/PerfBlog/202505/20250527/20250527-53911.jpg',
      'purchasedAt': '2025.06.10 20:00',
      'canTransfer': true,
    },
    {
      'id': 'available_002',
      'concertTitle': 'aespa MY WORLD TOUR',
      'artist': 'aespa',
      'date': '2025.07.05',
      'time': '19:00',
      'venue': 'KSPO DOME',
      'seat': 'R석 2층 A구역 3열 12번',
      'originalPrice': 132000,
      'poster':
          'https://ticketimage.interpark.com/Play/image/large/24/24013254_p.gif',
      'purchasedAt': '2025.06.05 15:30',
      'canTransfer': false,
      'reason': '공연 7일 전부터는 양도가 불가능합니다',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Column(
      children: [
        _buildTransferSummary(),
        Expanded(
          child: _myTransferTickets.isEmpty
              ? _buildEmptyState('등록된 양도 내역이 없습니다', '티켓을 양도 등록해보세요')
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _myTransferTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTransferHistoryCard(_myTransferTickets[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAvailableTicketsTab() {
    return Column(
      children: [
        _buildTransferGuide(),
        Expanded(
          child: _availableTickets.isEmpty
              ? _buildEmptyState('보유한 티켓이 없습니다', '티켓을 구매해보세요')
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _availableTickets.length,
                  itemBuilder: (context, index) {
                    return _buildAvailableTicketCard(_availableTickets[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransferSummary() {
    final activeCount = _myTransferTickets
        .where((t) => t['status'] == 'active')
        .length;
    final soldCount = _myTransferTickets
        .where((t) => t['status'] == 'sold')
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

  Widget _buildTransferHistoryCard(Map<String, dynamic> ticket) {
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
                _buildStatusBadge(ticket['status']),
                Text(
                  '등록: ${ticket['registeredAt']}',
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
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.gray300,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ticket['poster'],
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
                        ticket['concertTitle'],
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
                        '${ticket['date']} ${ticket['time']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        ticket['seat'],
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
                      '${_formatPrice(ticket['transferPrice'])}원',
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

          if (ticket['status'] == 'active')
            _buildActiveActions(ticket)
          else if (ticket['status'] == 'sold')
            _buildSoldInfo(ticket),
        ],
      ),
    );
  }

  Widget _buildAvailableTicketCard(Map<String, dynamic> ticket) {
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
                    child: Image.network(
                      ticket['poster'],
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
                        ticket['concertTitle'],
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
                        '${ticket['date']} ${ticket['time']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        ticket['seat'],
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
                  '${_formatPrice(ticket['originalPrice'])}원',
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
            child: ticket['canTransfer']
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
                          ticket['reason'] ?? '양도 불가',
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
      case 'active':
        color = AppColors.warning;
        text = '등록 중';
        break;
      case 'sold':
        color = AppColors.success;
        text = '판매 완료';
        break;
      case 'expired':
        color = AppColors.error;
        text = '만료됨';
        break;
      case 'cancelled':
        color = AppColors.gray500;
        text = '취소됨';
        break;
      default:
        color = AppColors.gray500;
        text = '    ';
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

  Widget _buildActiveActions(Map<String, dynamic> ticket) {
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
                  ticket['transferType'] == 'private'
                      ? Icons.lock
                      : Icons.public,
                  size: 16,
                  color: ticket['transferType'] == 'private'
                      ? AppColors.secondary
                      : AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  ticket['transferType'] == 'private' ? '비공개 양도' : '공개 양도',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (ticket['transferType'] == 'private') ...[
                  Spacer(),
                  GestureDetector(
                    onTap: () => TransferDialogs.showUniqueCodeDialog(
                      context,
                      ticket['uniqueCode'],
                    ),
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
            children: [
              if (ticket['daysLeft'] != null) ...[
                Icon(Icons.timer, size: 16, color: AppColors.warning),
                SizedBox(width: 4),
                Text(
                  '${ticket['daysLeft']}일 후 공연',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
                Spacer(),
              ],

              TextButton(
                onPressed: () => TransferDialogs.showEditTransferDialog(
                  context,
                  ticket,
                  _updateTicketData,
                ),
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

  Widget _buildSoldInfo(Map<String, dynamic> ticket) {
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
              '${ticket['soldAt']}에 판매 완료',
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

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showTransferOptions(Map<String, dynamic> ticket) {
    TransferDialogs.showTransferOptions(context, ticket, _registerTransfer);
  }

  void _registerTransfer(
    Map<String, dynamic> ticket,
    String transferType,
    String? uniqueCode,
  ) {
    setState(() {
      _myTransferTickets.add({
        ...ticket,
        'id': 'new_transfer_${DateTime.now().millisecondsSinceEpoch}',
        'registeredAt':
            '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'status': 'active',
        'transferType': transferType,
        'uniqueCode': uniqueCode,
        'viewCount': 0,
        'daysLeft': 15,
      });

      _availableTickets.removeWhere((t) => t['id'] == ticket['id']);
    });
  }

  void _updateTicketData(Map<String, dynamic> updatedTicket) {
    setState(() {
      final index = _myTransferTickets.indexWhere(
        (t) => t['id'] == updatedTicket['id'],
      );
      if (index != -1) {
        _myTransferTickets[index] = updatedTicket;
      }
    });
  }

  void _cancelTransfer(Map<String, dynamic> ticket) {
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
              setState(() {
                final index = _myTransferTickets.indexWhere(
                  (t) => t['id'] == ticket['id'],
                );
                if (index != -1) {
                  _myTransferTickets[index]['status'] = 'cancelled';
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('양도가 취소되었습니다'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('취소하기', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
