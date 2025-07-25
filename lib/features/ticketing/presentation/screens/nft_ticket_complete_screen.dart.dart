import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:we_ticket/features/mypage/presentation/screens/my_tickets_screen.dart';
import '../../../../core/constants/app_colors.dart';

class NFTTicketCompleteScreen extends StatefulWidget {
  final Map<String, dynamic> nftData;

  const NFTTicketCompleteScreen({Key? key, required this.nftData})
    : super(key: key);

  @override
  _NFTTicketCompleteScreenState createState() =>
      _NFTTicketCompleteScreenState();
}

class _NFTTicketCompleteScreenState extends State<NFTTicketCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 200));
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 40),

              _buildSuccessHeader(),

              SizedBox(height: 40),

              _buildNFTTicketCard(),

              SizedBox(height: 32),

              _buildNFTInfo(),

              SizedBox(height: 32),

              _buildActionButtons(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.successGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  spreadRadius: 8,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.check, size: 50, color: AppColors.white),
          ),

          SizedBox(height: 24),

          Text(
            '예매 완료!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 8),

          Text(
            '안전한 NFT 티켓이 발행되었습니다.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNFTTicketCard() {
    final concertInfo = widget.nftData['concertInfo'] ?? {};
    final schedule = widget.nftData['selectedSchedule'] ?? {};
    final seat = widget.nftData['selectedSeat'] ?? {};
    final zone = widget.nftData['selectedZone'] ?? '';
    final grade = widget.nftData['seatGrade'] ?? '';

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              spreadRadius: 4,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFT 디지털 티켓',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '#${widget.nftData['tokenId'] ?? 'UNKNOWN'}',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: AppColors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '인증됨',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // 공연 정보
            Text(
              concertInfo['title'] ?? '공연명',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 4),

            Text(
              concertInfo['artist'] ?? '아티스트',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 20),

            // 공연 상세 정보
            _buildTicketDetailRow(
              Icons.calendar_today,
              '${schedule['date'] ?? ''} ${schedule['time'] ?? ''}',
            ),

            SizedBox(height: 8),

            _buildTicketDetailRow(
              Icons.location_on,
              concertInfo['venue'] ?? '공연장',
            ),

            SizedBox(height: 8),

            _buildTicketDetailRow(
              Icons.event_seat,
              '$grade ${zone}구역 ${seat['row'] ?? ''}행 ${seat['col'] ?? ''}번',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white.withOpacity(0.8), size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNFTInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'NFT 상세 정보',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            _buildInfoRow('토큰 ID', widget.nftData['tokenId'] ?? 'N/A'),
            _buildInfoRow(
              '컨트랙트 주소',
              _formatAddress(widget.nftData['contractAddress']),
            ),
            _buildInfoRow(
              '블록체인 네트워크',
              widget.nftData['blockchainNetwork'] ?? 'OmniOne Chain',
            ),
            _buildInfoRow('발행 일시', _formatDateTime(widget.nftData['issuedAt'])),
            _buildInfoRow(
              '소유자',
              _formatAuthLevel(widget.nftData['verificationLevel'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontFamily: value.contains('0x') ? 'monospace' : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // 내 티켓 보기
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _goToMyTickets,
              icon: Icon(Icons.confirmation_number, size: 24),
              label: Text(
                '내 티켓에서 확인하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.3),
              ),
            ),
          ),

          SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _downloadTicket,
              icon: Icon(Icons.download, size: 20),
              label: Text(
                '티켓 이미지로 저장하기',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

          SizedBox(height: 24),

          TextButton(
            onPressed: _goToHome,
            child: Text(
              '홈으로 돌아가기',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) return 'N/A';
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAuthLevel(String? authLevel) {
    if (authLevel == null) return '인증자';
    try {
      if (authLevel == 'general')
        return '일반 인증자';
      else if (authLevel == 'mobile_id')
        return '모바일 신분증 인증자';
      else if (authLevel == 'mobile_id_totally')
        return '안전 인증자';
      else
        return '인증자';
    } catch (e) {
      return '인증자';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('클립보드에 복사되었습니다'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _goToMyTickets() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyTicketsScreen()),
    );
  }

  void _downloadTicket() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('티켓이 이미지로 저장 되었습니다'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _goToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
