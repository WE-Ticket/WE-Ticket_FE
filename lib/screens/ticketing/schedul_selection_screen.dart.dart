import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/screens/ticketing/seat_selection_screen.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  final Map<String, dynamic>? concertInfo; // nullable로 변경

  const ScheduleSelectionScreen({Key? key, this.concertInfo}) : super(key: key);

  @override
  _ScheduleSelectionScreenState createState() =>
      _ScheduleSelectionScreenState();
}

class _ScheduleSelectionScreenState extends State<ScheduleSelectionScreen> {
  String? _selectedShowTime;

  // FIXME: 더미 데이터 - 실제로는 API에서 가져올 예정
  final List<Map<String, dynamic>> _allSchedules = [
    {
      'showId': 'show_001',
      'date': '2025년 7월 4일',
      'weekday': '금요일',
      'time': '18:00',
      'availableSeats': 1250,
      'totalSeats': 1500,
      'prices': {'VIP': 220000, 'R': 165000, 'S': 132000, 'A': 99000},
      'isAvailable': true,
    },
    {
      'showId': 'show_002',
      'date': '2025년 7월 4일',
      'weekday': '금요일',
      'time': '20:00',
      'availableSeats': 980,
      'totalSeats': 1500,
      'prices': {'VIP': 220000, 'R': 165000, 'S': 132000, 'A': 99000},
      'isAvailable': true,
    },
    {
      'showId': 'show_003',
      'date': '2025년 7월 5일',
      'weekday': '토요일',
      'time': '19:00',
      'availableSeats': 0,
      'totalSeats': 1500,
      'prices': {'VIP': 220000, 'R': 165000, 'S': 132000, 'A': 99000},
      'isAvailable': false, // 매진
    },
    {
      'showId': 'show_004',
      'date': '2025년 7월 6일',
      'weekday': '일요일',
      'time': '15:00',
      'availableSeats': 1350,
      'totalSeats': 1500,
      'prices': {'VIP': 220000, 'R': 165000, 'S': 132000, 'A': 99000},
      'isAvailable': true,
    },
    {
      'showId': 'show_005',
      'date': '2025년 7월 6일',
      'weekday': '일요일',
      'time': '19:00',
      'availableSeats': 890,
      'totalSeats': 1500,
      'prices': {'VIP': 220000, 'R': 165000, 'S': 132000, 'A': 99000},
      'isAvailable': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.user != null;

    final prices = _allSchedules.isNotEmpty
        ? _allSchedules.first['prices']
        : {};

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
          '일정 선택',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildConcertHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildScheduleListSection()],
              ),
            ),
          ),

          _buildNextButton(isAuthenticated),
        ],
      ),
    );
  }

  Widget _buildConcertHeader() {
    final concertData = widget.concertInfo ?? {};
    final title = concertData['title'] ?? '공연 제목';
    final artist = concertData['artist'] ?? '아티스트';
    final venue = concertData['venue'] ?? '공연장';
    final poster = concertData['poster'] ?? '';

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.gray200,
                  image: poster.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(poster),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: poster.isEmpty
                    ? Icon(Icons.music_note, color: AppColors.gray400, size: 30)
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      venue,
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
          SizedBox(height: 16),
          _buildPriceInfoCard(),
        ],
      ),
    );
  }

  Widget _buildScheduleListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '공연 일정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '원하는 회차를 선택해주세요',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        SizedBox(height: 16),

        // 회차 리스트
        ..._allSchedules
            .map((schedule) => _buildShowTimeCard(schedule))
            .toList(),
      ],
    );
  }

  Widget _buildPriceInfoCard() {
    final prices = _allSchedules.isNotEmpty
        ? _allSchedules.first['prices']
        : {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '좌석별 가격 정보',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: prices.entries.map<Widget>((entry) {
            return Text(
              '${entry.key}석 ${_formatPrice(entry.value)}원',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShowTimeCard(Map<String, dynamic> schedule) {
    final isSelected = _selectedShowTime == schedule['showId'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedShowTime = schedule['showId'];
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${schedule['date']} (${schedule['weekday']})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                schedule['time'],
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
                  ],
                ),

                SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(bool isAuthenticated) {
    final canProceed = _selectedShowTime != null && isAuthenticated;

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
      child: Column(
        children: [
          if (_selectedShowTime != null) _buildSelectedShowSummary(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canProceed
                  ? _goToSeatSelection
                  : _handleNextButtonPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed
                    ? AppColors.primary
                    : AppColors.gray400,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                !isAuthenticated
                    ? '본인 인증 후 예매 가능'
                    : _selectedShowTime == null
                    ? '회차를 선택해주세요'
                    : '좌석 선택하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedShowSummary() {
    if (_selectedShowTime == null) return SizedBox.shrink();

    final selectedSchedule = _allSchedules.firstWhere(
      (schedule) => schedule['showId'] == _selectedShowTime,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${selectedSchedule['date']} (${selectedSchedule['weekday']}) ${selectedSchedule['time']}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
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

  void _handleNextButtonPress() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('본인 인증 필요'),
          content: Text('티켓 예매를 위해서는 모바일 신분증 인증이 필요합니다.\n인증을 진행하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 본인 인증 화면으로 이동
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('본인 인증 화면으로 이동합니다')));
              },
              child: Text('인증하기'),
            ),
          ],
        ),
      );
    }
  }

  void _goToSeatSelection() {
    final selectedSchedule = _allSchedules.firstWhere(
      (schedule) => schedule['showId'] == _selectedShowTime,
    );

    final selectionData = {
      'concertInfo': widget.concertInfo ?? {}, // null 체크
      'selectedSchedule': selectedSchedule,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(data: selectionData),
      ),
    );
  }
}
