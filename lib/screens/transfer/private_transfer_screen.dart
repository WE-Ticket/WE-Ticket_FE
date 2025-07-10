import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import 'transfer_detail_screen.dart';

class PrivateTransferScreen extends StatefulWidget {
  @override
  _PrivateTransferScreenState createState() => _PrivateTransferScreenState();
}

class _PrivateTransferScreenState extends State<PrivateTransferScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '고유 번호로 양도 티켓 조회',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionHeader(),

            SizedBox(height: 24),

            _buildCodeInputForm(),

            SizedBox(height: 20),

            _buildNoticeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.secondary, size: 24),
              SizedBox(width: 8),
              Text(
                '비공개 양도 티켓 조회',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            '지인으로부터 받은 고유 번호를 입력하여\n양도 티켓을 조회하고 구매할 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          SizedBox(height: 12),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: AppColors.warning, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '고유 번호는 24시간 후 자동으로 만료됩니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '고유 번호 입력',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 12),

          // 고유 번호 입력 필드
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX-XXXX-XXXX',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          setState(() {
                            _codeController.clear();
                          });
                        },
                      )
                    : null,
              ),
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                LengthLimitingTextInputFormatter(19), // XXXX-XXXX-XXXX-XXXX
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '고유 번호를 입력해주세요';
                }
                if (value.length < 19) {
                  return '올바른 형식의 고유 번호를 입력해주세요';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  // 자동으로 하이픈 추가
                  if (value.length == 4 ||
                      value.length == 9 ||
                      value.length == 14) {
                    if (!value.endsWith('-')) {
                      _codeController.text = value + '-';
                      _codeController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _codeController.text.length),
                      );
                    }
                  }
                });
              },
            ),
          ),

          SizedBox(height: 20),

          // 조회 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSearchTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: AppColors.secondary.withOpacity(0.3),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '티켓 조회하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                '이용 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          _buildNoticeItem('• 고유 번호는 양도자가 제공한 정확한 코드를 입력해주세요'),
          _buildNoticeItem('• 입력한 코드가 유효하지 않거나 만료된 경우 조회가 불가능합니다'),
          _buildNoticeItem('• 조회된 티켓은 즉시 구매 가능하며, 선착순으로 처리됩니다'),
          _buildNoticeItem('• 모바일 신분증 인증이 완료된 사용자만 구매할 수 있습니다'),
          _buildNoticeItem('• 고유 번호는 일회성이며, 사용 후 즉시 무효화됩니다'),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  void _handleSearchTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제로는 API 호출하여 고유 번호로 티켓 조회
      await Future.delayed(Duration(seconds: 2));

      // 더미 응답 - 실제로는 서버 응답 처리
      final isValidCode = _codeController.text.startsWith('ABCD'); // 가상 조건

      if (isValidCode) {
        // 조회 성공 - 티켓 정보 반환
        final ticketData = {
          'id': 'private_transfer_001',
          'concertTitle': 'NewJeans Get Up Concert',
          'artist': 'NewJeans',
          'date': '2025.08.15',
          'time': '19:00',
          'venue': 'KSPO DOME',
          'location': '서울',
          'seat': 'VIP석 1층 A구역 2열 15번',
          'originalPrice': 154000,
          'transferPrice': 154000,
          'poster': 'https://example.com/newjeans_poster.jpg',
          'transferTime': '3시간 전',
          'isUrgent': false,
          'sellerId': 'private_seller',
          'status': 'available',
          'uniqueCode': _codeController.text,
          'isPrivate': true,
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransferDetailScreen(ticket: ticketData),
          ),
        );
      } else {
        // 조회 실패
        _showErrorDialog(
          '유효하지 않은 고유 번호',
          '입력하신 고유 번호를 찾을 수 없습니다.\n코드를 다시 확인해주세요.',
        );
      }
    } catch (e) {
      _showErrorDialog('조회 실패', '네트워크 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// 대문자 변환 포매터
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
