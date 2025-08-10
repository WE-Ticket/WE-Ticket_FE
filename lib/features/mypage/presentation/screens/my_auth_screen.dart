import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_ticket/core/constants/app_colors.dart';
import 'package:we_ticket/features/auth/presentation/providers/auth_provider.dart';
import 'package:we_ticket/features/auth/presentation/screens/omnione_cx_auth_screen.dart';
import 'package:we_ticket/features/auth/data/user_models.dart';
import 'package:we_ticket/features/shared/providers/api_provider.dart';

class MyAuthScreen extends StatefulWidget {
  @override
  _MyAuthScreenState createState() => _MyAuthScreenState();
}

class _MyAuthScreenState extends State<MyAuthScreen> {
  static const platform = MethodChannel('did_sdk');

  bool _isLoadingAuth = false;
  String? _errorMessage;
  Map<String, dynamic>? _authData;

  String? _userDid;
  bool _isDidCreationInProgress = false;

  final Map<String, int> _authLevelOrder = {
    'none': 0,
    'general': 1,
    'mobile_id': 2,
    'mobile_id_totally': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadUserAuthLevel();
  }

  /// 사용자 인증 레벨 API 호출
  Future<void> _loadUserAuthLevel() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUserId; // 현재 로그인한 사용자 ID

    if (userId == null) {
      print('❌ 사용자 ID가 없습니다');
      return;
    }

    setState(() {
      _isLoadingAuth = true;
      _errorMessage = null;
    });

    try {
      // API 호출
      final apiProvider = context.read<ApiProvider>();
      final result = await apiProvider.authService.loadUserAuthLevel(userId);

      if (result.isSuccess) {
        print('✅ API 성공: ${result.data}');
        setState(() {
          _authData = result.data; // 응답 데이터 저장
        });

        await authProvider.updateAuthLevel(result.data?['verification_level']);
      } else {
        setState(() {
          _errorMessage = result.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류: $e';
      });
    } finally {
      setState(() {
        _isLoadingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final String authLevel = user?.userAuthLevel ?? 'none';
    final String userName = user?.userName ?? '사용자';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '내 인증 관리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoadingAuth
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _isLoadingAuth ? null : _loadUserAuthLevel, // 새로고침 버튼
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatusCard(authLevel, userName, context),
            SizedBox(height: 24),
            _buildUpgradeOptions(authLevel, context),
            SizedBox(height: 24),
            _buildAuthLevelGuide(authLevel),
            SizedBox(height: 24),
            _buildBenefitsSection(),
            SizedBox(height: 24),
            _buildSecurityNotice(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(
    String level,
    String userName,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getAuthLevelColor(level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getAuthLevelIcon(level),
                  color: _getAuthLevelColor(level),
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName 님의 인증 현황',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getAuthLevelColor(level),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getAuthLevelText(level),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _getAuthLevelDescription(level),
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
          SizedBox(height: 20),
          _buildPrivileges(level),
        ],
      ),
    );
  }

  Widget _buildPrivileges(String level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이용 가능한 서비스',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        _buildPrivilege('공연 예매', _isAtLeast(level, 'general')),
        _buildPrivilege('3초 간편입장', _isAtLeast(level, 'mobile_id')),
        _buildPrivilege('양도 거래', _isAtLeast(level, 'mobile_id_totally')),
      ],
    );
  }

  Widget _buildPrivilege(String title, bool available) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: available ? AppColors.success : AppColors.gray300,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: available
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeOptions(String level, BuildContext context) {
    if (level == 'mobile_id_totally') {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: AppColors.success, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '완전 인증 회원 완료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '모든 WE-Ticket 서비스를 자유롭게 이용하실 수 있습니다',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '인증 업그레이드',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => _navigateToAuth(context, level),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getUpgradeColor(level).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getUpgradeColor(level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getUpgradeIcon(level),
                    color: _getUpgradeColor(level),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUpgradeTitle(level),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getUpgradeDescription(level),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: _getUpgradeColor(level),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthLevelGuide(String currentLevel) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인증 등급 안내',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildLevelItem(
            'general',
            '일반 인증 회원',
            '휴대폰 또는 간편인증으로 기본 티켓 구매',
            AppColors.info,
            currentLevel,
          ),
          SizedBox(height: 12),
          _buildLevelItem(
            'mobile_id',
            '모바일 신분증 인증 회원',
            '모바일신분증으로 강화된 보안과 3초 간편입장',
            AppColors.primary,
            currentLevel,
          ),
          SizedBox(height: 12),
          _buildLevelItem(
            'mobile_id_totally',
            '완전 인증 회원',
            '모든 서비스 이용 가능 및 안전한 양도 거래',
            AppColors.success,
            currentLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelItem(
    String level,
    String title,
    String desc,
    Color color,
    String currentLevel,
  ) {
    final isCurrent = level == currentLevel;
    final isHigher = _authLevelOrder[level]! > _authLevelOrder[currentLevel]!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color : AppColors.gray300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrent ? color : AppColors.gray300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (_authLevelOrder[level]).toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '현재',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  desc,
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

  Widget _buildBenefitsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '회원 등급별 혜택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildBenefit(Icons.shopping_cart, '안전한 티켓 거래', '일반 인증+'),
          _buildBenefit(Icons.nfc, '3초 간편 입장', '모바일 신분증+'),
          _buildBenefit(Icons.swap_horiz, '자유로운 양도 거래', '완전 인증'),
          _buildBenefit(Icons.shield, '법적 분쟁 보호', '완전 인증'),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String level) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray300.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray400.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개인정보 보호 안내',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '모든 개인정보는 암호화되어 안전하게 보관되며, 본인인증 목적으로만 사용됩니다. 언제든지 인증 정보를 삭제하거나 수정할 수 있습니다.',
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

  // Utility Methods

  bool _isAtLeast(String currentLevel, String requiredLevel) {
    return _authLevelOrder[currentLevel]! >= _authLevelOrder[requiredLevel]!;
  }

  String _getAuthLevelText(String level) =>
      {
        'none': '미인증',
        'general': '일반 인증 회원',
        'mobile_id': '모바일 신분증 인증 회원',
        'mobile_id_totally': '완전 인증 회원',
      }[level] ??
      '알 수 없음';

  String _getAuthLevelDescription(String level) =>
      {
        'none': '서비스 이용을 위해 본인 인증이 필요합니다',
        'general': '휴대폰 또는 간편인증으로 기본 서비스 이용 가능',
        'mobile_id': '모바일신분증 인증으로 강화된 보안 서비스 이용',
        'mobile_id_totally': '모든 서비스 이용 가능한 최고 등급',
      }[level] ??
      '';

  Color _getAuthLevelColor(String level) =>
      {
        'none': AppColors.gray600,
        'general': AppColors.info,
        'mobile_id': AppColors.primary,
        'mobile_id_totally': AppColors.success,
      }[level] ??
      AppColors.gray600;

  IconData _getAuthLevelIcon(String level) =>
      {
        'none': Icons.person_outline,
        'general': Icons.verified_user,
        'mobile_id': Icons.credit_card,
        'mobile_id_totally': Icons.diamond,
      }[level] ??
      Icons.help_outline;

  String _getUpgradeTitle(String level) =>
      {
        'none': '본인 인증하러 가기',
        'general': '모바일 신분증 인증 회원 되기',
        'mobile_id': '완전 인증 회원 되기',
      }[level] ??
      '';

  String _getUpgradeDescription(String level) =>
      {
        'none': '간편인증 또는 모바일 신분증으로 안전하게 인증하세요',
        'general': '모바일신분증으로 인증하고 3초 간편입장을 경험하세요',
        'mobile_id': '추가 인증으로 양도 거래를 통한 더 즐거운 공연을 누리세요',
      }[level] ??
      '';

  Color _getUpgradeColor(String level) => _getAuthLevelColor(level);
  IconData _getUpgradeIcon(String level) => _getAuthLevelIcon(level);

  // Navigation Methods

  Future<void> _navigateToAuth(
    BuildContext context,
    String currentLevel,
  ) async {
    // 필요한 데이터 가져오기
    final authProvider = context.read<AuthProvider>();
    final apiProvider = context.read<ApiProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // OmniOne 인증 화면으로 이동
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => OmniOneCXAuthScreen(
          userId: userId,
          currentAuthLevel: _authLevelOrder[currentLevel] ?? 0,
          authService: apiProvider.authService,
        ),
      ),
    );

    // 인증 결과 처리
    if (result != null && result['success'] == true) {
      await _handleAuthSuccess(result);
    }
  }

  /// 인증 성공 후 처리
  Future<void> _handleAuthSuccess(Map<String, dynamic> result) async {
    final authResult = result['authResult'];
    final serverResponse =
        result['serverResponse'] as IdentityVerificationResponse?;
    final serverError = result['serverError'];

    if (serverResponse != null) {
      // 서버 저장 성공
      await _showSuccessDialog(
        '본인인증이 완료되었습니다!',
        '새로운 인증 레벨: ${serverResponse.newVerificationLevel ?? "업데이트됨"}\n'
            '이제 더 많은 서비스를 이용하실 수 있습니다.',
      );

      // 인증 레벨 새로고침
      await _loadUserAuthLevel();

      // AuthProvider 업데이트
      if (serverResponse.newVerificationLevel != null) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.updateAuthLevel(
          serverResponse.newVerificationLevel!,
        );
      }

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUserId; // 현재 로그인한 사용자 ID

      // DID 생성 플로우 시작
      await _startDidCreationFlow(serverResponse, userId!);

      //FIXME test
      // await _saveDidDoc();
      // await _didAuth();
    } else if (serverError != null) {
      // 인증 성공했으나 서버 저장 실패
      await _showWarningDialog(
        '인증은 성공했으나 저장 중 문제가 발생했습니다.',
        '잠시 후 다시 시도해주세요.\n\n오류: $serverError',
      );
    }
  }

  /// DID 생성 플로우 시작
  Future<void> _startDidCreationFlow(
    IdentityVerificationResponse serverResponse,
    int userId,
  ) async {
    if (_isDidCreationInProgress) return; // 중복 실행 방지

    setState(() {
      _isDidCreationInProgress = true;
    });

    // 1. 진행 다이얼로그 표시
    _showDidCreationProgressDialog();

    try {
      print('[Flutter] WE-Ticket DID 생성 플로우 시작');

      // 2. DID 생성
      final didResult = await _createWeTicketDid();

      await registerDid(didResult, userId);
      print('[Flutter] DID 서버 등록 완료 ');

      // 3. DID 저장 및 상태 업데이트
      setState(() {
        _userDid = didResult['did']; // DID 문자열만 추출
        _isDidCreationInProgress = false;
      });

      // 4. 성공 처리
      await _handleDidCreationSuccess(didResult, serverResponse);

      print('[Flutter] WE-Ticket DID 생성 플로우 완료');
    } catch (e) {
      // 5. 실패 처리
      setState(() {
        _isDidCreationInProgress = false;
      });
      await _handleDidCreationFailure(e, serverResponse);
      print('[Flutter] WE-Ticket DID 생성 플로우 실패: $e');
    }
  }

  /// WE-Ticket DID 생성 (CI 제거된 깔끔한 버전)
  Future<Map<String, dynamic>> _createWeTicketDid() async {
    try {
      print('[Flutter] WE-Ticket DID 생성 시작');

      // Android의 상세 DID 생성 메서드 호출
      final response = await platform.invokeMethod('createDid');
      final result = _safeMapConversion(response);

      if (result['success'] == true) {
        print('[Flutter] ✅ WE-Ticket DID 생성 성공');
        print('[Flutter] 🆔 생성된 DID: ${result['did']}');
        print('[Flutter] 🔑 Key ID: ${result['keyId']}');

        // 공개키 길이에 따라 안전하게 표시
        final publicKey = result['publicKey']?.toString() ?? '';
        final displayKey = publicKey.length > 32
            ? '${publicKey.substring(0, 32)}...'
            : publicKey;
        print('[Flutter] 🔓 공개키: $displayKey');

        print('[Flutter] 🔐 Key Attestation: ${result['keyAttestation']}');

        return result;
      } else {
        print('[Flutter] ❌ WE-Ticket DID 생성 실패: ${result['error']}');
        throw Exception('WE-Ticket DID 생성 실패: ${result['error']}');
      }
    } on PlatformException catch (e) {
      print('[Flutter] ❌ 플랫폼 예외: ${e.message}');
      throw Exception('플랫폼 오류: ${e.message}');
    } catch (e) {
      print('[Flutter] ❌ WE-Ticket DID 생성 예외: $e');
      throw Exception('WE-Ticket DID 생성 중 예상치 못한 오류: $e');
    }
  }

  Future<void> registerDid(Map<String, dynamic> didData, int userId) async {
    print('DID 등록 API 시작 ');
    final url = Uri.parse('http://13.236.171.188:8000/api/users/did/register/');

    final payload = {
      'user_id': userId,
      'key_attestation': {
        'keyId': didData['keyAttestation']['keyId'],
        'algorithm': didData['keyAttestation']['algorithm'],
        'storage': didData['keyAttestation']['storage'],
        'createdAt': didData['keyAttestation']['createdAt'], // ISO 8601 형식의 문자열
      },
      'owner_did_doc': didData['didDocument'], // JSON 객체
    };

    print('DID 등록 payload : $payload ');

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAccessToken = prefs.getString('access_token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedAccessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[Flutter] ✅ DID 등록 성공: ${response.body}');
      } else {
        print('[Flutter] ❌ DID 등록 실패: ${response.statusCode}');
        print('[Flutter] 응답 내용: ${response.body}');
        await _delDidDoc();
      }
    } catch (e) {
      print('[Flutter] ❌ 요청 예외 발생: $e');
      throw Exception('DID 등록 중 오류 발생: $e');
    }
  }

  // Future<void> _saveDidDoc() async {
  //   try {
  //     print('[Flutter] WE-Ticket DID 저장장 시작');

  //     // Android의 상세 DID 생성 메서드 호출
  //     final response = await platform.invokeMethod('saveDidDoc', {
  //       "didDoc": didDoc,
  //     });
  //     final result = _safeMapConversion(response);

  //     if (result['success'] == true) {
  //       print('[Flutter] WE-Ticket DID 저장 성공');
  //       print('[Flutter] 생성된 DID: ${result['didDocument']}');
  //     } else {
  //       print('[Flutter] ❌ WE-Ticket DID 저장 실패: ${result['error']}');
  //       throw Exception('WE-Ticket DID 저장장 실패: ${result['error']}');
  //     }
  //   } on PlatformException catch (e) {
  //     print('[Flutter] ❌ 플랫폼 예외: ${e.message}');
  //     throw Exception('플랫폼 오류: ${e.message}');
  //   } catch (e) {
  //     print('[Flutter] ❌ WE-Ticket DID 저장 예외: $e');
  //     throw Exception('WE-Ticket DID 저장 중 예상치 못한 오류: $e');
  //   }
  // }

  Future<void> _delDidDoc() async {
    try {
      print('[Flutter] WE-Ticket did del 시작');

      // Android의 상세 DID 생성 메서드 호출
      final response = await platform.invokeMethod('delDidDoc');
      final result = _safeMapConversion(response);

      if (result['success'] == true) {
        print('[Flutter] WE-Ticket DID DOC 삭제  성공');
      } else {
        print('[Flutter] ❌ WE-Ticket DID 삭제 실패: ${result['error']}');
        throw Exception('WE-Ticket DID 삭제 실패: ${result['error']}');
      }
    } on PlatformException catch (e) {
      print('[Flutter] ❌ 플랫폼 예외: ${e.message}');
      throw Exception('플랫폼 오류: ${e.message}');
    } catch (e) {
      print('[Flutter] ❌ WE-Ticket DID 삭제 예외: $e');
      throw Exception('WE-Ticket DID 삭제 중 예상치 못한 오류: $e');
    }
  }

  Future<void> _didAuth() async {
    try {
      print('[Flutter] WE-Ticket auth did 시작');

      // Android의 상세 DID 생성 메서드 호출
      final response = await platform.invokeMethod('didAuth');
      final result = _safeMapConversion(response);

      if (result['success'] == true) {
        print('[Flutter] WE-Ticket Auth DID 성공');
        print('[Flutter] 생성된 DID: ${result['didDocument']}');
        print('[Flutter] 생성된 DID Auth : ${result['didAuth']}');
      } else {
        print('[Flutter] ❌ WE-Ticket DID Auth 실패: ${result['error']}');
        throw Exception('WE-Ticket DID Auth 실패: ${result['error']}');
      }
    } on PlatformException catch (e) {
      print('[Flutter] ❌ 플랫폼 예외: ${e.message}');
      throw Exception('플랫폼 오류: ${e.message}');
    } catch (e) {
      print('[Flutter] ❌ WE-Ticket DID Auth 예외: $e');
      throw Exception('WE-Ticket DID Auth 중 예상치 못한 오류: $e');
    }
  }

  /// DID 생성 성공 처리 (수정된 버전 - 무한재귀 해결)
  Future<void> _handleDidCreationSuccess(
    Map<String, dynamic> didResult,
    IdentityVerificationResponse serverResponse,
  ) async {
    // 진행 다이얼로그 닫기
    Navigator.of(context).pop();

    // 상세 정보 표시 다이얼로그
    await _showDidDetailsDialog(
      '🎉 WE-Ticket DID 생성 완료!',
      '본인인증과 DID 생성이 모두 완료되었습니다.',
      didResult,
      serverResponse,
    );
  }

  /// DID 상세 정보 표시 다이얼로그
  Future<void> _showDidDetailsDialog(
    String title,
    String message,
    Map<String, dynamic> didResult,
    IdentityVerificationResponse serverResponse,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 메인 메시지
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // 인증 레벨 정보
                _buildInfoCard(
                  '📊 새로운 인증 레벨',
                  serverResponse.newVerificationLevel ?? '업데이트됨',
                  AppColors.primary,
                ),
                SizedBox(height: 12),

                // DID 정보
                _buildInfoCard(
                  '🆔 생성된 WE-Ticket DID',
                  didResult['did']?.toString() ?? 'N/A',
                  AppColors.info,
                ),
                SizedBox(height: 12),

                // 키 ID 정보
                _buildInfoCard(
                  '🔑 키 식별자',
                  didResult['keyId']?.toString() ?? 'N/A',
                  AppColors.secondary,
                ),
                SizedBox(height: 12),

                // 공개키 정보 (안전하게 길이 체크)
                _buildInfoCard(
                  '🔓 공개키',
                  _safeSubstring(didResult['publicKey']?.toString(), 32),
                  AppColors.warning,
                ),
                SizedBox(height: 12),

                // Key Attestation 정보
                if (didResult['keyAttestation'] != null)
                  _buildAttestationCard(
                    _safeMapConversion(didResult['keyAttestation']),
                  ),
                SizedBox(height: 12),

                // DID Document 정보
                _buildInfoCard(
                  '📄 DID Document 크기',
                  '${didResult['didDocument']?.toString().length ?? 0} 문자',
                  AppColors.success,
                ),
                SizedBox(height: 16),

                // 보안 안내
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: AppColors.primary, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '개인키는 Android KeyStore에 안전하게 저장됩니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // DID Document 전체 보기 버튼
          TextButton(
            onPressed: () => _showFullDidDocument(
              didResult['didDocument']?.toString() ?? '',
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('DID Document 전체 보기', style: TextStyle(fontSize: 12)),
          ),
          // 확인 버튼
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '확인',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// 안전한 문자열 자르기 헬퍼 함수
  String _safeSubstring(String? text, int maxLength) {
    if (text == null || text.isEmpty) return 'N/A';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 안전한 Map 변환 헬퍼 함수
  Map<String, dynamic> _safeMapConversion(dynamic input) {
    if (input == null) return <String, dynamic>{};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return Map<String, dynamic>.from(
        input.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return <String, dynamic>{};
  }

  /// 정보 카드 위젯
  Widget _buildInfoCard(String title, String content, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Key Attestation 카드 위젯
  Widget _buildAttestationCard(Map<String, dynamic> attestation) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔐 Key Attestation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 8),
          ...attestation.entries
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  /// DID Document 전체 내용 표시
  void _showFullDidDocument(String didDocument) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '📄 DID Document 전체 내용',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Text(
                didDocument,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// DID 생성 실패 처리 (향후 롤백 확장점)
  Future<void> _handleDidCreationFailure(
    dynamic error,
    IdentityVerificationResponse serverResponse,
  ) async {
    // 진행 다이얼로그 닫기
    Navigator.of(context).pop();

    print('[Flutter] DID 생성 실패 처리: $error');

    await _showDidCreationFailureDialog(
      '보안 인증서 생성 실패',
      '본인인증은 성공했으나 보안 인증서 생성 중 문제가 발생했습니다.\n\n'
          '오류 내용: ${error.toString()}\n\n'
          '잠시 후 다시 시도해주시거나 고객센터에 문의해주세요.',
      serverResponse,
    );
  }

  /// DID 생성 진행 다이얼로그 표시
  void _showDidCreationProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 임의로 닫을 수 없음
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 로딩 애니메이션
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              // 제목
              Text(
                '보안 인증서 생성 중',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              // 설명
              Text(
                '안전한 서비스 이용을 위한\n보안 인증서를 생성하고 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8),
              // 안내 메시지
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '잠시만 기다려주세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
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
  }

  /// DID 생성 실패 다이얼로그
  Future<void> _showDidCreationFailureDialog(
    String title,
    String message,
    IdentityVerificationResponse serverResponse,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 부분 성공 알림
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '본인인증은 정상적으로 완료되었습니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // 오류 메시지
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 12),
              // 안내 메시지
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '일부 고급 기능은 제한될 수 있으나, 기본 서비스는 정상적으로 이용 가능합니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 다시 시도 버튼
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              // DID 생성 재시도
              final authProvider = context.read<AuthProvider>();
              final userId = authProvider.currentUserId; // 현재 로그인한 사용자 ID

              _startDidCreationFlow(serverResponse, userId!);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('다시 시도', style: TextStyle(fontSize: 14)),
          ),
          // 확인 버튼 (나중에 시도)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '나중에 시도',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// DID 생성 상태 확인
  bool get isDidCreated => _userDid != null && _userDid!.isNotEmpty;

  /// DID 생성 진행 상태 확인
  bool get isDidCreationInProgress => _isDidCreationInProgress;

  /// 현재 사용자의 DID 반환
  String? get currentUserDid => _userDid;

  /// DID 초기화 (로그아웃 시 등에 사용)
  void _clearDidData() {
    setState(() {
      _userDid = null;
      _isDidCreationInProgress = false;
    });
  }

  /// 성공 다이얼로그 표시
  Future<void> _showSuccessDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '확인',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// 경고 다이얼로그 표시
  Future<void> _showWarningDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '확인',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
