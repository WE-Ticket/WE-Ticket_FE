import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/ticketing/presentation/screens/seat_selection_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/providers/api_provider.dart';
import '../../data/models/ticket_models.dart';
import '../../../../core/constants/app_colors.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> performanceInfo;

  const ScheduleSelectionScreen({Key? key, required this.performanceInfo})
    : super(key: key);

  @override
  _ScheduleSelectionScreenState createState() =>
      _ScheduleSelectionScreenState();
}

class _ScheduleSelectionScreenState extends State<ScheduleSelectionScreen> {
  int? _selectedSessionId;
  PerformanceSchedule? _scheduleData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiProvider = context.read<ApiProvider>();

      print(
        '🎫 공연 스케줄 로딩 시작 - 공연 ID: ${widget.performanceInfo['performace_id']}',
      );

      final schedule = await apiProvider.apiService.ticket
          .getPerformanceSchedule(widget.performanceInfo['performance_id']);

      setState(() {
        _scheduleData = schedule;
        _isLoading = false;
      });

      print('✅ 공연 스케줄 로딩 완료 - ${schedule.sessions.length}개 세션');
    } catch (e) {
      print('❌ 공연 스케줄 로딩 실패: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
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
          '일정 선택',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadScheduleData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConcertHeader(),
          Expanded(child: _buildMainContent()),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_scheduleData == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildScheduleListSection()],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            '공연 일정을 불러오고 있습니다...',
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
              '일정 정보를 불러올 수 없습니다',
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
              onPressed: _loadScheduleData,
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
            Icon(Icons.event_busy, size: 64, color: AppColors.gray400),
            SizedBox(height: 16),
            Text(
              '예매 가능한 일정이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '현재 예매 가능한 공연 일정이 없습니다',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcertHeader() {
    final title = widget.performanceInfo['title'] ?? '공연 제목';
    final performerName = widget.performanceInfo['performer_name'] ?? '아티스트';
    final venue = widget.performanceInfo['venue_name'] ?? '공연장';
    final poster = widget.performanceInfo['main_image'] ?? '';

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
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
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
                      performerName,
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
    if (_scheduleData == null) return SizedBox.shrink();

    final availableSessions = _scheduleData!.availableSessions;
    final soldOutSessions = _scheduleData!.soldOutSessions;

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

        // 예매 가능한 세션들
        if (availableSessions.isNotEmpty) ...[
          ...availableSessions.map((session) => _buildSessionCard(session)),
        ],

        // 매진 세션들
        if (soldOutSessions.isNotEmpty) ...[
          SizedBox(height: 24),
          Text(
            '매진된 일정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12),
          ...soldOutSessions.map((session) => _buildSessionCard(session)),
        ],
      ],
    );
  }

  Widget _buildPriceInfoCard() {
    if (_scheduleData == null || _scheduleData!.seatPricings.isEmpty) {
      return SizedBox.shrink();
    }

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
          children: _scheduleData!.seatPricings.map<Widget>((pricing) {
            return Text(
              '${pricing.seatGrade} ${pricing.priceDisplay}',
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

  Widget _buildSessionCard(PerformanceSession session) {
    final isSelected = _selectedSessionId == session.performanceSessionId;
    final isAvailable = session.isAvailable;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable
              ? () {
                  setState(() {
                    _selectedSessionId = session.performanceSessionId;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: !isAvailable
                  ? AppColors.gray100
                  : isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !isAvailable
                    ? AppColors.gray300
                    : isSelected
                    ? AppColors.primary
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: !isAvailable
                  ? []
                  : [
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
                            session.dateDisplay,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: isAvailable
                                    ? AppColors.primary
                                    : AppColors.gray400,
                              ),
                              SizedBox(width: 6),
                              Text(
                                session.timeDisplay,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isAvailable
                                      ? AppColors.primary
                                      : AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Container(
                    //   padding: EdgeInsets.symmetric(
                    //     horizontal: 12,
                    //     vertical: 6,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: session.isSoldOut
                    //         ? AppColors.error.withOpacity(0.1)
                    //         : session.remainingSeats < 10
                    //         ? AppColors.warning.withOpacity(0.1)
                    //         : AppColors.success.withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(16),
                    //   ),
                    //   child: Text(
                    //     session.availabilityText,
                    //     style: TextStyle(
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.w600,
                    //       color: session.isSoldOut
                    //           ? AppColors.error
                    //           : session.remainingSeats < 10
                    //           ? AppColors.warning
                    //           : AppColors.success,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final canProceed = _selectedSessionId != null && _scheduleData != null;

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
          if (_selectedSessionId != null) _buildSelectedSessionSummary(),
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
                _selectedSessionId == null ? '회차를 선택해주세요' : '좌석 선택하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSelectedSessionSummary() {
    if (_selectedSessionId == null || _scheduleData == null) {
      return SizedBox.shrink();
    }

    final selectedSession = _scheduleData!.sessions.firstWhere(
      (session) => session.performanceSessionId == _selectedSessionId,
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
              '${selectedSession.dateTimeDisplay}',

              // '${selectedSession.dateTimeDisplay} (${selectedSession.availabilityText})',
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
    if (_scheduleData == null || _selectedSessionId == null) return;

    final selectedSession = _scheduleData!.sessions.firstWhere(
      (session) => session.performanceSessionId == _selectedSessionId,
    );

    final selectionData = {
      'performanceId': widget.performanceInfo['performance_id'],
      'performanceSessionId': selectedSession.performanceSessionId,
      'performaceInfo': widget.performanceInfo,
      'selectedSession': {
        'sessionId': selectedSession.performanceSessionId,
        'dateTime': selectedSession.dateTimeDisplay,
        'availabilityText': selectedSession.availabilityText,
        'remainingSeats': selectedSession.remainingSeats,
      },
      'scheduleData': _scheduleData,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(data: selectionData),
      ),
    );
  }
}
