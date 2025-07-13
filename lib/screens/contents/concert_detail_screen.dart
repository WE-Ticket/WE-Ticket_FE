import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/screens/ticketing/schedul_selection_screen.dart.dart';
import 'package:we_ticket/providers/api_provider.dart';
import 'package:we_ticket/models/performance_models.dart';
import '../../utils/app_colors.dart';

class ConcertDetailScreen extends StatefulWidget {
  final Map<String, dynamic> concert;

  const ConcertDetailScreen({Key? key, required this.concert})
    : super(key: key);

  @override
  _ConcertDetailScreenState createState() => _ConcertDetailScreenState();
}

class _ConcertDetailScreenState extends State<ConcertDetailScreen> {
  PerformanceDetail? _detailFromApi;
  bool _isLoadingDetail = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPerformanceDetail();
  }

  Future<void> _loadPerformanceDetail() async {
    // concert['id']에서 performanceId 추출
    final concertId = widget.concert['id'].toString();
    int? performanceId;

    // ID에서 숫자 추출 (예: "featured_123" → 123, "upcoming_456" → 456)
    if (concertId.contains('_')) {
      final parts = concertId.split('_');
      if (parts.length > 1) {
        performanceId = int.tryParse(parts.last);
      }
    } else {
      performanceId = int.tryParse(concertId);
    }

    if (performanceId == null) {
      print('⚠️ Performance ID를 추출할 수 없습니다: $concertId');
      return;
    }

    setState(() {
      _isLoadingDetail = true;
      _errorMessage = null;
    });

    try {
      final apiProvider = context.read<ApiProvider>();
      final detail = await apiProvider.apiService.performance
          .getPerformanceDetail(performanceId);

      setState(() {
        _detailFromApi = detail;
        _isLoadingDetail = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '상세 정보를 불러올 수 없습니다.';
        _isLoadingDetail = false;
      });
      print('❌ 공연 상세 정보 로드 실패: $e');
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
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 10,
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

                        _buildDetailInfoCard(),

                        SizedBox(height: 20),

                        Text(
                          '태그',
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showTransferMarketDialog(context);
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

              // 예매 버튼
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _getStatus() == 'available'
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScheduleSelectionScreen(
                                concertInfo: widget.concert,
                              ),
                            ),
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
    if (_detailFromApi != null) {
      return _detailFromApi!.mainImage.isNotEmpty
          ? _detailFromApi!.mainImage
          : widget.concert['image'] ??
                'https://via.placeholder.com/400x300?text=No+Image';
    }
    return widget.concert['image'] ??
        'https://via.placeholder.com/400x300?text=No+Image';
  }

  String _getTitle() {
    if (_detailFromApi != null) {
      return _detailFromApi!.title.isNotEmpty ? _detailFromApi!.title : '제목 없음';
    }
    return widget.concert['title'] ?? '제목 없음';
  }

  String _getArtist() {
    if (_detailFromApi != null) {
      return _detailFromApi!.performerName.isNotEmpty
          ? _detailFromApi!.performerName
          : '아티스트';
    }
    return widget.concert['artist'] ?? '아티스트';
  }

  String _getStatus() {
    if (_detailFromApi != null) {
      if (_detailFromApi!.isSoldOut) return 'soldout';
      if (!_detailFromApi!.isTicketOpen) return 'coming_soon';
      if (_detailFromApi!.isAvailable) return 'available';
      return 'closed';
    }
    return widget.concert['status'] ?? 'available';
  }

  bool _getIsHot() {
    if (_detailFromApi != null) {
      return _detailFromApi!.isHot;
    }
    return widget.concert['isHot'] ?? false;
  }

  String _getPrice() {
    if (_detailFromApi != null) {
      return _detailFromApi!.minPrice > 0
          ? _detailFromApi!.priceDisplay
          : '가격 미정';
    }
    return widget.concert['price'] ?? '가격 미정';
  }

  String _getGenre() {
    if (_detailFromApi != null) {
      return _detailFromApi!.genre.isNotEmpty ? _detailFromApi!.genre : 'K-POP';
    }
    return widget.concert['category'] ?? 'K-POP';
  }

  String _getVenue() {
    if (_detailFromApi != null) {
      return _detailFromApi!.venueName.isNotEmpty
          ? _detailFromApi!.venueName
          : '장소 미정';
    }
    return widget.concert['venue'] ?? '장소 미정';
  }

  String _getDate() {
    if (_detailFromApi != null) {
      return _detailFromApi!.startDate.isNotEmpty
          ? _detailFromApi!.startDate
          : '날짜 미정';
    }
    return widget.concert['date'] ?? '날짜 미정';
  }

  List<String> _getTags() {
    if (_detailFromApi != null) {
      return _detailFromApi!.tags.isNotEmpty ? _detailFromApi!.tags : ['공연'];
    }
    if (widget.concert['tags'] != null) {
      return List<String>.from(widget.concert['tags']);
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
            color: AppColors.primary.withOpacity(0.1),
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
            '${_getDate()} ${widget.concert['time'] ?? '시간 미정'}',
          ),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(
            Icons.location_on,
            '공연장소',
            '${_getVenue()} (${widget.concert['location'] ?? '위치 미정'})',
          ),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(Icons.local_offer, '가격', _getPrice()),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(Icons.category, '장르', _getGenre()),
        ],
      ),
    );
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
        else if (_detailFromApi?.detailImage != null &&
            _detailFromApi!.detailImage.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _detailFromApi!.detailImage,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.gray100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
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
                    height: 200,
                    color: AppColors.gray100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 32,
                          color: AppColors.gray400,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '상세 이미지를 불러올 수 없습니다',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontSize: 12,
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

  void _showTransferMarketDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('양도 마켓'),
        content: Text('${_getTitle()} 양도 티켓을 확인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('양도 마켓으로 이동합니다.')));
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}
