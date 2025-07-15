import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

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
                icon: Icon(Icons.share, color: AppColors.white),
                onPressed: () => _shareTicket(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ticket['poster'],
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

  // 티켓 디지털 표시 섹션 (QR 코드 제거)
  Widget _buildDigitalTicketSection() {
    final ticket = widget.ticket;

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
                  Text(
                    '# ${ticket['id']?.toUpperCase() ?? 'UNKNOWN'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
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
            ticket['title'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            ticket['artist'],
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
                    SizedBox(height: 20),
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
    final ticket = widget.ticket;

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
            '${ticket['date']} ${ticket['time']}',
          ),
          _buildDetailRow(Icons.location_on, '공연 장소', ticket['venue']),
          _buildDetailRow(Icons.event_seat, '좌석 정보', ticket['seat']),
          _buildDetailRow(Icons.local_offer, '티켓 가격', ticket['price']),
        ],
      ),
    );
  }

  // NFT 정보 섹션
  Widget _buildNFTInfoSection() {
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

          _buildNFTDetailRow('발행 일시', '2025.06.15 14:30'),
          _buildNFTDetailRow('소유권 이력', '원소유자 → 현재 소유자'),
          _buildNFTDetailRow('블록체인', 'Omnione Chain'),

          SizedBox(height: 12),
        ],
      ),
    );
  }

  // 액션 버튼 섹션
  Widget _buildActionButtonsSection() {
    final ticket = widget.ticket;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (ticket['status'] == 'upcoming') ...[
            // 입장하기 버튼 (공연 당일에 활성화)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _handleEntry(),
                icon: Icon(Icons.nfc, size: 24),
                label: Text(
                  '입장하기 (NFC 인증)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
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
          ],
        ],
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
            '• 여기에 기획사별 주어지는 주의사항 혹은 일반적인 주의사항 입력하면 될듯\n'
            '• 입장 시 신분증과 NFT 티켓이 모두 필요합니다\n'
            '• 공연 시작 30분 전까지 입장해주세요\n'
            '• 재입장은 불가하니 유의해주세요\n'
            '• 촬영 및 녹음은 금지되어 있습니다',
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
  Widget _buildDetailRow(IconData icon, String label, String value) {
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
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상태 관련 헬퍼 메서드들
  Color _getStatusColor() {
    switch (widget.ticket['status']) {
      case 'upcoming':
        return AppColors.success;
      case 'transferring':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusText() {
    switch (widget.ticket['status']) {
      case 'upcoming':
        return '입장 대기';
      case 'transferring':
        return '양도 중';
      default:
        return '활성';
    }
  }

  // 액션 핸들러들
  void _handleEntry() {
    // TODO: 05_01_NFC입장활성화 / 05_02_일반 검표 입장
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('입장하기'),
        content: Text('NFC 입장 또는 일반 검표 입장을 선택하세요.'),
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
              ).showSnackBar(SnackBar(content: Text('NFC 입장 활성화 화면으로 이동합니다')));
            },
            child: Text('NFC 입장'),
          ),
        ],
      ),
    );
  }

  void _handleTransfer() {
    // TODO: 04_02_양도등록
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('양도 등록 화면으로 이동합니다')));
  }

  void _handleTransferManage() {
    // TODO: 06_03_내티켓관리
    Navigator.pop(context);
  }

  void _shareTicket() {
    // 티켓 공유 기능
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('티켓 정보가 공유되었습니다')));
  }
}
