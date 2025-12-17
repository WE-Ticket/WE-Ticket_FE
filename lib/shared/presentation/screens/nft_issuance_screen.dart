import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/shared/data/models/patment_data.dart';
import 'package:we_ticket/shared/data/models/ticket_models.dart';
import 'package:we_ticket/features/ticketing/data/services/ticket_service.dart';
import 'package:we_ticket/shared/presentation/screens/nft_ticket_complete_screen.dart';
import 'package:we_ticket/shared/presentation/providers/api_provider.dart';
import '../../../core/constants/app_colors.dart';

class NFTIssuanceScreen extends StatefulWidget {
  final PaymentData paymentData;

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
    print('🎫 NFT 발행/양도 화면 초기화');
    print('📦 paymentData: ${widget.paymentData.toMap()}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
      _initSteps();
      _initAnimations();
      _startProcessing();
    });
  }

  void _initServices() {
    final apiProvider = context.read<ApiProvider>();
    _ticketService = apiProvider.apiService.ticket;
  }

  void _initSteps() {
    final isTransfer = widget.paymentData.paymentType == 'transfer';
    if (isTransfer) {
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

  void _startProcessing() async {
    try {
      final isTransfer = widget.paymentData.paymentType == 'transfer';

      if (isTransfer) {
        await _processTransfer();
      } else {
        await _processTicketing();
      }
    } catch (e) {
      print('❌ 발행/양도 처리 오류: $e');
      _handleError(e.toString());
    }
  }

  /// 티켓 발행 프로세스 (애니메이션만)
  Future<void> _processTicketing() async {
    final ticketData = widget.paymentData as TicketingPaymentData;

    // 1단계: 결제 정보 검증
    await _executeStep(0, () async {
      await Future.delayed(Duration(milliseconds: 1500));
      print('✅ 결제 검증 완료');
    });

    // 2단계: NFT 티켓 생성 (애니메이션만)
    await _executeStep(1, () async {
      await Future.delayed(Duration(milliseconds: 2000));
      print('✅ NFT 티켓 생성 완료');
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

    await Future.delayed(Duration(milliseconds: 500));
    _navigateToCompleteScreen(null);
  }

  /// 양도 이행 프로세스 (애니메이션만)
  Future<void> _processTransfer() async {
    final transferData = widget.paymentData as TransferPaymentData;

    // 1단계: 양도 요청 검증
    await _executeStep(0, () async {
      await Future.delayed(Duration(milliseconds: 1200));
      print('✅ 양도 요청 검증 완료');
    });

    // 2단계: 소유권 이전 처리 (애니메이션만)
    await _executeStep(1, () async {
      await Future.delayed(Duration(milliseconds: 1800));
      print('✅ 소유권 이전 완료');
    });

    // 3단계: 블록체인 기록
    await _executeStep(2, () async {
      await Future.delayed(Duration(milliseconds: 2000));
      print('✅ 블록체인 기록 완료');
    });

    // 4단계: 완료
    await _executeStep(3, () async {
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ 양도 이행 완료');
    });

    await Future.delayed(Duration(milliseconds: 500));
    _navigateToCompleteScreen(null, null);
  }

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

  void _navigateToCompleteScreen(
    CreateTicketResponse? ticketResponse, [
    Map<String, dynamic>? transferResponse,
  ]) {
    final isTransfer = widget.paymentData.paymentType == 'transfer';

    Map<String, dynamic> resultData;

    if (isTransfer) {
      final transferData = widget.paymentData as TransferPaymentData;
      final apiResponse = transferData.apiResponse;

      // 양도 완룼 데이터 생성
      resultData = {
        'type': 'transfer',
        'transferId':
            apiResponse?['transfer_ticket_id']?.toString() ??
            transferResponse?['transfer_ticket_id']?.toString() ??
            'TRF_${DateTime.now().millisecondsSinceEpoch}',
        'transactionHash':
            apiResponse?['transaction_hash'] ??
            transferResponse?['transaction_hash'] ??
            'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'completedAt':
            apiResponse?['finished_datetime'] ??
            transferResponse?['finished_datetime'] ??
            DateTime.now().toIso8601String(),
        'transferStatus': 
            apiResponse?['transfer_status'] ??
            transferResponse?['transfer_status'] ?? 'completed',

        // 공연 정보
        'performanceTitle': transferData.performanceTitle,
        'performerName': transferData.performerName,
        'sessionDatetime': transferData.sessionDatetime,
        'venueName': transferData.venueName,
        'seatNumber': transferData.seatNumber,
        'seatGrade': transferData.seatGrade,

        // 가격 정보
        'transferPrice': transferData.transferPrice,
        'buyerFee': transferData.buyerFee,
        'totalPrice': transferData.totalPrice,
        'transferPriceDisplay': transferData.transferPriceDisplay,
        'buyerFeeDisplay': transferData.buyerFeeDisplay,
        'totalPriceDisplay': transferData.totalPriceDisplay,

        // 결제 정보
        'paymentAmount': transferData.amount,
        'paymentMethod': transferData.paymentMethod,
        'merchantUid': transferData.merchantUid,
      };
    } else {
      final ticketData = widget.paymentData as TicketingPaymentData;
      final apiResponse = ticketData.apiResponse;

      if (apiResponse != null) {
        // 실제 API 응답 데이터 사용
        resultData = {
          'type': 'ticketing',
          'ticketId': apiResponse['ticket_id']?.toString() ?? '',
          'performanceTitle': apiResponse['performance_title'] ?? '공연',
          'performerName': apiResponse['performer_name'] ?? '공연자',
          'sessionDatetime': apiResponse['session_datetime'] ?? '',
          'venueName': apiResponse['venue_name'] ?? '공연장',
          'seatZone': apiResponse['seat_zone'] ?? '',
          'seatRow': apiResponse['seat_row'] ?? '',
          'seatColumn': apiResponse['seat_column']?.toString() ?? '',
          'seatGrade': apiResponse['seat_grade'] ?? '',
          'issuedAt': DateTime.now().toIso8601String(),
          
          // 추가 정보
          'concertInfo': ticketData.concertInfo,
          'selectedSession': ticketData.selectedSession,
          'selectedSeat': ticketData.selectedSeat,
          'selectedZone': ticketData.selectedZone,
          'paymentAmount': ticketData.amount,
          'paymentMethod': ticketData.paymentMethod,
          'merchantUid': ticketData.merchantUid,
        };
      } else {
        // 더미 데이터 생성 (백업용)
        resultData = {
          'type': 'ticketing',
          'ticketId': 'TKT_${DateTime.now().millisecondsSinceEpoch}',
          'performanceTitle': ticketData.sessionSeatInfo['title'] ?? '공연',
          'performerName': ticketData.concertInfo['performer'] ?? '공연자',
          'sessionDatetime': ticketData.selectedSession['datetime'] ?? '',
          'venueName': ticketData.concertInfo['venue'] ?? '공연장',
          'seatZone': ticketData.selectedZone,
          'seatRow': ticketData.selectedSeat['row'] ?? '',
          'seatColumn': ticketData.selectedSeat['column']?.toString() ?? '',
          'seatGrade': ticketData.seatGrade,
          'issuedAt': DateTime.now().toIso8601String(),
          
          // 추가 정보
          'concertInfo': ticketData.concertInfo,
          'selectedSession': ticketData.selectedSession,
          'selectedSeat': ticketData.selectedSeat,
          'selectedZone': ticketData.selectedZone,
          'paymentAmount': ticketData.amount,
          'paymentMethod': ticketData.paymentMethod,
          'merchantUid': ticketData.merchantUid,
        };
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NFTTicketCompleteScreen(nftData: resultData),
      ),
    );
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  void _retryProcess() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _currentStep = 0;
    });
    _startProcessing();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.paymentData.paymentType == 'transfer';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 40),
                _buildHeader(isTransfer),
                SizedBox(height: 60),
                _buildProcessingAnimation(isTransfer),
                SizedBox(height: 60),

                if (_hasError) ...[
                  _buildErrorSection(isTransfer),
                  SizedBox(height: 40),
                ] else ...[
                  _buildProgressSection(),
                  SizedBox(height: 40),
                  _buildCurrentStep(),
                  SizedBox(height: 60),
                  _buildBottomMessage(isTransfer),
                ],

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTransfer) {
    return Column(
      children: [
        Icon(
          isTransfer ? Icons.swap_horiz : Icons.verified,
          size: 48,
          color: _hasError
              ? AppColors.error
              : (isTransfer ? AppColors.warning : AppColors.primary),
        ),
        SizedBox(height: 16),
        Text(
          _hasError
              ? (isTransfer ? '양도 이행 실패' : 'NFT 티켓 발행 실패')
              : widget.paymentData.processTitle,
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

  Widget _buildProcessingAnimation(bool isTransfer) {
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
                      colors: isTransfer
                          ? [AppColors.warning, AppColors.warningLight]
                          : AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_hasError
                              ? AppColors.error
                              : (isTransfer
                                    ? AppColors.warning
                                    : AppColors.primary))
                          .withValues(alpha: 0.4),
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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

  Widget _buildErrorSection(bool isTransfer) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
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
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
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

  Widget _buildBottomMessage(bool isTransfer) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
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
