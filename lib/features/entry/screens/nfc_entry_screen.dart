import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:we_ticket/features/shared/providers/api_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NFCEntryScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> ticketData;

  const NFCEntryScreen({
    Key? key,
    required this.ticketId,
    required this.ticketData,
  }) : super(key: key);

  @override
  _NFCEntryScreenState createState() => _NFCEntryScreenState();
}

class _NFCEntryScreenState extends State<NFCEntryScreen>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  bool _isProcessing = false;
  bool? _entryResult;
  String? _errorMessage;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _startNFCScanning() async {
    setState(() {
      _isScanning = true;
      _entryResult = null;
      _errorMessage = null;
    });

    try {
      // NFC 사용 가능 여부 확인
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw Exception('NFC가 지원되지 않는 기기입니다.');
      }

      // NFC 태그 스캔 시작
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "여러 태그가 감지되었습니다",
        iosAlertMessage: "NFC 태그를 스캔하세요",
      );

      print('✅ NFC 태그 감지: ${tag.id}');

      // NDEF 데이터 읽기
      var ndefRecords = await FlutterNfcKit.readNDEFRecords(cached: false);

      if (ndefRecords.isEmpty) {
        throw Exception('NFC 태그에 데이터가 없습니다.');
      }

      // 첫 번째 레코드에서 JSON 텍스트 데이터 추출
      var record = ndefRecords.first;
      var payload = record.payload!;

      // 텍스트 레코드의 경우 앞 3바이트 제거 (언어 코드)
      String jsonString = String.fromCharCodes(payload.sublist(3));

      print('📖 NFC 데이터: $jsonString');

      // JSON 파싱
      final Map<String, dynamic> nfcData = jsonDecode(jsonString);
      final sessionId = nfcData['sessionId'];
      final gateId = nfcData['gateId'];

      // 세션 ID 일치 여부 확인
      //FIXME : 세션 id 읽을 수 있도록 앞선 api에서 수정 필요ㄴ
      // print('티켓 데이터:  ${widget.ticketData}');
      // if (sessionId != widget.ticketData['sessionId']) {
      //   throw Exception('세션 ID가 일치하지 않습니다.');
      // }

      // NFC 세션 종료
      await FlutterNfcKit.finish();

      final apiProvider = context.read<ApiProvider>();
      final success =
          await apiProvider.apiService.ticket.postEntry(
            widget.ticketId,
            gateId,
          ) ==
          "200";

      setState(() {
        _isScanning = false;
        _entryResult = success;
      });

      if (success) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('❌ NFC 스캔 오류: $e');
      setState(() {
        _errorMessage = e.toString();
        _entryResult = false;
        _isScanning = false;
      });

      try {
        await FlutterNfcKit.finish(iosErrorMessage: '스캔 실패');
      } catch (finishError) {
        print('NFC 세션 종료 오류: $finishError');
      }
    }
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
            Text('입장 게이트 인증을 완료해주세요!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('공연장 입장이 승인되었습니다.'),
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
              Navigator.of(context).pop(); // NFC 화면 닫기
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
        title: Text('NFC 간편 입장', style: TextStyle(color: AppColors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // 티켓 정보 요약
            Container(
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
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    widget.ticketData['venue'] ?? '공연장',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // NFC 스캔 영역
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_entryResult == null) ...[
                      // 스캔 대기 또는 처리 중 상태
                      AnimatedBuilder(
                        animation: _isProcessing
                            ? _rotationAnimation
                            : _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                            child: Transform.rotate(
                              angle: _isProcessing
                                  ? _rotationAnimation.value * 2 * 3.14159
                                  : 0,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isScanning || _isProcessing
                                      ? AppColors.primary.withOpacity(0.2)
                                      : AppColors.gray100,
                                  border: Border.all(
                                    color: _isScanning || _isProcessing
                                        ? AppColors.primary
                                        : AppColors.gray300,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  Icons.nfc,
                                  size: 80,
                                  color: _isScanning || _isProcessing
                                      ? AppColors.primary
                                      : AppColors.gray400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 32),

                      if (_isScanning) ...[
                        Text(
                          'NFC 태그를 스캔 중...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '휴대폰을 NFC 태그에 가까이 대어주세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else if (_isProcessing) ...[
                        Text(
                          '입장 인증 중...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ZKP 인증 및 NFT 소유권 확인 중입니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          'NFC 태그에 휴대폰을 대어주세요',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '3초 내 간편 입장이 완료됩니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ] else if (_entryResult == true) ...[
                      // 성공 상태
                      Icon(
                        Icons.check_circle,
                        size: 120,
                        color: AppColors.success,
                      ),
                      SizedBox(height: 24),
                      Text(
                        '입장 완료!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '공연장 입장이 승인되었습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      // 실패 상태
                      Icon(Icons.error, size: 120, color: AppColors.error),
                      SizedBox(height: 24),
                      Text(
                        '입장 실패',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage ?? '알 수 없는 오류가 발생했습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    SizedBox(height: 40),

                    // 액션 버튼
                    if (!_isScanning && !_isProcessing) ...[
                      if (_entryResult == null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _startNFCScanning,
                            icon: Icon(Icons.nfc, size: 24),
                            label: Text(
                              'NFC 스캔 시작',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ] else if (_entryResult == false) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _entryResult = null;
                                _errorMessage = null;
                              });
                            },
                            icon: Icon(Icons.refresh, size: 24),
                            label: Text(
                              '다시 시도',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // 안내 정보
            if (_entryResult == null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ZKP 인증으로 개인정보 보호',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '블록체인 기반 안전한 입장 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
