import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/contents/presentation/screens/concert_list_screen.dart';
import 'package:we_ticket/features/contents/presentation/screens/concert_detail_screen.dart';
import 'package:we_ticket/features/contents/presentation/widgets/performace_view_card.dart';
import 'package:we_ticket/features/mypage/presentation/screens/my_page_screen.dart';
import 'package:we_ticket/features/mypage/presentation/screens/my_tickets_screen.dart';
import 'package:we_ticket/features/transfer/presentation/screens/transfer_market_screen.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_guard.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/auth/presentation/screens/login_screen.dart';
import 'package:we_ticket/features/contents/presentation/providers/contents_provider.dart';
import 'package:we_ticket/features/contents/data/mappers/performance_mapper.dart';
import 'package:we_ticket/features/contents/domain/entities/performance_list.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  Timer? _timer;
  final PerformanceMapper _mapper = PerformanceMapper();

  @override
  void initState() {
    super.initState();
    // API 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentsProvider>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int itemCount) {
    _timer?.cancel();
    if (itemCount > 1) {
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        if (_pageController.hasClients && mounted) {
          int nextPage = (_currentSlide + 1) % itemCount;
          _pageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentsProvider>(
      builder: (context, contentsProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  color: AppColors.primary,
                  size: 28,
                ),
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
                  AuthGuard.requireAuth(
                    context,
                    onAuthenticated: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyPageScreen()),
                      );
                    },
                    message: '마이페이지 이용을 위해 로그인이 필요합니다.',
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => contentsProvider.loadDashboardData(),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 7),
                  _buildFeaturedSlider(contentsProvider),
                  SizedBox(height: 20),
                  _buildQuickAccess(),
                  SizedBox(height: 20),

                  _buildUpcomingConcerts(contentsProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSlider(ContentsProvider contentsProvider) {
    // 로딩 상태
    if (contentsProvider.isLoading && (contentsProvider.hotPerformances?.isEmpty ?? true)) {
      return Container(
        height: 220,
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'HOT 공연 로딩 중...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // 로딩 중 점 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gray300,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 에러 상태
    if (contentsProvider.errorMessage != null &&
        (contentsProvider.hotPerformances?.isEmpty ?? true)) {
      return Container(
        height: 220,
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.gray600,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'HOT 공연 로드 실패',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            contentsProvider.loadDashboardData(),
                        child: Text(
                          '다시 시도',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gray300,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hotPerformances = contentsProvider.hotPerformances;

    // 빈 상태
    if (hotPerformances == null || hotPerformances.isEmpty) {
      return Container(
        height: 220,
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        color: AppColors.gray600,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '현재 HOT 공연이 없습니다',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gray300,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 정상 데이터 표시
    _startAutoSlide(hotPerformances.length);

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
                // 사용자가 수동으로 슬라이드 조작할 때 타이머 재시작
                _timer?.cancel();
                _startAutoSlide(hotPerformances.length);
              },
              itemCount: hotPerformances.length,
              itemBuilder: (context, index) {
                final performance = hotPerformances[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConcertDetailScreen(
                          performanceId: performance.performanceId,
                        ),
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
                              performance.mainImage.isNotEmpty
                                  ? performance.mainImage
                                  : 'https://via.placeholder.com/400x300?text=No+Image',
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
                                        performance.title.length > 15
                                            ? '${performance.title.substring(0, 15)}...'
                                            : performance.title,
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
                                  performance.title.isNotEmpty
                                      ? performance.title
                                      : '제목 없음',
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
                                  '장르: ${performance.genre}',
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
              hotPerformances.length > 0
                  ? hotPerformances.length
                  : 1, // 최소 1개는 표시
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hotPerformances.length > 0 && _currentSlide == index
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
                AuthGuard.requireAuth(
                  context,
                  onAuthenticated: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyTicketsScreen(),
                      ),
                    );
                  },
                  message: '해당 서비스는 로그인이 필요합니다.',
                );
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildQuickAccessCard(
              '양도 마켓',
              Icons.storefront,
              AppColors.error,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TransferMarketScreen()),
                );
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

  Widget _buildUpcomingConcerts(ContentsProvider contentsProvider) {
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

        // 로딩 상태
        if (contentsProvider.isLoading &&
            (contentsProvider.availablePerformances?.isEmpty ?? true)) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3, // 로딩 스켈레톤 3개
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.gray400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.gray400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 150,
                            decoration: BoxDecoration(
                              color: AppColors.gray400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ]
        // 에러 상태
        else if (contentsProvider.errorMessage != null &&
            (contentsProvider.availablePerformances?.isEmpty ?? true)) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: AppColors.gray600, size: 32),
                  SizedBox(height: 8),
                  Text(
                    '예매 가능한 공연 로드 실패',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        contentsProvider.loadDashboardData(),
                    child: Text(
                      '다시 시도',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
        // 정상 데이터 또는 빈 상태
        else ...[
          _buildAvailablePerformancesList(
            (contentsProvider.availablePerformances ?? [])
                .map((item) => _mapper.availableItemToDomain(item))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAvailablePerformancesList(
    List<PerformanceAvailable> performances,
  ) {
    if (performances.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.event_note, color: AppColors.gray600, size: 48),
                SizedBox(height: 16),
                Text(
                  '현재 예매 가능한 공연이 없습니다',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: performances.length,
      itemBuilder: (context, index) {
        final performance = performances[index];
        return buildPerformanceDashboardListCard(context, performance);
      },
    );
  }
}
