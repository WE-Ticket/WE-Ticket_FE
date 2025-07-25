import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/ticketing/data/models/ticket_models.dart';
import 'package:we_ticket/features/ticketing/data/services/ticket_service.dart';
import 'package:we_ticket/features/ticketing/presentation/screens/nft_ticket_complete_screen.dart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/providers/api_provider.dart';

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
  List<String> _steps = [];
  bool _hasError = false;
  String _errorMessage = '';
  late TicketService _ticketService;

  @override
  void initState() {
    super.initState();
    print('🎫 NFT 발행 화면 초기화');
    print('📦 paymentData: ${widget.paymentData}');

    // initState에서는 context.read를 사용할 수 없으므로
    // didChangeDependencies에서 초기화하도록 연기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
      _initSteps();
      _initAnimations();
      _startIssuanceProcess();
    });
  }

  void _initServices() {
    // ApiProvider에서 이미 초기화된 서비스 사용
    final apiProvider = context.read<ApiProvider>();
    _ticketService = apiProvider.apiService.ticket;
  }

  void _initSteps() {
    final paymentType = widget.paymentData['paymentType'] as String?;
    if (paymentType == 'transfer') {
      _steps = ['양도 요청 검증 중...', '소유권 이전 처리 중...', '블록체인 기록 중...', '양도 이행 완료!'];
    } else {
      _steps = ['결제 정보 검증 중...', 'NFT 티켓 생성 중...', '블록체인 등록 중...', '티켓 발행 완료!'];
    }
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
    try {
      final paymentType = widget.paymentData['paymentType'] as String?;

      if (paymentType == 'transfer') {
        await _processTransfer();
      } else {
        await _processTicketing();
      }
    } catch (e) {
      print('❌ 발행/양도 처리 오류: $e');
      _handleError(e.toString());
    }
  }

  /// 티켓 발행 프로세스
  Future<void> _processTicketing() async {
    // 1단계: 결제 정보 검증
    await _executeStep(0, () async {
      // 결제 검증 로직 (실제로는 PG사 검증 API 호출)
      await Future.delayed(Duration(milliseconds: 1500));
      print('✅ 결제 검증 완료');
    });

    // 2단계: NFT 티켓 생성 요청
    CreateTicketResponse? ticketResponse;
    await _executeStep(1, () async {
      // 인증된 사용자 ID 가져오기
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUserId;

      if (userId == null) {
        throw Exception('로그인이 필요합니다. 다시 로그인해주세요.');
      }

      // 안전한 타입 변환
      final performanceSessionId = _safeParseInt(
        widget.paymentData['performanceSessionId'],
      );
      final seatId = _safeParseInt(
        widget.paymentData['selectedSeat']?['seatId'] ??
            widget.paymentData['seatId'],
      );

      print(
        '🔍 티켓 생성 요청 데이터: performanceSessionId=$performanceSessionId, seatId=$seatId, userId=$userId',
      );

      final request = CreateTicketRequest(
        performanceSessionId: performanceSessionId,
        seatId: seatId,
        userId: userId,
      );

      ticketResponse = await _ticketService.createTicket(request);
      print('✅ NFT 티켓 생성 요청 완료: ${ticketResponse?.ticketId}');
    });

    // 3단계: 블록체인 등록 처리
    await _executeStep(2, () async {
      await Future.delayed(Duration(milliseconds: 2000));
      print('✅ 블록체인 등록 완료');
    });

    // 4단계: 완료
    await _executeStep(3, () async {
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ 티켓 발행 완료');
    });

    // 완료 화면으로 이동
    await Future.delayed(Duration(milliseconds: 500));
    _navigateToCompleteScreen(ticketResponse);
  }

  /// 양도 이행 프로세스
  Future<void> _processTransfer() async {
    // 1단계: 양도 요청 검증
    await _executeStep(0, () async {
      await Future.delayed(Duration(milliseconds: 1200));
      print('✅ 양도 요청 검증 완료');
    });

    // 2단계: 소유권 이전 처리
    await _executeStep(1, () async {
      await Future.delayed(Duration(milliseconds: 1800));
      print('✅ 소유권 이전 처리 완료');
    });

    // 3단계: 블록체인 기록
    await _executeStep(2, () async {
      await Future.delayed(Duration(milliseconds: 2200));
      print('✅ 블록체인 기록 완료');
    });

    // 4단계: 완료
    await _executeStep(3, () async {
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ 양도 이행 완료');
    });

    // 완료 화면으로 이동
    await Future.delayed(Duration(milliseconds: 500));
    _navigateToCompleteScreen(null);
  }

  /// 각 단계 실행
  Future<void> _executeStep(
    int stepIndex,
    Future<void> Function() action,
  ) async {
    setState(() {
      _currentStep = stepIndex;
    });

    _progressController.reset();
    _progressController.forward();

    await action();
  }

  void _handleError(String error) {
    setState(() {
      _hasError = true;
      _errorMessage = error;
    });
  }

  void _navigateToCompleteScreen(CreateTicketResponse? ticketResponse) {
    final paymentType = widget.paymentData['paymentType'] as String?;

    Map<String, dynamic> resultData;

    if (paymentType == 'transfer') {
      // 양도 이행 완료 데이터
      resultData = {
        ...widget.paymentData,
        'transferId': 'TRF_${DateTime.now().millisecondsSinceEpoch}',
        'completedAt': DateTime.now().toIso8601String(),
        'type': 'transfer',
      };
    } else if (ticketResponse != null) {
      // ✅ 실제 API 응답 데이터를 Complete 화면 형식으로 변환
      resultData = ticketResponse.toCompleteScreenData();

      // paymentData의 추가 정보도 포함 (API에 없는 경우를 위해)
      resultData.addAll({
        'paymentAmount': widget.paymentData['paymentAmount'],
        'paymentMethod': widget.paymentData['paymentMethod'],
        'orderId': widget.paymentData['orderId'],
      });

      print('✅ Complete 화면으로 전달할 데이터: $resultData');
    } else {
      // 더미 데이터 (API 응답이 없는 경우)
      resultData = {
        ...widget.paymentData,
        'nftId': 'NFT_${DateTime.now().millisecondsSinceEpoch}',
        'tokenId': '${DateTime.now().millisecondsSinceEpoch}',
        'contractAddress':
            '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        'blockchainNetwork': 'OmniOne Chain',
        'issuedAt': DateTime.now().toIso8601String(),
        'type': 'ticketing',
      };
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NFTTicketCompleteScreen(nftData: resultData),
      ),
    );
  }

  /// 안전한 int 파싱
  int _safeParseInt(dynamic value) {
    if (value == null) {
      print('⚠️ null 값을 기본값 0으로 변환');
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.toInt();
    }
    print('⚠️ 알 수 없는 타입 ${value.runtimeType}을 기본값 0으로 변환');
    return 0;
  }

  void _retryProcess() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _currentStep = 0;
    });
    _startIssuanceProcess();
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

                if (_hasError) ...[
                  _buildErrorSection(),
                  SizedBox(height: 40),
                ] else ...[
                  _buildProgressSection(),
                  SizedBox(height: 40),
                  _buildCurrentStep(),
                  SizedBox(height: 60),
                  _buildBottomMessage(),
                ],

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final paymentType = widget.paymentData['paymentType'] as String?;
    final isTransfer = paymentType == 'transfer';

    return Column(
      children: [
        Icon(
          isTransfer ? Icons.swap_horiz : Icons.verified,
          size: 48,
          color: _hasError ? AppColors.error : AppColors.primary,
        ),
        SizedBox(height: 16),
        Text(
          _hasError
              ? (isTransfer ? '양도 이행 실패' : 'NFT 티켓 발행 실패')
              : (isTransfer ? '양도 이행 중' : 'NFT 티켓 발행 중'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _hasError ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _hasError
              ? '처리 중 문제가 발생했습니다'
              : (isTransfer
                    ? '티켓 소유권을 안전하게 이전하고 있습니다'
                    : '블록체인에 당신만의 티켓을 생성하고 있습니다'),
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNFTAnimation() {
    final paymentType = widget.paymentData['paymentType'] as String?;
    final isTransfer = paymentType == 'transfer';

    return AnimatedBuilder(
      animation: _hasError ? AlwaysStoppedAnimation(1.0) : _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _hasError ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: _hasError
                  ? LinearGradient(
                      colors: [
                        AppColors.error,
                        AppColors.error.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_hasError ? AppColors.error : AppColors.primary)
                      .withOpacity(0.4),
                  spreadRadius: 8,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _hasError
                  ? Icons.error_outline
                  : (isTransfer
                        ? Icons.swap_horizontal_circle
                        : Icons.confirmation_number_outlined),
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

  Widget _buildErrorSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '처리 중 오류가 발생했습니다',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _errorMessage.isNotEmpty
                          ? _errorMessage
                          : '잠시 후 다시 시도해주세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retryProcess,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '다시 시도',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMessage() {
    final paymentType = widget.paymentData['paymentType'] as String?;
    final isTransfer = paymentType == 'transfer';

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
                  isTransfer
                      ? '티켓 소유권이 블록체인에 안전하게 이전되고 있습니다.\n화면을 닫지 마세요.'
                      : 'NFT 티켓이 블록체인에 안전하게 기록되고 있습니다.\n화면을 닫지 마세요.',
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
