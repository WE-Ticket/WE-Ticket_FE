import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ConcertDetailScreen extends StatelessWidget {
  final Map<String, dynamic> concert;

  const ConcertDetailScreen({Key? key, required this.concert})
    : super(key: key);

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
                onPressed: () {
                  // TODO 공유 기능
                },
              ),
              IconButton(
                icon: Icon(Icons.favorite_border, color: AppColors.white),
                onPressed: () {
                  // TODO 찜하기 기능
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    concert['image'],
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

          // 컨텐츠 영역
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기본 정보
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상태 배지들
                        Row(
                          children: [
                            _buildStatusBadge(concert['status']),
                            if (concert['isHot']) ...[
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

                        // 제목과 아티스트
                        Text(
                          concert['title'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          concert['artist'],
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 20),

                        // 상세 정보
                        _buildDetailInfoCard(),

                        SizedBox(height: 20),

                        // 태그들
                        Text(
                          '태그',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: concert['tags'].map<Widget>((tag) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                        ),

                        SizedBox(height: 100), // 하단 버튼 공간 확보
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
              // 가격 정보
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '가격',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      concert['price'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // 예매 버튼
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: concert['status'] == 'available'
                      ? () {
                          // TODO 예매하기 페이지로 이동
                          _showBookingDialog(context);
                        }
                      : concert['status'] == 'coming_soon'
                      ? () {
                          // TODO 오픈 알림 신청
                          _showNotificationDialog(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(concert['status']),
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _getButtonText(concert['status']),
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
            '${concert['date']} ${concert['time']}',
          ),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(
            Icons.location_on,
            '공연장소',
            '${concert['venue']} (${concert['location']})',
          ),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(Icons.local_offer, '가격', concert['price']),
          Divider(color: AppColors.gray200, height: 24),
          _buildDetailInfoRow(Icons.category, '장르', concert['category']),
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
        return '오픈 알림 신청';
      default:
        return '예매하기';
    }
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('예매하기'),
        content: Text('${concert['title']} 예매 페이지로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO 실제 예매 페이지로 이동
            },
            child: Text('예매하기'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오픈 알림 신청'),
        content: Text('${concert['title']} 예매 오픈 시 알림을 받으시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO 알림 신청 로직
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('오픈 알림이 신청되었습니다.')));
            },
            child: Text('신청하기'),
          ),
        ],
      ),
    );
  }
}
