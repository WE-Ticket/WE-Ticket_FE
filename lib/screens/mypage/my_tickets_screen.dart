import 'package:flutter/material.dart';
import 'package:we_ticket/screens/mypage/ticket_detail_screen.dart';
import '../../utils/app_colors.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({Key? key}) : super(key: key);

  @override
  _MyTicketsScreenState createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  String _selectedFilter = '전체 보유';

  final List<String> _filterOptions = ['전체 보유', '입장 예정', '양도 등록 중', '사용 완료'];

  // FIXME: 더미 데이터 - 실제로는 API에서 가져올 예정
  final List<Map<String, dynamic>> _activeTickets = [
    {
      'id': 'ticket_1',
      'title': '2025 RIIZE CONCERT TOUR',
      'artist': 'RIIZE',
      'date': '2025.07.04',
      'time': '20:00',
      'venue': 'KSPO DOME',
      'seat': 'S석 1층 A구역 3열 15번',
      'poster':
          'https://talkimg.imbc.com/TVianUpload/tvian/TViews/image/2025/05/22/0be8f4e2-5e79-4a67-b80c-b14654cf908c.jpg',
      'status': 'upcoming', // upcoming, transferring, used
      'dday': 15,
      'price': '154,000원',
    },
    {
      'id': 'ticket_2',
      'title': 'NewJeans Fan Meeting',
      'artist': 'NewJeans',
      'date': '2025.07.25',
      'time': '19:00',
      'venue': '올림픽공원 체조경기장',
      'seat': 'VIP석 1층 B구역 5열 8번',
      'poster':
          'https://img4.yna.co.kr/etc/inner/KR/2024/06/25/AKR20240625045000005_01_i_P4.jpg',
      'status': 'transferring',
      'dday': 36,
      'price': '88,000원',
    },
    {
      'id': 'ticket_3',
      'title': 'SEVENTEEN CONCERT',
      'artist': 'SEVENTEEN',
      'date': '2025.05.10',
      'time': '18:00',
      'venue': 'KSPO DOME',
      'seat': 'R석 2층 C구역 10열 20번',
      'poster': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
      'status': 'used',
      'dday': -60, // 과거 공연
      'price': '132,000원',
      'usedDate': '2025.05.10',
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
          '내 티켓 관리',
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

          // 티켓 카드 리스트
          Expanded(
            child: _filteredTickets.isEmpty
                ? _buildEmptyFilter()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _filteredTickets[index];
                      return _buildTicketCard(ticket);
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
      child: Row(
        children: _filterOptions.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
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
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredTickets {
    switch (_selectedFilter) {
      case '입장 예정':
        return _activeTickets
            .where((ticket) => ticket['status'] == 'upcoming')
            .toList();
      case '양도 등록 중':
        return _activeTickets
            .where((ticket) => ticket['status'] == 'transferring')
            .toList();
      case '사용 완료':
        return _activeTickets
            .where((ticket) => ticket['status'] == 'used')
            .toList();
      default: // 전체 보유
        return _activeTickets;
    }
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
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
                      image: NetworkImage(ticket['poster']),
                      fit: BoxFit.cover,
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
                        ticket['title'],
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
                        ticket['artist'],
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
                            '${ticket['date']} ${ticket['time']}',
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
                              ticket['venue'],
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

                Column(
                  children: [
                    _buildStatusBadge(ticket['status']),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDdayColor(ticket['dday']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getDdayText(ticket['dday'], ticket['status']),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getDdayColor(ticket['dday']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // 좌석 정보 및 액션 버튼
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '좌석 정보',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                Text(
                  ticket['seat'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 12),

                // 상태별 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTicketDetail(ticket),
                        icon: Icon(Icons.confirmation_number, size: 16),
                        label: Text('티켓 보기', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    Expanded(child: _buildSecondaryActionButton(ticket)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton(Map<String, dynamic> ticket) {
    switch (ticket['status']) {
      case 'upcoming':
        return ElevatedButton.icon(
          onPressed: () => _handleTransfer(ticket),
          icon: Icon(Icons.swap_horiz, size: 16),
          label: Text('양도하기', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
        );
      case 'transferring':
        return ElevatedButton.icon(
          onPressed: () => _handleTransferManage(ticket),
          icon: Icon(Icons.settings, size: 16),
          label: Text('양도 관리', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
        );
      case 'used':
        return ElevatedButton.icon(
          onPressed: () => _showUsedTicketInfo(ticket),
          icon: Icon(Icons.history, size: 16),
          label: Text('입장 기록', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    String text;

    switch (status) {
      case 'upcoming':
        backgroundColor = AppColors.success;
        text = '입장 예정';
        break;
      case 'transferring':
        backgroundColor = AppColors.warning;
        text = '양도 중';
        break;
      case 'used':
        backgroundColor = AppColors.primary;
        text = '사용 완료';
        break;
      default:
        backgroundColor = AppColors.gray400;
        text = '알 수 없음';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
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

  Color _getDdayColor(int dday) {
    if (dday < 0) return AppColors.secondary; // 과거
    if (dday <= 7) return AppColors.error; // 임박
    if (dday <= 30) return AppColors.warning; // 한 달 이내
    return AppColors.success; // 여유
  }

  String _getDdayText(int dday, String status) {
    if (status == 'used') return '사용 완료';
    if (dday < 0) return '종료';
    if (dday == 0) return 'D-Day';
    return 'D-$dday';
  }

  Widget _buildEmptyFilter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: AppColors.gray400,
          ),

          SizedBox(height: 16),

          Text(
            '$_selectedFilter 티켓이 없습니다',
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

  void _showTicketDetail(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
    );
  }

  void _handleTransfer(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('티켓 양도'),
        content: Text('${ticket['title']} 티켓을 양도하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 04_02_양도등록 화면으로 이동
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('양도 등록 화면으로 이동합니다')));
            },
            child: Text('양도하기'),
          ),
        ],
      ),
    );
  }

  void _handleTransferManage(Map<String, dynamic> ticket) {
    // TODO: 04_08_내양도관리로 이동
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${ticket['title']} 양도 관리')));
  }

  void _showUsedTicketInfo(Map<String, dynamic> ticket) {
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
            Text(
              '입장 완료 기록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '입장일: ${ticket['usedDate'] ?? ticket['date']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
