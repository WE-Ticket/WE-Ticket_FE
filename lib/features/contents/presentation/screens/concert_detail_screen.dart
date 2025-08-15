import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_guard.dart';
import 'package:we_ticket/features/ticketing/presentation/screens/schedule_selection_screen.dart';
import 'package:we_ticket/features/contents/presentation/providers/contents_provider.dart';
import 'package:we_ticket/features/contents/data/performance_models.dart';
import 'package:we_ticket/features/transfer/presentation/screens/transfer_market_screen.dart';
import 'package:we_ticket/core/utils/app_logger.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class ConcertDetailScreen extends StatefulWidget {
  final int performanceId;

  const ConcertDetailScreen({super.key, required this.performanceId});

  @override
  State<ConcertDetailScreen> createState() => _ConcertDetailScreenState();
}

class _ConcertDetailScreenState extends State<ConcertDetailScreen> {
  PerformanceDetail? _performanceDetail;
  bool _isLoadingDetail = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPerformanceDetail();
  }

  Future<void> _loadPerformanceDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _errorMessage = null;
    });

    try {
      final contentsProvider = context.read<ContentsProvider>();
      await contentsProvider.loadPerformanceDetail(widget.performanceId);
      
      // Get the result from provider state
      final detail = contentsProvider.selectedPerformance;
      final error = contentsProvider.errorMessage;

      setState(() {
        if (error != null) {
          _errorMessage = error;
          _isLoadingDetail = false;
          AppLogger.error('공연 상세 정보 로드 실패', error, null, 'CONCERT_DETAIL');
        } else if (detail != null) {
          _performanceDetail = detail;
          _isLoadingDetail = false;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '상세 정보를 불러올 수 없습니다.';
        _isLoadingDetail = false;
      });
      AppLogger.error('공연 상세 정보 로드 예외', e.toString(), null, 'CONCERT_DETAIL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 슬라이버 앱바 (이미지 헤더)
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
                icon: Icon(Icons.share, color: AppColors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.favorite_border, color: AppColors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _getImageUrl(),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.gray300,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.gray300,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 100,
                              color: AppColors.gray600,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _getTitle(),
                              style: TextStyle(
                                color: AppColors.gray600,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                          AppColors.black.withValues(alpha: 0.7),
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
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusBadge(_getStatus()),
                            if (_getIsHot()) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 16),

                        Text(
                          _getTitle(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getArtist(),
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 20),

                        if (!_performanceDetail!.canBook) ...[
                          _buildTicketOpenInfoSection(),
                          SizedBox(height: 20),
                        ],

                        _buildDetailInfoCard(),

                        SizedBox(height: 20),

                        // 공연 세션 정보
                        _buildSessionInfoSection(),

                        SizedBox(height: 20),

                        Text(
                          '# 태그',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTagsSection(),

                        SizedBox(height: 20),

                        // 공연 상세 정보 섹션
                        _buildConcertDetailsSection(),

                        SizedBox(height: 120), // 하단 버튼 공간 확보
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // 하단 고정 버튼
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // 양도 마켓 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      //TODO 필터링 걸 것
                      MaterialPageRoute(builder: (_) => TransferMarketScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.storefront,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    '양도 마켓',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // 예매 버튼 - AuthGuard 적용
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _getStatus() == 'available'
                      ? () {
                          // AuthGuard를 사용하여 로그인 + 인증 레벨 확인
                          AuthGuard.requireAuthForTicketing(
                            context,
                            onAuthenticated: () {
                              // 인증 완료 후 예매 진행
                              final Map<String, dynamic> performanceInfo = {
                                'performance_id': _performanceDetail!.performanceId,
                                'title': _performanceDetail?.title ?? '제목 없음',
                                'performer_name':
                                    _performanceDetail?.performerName ?? '미정',
                                'venue_name':
                                    _performanceDetail?.venueName ?? '장소 미정',
                                'main_image': _performanceDetail?.mainImage,
                              };
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScheduleSelectionScreen(
                                    performanceInfo: performanceInfo,
                                  ),
                                ),
                              );
                            },
                            message: '안전한 티켓 예매를 위해 로그인과 본인 인증이 필요합니다.',
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(_getStatus()),
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _getButtonText(_getStatus()),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // API 데이터 우선, 없으면 전달받은 데이터 사용
  String _getImageUrl() {
    if (_performanceDetail != null) {
      return _performanceDetail!.mainImage.isNotEmpty
          ? _performanceDetail!.mainImage
          : 'https://via.placeholder.com/400x300?text=No+Image';
    }
    return 'https://via.placeholder.com/400x300?text=No+Image';
  }

  String _getTitle() {
    if (_performanceDetail != null) {
      return _performanceDetail!.title.isNotEmpty
          ? _performanceDetail!.title
          : '제목 없음';
    }
    return '제목 없음';
  }

  String _getArtist() {
    if (_performanceDetail != null) {
      return _performanceDetail!.performerName.isNotEmpty
          ? _performanceDetail!.performerName
          : '아티스트';
    }
    return '아티스트';
  }

  String _getStatus() {
    if (_performanceDetail != null) {
      // For now, use minPrice == 0 as soldout indicator
      if (_performanceDetail!.minPrice == 0) return 'soldout';
      if (!_performanceDetail!.canBook) return 'coming_soon';
      if (_performanceDetail!.canBook) return 'available';
      return 'closed';
    }
    return 'closed';
  }

  bool _getIsHot() {
    if (_performanceDetail != null) {
      return _performanceDetail!.tags.contains('HOT') || _performanceDetail!.tags.contains('인기');
    }
    return false;
  }

  String _getPrice() {
    if (_performanceDetail != null) {
      return _performanceDetail!.minPrice > 0
          ? _performanceDetail!.priceDisplay
          : '가격 미정';
    }
    return '가격 미정';
  }

  String _getGenre() {
    if (_performanceDetail != null) {
      return _performanceDetail!.genre.isNotEmpty
          ? _performanceDetail!.genre
          : '콘서트';
    }
    return '콘서트';
  }

  String _getVenue() {
    if (_performanceDetail != null) {
      return _performanceDetail!.venueName.isNotEmpty
          ? _performanceDetail!.venueName
          : '장소 미정';
    }
    return '장소 미정';
  }


  bool _getIsTicketOpen() {
    if (_performanceDetail != null) {
      return _performanceDetail!.canBook;
    }
    return false;
  }

  // 공연 세션 정보
  List<String> _getSessions() {
    if (_performanceDetail != null && _performanceDetail!.sessionList.isNotEmpty) {
      return _performanceDetail!.sessionList;
    }
    return [];
  }

  List<String> _getTags() {
    if (_performanceDetail != null) {
      return _performanceDetail!.tags.isNotEmpty
          ? _performanceDetail!.tags
          : ['공연'];
    }

    return ['공연'];
  }

  Widget _buildTagsSection() {
    final tags = _getTags();

    if (tags.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '태그 정보가 없습니다.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map<Widget>((tag) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    String text;

    switch (status) {
      case 'soldout':
        backgroundColor = AppColors.error;
        text = 'SOLD OUT';
        break;
      case 'coming_soon':
        backgroundColor = AppColors.warning;
        text = '오픈 예정';
        break;
      case 'closed':
        backgroundColor = AppColors.gray500;
        text = '판매 마감';
        break;
      default:
        backgroundColor = AppColors.success;
        text = '예매 가능';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailInfoRow(
            Icons.calendar_today,
            '공연일시',
            '${_performanceDetail?.startDate} - ${_performanceDetail?.endDate}',
          ),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(
            Icons.location_on,
            '공연장소',
            '${_getVenue()}${_performanceDetail?.venueLocation.isNotEmpty == true ? '\n(${_performanceDetail!.venueLocation})' : ''}',
          ),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(Icons.local_offer, '가격', _getPrice()),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(
            Icons.child_care,
            '연령',
            _performanceDetail?.ageRating ?? '미정',
          ),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(Icons.category, '장르', _getGenre()),
        ],
      ),
    );
  }

  // 티켓 오픈 일시 섹션
  Widget _buildTicketOpenInfoSection() {
    final isTicketOpen = _getIsTicketOpen();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 20, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                '예매 오픈 예정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          if (!isTicketOpen) ...[
            SizedBox(height: 8),
            Text(
              '티켓 오픈 예정', // Placeholder since ticketOpenDatetime not in domain entity
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 공연 세션 정보 섹션
  Widget _buildSessionInfoSection() {
    final sessions = _getSessions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_note, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              '공연 회차',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${sessions.length}회차',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        if (sessions.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 32, color: AppColors.gray400),
                SizedBox(height: 8),
                Text(
                  '공연 회차 정보가 아직 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: sessions.asMap().entries.map((entry) {
                final index = entry.key;
                final session = entry.value;
                final isLast = index == sessions.length - 1;

                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: AppColors.gray200,
                              width: 1,
                            ),
                          ),
                  ),
                  child: _buildSessionItem(session, index + 1),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }


  Widget _buildSessionItem(String sessionDateTime, int sessionNumber) {
    final DateTime? dateTime = _parseDateTime(sessionDateTime);

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$sessionNumber',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                dateTime != null
                    //TODO 이거 처음 써봄. 정리하기
                    ? DateFormat('M월 d일 (E)', 'ko_KR').format(dateTime)
                    : _extractDate(sessionDateTime),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 12),

              Text(
                dateTime != null
                    ? DateFormat('HH:mm').format(dateTime)
                    : _extractTime(sessionDateTime),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 날짜/시간 파싱 헬퍼 메서드들
  DateTime? _parseDateTime(String dateTimeString) {
    try {
      return DateTime.parse(dateTimeString.replaceAll(' ', 'T'));
    } catch (e) {
      return null;
    }
  }

  String _extractDate(String dateTimeString) {
    try {
      final date = dateTimeString.split(' ')[0];
      final parts = date.split('-');
      if (parts.length >= 3) {
        return '${parts[1]}월 ${parts[2]}일';
      }
    } catch (e) {
      // 파싱 실패시 원본 반환
    }
    return dateTimeString.split(' ')[0];
  }

  String _extractTime(String dateTimeString) {
    try {
      final time = dateTimeString.split(' ')[1];
      return time.substring(0, 5); // HH:MM 형태로 자르기
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Row(
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConcertDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '공연 상세 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (_isLoadingDetail) ...[
              SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12),

        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 32, color: AppColors.gray400),
                SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: _loadPerformanceDetail,
                  child: Text(
                    '다시 시도',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          )
        else if (_performanceDetail?.detailImage != null &&
            _performanceDetail!.detailImage.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _performanceDetail!.detailImage,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.gray100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: AppColors.gray100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 48, color: AppColors.gray400),
                        SizedBox(height: 8),
                        Text(
                          '상세 이미지를 불러올 수 없습니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 48, color: AppColors.gray400),
                SizedBox(height: 8),
                Text(
                  '공연 상세 포스터',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '(준비 중)',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'soldout':
        return AppColors.gray400;
      case 'coming_soon':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'soldout':
        return '매진';
      case 'coming_soon':
        return '오픈 예정';
      case 'closed':
        return '판매 마감';
      default:
        return '예매하기';
    }
  }
}
