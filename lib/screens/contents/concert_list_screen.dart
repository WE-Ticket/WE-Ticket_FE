import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'concert_detail_screen.dart';

class ConcertListScreen extends StatefulWidget {
  @override
  _ConcertListScreenState createState() => _ConcertListScreenState();
}

class _ConcertListScreenState extends State<ConcertListScreen> {
  String _selectedCategory = '전체';
  String _sortBy = '최신순';

  // FIXME 더미 데이터 -> API
  final List<Map<String, dynamic>> _concerts = [
    {
      'id': 'concert_1',
      'title': '2025 RIIZE CONCERT TOUR',
      'artist': 'RIIZE',
      'date': '2025.07.04',
      'time': '20:00',
      'venue': 'KSPO DOME',
      'location': '서울',
      'image':
          'https://talkimg.imbc.com/TVianUpload/tvian/TViews/image/2025/05/22/0be8f4e2-5e79-4a67-b80c-b14654cf908c.jpg',
      'price': '99,000원부터',
      'category': 'K-POP',
      'status': 'available', // available, soldout, coming_soon
      'isHot': true,
      'tags': ['HOT', '라이즈'],
    },
    {
      'id': 'concert_2',
      'title': 'NewJeans Fan Meeting',
      'artist': 'NewJeans',
      'date': '2025.07.25',
      'time': '19:00',
      'venue': '올림픽공원 체조경기장',
      'location': '서울',
      'image':
          'https://img4.yna.co.kr/etc/inner/KR/2024/06/25/AKR20240625045000005_01_i_P4.jpg',
      'price': '88,000원부터',
      'category': 'K-POP',
      'status': 'available',
      'isHot': false,
      'tags': ['뉴진스', '팬미팅'],
    },
    {
      'id': 'concert_3',
      'title': 'SEVENTEEN CONCERT',
      'artist': 'SEVENTEEN',
      'date': '2025.08.10',
      'time': '18:00',
      'venue': 'KSPO DOME',
      'location': '서울',
      'image': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
      'price': '132,000원부터',
      'category': 'K-POP',
      'status': 'soldout',
      'isHot': true,
      'tags': ['세븐틴', 'SOLD OUT'],
    },
    {
      'id': 'concert_4',
      'title': 'KAI ON',
      'artist': 'KAI',
      'date': '2025.08.30',
      'time': '19:30',
      'venue': '잠실실내체육관',
      'location': '서울',
      'image':
          'https://cdn2.smentertainment.com/wp-content/uploads/2025/04/%EC%B9%B4%EC%9D%B4-%EC%86%94%EB%A1%9C-%EC%BD%98%EC%84%9C%ED%8A%B8-%ED%88%AC%EC%96%B4-KAION-%ED%8F%AC%EC%8A%A4%ED%84%B0-%EC%9D%B4%EB%AF%B8%EC%A7%80-1.jpg',
      'price': '110,000원부터',
      'category': 'K-POP',
      'status': 'coming_soon',
      'isHot': false,
      'tags': ['KAI', '곧 오픈'],
    },
    {
      'id': 'concert_5',
      'title': 'ATEEZ CONCERT 2025',
      'artist': 'ATEEZ',
      'date': '2025.08.15',
      'time': '20:00',
      'venue': '인스파이어 아레나',
      'location': '인천',
      'image':
          'https://tkfile.yes24.com/upload2/PerfBlog/202505/20250527/20250527-53911.jpg',
      'price': '99,000원부터',
      'category': 'K-POP',
      'status': 'available',
      'isHot': false,
      'tags': ['에이티즈'],
    },
  ];

  final List<String> _categories = ['전체', 'K-POP', '발라드', '록', '힙합', '인디'];
  final List<String> _sortOptions = ['최신순', '인기순', '가격순', '날짜순'];

  List<Map<String, dynamic>> get _filteredConcerts {
    List<Map<String, dynamic>> filtered = _concerts;

    // 카테고리 필터링
    if (_selectedCategory != '전체') {
      filtered = filtered
          .where((concert) => concert['category'] == _selectedCategory)
          .toList();
    }

    // 정렬
    switch (_sortBy) {
      case '최신순':
        // 기본 순서 유지
        break;
      case '인기순':
        filtered.sort((a, b) => (b['isHot'] ? 1 : 0) - (a['isHot'] ? 1 : 0));
        break;
      case '가격순':
        filtered.sort((a, b) => a['price'].compareTo(b['price']));
        break;
      case '날짜순':
        filtered.sort((a, b) => a['date'].compareTo(b['date']));
        break;
    }

    return filtered;
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
              // 검색 기능
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 및 정렬 필터
          _buildFilterSection(),

          // 공연 목록
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                // TODO 새로고침 로직
                await Future.delayed(Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _filteredConcerts.length,
                itemBuilder: (context, index) {
                  final concert = _filteredConcerts[index];
                  return _buildConcertCard(concert);
                },
              ),
            ),
          ),
        ],
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
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: AppColors.gray600,
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
                    children: concert['tags'].map<Widget>((tag) {
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
                          tag,
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
          ),
        ),
      ],
    );
  }
}
