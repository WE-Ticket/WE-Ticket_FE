import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:we_ticket/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class OmniOneCXAuthScreen extends StatefulWidget {
  final int currentAuthLevel;

  const OmniOneCXAuthScreen({Key? key, required this.currentAuthLevel})
    : super(key: key);

  @override
  _OmniOneCXAuthScreenState createState() => _OmniOneCXAuthScreenState();
}

class _OmniOneCXAuthScreenState extends State<OmniOneCXAuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _authStatus = '인증을 준비하고 있습니다...';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..addJavaScriptChannel(
        'FlutterAuth',
        onMessageReceived: (JavaScriptMessage message) {
          _handleAuthResult(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _authStatus = '인증 페이지를 불러오고 있습니다...';
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _authStatus = '인증을 진행해주세요';
            });

            // 페이지 로드 완료 후 바로 인증 시작
            _startAuthenticationImmediately();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _authStatus = '페이지 로드 오류가 발생했습니다';
              _isLoading = false;
            });
          },

          // 앱 스킴 처리
          onNavigationRequest: (NavigationRequest request) {
            print('네비게이션 요청: ${request.url}');

            // 앱 스킴 감지 및 처리
            if (_shouldLaunchExternalApp(request.url)) {
              _launchExternalApp(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // 바로 OmniOne CX 페이지 로드
    _loadOmniOnePage();
  }

  @override
  Widget build(BuildContext context) {
    // FIXME 앱바 삭제 + 웹뷰 X 누르면 바로 네비.pop 되도록
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '본인 인증',
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
      ),
      body: Column(
        children: [
          // 상태 표시 헤더
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: AppColors.surface,
          //     boxShadow: [
          //       BoxShadow(
          //         color: AppColors.shadowLight,
          //         spreadRadius: 1,
          //         blurRadius: 4,
          //         offset: Offset(0, 2),
          //       ),
          //     ],
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
          //       SizedBox(width: 12),
          //       Expanded(
          //         child: Text(
          //           _authStatus,
          //           style: TextStyle(
          //             fontSize: 14,
          //             fontWeight: FontWeight.w500,
          //             color: AppColors.textPrimary,
          //           ),
          //         ),
          //       ),
          //       if (_isLoading)
          //         SizedBox(
          //           width: 20,
          //           height: 20,
          //           child: CircularProgressIndicator(
          //             strokeWidth: 2,
          //             valueColor: AlwaysStoppedAnimation<Color>(
          //               AppColors.primary,
          //             ),
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
          // 웹뷰
          Expanded(child: WebViewWidget(controller: _controller)),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  // OmniOne CX 페이지 로드
  void _loadOmniOnePage() {
    String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>OmniOne CX 인증</title>
        <script defer="defer" src="https://cx.raonsecure.co.kr:17543/ent/esign/oacx-vendor.js"></script>
        <script defer="defer" src="https://cx.raonsecure.co.kr:17543/ent/esign/oacx-ux.js"></script>
        <link href="https://cx.raonsecure.co.kr:17543/ent/esign/oacx-ux.css" rel="stylesheet">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #F9FAFB;
            color: #111827;
          }
          #oacxDiv {
            width: 100%;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #FFFFFF;
          }
          .loading-container {
            text-align: center;
            padding: 40px;
          }
          .loading-text {
            color: #6B7280;
            font-size: 16px;
            margin-top: 16px;
          }
          .spinner {
            width: 40px;
            height: 40px;
            border: 4px solid #E5E7EB;
            border-top: 4px solid #1E3A8A;
            border-radius: 50%;
            animation: spin 1s linear infinite;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        </style>
      </head>
      <body>
        <div id="oacxDiv">
          <div class="loading-container">
            <div class="spinner"></div>
            <div class="loading-text">인증을 준비하고 있습니다...</div>
          </div>
        </div>
      </body>
      </html>
    ''';

    _controller.loadHtmlString(htmlContent);
  }

  // 페이지 로드 후 바로 인증 시작
  void _startAuthenticationImmediately() {
    // 인증 타입 결정
    String authType = _determineAuthType();

    setState(() {
      _authStatus = '${_getAuthTypeDisplayName(authType)} 인증을 시작합니다...';
    });

    _controller.runJavaScript('''
      console.log('OmniOne CX 즉시 인증 시작');
      
      // 상태 업데이트 함수
      function updateStatus(message) {
        FlutterAuth.postMessage(JSON.stringify({type: 'status', message: message}));
      }
      
      // 인증 설정
      var authConfig = ${_getAuthConfig(authType)};
      
      console.log('인증 요청 데이터:', JSON.stringify(authConfig, null, 2));
      updateStatus('${_getAuthTypeDisplayName(authType)} 인증 요청 중...');
      
      // OACX 스크립트 로드 확인 후 바로 실행
      setTimeout(function() {
        if (typeof OACX !== 'undefined') {
          console.log('OACX 객체 확인됨 - 즉시 인증 시작');
          updateStatus('🔗 인증 모듈 연결됨');
          
          OACX.LOAD_MODULE(
            "https://cx.raonsecure.co.kr:17543/ent/esign/config/config.mid.json", 
            authConfig, 
            function(res) {
              console.log("✅ OmniOne CX 인증 성공:", res);
              updateStatus('✅ 인증이 완료되었습니다!');
              
              FlutterAuth.postMessage(JSON.stringify({
                type: 'auth_result',
                success: true,
                authType: '$authType',
                data: res
              }));
            },
            function(err) {
              console.error("❌ OmniOne CX 인증 실패:", err);
              updateStatus('❌ 인증 중 오류가 발생했습니다');
              
              FlutterAuth.postMessage(JSON.stringify({
                type: 'auth_result',
                success: false,
                authType: '$authType',
                error: err
              }));
            }
          );
        } else {
          console.log('OACX 스크립트 로드 실패');
          updateStatus('❌ 인증 모듈 로드 실패');
          
          FlutterAuth.postMessage(JSON.stringify({
            type: 'script_error',
            message: 'OACX 스크립트 로드 실패'
          }));
        }
      }, 2000);
    ''');
  }

  // 인증 타입 결정
  String _determineAuthType() {
    if (widget.currentAuthLevel == 0) {
      return 'simple'; // 기본값: 간편 인증
    } else {
      return 'mobile_id'; // 모바일 신분증 인증
    }
  }

  // 인증 설정 JSON 반환
  String _getAuthConfig(String authType) {
    if (authType == 'simple') {
      return '''
      {
        "provider": "comdl_v1.5",
        "contentInfo": {
          "signType": "ENT_SIMPLE_AUTH"
        },
        "compareCI": false,
        "isBirth" : true
      }
      ''';
    } else {
      return '''
      {
        "provider": "coidentitydocument_v1.5",
        "contentInfo": {
          "signType": "ENT_MID",
        },
        "compareCI": false,
        "isBirth" : true
      }
      ''';
    }
  }

  // 인증 타입 표시명 반환
  String _getAuthTypeDisplayName(String authType) {
    switch (authType) {
      case 'simple':
        return '간편';
      case 'mobile_id':
        return '모바일 신분증';
      default:
        return '본인';
    }
  }

  // 인증 결과 처리
  void _handleAuthResult(String message) {
    try {
      final data = jsonDecode(message);

      switch (data['type']) {
        case 'status':
          setState(() {
            _authStatus = data['message'];
          });
          break;

        case 'auth_result':
          if (data['success']) {
            _onAuthSuccess(data);
          } else {
            _onAuthFailure(data['error']);
          }
          break;

        case 'script_error':
          setState(() {
            _authStatus = '인증 모듈 로드 실패';
            _isLoading = false;
          });
          _showErrorDialog('인증 모듈을 불러올 수 없습니다.\n네트워크 연결을 확인해주세요.');
          break;
      }
    } catch (e) {
      print('메시지 파싱 오류: $e');
    }
  }

  // 인증 성공 처리
  void _onAuthSuccess(dynamic result) {
    setState(() {
      _authStatus = '✅ 인증 성공!';
      _isLoading = false;
    });

    // 성공 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Text(
              '인증 성공',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '본인 인증이 완료되었습니다!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _getSuccessMessage(result['authType']),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(result); // 결과와 함께 이전 화면으로
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
              '확인',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 인증 실패 처리
  void _onAuthFailure(dynamic error) {
    setState(() {
      _authStatus = '인증 실패';
      _isLoading = false;
    });

    _showErrorDialog('인증 중 오류가 발생했습니다.\n다시 시도해주세요.\n\n오류 정보: $error');
  }

  // 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text(
              '인증 실패',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Container(
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 페이지 새로고침하여 다시 시도
              _loadOmniOnePage();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text('다시 시도'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 이전 화면으로
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 상태별 색상 반환
  Color _getStatusColor() {
    if (_authStatus.contains('성공') || _authStatus.contains('완료'))
      return AppColors.success;
    if (_authStatus.contains('실패') || _authStatus.contains('오류'))
      return AppColors.error;
    if (_authStatus.contains('요청') || _authStatus.contains('진행'))
      return AppColors.warning;
    return AppColors.primary;
  }

  // 상태별 아이콘 반환
  IconData _getStatusIcon() {
    if (_authStatus.contains('성공') || _authStatus.contains('완료'))
      return Icons.check_circle;
    if (_authStatus.contains('실패') || _authStatus.contains('오류'))
      return Icons.error;
    if (_authStatus.contains('요청') || _authStatus.contains('진행'))
      return Icons.hourglass_empty;
    return Icons.security;
  }

  // 성공 메시지 반환
  String _getSuccessMessage(String? authType) {
    if (authType == 'simple') {
      return '일반 인증 회원이 되었습니다!\n이제 공연 예매와 기본 서비스를 이용하실 수 있습니다.';
    } else {
      return '모바일 신분증 인증 회원이 되었습니다!\n이제 3초 간편입장과 강화된 보안 서비스를 이용하실 수 있습니다.';
    }
  }

  // 외부 앱 실행이 필요한 URL인지 확인
  bool _shouldLaunchExternalApp(String url) {
    final appSchemes = [
      'mobileid://', // 모바일 신분증 앱
      'tauthlink://', // 통합인증 앱
      'naversearchapp://', // 네이버 앱
      'kakaotalk://', // 카카오톡
      // 'ktauthexternalcall://', // KT 인증
      // 'upluscorporation://', // LG U+ 인증
      // 'nhappvardsstoken://', // NH 앱카드
      // 'cloudpay://', // 클라우드페이 앱
      // 'smartwall://', // 스마트월 앱
      // 'citispay://', // 시티페이 앱
      // 'payco://', // 페이코 앱
      // 'lguthepay://', // LGU+ 페이
      // 'hdcardappcardansimclick://', // HD카드 앱
      // 'smhyundaiansimclick://', // 현대카드 앱
      // 'shinhan-sr-ansimclick://', // 신한카드 앱
      // 'smshinhanansimclick://', // 신한카드 앱
      // 'kb-acp://', // KB 앱
      // 'mpocket.online.ansimclick://', // 삼성카드 앱
      // 'wooripay://', // 우리페이 앱
      // 'nhappcardansimclick://', // NH카드 앱
      // 'hanawalletmembers://', // 하나카드 앱
      // 'shinsegaeeasypayment://', // 신세계 앱
      'intent://', // Android Intent
      // 추가 스킴들
    ];

    // URL이 앱 스킴으로 시작하는지 확인
    return appSchemes.any((scheme) => url.startsWith(scheme));
  }

  // 외부 앱 실행
  Future<void> _launchExternalApp(String url) async {
    try {
      print('외부 앱 실행 시도: $url');

      setState(() {
        _authStatus = '인증 앱 실행 중...';
      });

      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 외부 앱에서 실행
        );

        if (launched) {
          print('!!외부 앱 실행 성공');
          setState(() {
            _authStatus = '인증 앱에서 인증을 진행하세요';
          });

          // 앱이 다시 돌아왔을 때를 위한 타이머 설정
          _startReturnWaitTimer();
        } else {
          print('❌ 외부 앱 실행 실패');
          _handleAppLaunchFailure(url);
        }
      } else {
        print('❌ 외부 앱을 실행할 수 없음');
        _handleAppLaunchFailure(url);
      }
    } catch (e) {
      print('외부 앱 실행 중 예외: $e');
      _handleAppLaunchFailure(url);
    }
  }

  // 앱 실행 실패 처리
  void _handleAppLaunchFailure(String url) {
    setState(() {
      _authStatus = '❌ 인증 앱 실행 실패';
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text(
              '인증 앱 실행 실패',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '인증 앱을 실행할 수 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '확인사항:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '• 해당 인증 앱이 설치되어 있는지 확인\n• 앱 스킴: ${url.split('://')[0]}://\n• 다른 인증 방법을 시도하거나 해당 앱을 설치해 주세요.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 페이지 새로고침하여 다시 시도
              _loadOmniOnePage();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text('다시 시도'),
          ),
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
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 앱에서 돌아오는 것을 기다리는 타이머
  void _startReturnWaitTimer() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _authStatus = '인증 완료를 기다리는 중...';
        });
      }
    });

    // 30초 후 타임아웃 처리
    Future.delayed(Duration(seconds: 30), () {
      if (mounted && _authStatus.contains('기다리는 중')) {
        setState(() {
          _authStatus = '인증 시간 초과 - 다시 시도해 주세요';
        });
      }
    });
  }
}
