import 'package:flutter/material.dart';
import './nft_ticket_complete_screen.dart.dart';
import '../../utils/app_colors.dart';

class NFTIssuanceScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const NFTIssuanceScreen({Key? key, required this.paymentData})
    : super(key: key);

  @override
  _NFTIssuanceScreenState createState() => _NFTIssuanceScreenState();
}

class _NFTIssuanceScreenState extends State<NFTIssuanceScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;
  //FIXME 어디까지 안내를 할 것인가
  final List<String> _steps = [
    '결제 검증 중...',
    '블록체인 네트워크 연결 중...',
    'NFT 메타데이터 생성 중...',
    '스마트 컨트랙트 배포 중...',
    'NFT 티켓 발행 중...',
    '티켓 등록 완료!',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startIssuanceProcess();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startIssuanceProcess() async {
    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _currentStep = i;
      });

      _progressController.reset();
      _progressController.forward();

      // 각 단계별 소요 시간 가상 설정
      int delay = i == _steps.length - 1 ? 1000 : 1500 + (i * 200);
      await Future.delayed(Duration(milliseconds: delay));
    }

    await Future.delayed(Duration(milliseconds: 500));
    _navigateToCompleteScreen();
  }

  void _navigateToCompleteScreen() {
    // FIXME NFT 티켓 데이터 생성 (더미데이터)
    final nftTicketData = {
      ...widget.paymentData,
      'nftId': 'NFT_${DateTime.now().millisecondsSinceEpoch}',
      'tokenId': '${DateTime.now().millisecondsSinceEpoch}',
      'contractAddress':
          '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
      'blockchainNetwork': 'OmniOne Chain',
      'issuedAt': DateTime.now().toIso8601String(),
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NFTTicketCompleteScreen(nftData: nftTicketData),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 방지
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 40),

                _buildHeader(),

                SizedBox(height: 60),

                _buildNFTAnimation(),

                SizedBox(height: 60),

                _buildProgressSection(),

                SizedBox(height: 40),

                _buildCurrentStep(),

                SizedBox(height: 60),

                _buildBottomMessage(),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.verified, size: 48, color: AppColors.primary),
        SizedBox(height: 16),
        Text(
          'NFT 티켓 발행 중',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '블록체인에 당신만의 티켓을 생성하고 있습니다',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNFTAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  spreadRadius: 8,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              size: 60,
              color: AppColors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    double progress = (_currentStep + 1) / _steps.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '진행률',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_currentStep + 1)}/${_steps.length}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value:
                  (progress - (1 / _steps.length)) +
                  (_progressAnimation.value / _steps.length),
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            );
          },
        ),

        SizedBox(height: 8),

        Text(
          '${(progress * 100).toInt()}% 완료',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sync, color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 진행 중',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _steps[_currentStep],
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),

          if (_currentStep > 0) ...[
            SizedBox(height: 16),
            Divider(color: AppColors.border),
            SizedBox(height: 12),

            Column(
              children: List.generate(_currentStep, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      SizedBox(width: 12),
                      Text(
                        _steps[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '잠시만 기다려주세요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'NFT 티켓이 블록체인에 안전하게 기록되고 있습니다.\n화면을 닫지 마세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
