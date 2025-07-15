import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/ticketing/presentation/screens/payment_webview_screen.dart';
import '../../../shared/providers/api_provider.dart';
import '../../data/models/ticket_models.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/json_parser.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const SeatSelectionScreen({Key? key, required this.data}) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  String? _selectedZone;
  String? _selectedSeatNumber;

  // API 데이터
  SessionSeatInfo? _sessionSeatInfo;
  SeatLayout? _currentSeatLayout;

  // 로딩 상태
  bool _isLoadingSeatInfo = true;
  bool _isLoadingSeatLayout = false;
  String? _errorMessage;

  // 추출된 ID 정보
  late int _performanceId;
  late int _sessionId;

  @override
  void initState() {
    super.initState();
    _extractIds();
    _loadSessionSeatInfo();
  }

  /// 전달받은 데이터에서 필요한 ID들 추출
  void _extractIds() {
    // 공연 ID 추출
    _performanceId =
        JsonParserUtils.extractPerformanceId(widget.data) ??
        JsonParserUtils.extractPerformanceId(widget.data['concertInfo']) ??
        0;

    // 세션 ID 추출 (여러 경로에서 시도)
    _sessionId =
        JsonParserUtils.extractSessionId(widget.data) ??
        JsonParserUtils.extractSessionId(widget.data['selectedSession']) ??
        JsonParserUtils.parseId(widget.data['performanceSessionId']) ??
        0;

    print('🆔 추출된 ID: 공연($_performanceId), 세션($_sessionId)');
    print('🔍 전달받은 데이터 키: ${widget.data.keys.toList()}');

    if (_performanceId <= 0 || _sessionId <= 0) {
      print('❌ ID 추출 실패 - 전체 데이터: ${widget.data}');
      setState(() {
        _errorMessage =
            'ID 정보를 찾을 수 없습니다.\n공연 ID: $_performanceId, 세션 ID: $_sessionId\n\n전달받은 데이터를 확인해주세요.';
        _isLoadingSeatInfo = false;
      });
    }
  }

  /// 세션별 좌석 정보 로드 (구역 정보)
  Future<void> _loadSessionSeatInfo() async {
    if (_performanceId <= 0 || _sessionId <= 0) return;

    try {
      setState(() {
        _isLoadingSeatInfo = true;
        _errorMessage = null;
      });

      final apiProvider = context.read<ApiProvider>();
      print('🏢 세션별 좌석 정보 로딩 시작');

      final seatInfo = await apiProvider.apiService.ticket.getSessionSeatInfo(
        _performanceId,
        _sessionId,
      );

      setState(() {
        _sessionSeatInfo = seatInfo;
        _isLoadingSeatInfo = false;
      });

      print('✅ 세션별 좌석 정보 로딩 완료: ${seatInfo.seatPricingInfo.length}개 구역');
    } catch (e) {
      print('❌ 세션별 좌석 정보 로딩 실패: $e');
      setState(() {
        _errorMessage = '좌석 정보를 불러올 수 없습니다.\n$e';
        _isLoadingSeatInfo = false;
      });
    }
  }

  /// 특정 구역의 좌석 배치 로드 (임시: 더미 데이터 사용)
  Future<void> _loadSeatLayout(String seatZone) async {
    if (_performanceId <= 0 || _sessionId <= 0) return;

    try {
      setState(() {
        _isLoadingSeatLayout = true;
        _errorMessage = null;
      });

      print('🎭 좌석 배치 정보 로딩 시작: $seatZone구역 (임시 더미 데이터 사용)');

      // TODO: 백엔드 API 문제 해결 후 실제 API 호출로 변경
      // final apiProvider = context.read<ApiProvider>();
      // final seatLayout = await apiProvider.apiService.ticket
      //     .getSeatLayout(_performanceId, _sessionId, seatZone);

      // 임시 더미 좌석 배치 생성
      final dummySeatLayout = _generateDummySeatLayout(seatZone);

      // 약간의 로딩 시간 시뮬레이션
      await Future.delayed(Duration(milliseconds: 800));

      setState(() {
        _currentSeatLayout = dummySeatLayout;
        _isLoadingSeatLayout = false;
      });

      print('✅ 좌석 배치 정보 로딩 완료: ${dummySeatLayout.totalSeats}석 (더미 데이터)');
    } catch (e) {
      print('❌ 좌석 배치 정보 로딩 실패: $e');
      setState(() {
        _errorMessage = '좌석 배치를 불러올 수 없습니다.\n$e';
        _isLoadingSeatLayout = false;
      });
    }
  }

  /// 임시 더미 좌석 배치 생성
  SeatLayout _generateDummySeatLayout(String seatZone) {
    // 구역별 좌석 정보 (실제 API 데이터 참고)
    final zoneInfo = _sessionSeatInfo!.seatPricingInfo.firstWhere(
      (zone) => zone.seatZone == seatZone,
    );

    // 구역별 행/열 설정
    final rows = ['A', 'B', 'C', 'D', 'E', 'F'];
    final seatsPerRow = 10;
    final totalSeats = rows.length * seatsPerRow;

    // 잔여석 수를 기반으로 예약 상태 결정
    final availableCount = zoneInfo.remainingSeats;
    final reservedCount = (totalSeats * 0.1).round(); // 전체의 10%는 예약됨
    final soldCount = totalSeats - availableCount - reservedCount;

    print(
      '🎭 더미 좌석 생성: 총 $totalSeats석, 사용가능 $availableCount석, 예약됨 $reservedCount석, 판매됨 $soldCount석',
    );

    // 좌석 상태 배열 생성
    List<String> seatStatuses = [];
    seatStatuses.addAll(List.filled(availableCount, 'available'));
    seatStatuses.addAll(List.filled(reservedCount, 'reserved'));
    seatStatuses.addAll(List.filled(soldCount, 'sold'));
    seatStatuses.shuffle(); // 랜덤하게 섞기

    // 좌석 행 생성
    List<SeatRow> seatRows = [];
    int seatIndex = 0;

    for (String row in rows) {
      List<Seat> seats = [];
      for (int col = 1; col <= seatsPerRow; col++) {
        final seatNumber = '$row$col';
        final status = seatIndex < seatStatuses.length
            ? seatStatuses[seatIndex]
            : 'sold';

        seats.add(Seat(seatNumber: seatNumber, reservationStatus: status));
        seatIndex++;
      }
      seatRows.add(SeatRow(row: row, seats: seats));
    }

    return SeatLayout(
      performanceId: _performanceId,
      performanceSessionId: _sessionId,
      seatZone: seatZone,
      price: zoneInfo.price,
      maxRow: rows.last,
      maxCol: seatsPerRow,
      seatLayout: seatRows,
    );
  }

  /// 구역 선택 핸들러
  void _onZoneSelected(String zone) {
    setState(() {
      _selectedZone = zone;
      _selectedSeatNumber = null;
      _currentSeatLayout = null;
    });
    _loadSeatLayout(zone);
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
          '좌석 선택',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadSessionSeatInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildEventHeader(),
          Expanded(child: _buildMainContent()),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoadingSeatInfo) {
      return _buildLoadingState('좌석 정보를 불러오고 있습니다...');
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_sessionSeatInfo == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceGuide(),
          SizedBox(height: 24),
          _buildZoneLayout(),
          SizedBox(height: 24),
          if (_selectedZone != null) ...[
            if (_isLoadingSeatLayout)
              _buildLoadingWidget('좌석 배치를 불러오고 있습니다...')
            else if (_currentSeatLayout != null)
              _buildSeatSelection()
            else
              _buildSeatLoadingError(),
          ] else
            _buildLegend(),
        ],
      ),
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
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              '좌석 정보를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? '네트워크 연결을 확인해주세요',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSessionSeatInfo,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat, size: 64, color: AppColors.gray400),
            SizedBox(height: 16),
            Text(
              '예매 가능한 좌석이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatLoadingError() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          SizedBox(height: 8),
          Text(
            '좌석 배치를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _loadSeatLayout(_selectedZone!),
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

  Widget _buildEventHeader() {
    final concertInfo = widget.data['concertInfo'] ?? {};
    final selectedSession = widget.data['selectedSession'] ?? {};

    // API 데이터가 있으면 사용, 없으면 전달받은 데이터 사용
    final title = _sessionSeatInfo?.title ?? concertInfo['title'] ?? '공연 제목';
    final artist =
        _sessionSeatInfo?.performerName ?? concertInfo['artist'] ?? '아티스트';
    final venue = _sessionSeatInfo?.venueName ?? concertInfo['venue'] ?? '공연장';
    final dateTime = selectedSession['dateTime'] ?? '';

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
                    '$dateTime • $venue',
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

  Widget _buildPriceGuide() {
    if (_sessionSeatInfo == null) return SizedBox.shrink();

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
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _sessionSeatInfo!.seatPricingInfo.map((pricing) {
              return _buildPriceItem(
                pricing.zoneDisplayName,
                _getZoneColor(pricing.seatZone),
                pricing.priceDisplay,
              );
            }).toList(),
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

  Color _getZoneColor(String zone) {
    // 구역별 색상 매핑 (임시)
    final colors = {
      'A': Color(0xFFE6D16B),
      'B': Color(0xFF8BB5DB),
      'C': Color(0xFFB8E6B8),
      'D': Color(0xFFFFB6C1),
    };
    return colors[zone] ?? AppColors.primary;
  }

  Widget _buildZoneLayout() {
    if (_sessionSeatInfo == null) return SizedBox.shrink();

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

        // 구역 카드들을 동적으로 생성
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: _sessionSeatInfo!.availableZones.length,
          itemBuilder: (context, index) {
            final zone = _sessionSeatInfo!.availableZones[index];
            return _buildZoneCard(zone);
          },
        ),
      ],
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

  Widget _buildZoneCard(SeatPricingInfo zone) {
    final isSelected = _selectedZone == zone.seatZone;
    final zoneColor = _getZoneColor(zone.seatZone);

    return GestureDetector(
      onTap: zone.isAvailable ? () => _onZoneSelected(zone.seatZone) : null,
      child: Container(
        decoration: BoxDecoration(
          color: zone.isAvailable
              ? (isSelected
                    ? zoneColor.withOpacity(0.3)
                    : zoneColor.withOpacity(0.1))
              : AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: zone.isAvailable
                ? (isSelected ? AppColors.primary : zoneColor.withOpacity(0.5))
                : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: zone.isAvailable
              ? [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${zone.seatZone}구역',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: zone.isAvailable
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              zone.seatGrade,
              style: TextStyle(
                fontSize: 12,
                color: zone.isAvailable
                    ? AppColors.textSecondary
                    : AppColors.gray400,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              zone.availabilityText,
              style: TextStyle(
                fontSize: 10,
                color: zone.isSoldOut ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
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
    if (_currentSeatLayout == null) return SizedBox.shrink();

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
            '원하는 좌석을 선택해주세요 (가격: ${_currentSeatLayout!.priceDisplay})',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16),

          // 좌석 그리드 표시
          _buildSeatGrid(),

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

  Widget _buildSeatGrid() {
    if (_currentSeatLayout == null) return SizedBox.shrink();

    // 행별로 좌석 그룹화
    final seatRows = _currentSeatLayout!.seatLayout;

    return Column(
      children: [
        // 열 번호 표시 (예: 1, 2, 3...)
        if (seatRows.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: 30),
            child: Row(
              children: List.generate(
                _currentSeatLayout!.maxCol,
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
        ],

        // 좌석 행들
        ...seatRows.map((seatRow) => _buildSeatRow(seatRow)).toList(),
      ],
    );
  }

  Widget _buildSeatRow(SeatRow seatRow) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // 행 라벨 (A, B, C...)
          SizedBox(
            width: 30,
            child: Text(
              seatRow.row,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 좌석들
          ...seatRow.seats
              .map((seat) => Expanded(child: _buildSeatButton(seat)))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSeatButton(Seat seat) {
    final isSelected = _selectedSeatNumber == seat.seatNumber;
    final isAvailable = seat.isAvailable;

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
                  _selectedSeatNumber = seat.seatNumber;
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
          child: Center(
            child: Text(
              '${seat.column}',
              style: TextStyle(
                fontSize: 10,
                color: isAvailable
                    ? (isSelected ? AppColors.white : AppColors.textPrimary)
                    : AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
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
    final canProceed =
        _selectedSeatNumber != null && _currentSeatLayout != null;

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
          if (_selectedSeatNumber != null) _buildSelectedSeatSummary(),
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
                _selectedSeatNumber == null ? '좌석을 선택해주세요' : '결제하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSeatSummary() {
    if (_selectedSeatNumber == null || _currentSeatLayout == null) {
      return SizedBox.shrink();
    }

    final selectedSeat = _currentSeatLayout!.allSeats.firstWhere(
      (seat) => seat.seatNumber == _selectedSeatNumber,
    );

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
                '${_selectedZone}구역 ${selectedSeat.row}행 ${selectedSeat.column}번',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _currentSeatLayout!.priceDisplay,
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
    if (_selectedSeatNumber == null ||
        _selectedZone == null ||
        _currentSeatLayout == null ||
        _sessionSeatInfo == null)
      return;

    final selectedSeat = _currentSeatLayout!.allSeats.firstWhere(
      (seat) => seat.seatNumber == _selectedSeatNumber,
    );

    final selectedZoneInfo = _sessionSeatInfo!.seatPricingInfo.firstWhere(
      (zone) => zone.seatZone == _selectedZone,
    );

    // 임시: 좌석 ID는 좌석 번호를 기반으로 생성 (실제로는 API에서 받아야 함)
    final tempSeatId = _generateSeatId(selectedSeat.seatNumber, _selectedZone!);

    final paymentData = {
      // 기본 정보
      'concertInfo': widget.data['concertInfo'] ?? {},
      'selectedSession': widget.data['selectedSession'] ?? {},

      // API에서 받은 실제 데이터
      'performanceId': _performanceId,
      'performanceSessionId': _sessionId,
      'sessionSeatInfo': {
        'title': _sessionSeatInfo!.title,
        'performerName': _sessionSeatInfo!.performerName,
        'venueName': _sessionSeatInfo!.venueName,
        'sessionDatetime': _sessionSeatInfo!.sessionDatetime,
      },

      // 선택한 좌석 정보
      'selectedZone': _selectedZone,
      'selectedSeat': {
        'seatId': tempSeatId, // 임시 생성된 ID
        'seatNumber': selectedSeat.seatNumber,
        'row': selectedSeat.row,
        'column': selectedSeat.column,
        'status': selectedSeat.reservationStatus,
        'zone': _selectedZone,
      },

      // 가격 정보
      'seatGrade': selectedZoneInfo.seatGrade,
      'price': selectedZoneInfo.price,
      'priceDisplay': selectedZoneInfo.priceDisplay,

      // 디버깅용 정보
      'debug': {
        'dataSource': 'hybrid', // 구역정보는 API, 좌석배치는 더미
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    print('💳 결제 화면으로 이동');
    print('📋 전달 데이터: ${paymentData.keys.toList()}');
    print(
      '🎫 선택된 좌석: ${selectedZoneInfo.seatGrade} ${_selectedZone}구역 ${selectedSeat.seatNumber} (${selectedZoneInfo.priceDisplay})',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(paymentData: paymentData),
      ),
    );
  }

  /// 임시 좌석 ID 생성 (실제로는 API에서 받아야 함)
  int _generateSeatId(String seatNumber, String zone) {
    // 간단한 해시 기반 ID 생성 (실제 환경에서는 사용하지 말 것)
    final combined = '$_performanceId-$_sessionId-$zone-$seatNumber';
    return combined.hashCode.abs() % 100000;
  }
}
