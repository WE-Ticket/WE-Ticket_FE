import 'package:flutter/material.dart';
import 'package:we_ticket/screens/transfer/my_transfer_manage_screen.dart.dart';
import '../../utils/app_colors.dart';
import '../../utils/auth_guard.dart';
import 'transfer_detail_screen.dart';
import 'private_transfer_screen.dart';
// import 'my_transfer_manage_screen.dart';

class TransferMarketScreen extends StatefulWidget {
  @override
  _TransferMarketScreenState createState() => _TransferMarketScreenState();
}

class _TransferMarketScreenState extends State<TransferMarketScreen> {
  String _selectedFilter = '전체보기';
  final List<String> _filterOptions = ['전체보기', '공연별로 보기'];

  // 더미 데이터 - 실제로는 API에서 가져올 예정
  final List<Map<String, dynamic>> _transferTickets = [
    {
      'id': 'transfer_001',
      'concertTitle': 'NewJeans Get Up Concert',
      'artist': 'NewJeans',
      'date': '2025.08.15',
      'time': '19:00',
      'venue': 'KSPO DOME',
      'location': '서울',
      'seat': 'VIP석 1층 A구역 2열 15번',
      'originalPrice': 154000,
      'transferPrice': 154000,
      'poster': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
      'transferTime': '3시간 전',
      'sellerId': 'user123',
      'status': 'available',
    },
    {
      'id': 'transfer_002',
      'concertTitle': 'IVE SHOW WHAT I HAVE',
      'artist': 'IVE',
      'date': '2025.07.28',
      'time': '18:00',
      'venue': '잠실실내체육관',
      'location': '서울',
      'seat': 'R석 2층 B구역 5열 20번',
      'originalPrice': 132000,
      'transferPrice': 132000,
      'poster': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
      'transferTime': '1일 전',
      'sellerId': 'user456',
      'status': 'available',
    },
    {
      'id': 'transfer_003',
      'concertTitle': 'SEVENTEEN GOD OF MUSIC',
      'artist': 'SEVENTEEN',
      'date': '2025.09.10',
      'time': '19:00',
      'venue': '고척스카이돔',
      'location': '서울',
      'seat': 'VIP석 1층 C구역 1열 8번',
      'originalPrice': 165000,
      'transferPrice': 165000,
      'poster': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
      'transferTime': '5시간 전',
      'sellerId': 'user789',
      'status': 'available',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '양도 마켓',
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
            onPressed: _refreshTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPurposeHeader(),

          _buildFilterAndActions(),

          Expanded(child: _buildTransferTicketList()),
        ],
      ),
    );
  }

  Widget _buildPurposeHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 15),
          SizedBox(width: 6),
          Text(
            '모바일 신분증 인증이 완료된 사용자만 양도 거래가 가능합니다.',
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndActions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      items: _filterOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFilter = newValue!;
                        });
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  SizedBox(width: 4),

                  GestureDetector(
                    onTap: () {
                      AuthGuard.requireAuth(
                        context,
                        onAuthenticated: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyTransferManageScreen(),
                            ),
                          );
                        },
                        message: '양도 관리는 로그인이 필요합니다',
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 45,
                      height: 45,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray300),
                      ),
                      child: Icon(Icons.person, color: AppColors.secondary),
                    ),
                  ),

                  SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      AuthGuard.requireAuth(
                        context,
                        onAuthenticated: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivateTransferScreen(),
                            ),
                          );
                        },
                        message: '비공개 양도는 로그인이 필요합니다',
                      );
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray300),
                      ),
                      child: Icon(Icons.lock, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferTicketList() {
    if (_transferTickets.isEmpty) {
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
              '현재 양도 중인 티켓이 없습니다',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              '새로고침을 통해 최신 목록을 확인해보세요',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.warning,
      onRefresh: _refreshTickets,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _transferTickets.length,
        itemBuilder: (context, index) {
          final ticket = _transferTickets[index];
          return _buildTransferTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTransferTicketCard(Map<String, dynamic> ticket) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransferDetailScreen(ticket: ticket),
          ),
        );
      },
      child: Container(
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
                  SizedBox(),
                  // 양도 등록 시간
                  Text(
                    '${ticket['transferTime']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // 포스터 이미지
                  Container(
                    width: 80,
                    height: 80,
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
                              size: 30,
                              color: AppColors.gray600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // 공연 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket['concertTitle'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4),

                        Text(
                          ticket['artist'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: 8),

                        _buildInfoRow(
                          Icons.calendar_today,
                          '${ticket['date']} ${ticket['time']}',
                        ),
                        SizedBox(height: 4),
                        _buildInfoRow(Icons.location_on, '${ticket['venue']}'),
                      ],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좌석 등급
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '좌석 정보',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        ticket['seat'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warningDark,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '양도 가격',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${_formatPrice(ticket['transferPrice'])}원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _refreshTickets() async {
    // TODO: 실제로는 API 호출하여 최신 양도 티켓 목록을 가져옴
    await Future.delayed(Duration(seconds: 1));
  }
}
