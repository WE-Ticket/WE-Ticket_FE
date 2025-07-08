import 'package:flutter/material.dart';
import 'package:we_ticket/screens/contents/concert_list_screen.dart';
import 'package:we_ticket/screens/contents/concert_detail_screen.dart';
import 'dart:async';
import '../../utils/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  Timer? _timer;

  // FIXME 더미 데이터 -> API
  final List<Map<String, String>> _featuredConcerts = [
    {
      'title': '2025 RIIZE CONCERT TOUR',
      'date': '2025.07.04',
      'venue': 'KSPO DOME',
      'image':
          'https://talkimg.imbc.com/TVianUpload/tvian/TViews/image/2025/05/22/0be8f4e2-5e79-4a67-b80c-b14654cf908c.jpg',
    },
    {
      'title': 'ATEEZ CONCERT 2025',
      'date': '2025.08.15',
      'venue': '인스파이어 아레나',
      'image':
          'https://tkfile.yes24.com/upload2/PerfBlog/202505/20250527/20250527-53911.jpg',
    },
    {
      'title': '키스오프라이프 콘서트',
      'date': '2025.09.20',
      'venue': '서울월드컵경기장',
      'image':
          'https://ticketimage.interpark.com/Play/image/large/24/24013254_p.gif',
    },
  ];

  //FIXME 더미 데이터 -> API
  final List<Map<String, String>> _upcomingConcerts = [
    {
      'title': 'NewJeans Fan Meeting',
      'date': '2025.07.25',
      'venue': '올림픽공원',
      'image':
          'https://img4.yna.co.kr/etc/inner/KR/2024/06/25/AKR20240625045000005_01_i_P4.jpg',
    },
    {
      'title': 'SEVENTEEN CONCERT',
      'date': '2025.08.10',
      'venue': 'KSPO DOME',
      'image': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
    },
    {
      'title': 'KAI ON',
      'date': '2025.08.30',
      'venue': '잠실실내체육관',
      'image':
          'https://cdn2.smentertainment.com/wp-content/uploads/2025/04/%EC%B9%B4%EC%9D%B4-%EC%86%94%EB%A1%9C-%EC%BD%98%EC%84%9C%ED%8A%B8-%ED%88%AC%EC%96%B4-KAION-%ED%8F%AC%EC%8A%A4%ED%84%B0-%EC%9D%B4%EB%AF%B8%EC%A7%80-1.jpg',
    },
    {
      'title': 'SEVENTEEN CONCERT',
      'date': '2025.08.10',
      'venue': 'KSPO DOME',
      'image': 'https://newsimg.sedaily.com/2024/08/14/2DD0HP41GF_1.jpg',
    },
    {
      'title': '2025 RIIZE CONCERT TOUR',
      'date': '2025.07.04',
      'venue': 'KSPO DOME',
      'image':
          'https://talkimg.imbc.com/TVianUpload/tvian/TViews/image/2025/05/22/0be8f4e2-5e79-4a67-b80c-b14654cf908c.jpg',
    },
    {
      'title': 'ATEEZ CONCERT 2025',
      'date': '2025.08.15',
      'venue': '인스파이어 아레나',
      'image':
          'https://tkfile.yes24.com/upload2/PerfBlog/202505/20250527/20250527-53911.jpg',
    },
    {
      'title': '키스오프라이프 콘서트',
      'date': '2025.09.20',
      'venue': '서울월드컵경기장',
      'image':
          'https://ticketimage.interpark.com/Play/image/large/24/24013254_p.gif',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentSlide + 1) % _featuredConcerts.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // FIXME API 연동 후 삭제
  String _getArtistFromTitle(String title) {
    if (title.contains('RIIZE')) return 'RIIZE';
    if (title.contains('ATEEZ')) return 'ATEEZ';
    if (title.contains('키스오프라이프')) return 'Kiss Of Life';
    return '아티스트';
  }

  // FIXME API 연동 후 삭제
  String _getLocationFromVenue(String venue) {
    if (venue.contains('KSPO') || venue.contains('잠실') || venue.contains('올림픽'))
      return '서울';
    if (venue.contains('인스파이어')) return '인천';
    if (venue.contains('서울월드컵')) return '서울';
    return '서울';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.confirmation_number, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text(
              'WE-Ticket',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: AppColors.textPrimary),
            onPressed: () {
              // TODO 마이페이지로 이동
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          // TODO 새로고침 로직
          await Future.delayed(Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 추천 공연 슬라이더
              _buildFeaturedSlider(),

              SizedBox(height: 20),

              // 빠른 액세스 메뉴 (내 티켓, 양도 마켓)
              _buildQuickAccess(),

              SizedBox(height: 20),

              // 예매 가능한 공연 목록
              _buildUpcomingConcerts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSlider() {
    return Container(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
                //사용자가 수동으로 슬라이드 조작 할 때 타이머 재시작
                _timer?.cancel();
                _startAutoSlide();
              },
              itemCount: _featuredConcerts.length,
              itemBuilder: (context, index) {
                final concert = _featuredConcerts[index];
                return GestureDetector(
                  onTap: () {
                    // FIXME API 연동 후 수정
                    final detailConcert = {
                      'id': 'featured_${index}',
                      'title': concert['title']!,
                      'artist': _getArtistFromTitle(concert['title']!),
                      'date': concert['date']!,
                      'time': '20:00', // 기본값
                      'venue': concert['venue']!,
                      'location': _getLocationFromVenue(concert['venue']!),
                      'image': concert['image']!,
                      'price': '99,000원부터', // 기본값
                      'category': 'K-POP',
                      'status': 'available',
                      'isHot': true,
                      'tags': ['HOT', '추천'],
                    };

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConcertDetailScreen(concert: detailConcert),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.network(
                              concert['image']!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: AppColors.gray300,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
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
                          // 그라데이션 오버레이
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
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  concert['title']!,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${concert['date']} | ${concert['venue']}',
                                  style: TextStyle(
                                    color: AppColors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _featuredConcerts.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentSlide == index
                      ? AppColors.primary
                      : AppColors.gray300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickAccessCard(
              '내 티켓',
              Icons.confirmation_number,
              AppColors.success,
              () {
                // TODO 내 티켓 화면으로 이동
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildQuickAccessCard(
              '양도 마켓',
              Icons.swap_horiz,
              AppColors.error,
              () {
                // 양도 마켓으로 이동
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingConcerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '예매 가능한 공연',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConcertListScreen(),
                    ),
                  );
                },
                child: Text('전체보기', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: _upcomingConcerts.length,
          itemBuilder: (context, index) {
            final concert = _upcomingConcerts[index];
            return _buildConcertCard(concert);
          },
        ),
      ],
    );
  }

  Widget _buildConcertCard(Map<String, String> concert) {
    return GestureDetector(
      onTap: () {
        // 카드 데이터를 상세 화면 형식에 맞게 변환
        final detailConcert = {
          'id': 'upcoming_${concert['title']}',
          'title': concert['title']!,
          'artist': _getArtistFromTitle(concert['title']!),
          'date': concert['date']!,
          'time': '19:30', // 기본값
          'venue': concert['venue']!,
          'location': _getLocationFromVenue(concert['venue']!),
          'image': concert['image']!,
          'price': '88,000원부터', // 기본값
          'category': 'K-POP',
          'status': 'available',
          'isHot': false,
          'tags': ['예매 가능'],
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConcertDetailScreen(concert: detailConcert),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  concert['image']!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.gray300,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.music_note,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concert['title']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${concert['date']} | ${concert['venue']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
