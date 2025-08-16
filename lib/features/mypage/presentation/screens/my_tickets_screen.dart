import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/shared/presentation/screens/ticket_detail_screen.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/presentation/widgets/app_snackbar.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({Key? key}) : super(key: key);

  @override
  _MyTicketsScreenState createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  String _selectedFilter = '전체 보유';
  List<Map<String, dynamic>> _myTickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _filterOptions = ['전체 보유', '입장 예정', '양도 등록 중', '사용 완료'];

  @override
  void initState() {
    super.initState();
    _loadMyTickets();
  }

  /// 클라이언트 사이드 필터링: 서버에서 전체 데이터를 받아온 후 클라이언트에서 필터링
  List<Map<String, dynamic>> get _filteredTickets {
    List<Map<String, dynamic>> filtered;
    
    switch (_selectedFilter) {
      case '입장 예정':
        filtered = _myTickets.where((ticket) => ticket['status'] == 'pending').toList();
        break;
      case '양도 등록 중':
        filtered = _myTickets.where((ticket) => ticket['status'] == 'transferring').toList();
        break;
      case '사용 완료':
        filtered = _myTickets.where((ticket) => ticket['status'] == 'completed').toList();
        break;
      default: // 전체 보유
        filtered = _myTickets;
        break;
    }
    
    print('🔍 클라이언트 필터링 결과: $_selectedFilter -> 전체 ${_myTickets.length}개 중 ${filtered.length}개 필터됨');
    return filtered;
  }

  /// 내 티켓 목록 API 호출
  Future<void> _loadMyTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final apiProvider = context.read<ApiProvider>();

      // 사용자 ID 확인
      // FIXME ?? 0 이거 수정 필요
      final int userId = authProvider.currentUserId ?? 0;

      print('내 티켓 목록 조회 요청: 사용자 ID $userId (전체 데이터 로드)');

      // 전체 데이터를 가져오고 클라이언트에서 필터링
      final tickets = await apiProvider.apiService.getOwnedTickets(
        userId,
        // state 파라미터 제거 - 전체 데이터 요청
      );

      setState(() {
        _myTickets = tickets
            .map((item) => _convertApiToLocalFormat(item))
            .toList();
        _isLoading = false;
      });

      print('✅ 내 티켓 목록 ${_myTickets.length}개 조회 성공 (전체 데이터, 현재 필터: $_selectedFilter)');
      
      // 상태별 분포 출력 (디버깅용)
      final statusCounts = <String, int>{};
      for (final ticket in _myTickets) {
        final status = ticket['status'] ?? 'unknown';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      print('📊 상태별 분포: $statusCounts');
    } catch (e) {
      print('❌ 내 티켓 목록 조회 오류: $e');
      setState(() {
        _errorMessage = '티켓 목록을 불러올 수 없습니다. 다시 시도해주세요.';
        _isLoading = false;
      });
    }
  }

  // _getStateFromFilter 함수 제거됨 - 더 이상 서버 필터링을 사용하지 않음

  /// API 응답 데이터를 화면에서 사용하는 형식으로 변환
  ///
  /// FIXME 모델이랑 서비스 파일 새로 만들기
  Map<String, dynamic> _convertApiToLocalFormat(Map<String, dynamic> apiData) {
    try {
      final sessionDateTimeStr = apiData['session_datetime'];
      DateTime sessionDateTime;

      if (sessionDateTimeStr != null &&
          sessionDateTimeStr.toString().isNotEmpty) {
        try {
          sessionDateTime = DateTime.parse(sessionDateTimeStr.toString());
        } catch (e) {
          print('❌ 날짜 파싱 오류: $e');
          sessionDateTime = DateTime.now().add(Duration(days: 30)); // 기본값
        }
      } else {
        sessionDateTime = DateTime.now().add(Duration(days: 30)); // 기본값
      }

      final now = DateTime.now();
      final dday = sessionDateTime.difference(now).inDays;

      return {
        'id': (apiData['ticket'] ?? 'unknown').toString(),
        'performanceId': apiData['performance_id'] ?? 0,
        'title': (apiData['performance_title'] ?? '제목 없음').toString(),
        'performerName': (apiData['performer_name'] ?? '아티스트 미정').toString(),
        'date': _formatDate(sessionDateTime),
        'time': _formatTime(sessionDateTime),
        'venue': (apiData['venue_name'] ?? '장소 미정').toString(),
        'seatNumber': (apiData['seat_number'] ?? '좌석 미정').toString(),
        'seatZone': (apiData['seat_zone'] ?? 1).toString(),
        'seatGrade': (apiData['seat_grade'] ?? 1).toString(),
        'status': (apiData['ticket_status'] ?? 'pending').toString(),
        'poster': _getSafeImageUrl(apiData['performance_main_image']),
        'dday': dday,
        'transferTicketId': apiData['transfer_ticket_id'],
        'sessionDateTime': sessionDateTime,
        'completeDatetime': apiData['complete_datetime'],
      };
    } catch (e) {
      print('❌ 티켓 데이터 변환 오류: $e');
      print('❌ 원본 데이터: $apiData');

      // 오류 발생 시 안전한 기본값으로 반환
      return {
        'id': 'unknown',
        'performanceId': 0,
        'title': '제목 없음',
        'artist': '아티스트 미정',
        'date': '날짜 미정',
        'time': '시간 미정',
        'venue': '장소 미정',
        'seat': '좌석 미정',
        'poster': 'https://via.placeholder.com/300x400?text=No+Image',
        'status': 'pending',
        'dday': 0,
        'transferTicketId': null,
        'sessionDateTime': DateTime.now(),
      };
    }
  }

  /// 안전한 이미지 URL 생성
  String _getSafeImageUrl(dynamic imageUrl) {
    if (imageUrl == null ||
        imageUrl.toString().isEmpty ||
        imageUrl.toString() == 'null') {
      return 'https://via.placeholder.com/300x400?text=No+Image';
    }

    final urlString = imageUrl.toString();

    // URL이 유효한지 확인
    try {
      final uri = Uri.parse(urlString);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return urlString;
      } else {
        return 'https://via.placeholder.com/300x400?text=No+Image';
      }
    } catch (e) {
      print('❌ 이미지 URL 파싱 오류: $e');
      return 'https://via.placeholder.com/300x400?text=No+Image';
    }
  }

  /// 날짜 포맷팅 (YYYY.MM.DD)
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 시간 포맷팅 (HH:MM)
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 필터 변경 시 - 데이터 리로드 없이 UI만 업데이트
  void _onFilterChanged(String newFilter) {
    if (_selectedFilter == newFilter) return; // 동일한 필터면 무시
    
    setState(() {
      _selectedFilter = newFilter;
    });
    
    print('🔄 필터 변경: $_selectedFilter -> 클라이언트 필터링 실행');
    // _loadMyTickets() 제거 - 더 이상 API 호출하지 않음
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
          '내 티켓 관리',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadMyTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),

          // 티켓 카드 리스트
          Expanded(child: _buildTicketList()),
          SizedBox(height: 40),
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
              onTap: () => _onFilterChanged(filter),
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

  Widget _buildTicketList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              '티켓 목록을 불러오는 중...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMyTickets,
              icon: Icon(Icons.refresh),
              label: Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    final filteredTickets = _filteredTickets;
    if (filteredTickets.isEmpty) {
      return _buildEmptyFilter();
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = filteredTickets[index];
        return _buildTicketCard(ticket);
      },
    );
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
                      image: NetworkImage(
                        ticket['poster'] ??
                            'https://via.placeholder.com/300x400?text=No+Image',
                      ),
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
                        ticket['title'] ?? '제목 없음',
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
                        ticket['performerName'] ?? '아티스트 미정',
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
                            '${ticket['date'] ?? '날짜 미정'} ${ticket['time'] ?? '시간 미정'}',
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
                              ticket['venue'] ?? '장소 미정',
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
                    _buildStatusBadge(ticket['status'] ?? 'pending'),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDdayColor(
                          ticket['dday'] ?? 0,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getDdayText(
                          ticket['dday'] ?? 0,
                          ticket['status'] ?? 'pending',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getDdayColor(ticket['dday'] ?? 0),
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
                  '${ticket['seatGrade']} ${ticket['seatZone']}구역 ${ticket['seatNumber']}',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
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
    final status = ticket['status'];

    switch (status) {
      case 'pending':
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
      case 'completed':
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

  Widget _buildStatusBadge(String? status) {
    Color backgroundColor;
    String text;

    switch (status) {
      case 'pending':
        backgroundColor = AppColors.success;
        text = '입장 예정';
        break;
      case 'transferring':
        backgroundColor = AppColors.warning;
        text = '양도 중';
        break;
      case 'completed':
        backgroundColor = AppColors.secondary;
        text = '사용 완료';
        break;
      case 'expired':
        backgroundColor = AppColors.secondary;
        text = '만료';
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

  Color _getDdayColor(int? dday) {
    final d = dday ?? 0;
    if (d < 0) return AppColors.secondary; // 과거
    if (d <= 7) return AppColors.error; // 임박
    if (d <= 30) return AppColors.warning; // 한 달 이내
    return AppColors.success; // 여유
  }

  String _getDdayText(int? dday, String? status) {
    final d = dday ?? 0;
    final s = status ?? 'pending';

    if (s == 'completed') return '사용 완료';
    if (d < 0) return '종료';
    if (d == 0) return 'D-Day';
    return 'D-$d';
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
      MaterialPageRoute(
        builder: (_) =>
            TicketDetailScreen(ticketId: ticket['id'], ticket: ticket),
      ),
    );
  }

  void _handleTransfer(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '티켓 양도',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '${ticket['title'] ?? '티켓'}을 양도하시겠습니까?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: 양도 등록 화면으로 이동
                    AppSnackBar.showInfo(context, '양도 등록 화면으로 이동합니다');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '양도하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTransferManage(Map<String, dynamic> ticket) {
    // TODO: 양도 관리 화면으로 이동
    AppSnackBar.showInfo(context, '${ticket['title'] ?? '티켓'} 양도 관리');
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
                        ticket['title'] ?? '제목 없음',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '입장일: ${ticket['date'] ?? '날짜 미정'}',
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
