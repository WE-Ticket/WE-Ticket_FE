import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/entry/screens/manual_entry_screen.dart'
    show ManualEntryScreen;
import 'package:we_ticket/features/entry/screens/nfc_entry_screen.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';
import '../../../../core/constants/app_colors.dart';

class TicketDetailScreen extends StatefulWidget {
  final String? ticketId;
  final Map<String, dynamic>? ticket;

  const TicketDetailScreen({Key? key, this.ticketId, this.ticket})
    : super(key: key);

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? _ticketDetail;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.ticket != null) {
      // 리스트에서 넘어온 데이터가 있으면 사용
      _ticketDetail = widget.ticket;
    } else if (widget.ticketId != null) {
      // 티켓 ID만 있으면 API 호출
      _loadTicketDetail();
    }
  }

  /// 티켓 상세 정보 API 호출
  Future<void> _loadTicketDetail() async {
    if (widget.ticketId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiProvider = context.read<ApiProvider>();

      // API 호출 데이터 준비
      final requestData = {'nft_ticket_id': widget.ticketId!};

      print('티켓 상세 정보 조회 요청: $requestData');

      // API 호출 (임시로 직접 호출)
      final response = await apiProvider.apiService.getTicketDetail(
        widget.ticketId!,
      );

      if (response != null) {
        setState(() {
          _ticketDetail = _convertApiToLocalFormat(response);
          _isLoading = false;
        });

        print('✅ 티켓 상세 정보 조회 성공');
      } else {
        throw Exception('티켓 상세 정보를 찾을 수 없습니다.');
      }
    } catch (e) {
      print('❌ 티켓 상세 정보 조회 오류: $e');
      setState(() {
        _errorMessage = '티켓 정보를 불러올 수 없습니다. 다시 시도해주세요.';
        _isLoading = false;
      });
    }
  }

  /// API 응답 데이터를 화면에서 사용하는 형식으로 변환
  Map<String, dynamic> _convertApiToLocalFormat(Map<String, dynamic> apiData) {
    try {
      final DateTime sessionDateTime = DateTime.parse(
        apiData['session_datetime'] ?? '2025-01-01T00:00:00Z',
      );
      final DateTime createdAt = DateTime.parse(
        apiData['created_at'] ?? '2025-01-01T00:00:00Z',
      );
      final now = DateTime.now();
      final dday = sessionDateTime.difference(now).inDays;

      // 티켓 상태 결정 로직
      String status = 'pending';
      if (sessionDateTime.isBefore(now)) {
        status = 'expired';
      }
      // 양도 중인지는 별도 API나 필드가 필요할 수 있음

      return {
        'id': apiData['nft_ticket_id'] ?? 'unknown',
        'performanceId': apiData['performance_id'] ?? 0,
        'title': apiData['performance_title'] ?? '제목 없음',
        'performerName': apiData['performer_name'] ?? '아티스트 미정',
        'date': _formatDate(sessionDateTime),
        'time': _formatTime(sessionDateTime),
        'venue': apiData['venue_name'] ?? '장소 미정',
        'venueLocation': apiData['venue_location'] ?? '',
        'seat': apiData['seat_number'] ?? '좌석 미정',
        'seatGrade': apiData['seat_grade'] ?? '',
        'price': _formatPrice(apiData['seat_price']),
        'poster': _getSafeImageUrl(apiData['performance_main_image']),
        'status': status,
        'dday': dday,
        'createdAt': _formatDateTime(createdAt),
        'transferHistory': apiData['transfer_history'] ?? [],
        'sessionDateTime': sessionDateTime,
        'rawPrice': apiData['seat_price'] ?? 0,
      };
    } catch (e) {
      print('❌ 데이터 변환 오류: $e');
      // 오류 발생 시 기본값으로 반환
      return {
        'id': apiData['nft_ticket_id'] ?? 'unknown',
        'performanceId': apiData['performance_id'] ?? 0,
        'title': apiData['performance_title'] ?? '제목 없음',
        'performerName': apiData['performer_name'] ?? '아티스트 미정',
        'date': '날짜 미정',
        'time': '시간 미정',
        'venue': apiData['venue_name'] ?? '장소 미정',
        'venueLocation': apiData['venue_location'] ?? '',
        'seat': apiData['seat_number'] ?? '좌석 미정',
        'seatGrade': apiData['seat_grade'] ?? '',
        'price': _formatPrice(apiData['seat_price']),
        'poster': _getSafeImageUrl(apiData['performance_main_image']),
        'status': 'pending',
        'dday': 0,
        'createdAt': '날짜 미정',
        'transferHistory': apiData['transfer_history'] ?? [],
        'sessionDateTime': DateTime.now(),
        'rawPrice': apiData['seat_price'] ?? 0,
      };
    }
  }

  /// 안전한 이미지 URL 생성
  String _getSafeImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == 'null') {
      return 'https://via.placeholder.com/300x400?text=No+Image';
    }

    // URL이 유효한지 확인
    try {
      final uri = Uri.parse(imageUrl);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return imageUrl;
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

  /// 날짜시간 포맷팅 (YYYY.MM.DD HH:MM)
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  /// 가격 포맷팅
  String _formatPrice(int? price) {
    if (price == null || price == 0) return '가격 정보 없음';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('티켓 상세', style: TextStyle(color: AppColors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                '티켓 정보를 불러오는 중...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('티켓 상세', style: TextStyle(color: AppColors.white)),
        ),
        body: Center(
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
                onPressed: _loadTicketDetail,
                icon: Icon(Icons.refresh),
                label: Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_ticketDetail == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('티켓 상세', style: TextStyle(color: AppColors.white)),
        ),
        body: Center(
          child: Text(
            '티켓 정보가 없습니다.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final ticket = _ticketDetail!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 상단 이미지 헤더 (SliverAppBar)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.white),
                onPressed: widget.ticketId != null ? _loadTicketDetail : null,
              ),
              IconButton(
                icon: Icon(Icons.share, color: AppColors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ticket['poster'] ??
                        'https://via.placeholder.com/300x400?text=No+Image',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.gray300,
                        child: Icon(
                          Icons.broken_image,
                          size: 100,
                          color: AppColors.gray600,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 티켓 디지털 표시
                  _buildDigitalTicketSection(),

                  // 공연 상세 정보
                  _buildConcertDetailsSection(),

                  // NFT 정보
                  _buildNFTInfoSection(),

                  // 티켓 상태별 액션 버튼
                  _buildActionButtonsSection(),

                  // 주의사항 및 관람 안내
                  _buildNoticeSection(),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 티켓 디지털 표시 섹션
  Widget _buildDigitalTicketSection() {
    final ticket = _ticketDetail!;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            spreadRadius: 2,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 티켓 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NFT 디지털 티켓',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _copyTicketId(ticket['id']),
                    child: Text(
                      '# ${ticket['id']?.toUpperCase() ?? 'UNKNOWN'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          Text(
            ticket['title'] ?? '제목 없음',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            ticket['performerName'] ?? '아티스트 미정',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 20),

          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 24, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'NFT 인증 완료',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '블록체인에 기록된 디지털 티켓',
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
    );
  }

  // 공연 상세 정보 섹션
  Widget _buildConcertDetailsSection() {
    final ticket = _ticketDetail!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
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
            '공연 상세 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 16),

          _buildDetailRow(
            Icons.calendar_today,
            '공연 일시',
            '${ticket['date'] ?? '날짜 미정'} ${ticket['time'] ?? '시간 미정'}',
          ),
          _buildDetailRow(
            Icons.location_on,
            '공연 장소',
            ticket['venue'] ?? '장소 미정',
            subtitle:
                (ticket['venueLocation'] != null &&
                    ticket['venueLocation'].isNotEmpty)
                ? ticket['venueLocation']
                : null,
          ),
          _buildDetailRow(
            Icons.event_seat,
            '좌석 정보',
            '${ticket['seatGrade']} ${ticket['seatZone']}구역 ${ticket['seatNumber']}',
          ),
          //FIXME -> API 호출 방식 수정 필요
          // _buildDetailRow(
          //   Icons.local_offer,
          //   '티켓 가격',
          //   ticket['price'] ?? '가격 정보 없음',
          // ),
        ],
      ),
    );
  }

  // NFT 정보 섹션
  Widget _buildNFTInfoSection() {
    final ticket = _ticketDetail!;

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'NFT 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          _buildNFTDetailRow('발행 일시', ticket['createdAt'] ?? '정보 없음'),
          _buildNFTDetailRow('토큰 ID', ticket['id'] ?? 'unknown'),
          _buildNFTDetailRow(
            '소유권 이력',
            (ticket['transferHistory'] != null &&
                    ticket['transferHistory'].isNotEmpty)
                ? '${ticket['transferHistory'].length}회 양도됨'
                : '원소유자 → 현재 소유자',
          ),
          _buildNFTDetailRow('블록체인', 'Omnione Chain'),

          SizedBox(height: 12),
        ],
      ),
    );
  }

  // 액션 버튼 섹션
  // 액션 버튼 섹션 (수정된 부분)
  Widget _buildActionButtonsSection() {
    final ticket = _ticketDetail!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (ticket['status'] == 'pending') ...[
            // NFC 입장하기 버튼 (모바일 신분증 인증자만)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final canUseNFC =
                    authProvider.currentUserAuthLevel == 'mobile_id' ||
                    authProvider.currentUserAuthLevel == 'mobile_id_totally';
                // final canUseNFC = true;

                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: canUseNFC ? () => _handleNFCEntry() : null,
                    icon: Icon(Icons.nfc, size: 24),
                    label: Text(
                      canUseNFC ? 'NFC 간편 입장' : 'NFC 입장 (모바일 신분증 필요)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUseNFC
                          ? AppColors.success
                          : AppColors.gray400,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 12),

            // 수동 검표 버튼 (모든 사용자)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _handleManualEntry(),
                icon: Icon(Icons.person_pin, size: 24),
                label: Text(
                  '수동 검표',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // 양도하기 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _handleTransfer(),
                icon: Icon(Icons.swap_horiz, size: 24),
                label: Text(
                  '양도하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(color: AppColors.warning),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (ticket['status'] == 'transferring') ...[
            // 양도 관리 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _handleTransferManage(),
                icon: Icon(Icons.settings, size: 24),
                label: Text(
                  '양도 관리',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (ticket['status'] == 'completed') ...[
            // 사용 완료된 티켓
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '공연 입장 완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 액션 핸들러들 (수정된 부분)
  void _handleNFCEntry() {
    // NFC 입장 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NFCEntryScreen(
          ticketId: _ticketDetail!['id'],
          //FIXME 더미 테스트 삭제
          // ticketId: "1",
          ticketData: _ticketDetail!,
        ),
      ),
    );
  }

  void _handleManualEntry() {
    // 수동 검표 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualEntryScreen(
          ticketId: _ticketDetail!['id'],
          ticketData: _ticketDetail!,
        ),
      ),
    );
  }

  // 주의사항 및 관람 안내 섹션
  Widget _buildNoticeSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.gray600, size: 20),
              SizedBox(width: 8),
              Text(
                '주의사항 및 관람 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            '• 입장 시 신분증과 NFT 티켓이 모두 필요합니다\n'
            '• 공연 시작 30분 전까지 입장해주세요\n'
            '• 재입장은 불가하니 유의해주세요\n'
            '• 촬영 및 녹음은 금지되어 있습니다\n'
            '• 티켓 양도는 공연 7일 전까지만 가능합니다',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 상세 정보 행 위젯
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NFT 상세 정보 행 위젯
  Widget _buildNFTDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: label == '토큰 ID' ? () => _copyTicketId(value) : null,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  decoration: label == '토큰 ID'
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상태 관련 헬퍼 메서드들
  Color _getStatusColor() {
    switch (_ticketDetail?['status']) {
      case 'pending':
        return AppColors.success;
      case 'transferring':
        return AppColors.warning;
      case 'completed':
        return AppColors.primary;
      default:
        return AppColors.gray400;
    }
  }

  String _getStatusText() {
    switch (_ticketDetail?['status']) {
      case 'pending':
        return '입장 대기';
      case 'transferring':
        return '양도 중';
      case 'completed':
        return '사용 완료';
      default:
        return '알 수 없음';
    }
  }

  // 유틸리티 메서드들
  void _copyTicketId(String? ticketId) {
    final id = ticketId ?? 'unknown';
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('티켓 ID가 복사되었습니다'), duration: Duration(seconds: 2)),
    );
  }

  void _handleTransfer() {
    // TODO: 양도 등록 화면으로 이동
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('양도 등록 화면으로 이동합니다')));
  }

  void _handleTransferManage() {
    // TODO: 양도 관리 화면으로 이동
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('양도 관리 화면으로 이동합니다')));
  }
}
