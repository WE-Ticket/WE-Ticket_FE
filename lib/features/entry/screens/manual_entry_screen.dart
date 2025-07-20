import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';

class ManualEntryScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> ticketData;

  const ManualEntryScreen({
    Key? key,
    required this.ticketId,
    required this.ticketData,
  }) : super(key: key);

  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _userInfo;
  String? _verificationCode;
  bool? _finalResult;
  String? _errorMessage;

  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 1단계: 사용자 정보 조회
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // TODO: 백엔드 API 호출 - 사용자 정보 조회
      final userInfo = await _fetchUserInfoFromAPI(authProvider);

      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
        _currentStep = 1;
      });
    } catch (e) {
      print('❌ 사용자 정보 조회 오류: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// TODO: 백엔드 API - 사용자 정보 조회
  Future<Map<String, dynamic>> _fetchUserInfoFromAPI(
    AuthProvider authProvider,
  ) async {
    print('👤 사용자 정보 조회 시작');

    final requestData = {
      'user_id': authProvider.userId,
      'ticket_id': widget.ticketId,
    };

    print('📤 사용자 정보 조회 요청: $requestData');

    // 실제 구현시:
    // final response = await apiService.getUserInfoForManualEntry(requestData);
    // return response.data;

    await Future.delayed(Duration(seconds: 1)); // 시뮬레이션

    // 더미 응답 데이터
    return {
      'name': authProvider.userName ?? '홍길동',
      'birth_date': '2001.01.15',
      'gender': '여',
      'phone_number': '010-1234-5678',
      'auth_level': authProvider.currentUserAuthLevel ?? 'general',
      'auth_level_name': authProvider.currentUserAuthLevelName,
    };
  }

  /// 2단계: 검표자 인증 코드 확인
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = '검표 번호를 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // TODO: 백엔드 API 호출 - 검표자 인증 및 입장 처리
      final result = await _processManualEntry(authProvider, code);

      setState(() {
        _finalResult = result;
        _isLoading = false;
        _currentStep = 2;
      });

      if (result) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('❌ 수동 검표 처리 오류: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// TODO: 백엔드 API - 검표자 인증 및 입장 처리
  Future<bool> _processManualEntry(
    AuthProvider authProvider,
    String verificationCode,
  ) async {
    print('🔍 수동 검표 처리 시작');

    final requestData = {
      'user_id': authProvider.userId,
      'ticket_id': widget.ticketId,
      'verification_code': verificationCode,
      'entry_method': 'manual',
      'venue_location': widget.ticketData['venue'],
      'entry_timestamp': DateTime.now().toIso8601String(),
    };

    print('📤 수동 검표 요청: $requestData');

    // 실제 구현시:
    // 1. 검표자 전용 인증 시스템 확인
    // 2. 실물 신분증과 예매 정보 대조 (검표자가 수동으로 확인)
    // 3. 블록체인 입장 기록 생성
    // final response = await apiService.processManualEntry(requestData);
    // return response.isSuccess;

    await Future.delayed(Duration(seconds: 2)); // 시뮬레이션

    // 더미 로직: 검표 번호가 "1234"면 성공
    return verificationCode == "1234";
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Text('입장 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수동 검표가 완료되어 입장이 승인되었습니다.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.ticketData['title']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${widget.ticketData['venue']}'),
                  Text('입장 시간: ${DateTime.now().toString().substring(0, 16)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 수동 검표 화면 닫기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('수동 검표', style: TextStyle(color: AppColors.white)),
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            _currentStep == 0 ? '사용자 정보를 조회하는 중...' : '검표를 처리하는 중...',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // 진행 단계 표시
          _buildProgressIndicator(),

          SizedBox(height: 24),

          // 티켓 정보 요약
          _buildTicketSummary(),

          SizedBox(height: 32),

          // 단계별 콘텐츠
          Expanded(child: _buildStepContent()),

          // 에러 메시지
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: AppColors.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
          ],

          // 액션 버튼
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepIndicator(0, '정보 조회', _currentStep >= 0),
        Expanded(child: _buildStepLine(_currentStep >= 1)),
        _buildStepIndicator(1, '검표 확인', _currentStep >= 1),
        Expanded(child: _buildStepLine(_currentStep >= 2)),
        _buildStepIndicator(2, '입장 완료', _currentStep >= 2),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.gray300,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.gray600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : AppColors.gray600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      height: 2,
      margin: EdgeInsets.only(bottom: 24),
      color: isActive ? AppColors.primary : AppColors.gray300,
    );
  }

  Widget _buildTicketSummary() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
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
            widget.ticketData['title'] ?? '공연명',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${widget.ticketData['date']} ${widget.ticketData['time']}',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            widget.ticketData['venue'] ?? '공연장',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildInitialStep();
      case 1:
        return _buildUserInfoStep();
      case 2:
        return _buildResultStep();
      default:
        return _buildInitialStep();
    }
  }

  Widget _buildInitialStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_search, size: 80, color: AppColors.primary),
        SizedBox(height: 24),
        Text(
          '수동 검표를 시작합니다',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '검표자가 신분증과 티켓 정보를 확인한 후\n검표 번호를 입력해주세요',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              SizedBox(height: 8),
              Text(
                '수동 검표 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• 실물 신분증을 준비해주세요\n'
                '• 검표자가 신분 확인 후 입장을 승인 해줍니다.\n'
                '• 입장 후 재입장은 불가합니다',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoStep() {
    return Column(
      children: [
        // 사용자 정보 표시
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    '티켓 소유자 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildInfoRow('이름', _userInfo?['name'] ?? '-'),
              _buildInfoRow('생년월일', _userInfo?['birth_date'] ?? '-'),
              _buildInfoRow('성별', _userInfo?['gender'] ?? '-'),
              _buildInfoRow('전화번호', _userInfo?['phone_number'] ?? '-'),
              _buildInfoRow('본인인증레벨', _userInfo?['auth_level_name'] ?? '-'),
            ],
          ),
        ),

        SizedBox(height: 32),

        // 검표 번호 입력
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '검표 번호 입력',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '검표자가 신분증 확인 후 번호를 입력합니다.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: '검표 번호 입력 (더미번호: 1234)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        Spacer(),
      ],
    );
  }

  Widget _buildResultStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _finalResult == true ? Icons.check_circle : Icons.error,
          size: 120,
          color: _finalResult == true ? AppColors.success : AppColors.error,
        ),
        SizedBox(height: 24),
        Text(
          _finalResult == true ? '입장 완료!' : '입장 실패',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _finalResult == true ? AppColors.success : AppColors.error,
          ),
        ),
        SizedBox(height: 12),
        Text(
          _finalResult == true ? '수동 검표가 완료되어 입장이 승인되었습니다' : '검표 번호가 올바르지 않습니다',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (_finalResult == true) ...[
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '입장 시간: ${DateTime.now().toString().substring(0, 16)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '블록체인에 입장 기록이 저장되었습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _getButtonAction(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(),
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _getButtonText(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  VoidCallback? _getButtonAction() {
    switch (_currentStep) {
      case 0:
        return _loadUserInfo;
      case 1:
        return _verifyCode;
      case 2:
        return _finalResult == true
            ? null
            : () {
                setState(() {
                  _currentStep = 1;
                  _finalResult = null;
                  _errorMessage = null;
                  _codeController.clear();
                });
              };
      default:
        return null;
    }
  }

  Color _getButtonColor() {
    switch (_currentStep) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.primary;
      case 2:
        return _finalResult == true ? AppColors.gray400 : AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return '사용자 정보 조회';
      case 1:
        return '검표 번호 확인';
      case 2:
        return _finalResult == true ? '입장 완료' : '다시 시도';
      default:
        return '시작하기';
    }
  }
}
