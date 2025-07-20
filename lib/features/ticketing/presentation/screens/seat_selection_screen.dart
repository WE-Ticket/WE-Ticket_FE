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

  // 고정된 구역 정보 (1,2,3,4)
  final List<String> _fixedZones = ['1', '2', '3', '4'];

  @override
  void initState() {
    super.initState();
    _extractIds();
    _loadSessionSeatInfo();
  }

  /// 전달받은 데이터에서 필요한 ID들 추출
  void _extractIds() {
    _performanceId =
        JsonParserUtils.extractPerformanceId(widget.data) ??
        JsonParserUtils.extractPerformanceId(widget.data['concertInfo']) ??
        0;

    _sessionId =
        JsonParserUtils.extractSessionId(widget.data) ??
        JsonParserUtils.extractSessionId(widget.data['selectedSession']) ??
        JsonParserUtils.parseId(widget.data['performanceSessionId']) ??
        0;

    print('🆔 추출된 ID: 공연($_performanceId), 세션($_sessionId)');

    if (_performanceId <= 0 || _sessionId <= 0) {
      setState(() {
        _errorMessage =
            'ID 정보를 찾을 수 없습니다.\n공연 ID: $_performanceId, 세션 ID: $_sessionId';
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
      setState(() {
        _errorMessage = '좌석 정보를 불러올 수 없습니다.\n$e';
        _isLoadingSeatInfo = false;
      });
    }
  }

  /// 특정 구역의 좌석 배치 로드 (API 호출)
  Future<void> _loadSeatLayout(String seatZone) async {
    if (_performanceId <= 0 || _sessionId <= 0) return;

    try {
      setState(() {
        _isLoadingSeatLayout = true;
        _errorMessage = null;
      });

      final apiProvider = context.read<ApiProvider>();

      // 실제 API 호출
      final seatLayout = await apiProvider.apiService.ticket.getSeatLayout(
        _performanceId,
        _sessionId,
        seatZone,
      );

      setState(() {
        _currentSeatLayout = seatLayout;
        _isLoadingSeatLayout = false;
      });

      print('✅ 좌석 배치 정보 로딩 완료: ${seatLayout.totalSeats}석');
    } catch (e) {
      print('❌ 좌석 배치 정보 로딩 실패: $e');
      // API 실패 시 더미 데이터로 대체
      final dummySeatLayout = _generateSeatLayoutFromAPI(seatZone);

      setState(() {
        _currentSeatLayout = dummySeatLayout;
        _isLoadingSeatLayout = false;
      });
    }
  }

  /// API 응답을 기반으로 좌석 배치 생성
  SeatLayout _generateSeatLayoutFromAPI(String seatZone) {
    if (_sessionSeatInfo == null) {
      return _generateDefaultSeatLayout(seatZone);
    }

    // 선택한 구역의 정보 찾기
    final zoneInfo = _sessionSeatInfo!.seatPricingInfo
        .where((zone) => zone.seatZone == seatZone)
        .firstOrNull;

    if (zoneInfo == null) {
      return _generateDefaultSeatLayout(seatZone);
    }

    // 구역별 기본 좌석 배치 (max_row, max_col 기반)
    final zoneConfig = _getZoneConfiguration(seatZone);
    final maxRow = zoneConfig['maxRow'] as String;
    final maxCol = zoneConfig['maxCol'] as int;

    // 행 생성 (A부터 maxRow까지)
    final rows = _generateRowNames(maxRow);
    final totalSeats = rows.length * maxCol;

    // 잔여석 수를 기반으로 좌석 상태 결정
    final availableCount = zoneInfo.remainingSeats;
    final soldCount = totalSeats - availableCount;

    print(
      '🎭 구역 $seatZone 좌석 생성: 총 $totalSeats석, 사용가능 $availableCount석, 판매됨 $soldCount석',
    );

    // 좌석 상태 배열 생성
    List<String> seatStatuses = [];
    seatStatuses.addAll(List.filled(availableCount, 'available'));
    seatStatuses.addAll(List.filled(soldCount, 'sold'));
    seatStatuses.shuffle(); // 랜덤하게 섞기

    // 좌석 행 생성
    List<SeatRow> seatRows = [];
    int seatIndex = 0;

    for (String row in rows) {
      List<Seat> seats = [];
      for (int col = 1; col <= maxCol; col++) {
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
      maxRow: maxRow,
      maxCol: maxCol,
      seatLayout: seatRows,
    );
  }

  /// 구역별 기본 설정값 (max_row, max_col)
  Map<String, dynamic> _getZoneConfiguration(String zone) {
    switch (zone) {
      case '1':
        return {'maxRow': 'F', 'maxCol': 8}; // VIP석
      case '2':
        return {'maxRow': 'E', 'maxCol': 10}; // R석
      case '3':
        return {'maxRow': 'D', 'maxCol': 12}; // S석
      case '4':
        return {'maxRow': 'C', 'maxCol': 15}; // A석
      default:
        return {'maxRow': 'C', 'maxCol': 10}; // 기본값
    }
  }

  /// A부터 maxRow까지 행 이름 생성
  List<String> _generateRowNames(String maxRow) {
    List<String> rows = [];
    int maxRowCode = maxRow.codeUnitAt(0);

    for (int i = 65; i <= maxRowCode; i++) {
      // A(65)부터 시작
      rows.add(String.fromCharCode(i));
    }

    return rows;
  }

  /// 기본 좌석 배치 생성 (API 실패 시)
  SeatLayout _generateDefaultSeatLayout(String seatZone) {
    final config = _getZoneConfiguration(seatZone);
    final maxRow = config['maxRow'] as String;
    final maxCol = config['maxCol'] as int;

    final rows = _generateRowNames(maxRow);
    List<SeatRow> seatRows = [];

    for (String row in rows) {
      List<Seat> seats = [];
      for (int col = 1; col <= maxCol; col++) {
        final seatNumber = '$row$col';
        // 기본적으로 절반은 available, 절반은 sold
        final status = (col % 2 == 0) ? 'available' : 'sold';
        seats.add(Seat(seatNumber: seatNumber, reservationStatus: status));
      }
      seatRows.add(SeatRow(row: row, seats: seats));
    }

    return SeatLayout(
      performanceId: _performanceId,
      performanceSessionId: _sessionId,
      seatZone: seatZone,
      price: 150000, // 기본 가격
      maxRow: maxRow,
      maxCol: maxCol,
      seatLayout: seatRows,
    );
  }

  /// 구역 정보 가져오기 (API 데이터 + 고정 구역)
  SeatPricingInfo? _getZoneInfo(String zone) {
    if (_sessionSeatInfo == null) return null;

    return _sessionSeatInfo!.seatPricingInfo
        .where((zoneInfo) => zoneInfo.seatZone == zone)
        .firstOrNull;
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sessionSeatInfo != null) _buildPriceGuide(),
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
    final colors = {
      '1': Color(0xFFE6D16B), // 골드 - VIP
      '2': Color(0xFF8BB5DB), // 블루 - R석
      '3': Color(0xFFB8E6B8), // 그린 - S석
      '4': Color(0xFFFFB6C1), // 핑크 - A석
    };
    return colors[zone] ?? AppColors.primary;
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

        // 고정된 2x2 구역 레이아웃
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

  Widget _buildZoneCard(String zone) {
    final isSelected = _selectedZone == zone;
    final zoneColor = _getZoneColor(zone);
    final zoneInfo = _getZoneInfo(zone);

    // API 데이터가 없는 구역은 비활성화
    final isAvailable = zoneInfo != null && zoneInfo.isAvailable;
    final hasZoneData = zoneInfo != null;

    return GestureDetector(
      onTap: isAvailable ? () => _onZoneSelected(zone) : null,
      child: Container(
        decoration: BoxDecoration(
          color: hasZoneData
              ? (isAvailable
                    ? (isSelected
                          ? zoneColor.withOpacity(0.3)
                          : zoneColor.withOpacity(0.1))
                    : AppColors.gray100)
              : AppColors.gray50, // 데이터 없는 구역
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasZoneData
                ? (isAvailable
                      ? (isSelected
                            ? AppColors.primary
                            : zoneColor.withOpacity(0.5))
                      : AppColors.gray300)
                : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isAvailable
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
        child: Container(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${zone}구역',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasZoneData
                      ? (isAvailable
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)
                      : AppColors.gray400,
                ),
              ),
              SizedBox(height: 4),
              if (zoneInfo != null) ...[
                Text(
                  zoneInfo.seatGrade,
                  style: TextStyle(
                    fontSize: 12,
                    color: isAvailable
                        ? AppColors.textSecondary
                        : AppColors.gray400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                // Text(
                //   zoneInfo.availabilityText,
                //   style: TextStyle(
                //     fontSize: 10,
                //     color: zoneInfo.isSoldOut
                //         ? AppColors.error
                //         : AppColors.success,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
              ] else ...[
                Text(
                  '구역 없음',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
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
            '${_currentSeatLayout!.maxRow}행 × ${_currentSeatLayout!.maxCol}열 배치 (가격: ${_currentSeatLayout!.priceDisplay})',
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

    final seatRows = _currentSeatLayout!.seatLayout;

    return Column(
      children: [
        // 열 번호 표시
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
          // 텍스트 제거 - 좌석 버튼만 표시
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
          SizedBox(height: 8),
          Text(
            '• 구역 1,2,3,4는 고정 배치입니다.\n• 각 구역의 좌석 배치는 API 데이터를 기반으로 자동 생성됩니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  //FIXME shared widget으로 분리 가능할 듯
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
          SizedBox(height: 40),
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

    final selectedZoneInfo = _getZoneInfo(_selectedZone!);
    if (selectedZoneInfo == null) return;

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

      // 좌석 배치 정보
      'seatLayout': {
        'maxRow': _currentSeatLayout!.maxRow,
        'maxCol': _currentSeatLayout!.maxCol,
        'totalSeats': _currentSeatLayout!.totalSeats,
        'availableSeats': _currentSeatLayout!.availableSeatsCount,
      },
    };

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
