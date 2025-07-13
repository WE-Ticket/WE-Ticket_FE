import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/providers/api_provider.dart';
import 'package:we_ticket/models/performance_models.dart';
import '../../utils/app_colors.dart';
import 'concert_detail_screen.dart';

class ConcertListScreen extends StatefulWidget {
  @override
  _ConcertListScreenState createState() => _ConcertListScreenState();
}

class _ConcertListScreenState extends State<ConcertListScreen> {
  String _selectedCategory = '전체';
  String _sortBy = '최신순';
  List<PerformanceListItem> _allPerformances = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _categories = ['전체', 'K-POP', '발라드', '록', '힙합', '인디'];
  final List<String> _sortOptions = ['최신순', '인기순', '가격순', '날짜순'];

  @override
  void initState() {
    super.initState();
    _loadAllPerformances();
  }

  Future<void> _loadAllPerformances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiProvider = context.read<ApiProvider>();
      final response = await apiProvider.apiService.performance
          .getAllPerformances();

      setState(() {
        _allPerformances = response.results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '공연 목록을 불러올 수 없습니다. 다시 시도해주세요.';
        _isLoading = false;
      });
      print('❌ 전체 공연 목록 로드 실패: $e');
    }
  }

  // FIXME API 연동 후 삭제 - 기존 호환성을 위해 유지
  String _getArtistFromTitle(String title) {
    if (title.contains('RIIZE')) return 'RIIZE';
    if (title.contains('ATEEZ')) return 'ATEEZ';
    if (title.contains('키스오브라이프') || title.contains('Kiss'))
      return 'Kiss Of Life';
    if (title.contains('NewJeans')) return 'NewJeans';
    if (title.contains('SEVENTEEN')) return 'SEVENTEEN';
    if (title.contains('KAI')) return 'KAI';
    return '아티스트';
  }

  // FIXME API 연동 후 삭제 - 기존 호환성을 위해 유지
  String _getLocationFromVenue(String venue) {
    if (venue.contains('KSPO') || venue.contains('잠실') || venue.contains('올림픽'))
      return '서울';
    if (venue.contains('인스파이어')) return '인천';
    if (venue.contains('서울월드컵')) return '서울';
    return '서울';
  }

  // API 데이터를 기존 형식으로 변환
  Map<String, dynamic> _convertToLegacyFormat(PerformanceListItem performance) {
    return {
      'id': 'performance_${performance.performanceId}',
      'title': performance.title.isNotEmpty ? performance.title : '제목 없음',
      'artist': performance.performerName.isNotEmpty
          ? performance.performerName
          : _getArtistFromTitle(performance.title),
      'date': performance.startDate.isNotEmpty
          ? performance.startDate
          : '날짜 미정',
      'time': '19:30', // 기본값 (API에서 시간 정보 없음)
      'venue': performance.venueName.isNotEmpty
          ? performance.venueName
          : '장소 미정',
      'location': _getLocationFromVenue(performance.venueName),
      'image': performance.mainImage.isNotEmpty
          ? performance.mainImage
          : 'https://via.placeholder.com/400x300?text=No+Image',
      'price': performance.minPrice > 0 ? performance.priceDisplay : '가격 미정',
      'category': performance.genre.isNotEmpty ? performance.genre : 'K-POP',
      'status': performance.isSoldOut
          ? 'soldout'
          : (performance.isTicketOpen ? 'available' : 'coming_soon'),
      'isHot': performance.isHot,
      'tags': performance.tags.isNotEmpty
          ? performance.tags
          : [performance.statusText],
    };
  }

  List<Map<String, dynamic>> get _filteredConcerts {
    List<Map<String, dynamic>> converted = _allPerformances
        .map((performance) => _convertToLegacyFormat(performance))
        .toList();

    // 카테고리 필터링
    if (_selectedCategory != '전체') {
      converted = converted
          .where((concert) => concert['category'] == _selectedCategory)
          .toList();
    }

    // 정렬
    switch (_sortBy) {
      case '최신순':
        // 기본 순서 유지
        break;
      case '인기순':
        converted.sort((a, b) => (b['isHot'] ? 1 : 0) - (a['isHot'] ? 1 : 0));
        break;
      case '가격순':
        converted.sort((a, b) {
          // 가격 문자열에서 숫자만 추출해서 비교
          String priceA = a['price'].toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          String priceB = b['price'].toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          int numA = int.tryParse(priceA) ?? 0;
          int numB = int.tryParse(priceB) ?? 0;
          return numA.compareTo(numB);
        });
        break;
      case '날짜순':
        converted.sort(
          (a, b) => a['date'].toString().compareTo(b['date'].toString()),
        );
        break;
    }

    return converted;
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
          '공연 목록',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: 검색 기능 구현
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('검색 기능은 추후 구현 예정입니다.')));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 및 정렬 필터
          _buildFilterSection(),

          // 공연 목록
          Expanded(child: _buildContentSection()),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    // 로딩 상태
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              '공연 목록을 불러오는 중...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 에러 상태
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.gray600),
              SizedBox(height: 16),
              Text(
                '공연 목록 로드 실패',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAllPerformances,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '다시 시도',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 빈 상태
    if (_allPerformances.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 64, color: AppColors.gray600),
              SizedBox(height: 16),
              Text(
                '등록된 공연이 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '곧 다양한 공연이 업데이트될 예정입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // 정상 데이터 표시
    final filteredConcerts = _filteredConcerts;

    if (filteredConcerts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: AppColors.gray600),
              SizedBox(height: 16),
              Text(
                '조건에 맞는 공연이 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '다른 카테고리나 정렬 조건을 시도해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAllPerformances,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredConcerts.length,
        itemBuilder: (context, index) {
          final concert = filteredConcerts[index];
          return _buildConcertCard(concert);
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 카테고리 선택
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                bool isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 12),

          // 정렬 옵션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${_filteredConcerts.length}개 공연',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              DropdownButton<String>(
                value: _sortBy,
                underline: Container(),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sortBy = newValue;
                    });
                  }
                },
                items: _sortOptions.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConcertCard(Map<String, dynamic> concert) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConcertDetailScreen(concert: concert),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 섹션
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      concert['image'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.gray300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
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
                                size: 50,
                                color: AppColors.gray600,
                              ),
                              SizedBox(height: 8),
                              Text(
                                concert['title'].toString().length > 20
                                    ? '${concert['title'].toString().substring(0, 20)}...'
                                    : concert['title'].toString(),
                                style: TextStyle(
                                  color: AppColors.gray600,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 상태 배지
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(concert['status']),
                ),

                // HOT 배지
                if (concert['isHot'])
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  ),
              ],
            ),

            // 정보 섹션
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concert['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    concert['artist'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 12),

                  _buildInfoRow(
                    Icons.calendar_today,
                    '${concert['date']} ${concert['time']}',
                  ),
                  SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.location_on,
                    '${concert['venue']} (${concert['location']})',
                  ),
                  SizedBox(height: 6),
                  _buildInfoRow(Icons.local_offer, concert['price']),

                  SizedBox(height: 12),

                  // 태그들
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (concert['tags'] as List<dynamic>).map<Widget>((
                      tag,
                    ) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag.toString(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      default:
        backgroundColor = AppColors.success;
        text = '예매 가능';
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
