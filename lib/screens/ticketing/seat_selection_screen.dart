import 'package:flutter/material.dart';
import 'package:we_ticket/screens/ticketing/payment_webview_screen.dart';
import '../../utils/app_colors.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const SeatSelectionScreen({Key? key, required this.data}) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  String? _selectedZone;
  String? _selectedSeat;

  // FIXME: 더미 데이터 - 실제로는 API에서 가져올 예정
  // TODO 실제로 데이터를 어떻게 받아야할지
  final Map<String, Map<String, dynamic>> _zones = {
    '1': {
      'grade': 'VIP',
      'price': 220000,
      'color': Color(0xFFE6D16B),
      'availableSeats': 45,
      'totalSeats': 60,
      'seats': List.generate(
        60,
        (index) => {
          'id': '1-${index + 1}',
          'row': String.fromCharCode(65 + (index ~/ 10)), // A, B, C, D, E, F
          'col': (index % 10) + 1,
          'isAvailable': index < 45,
        },
      ),
    },
    '2': {
      'grade': 'VIP',
      'price': 220000,
      'color': Color(0xFFE6D16B),
      'availableSeats': 38,
      'totalSeats': 60,
      'seats': List.generate(
        60,
        (index) => {
          'id': '2-${index + 1}',
          'row': String.fromCharCode(65 + (index ~/ 10)),
          'col': (index % 10) + 1,
          'isAvailable': index < 38,
        },
      ),
    },
    '3': {
      'grade': '일반석',
      'price': 132000,
      'color': Color(0xFF8BB5DB),
      'availableSeats': 72,
      'totalSeats': 80,
      'seats': List.generate(
        80,
        (index) => {
          'id': '3-${index + 1}',
          'row': String.fromCharCode(65 + (index ~/ 10)),
          'col': (index % 10) + 1,
          'isAvailable': index < 72,
        },
      ),
    },
    '4': {
      'grade': '일반석',
      'price': 132000,
      'color': Color(0xFF8BB5DB),
      'availableSeats': 68,
      'totalSeats': 80,
      'seats': List.generate(
        80,
        (index) => {
          'id': '4-${index + 1}',
          'row': String.fromCharCode(65 + (index ~/ 10)),
          'col': (index % 10) + 1,
          'isAvailable': index < 68,
        },
      ),
    },
  };

  @override
  Widget build(BuildContext context) {
    final concertInfo = widget.data['concertInfo'] ?? {};
    final selectedSchedule = widget.data['selectedSchedule'] ?? {};

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
          '좌석 선택',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // 공연 정보 헤더
          _buildEventHeader(concertInfo, selectedSchedule),

          // 좌석 선택 영역
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceGuide(),
                  SizedBox(height: 24),
                  _buildZoneLayout(),
                  SizedBox(height: 24),
                  if (_selectedZone != null)
                    _buildSeatSelection()
                  else
                    _buildLegend(),
                ],
              ),
            ),
          ),

          _buildNextButton(),
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

  Widget _buildEventHeader(
    Map<String, dynamic> concertInfo,
    Map<String, dynamic> selectedSchedule,
  ) {
    final title = concertInfo['title'] ?? '공연 제목';
    final artist = concertInfo['artist'] ?? '아티스트';
    final venue = concertInfo['venue'] ?? '공연장';
    final date = selectedSchedule['date'] ?? '';
    final weekday = selectedSchedule['weekday'] ?? '';
    final time = selectedSchedule['time'] ?? '';

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      maxLines: 1,
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
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$date ($weekday) $time • $venue',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStageIndicator() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gray400,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'STAGE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '무대',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildZoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '구역 선택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '원하는 구역을 선택해주세요',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        SizedBox(height: 16),
        _buildStageIndicator(),
        SizedBox(height: 16),

        // 구역 레이아웃
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildZoneCard('1')),
                SizedBox(width: 16),
                Expanded(child: _buildZoneCard('2')),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildZoneCard('3')),
                SizedBox(width: 16),
                Expanded(child: _buildZoneCard('4')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceGuide() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '좌석 등급별 가격 안내',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildPriceItem('VIP석 (1,2구역)', Color(0xFFE6D16B), '220,000원'),
              SizedBox(width: 24),
              _buildPriceItem('일반석 (3,4구역)', Color(0xFF8BB5DB), '132,000원'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String title, Color color, String price) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              price,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoneCard(String zone) {
    final zoneData = _zones[zone]!;
    final isSelected = _selectedZone == zone;
    final availabilityRate =
        zoneData['availableSeats'] / zoneData['totalSeats'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedZone = zone;
          _selectedSeat = null;
        });
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected
              ? zoneData['color'].withOpacity(0.3)
              : zoneData['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : zoneData['color'].withOpacity(0.5),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${zone}구역',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              zoneData['grade'],
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '잔여 ${zoneData['availableSeats']}석',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.gray500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '좌석 선택 안내',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '구역을 선택하시면 세부 좌석을 선택할 수 있습니다.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelection() {
    if (_selectedZone == null) return SizedBox.shrink();

    final zoneData = _zones[_selectedZone!]!;
    final seats = zoneData['seats'] as List<Map<String, dynamic>>;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedZone}구역 좌석 선택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '원하는 좌석을 선택해주세요',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16),

          // 좌석 그리드 컨테이너
          Container(
            child: Column(
              children: [
                // 열 번호 표시
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Row(
                    children: List.generate(
                      10,
                      (index) => Expanded(
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // 좌석 그리드 with 행 라벨
                ...List.generate(
                  6,
                  (rowIndex) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        // 행 라벨
                        SizedBox(
                          width: 20,
                          child: Text(
                            String.fromCharCode(65 + rowIndex),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // 좌석 행
                        ...List.generate(10, (colIndex) {
                          final seatIndex = rowIndex * 10 + colIndex;
                          if (seatIndex >= seats.length) {
                            return Expanded(child: SizedBox(height: 32));
                          }
                          final seat = seats[seatIndex];
                          return Expanded(child: _buildSeatButton(seat));
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSeatLegend(
                '선택 가능',
                AppColors.gray200,
                AppColors.textPrimary,
              ),
              _buildSeatLegend('선택됨', AppColors.primary, AppColors.white),
              _buildSeatLegend('예약 불가', AppColors.gray400, AppColors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatButton(Map<String, dynamic> seat) {
    final isSelected = _selectedSeat == seat['id'];
    final isAvailable = seat['isAvailable'];

    Color backgroundColor;

    if (!isAvailable) {
      backgroundColor = AppColors.gray400;
    } else if (isSelected) {
      backgroundColor = AppColors.primary;
    } else {
      backgroundColor = AppColors.gray200;
    }

    return Padding(
      padding: EdgeInsets.all(1),
      child: GestureDetector(
        onTap: isAvailable
            ? () {
                setState(() {
                  _selectedSeat = seat['id'];
                });
              }
            : null,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSeatLegend(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final canProceed = _selectedSeat != null;

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
          if (_selectedSeat != null) _buildSelectedSeatSummary(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canProceed ? _goToPayment : null,
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
                _selectedSeat == null ? '좌석을 선택해주세요' : '결제하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSeatSummary() {
    if (_selectedSeat == null || _selectedZone == null)
      return SizedBox.shrink();

    final zoneData = _zones[_selectedZone!]!;
    final selectedSeatData = (zoneData['seats'] as List<Map<String, dynamic>>)
        .firstWhere((seat) => seat['id'] == _selectedSeat);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_seat, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '선택된 좌석',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedZone}구역 ${selectedSeatData['row']}행 ${selectedSeatData['col']}번',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_formatPrice(zoneData['price'])}원',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPayment() {
    if (_selectedSeat == null || _selectedZone == null) return;

    final zoneData = _zones[_selectedZone!]!;
    final selectedSeatData = (zoneData['seats'] as List<Map<String, dynamic>>)
        .firstWhere((seat) => seat['id'] == _selectedSeat);

    final paymentData = {
      'concertInfo': widget.data['concertInfo'],
      'selectedSchedule': widget.data['selectedSchedule'],
      'selectedZone': _selectedZone,
      'selectedSeat': selectedSeatData,
      'seatGrade': zoneData['grade'],
      'price': zoneData['price'],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(paymentData: paymentData),
      ),
    );
  }
}
