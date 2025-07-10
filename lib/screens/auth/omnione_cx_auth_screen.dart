import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class OmniOneCXAuthScreen extends StatefulWidget {
  @override
  _OmniOneCXAuthScreenState createState() => _OmniOneCXAuthScreenState();
}

class _OmniOneCXAuthScreenState extends State<OmniOneCXAuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _authStatus = '인증 대기 중...';
  bool _isTestMode = true; // 테스트 모드 플래그

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // WebViewController 초기화
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 진행률 업데이트 (선택사항)
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _injectOmniOneScript();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _authStatus = '페이지 로드 오류: ${error.description}';
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterAuth',
        onMessageReceived: (JavaScriptMessage message) {
          _handleAuthResult(message.message);
        },
      );

    _loadAuthPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('모바일 신분증 인증'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTestMode ? Icons.bug_report : Icons.security),
            onPressed: () {
              setState(() {
                _isTestMode = !_isTestMode;
              });
              _showTestModeDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 표시 영역
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Icon(_getStatusIcon(), size: 32, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  _authStatus,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isTestMode)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TEST MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // WebView 영역
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('인증창을 로딩 중입니다...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 테스트 버튼 영역 (테스트 모드일 때만 표시)
          if (_isTestMode)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '테스트 모드',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _simulateSuccess,
                          child: Text('인증 성공 시뮬레이션'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _simulateFailure,
                          child: Text('인증 실패 시뮬레이션'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _loadAuthPage() {
    String htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>OmniOne CX 인증</title>
        <script defer="defer" src="https://cx.raonsecure.co.kr:17543/ent/esign/oacx-vendor.js"></script>
        <script defer="defer" src="https://cx.raonsecure.co.kr:17543/ent/esign/oacx-ux.js"></script>
        <link href="https://cx.raonsecure.co.kr:17543/ent/esign/oacx-ux.css" rel="stylesheet">
        <style>
          body {
            font-family: Arial, sans-serif;
            padding: 20px;
            margin: 0;
            background-color: #f5f5f5;
          }
          .auth-container {
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
          }
          .auth-button {
            background: #2196F3;
            color: white;
            border: none;
            padding: 16px 32px;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            margin: 16px 0;
            width: 100%;
            max-width: 300px;
          }
          .auth-button:hover {
            background: #1976D2;
          }
          .qr-container {
            margin: 20px 0;
            padding: 20px;
            border: 2px dashed #ccc;
            border-radius: 8px;
            min-height: 200px;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .status-text {
            color: #666;
            font-size: 14px;
            margin: 8px 0;
          }
        </style>
      </head>
      <body>
        <div class="auth-container">
          <h2>모바일 신분증 인증</h2>
          <p class="status-text">아래 버튼을 클릭하여 인증을 시작하세요</p>
          
          <button id="mobileBtn" class="auth-button">
            📱 모바일 신분증으로 인증하기
          </button>
          
          <div id="oacxDiv" class="qr-container">
            <div class="status-text">인증창이 여기에 표시됩니다</div>
          </div>
          
          <div id="statusDiv" class="status-text">
            준비 완료
          </div>
        </div>
      </body>
      </html>
    ''';

    _controller.loadHtmlString(htmlContent);
  }

  void _injectOmniOneScript() {
    _controller.runJavaScript('''
      console.log('OmniOne CX 스크립트 초기화 중...');
      
      // 상태 업데이트 함수
      function updateStatus(message) {
        document.getElementById('statusDiv').innerHTML = message;
        FlutterAuth.postMessage(JSON.stringify({type: 'status', message: message}));
      }
      
      // 버튼 클릭 이벤트
      document.getElementById("mobileBtn").onclick = function() {
        updateStatus('🔄 OmniOne CX 인증 요청 중...');
        
        try {
          // 방법 1: contentInfo 내부에 isBirth 설정
          var authData1 = {
            provider: "coidentitydocument_v1.5",
            contentInfo: {
              signType: "ENT_MID",
              isBirth: "true",        // 생년월일 정보 포함
              isGender: false,      // 성별 정보 미포함  
              isAddr: false,        // 주소 정보 미포함
              isPhone: true         // 휴대폰 번호 정보 포함
            },
            compareCI: false
          };
          
          // 방법 2: 최상위 레벨에 설정
          var authData2 = {
            provider: "coidentitydocument_v1.5",
            contentInfo: {
              signType: "ENT_MID"
            },
            compareCI: false,
            isBirth: "true",          // 최상위 레벨에 설정
            isGender: false,
            isAddr: false,
            isPhone: true
          };
          
          // 방법 3: 가장 상세한 설정
          var authData3 = {
            provider: "coidentitydocument_v1.5",
            token: null,  // 실제로는 토큰 생성 API에서 받아온 값
            txId: null,   // 실제로는 토큰 생성 API에서 받아온 값
            contentInfo: {
              signType: "ENT_MID",
              isBirth: "true",
              isGender: false,
              isAddr: false,
              isPhone: true,
              requestType: "WEB2APP"
            },
            compareCI: false,
            extraParams: {
              isBirth: "true",
              isGender: false,
              isAddr: false,
              isPhone: true
            }
          };
          
          // 우선 방법 1로 시도
          var finalAuthData = authData1;
          
          console.log('🔍 인증 요청 데이터 (방법 1):', JSON.stringify(finalAuthData, null, 2));
          
          // 실제 OmniOne CX 호출
          if (typeof OACX !== 'undefined') {
            updateStatus('🔗 OACX 모듈 연결됨 - 인증 시작');
            
            OACX.LOAD_MODULE(
              "https://cx.raonsecure.co.kr:17543/ent/esign/config/config.mid.json", 
              finalAuthData, 
              function(res) {
                console.log("✅ OmniOne CX 인증 성공:", res);
                updateStatus('🎉 모바일 신분증 인증 완료!');
                
                FlutterAuth.postMessage(JSON.stringify({
                  type: 'auth_result', 
                  success: true, 
                  data: {
                    token: res.token || 'success_token',
                    userInfo: {
                      name: res.name || res.data?.name || '인증완료',
                      birth: res.birth || res.data?.birth || '',
                      phone: res.telno || res.phone || res.data?.phone || '',
                      ci: res.ci || res.data?.ci || ''
                    },
                    provider: 'coidentitydocument',
                    timestamp: Date.now(),
                    rawData: res
                  }
                }));
              },
              function(error) {
                console.error("❌ OmniOne CX 인증 실패:", error);
                console.log("오류 상세 정보:", JSON.stringify(error, null, 2));
                
                // isBirth 관련 오류인 경우 다른 방법으로 재시도
                if (error && (error.message || '').includes('isBirth')) {
                  console.log('🔄 isBirth 오류 감지 - 다른 방법으로 재시도');
                  updateStatus('🔄 설정 변경 후 재시도 중...');
                  
                  // 방법 2로 재시도
                  setTimeout(() => {
                    console.log('🔍 인증 요청 데이터 (방법 2):', JSON.stringify(authData2, null, 2));
                    OACX.LOAD_MODULE(
                      "https://cx.raonsecure.co.kr:17543/ent/esign/config/config.mid.json", 
                      authData2, 
                      function(res2) {
                        console.log("✅ 재시도 성공:", res2);
                        updateStatus('🎉 재시도로 인증 완료!');
                        FlutterAuth.postMessage(JSON.stringify({
                          type: 'auth_result', 
                          success: true, 
                          data: res2
                        }));
                      },
                      function(error2) {
                        console.log('🔄 방법 2도 실패 - 방법 3으로 재시도');
                        console.log('🔍 인증 요청 데이터 (방법 3):', JSON.stringify(authData3, null, 2));
                        
                        // 방법 3으로 최종 재시도
                        OACX.LOAD_MODULE(
                          "https://cx.raonsecure.co.kr:17543/ent/esign/config/config.mid.json", 
                          authData3, 
                          function(res3) {
                            console.log("✅ 방법 3 성공:", res3);
                            updateStatus('🎉 최종 재시도로 인증 완료!');
                            FlutterAuth.postMessage(JSON.stringify({
                              type: 'auth_result', 
                              success: true, 
                              data: res3
                            }));
                          },
                          function(error3) {
                            console.error("❌ 모든 방법 실패:", error3);
                            updateStatus('💥 모든 설정 방법 실패');
                            FlutterAuth.postMessage(JSON.stringify({
                              type: 'auth_result', 
                              success: false, 
                              error: {
                                method1: error,
                                method2: error2, 
                                method3: error3,
                                message: 'isBirth 설정 문제 - 모든 방법 실패'
                              }
                            }));
                          }
                        );
                      }
                    );
                  }, 1000);
                } else {
                  updateStatus('💥 인증 실패: ' + (error.message || error));
                  FlutterAuth.postMessage(JSON.stringify({
                    type: 'auth_result', 
                    success: false, 
                    error: error
                  }));
                }
              }
            );
          } else {
            console.warn('OACX 스크립트가 로드되지 않음');
            updateStatus('⚠️ OACX 스크립트 로드 확인 필요');
            FlutterAuth.postMessage(JSON.stringify({
              type: 'script_error', 
              message: 'OACX script not loaded'
            }));
          }
          
        } catch (e) {
          console.error('💥 예외 발생:', e);
          updateStatus('🚨 시스템 오류: ' + e.message);
          FlutterAuth.postMessage(JSON.stringify({
            type: 'auth_result', 
            success: false, 
            error: {
              code: 'SYSTEM_ERROR',
              message: e.message,
              stack: e.stack
            }
          }));
        }
      };
      
      updateStatus('✅ 준비 완료 - 인증 버튼을 클릭하세요');
      
      // OACX 로드 상태 확인
      setTimeout(function() {
        if (typeof OACX !== 'undefined') {
          console.log('OACX 객체 로드됨:', typeof OACX);
          console.log('OACX 메서드들:', Object.keys(OACX));
          updateStatus('✅ OACX 스크립트 로드 완료');
        } else {
          console.log('OACX 스크립트 로드 실패');
          updateStatus('⚠️ OACX 스크립트 로드 실패 - 네트워크 확인 필요');
        }
      }, 3000);
    ''');
  }

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
            _onAuthSuccess(data['data']);
          } else {
            _onAuthFailure(data['error']);
          }
          break;

        case 'script_error':
          setState(() {
            _authStatus = '스크립트 로드 실패 - 테스트 모드를 사용하세요';
          });
          break;
      }
    } catch (e) {
      print('메시지 파싱 오류: $e');
    }
  }

  void _onAuthSuccess(dynamic authData) {
    setState(() {
      _authStatus = '✅ 인증 성공!';
    });

    // 성공 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('인증 성공'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('모바일 신분증 인증이 완료되었습니다.'),
            if (authData != null) ...[
              SizedBox(height: 16),
              Text('인증 데이터:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  jsonEncode(authData),
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(authData); // 결과와 함께 이전 화면으로 돌아가기
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _onAuthFailure(dynamic error) {
    setState(() {
      _authStatus = '❌ 인증 실패';
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('인증 실패'),
        content: Text('인증 중 오류가 발생했습니다.\n오류: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 테스트 모드 시뮬레이션 함수들
  void _simulateSuccess() {
    final mockData = {
      'token': 'mock_jwt_token_12345',
      'userInfo': {
        'name': '홍길동',
        'birthDate': '1990-01-01',
        'phoneNumber': '010-1234-5678',
        'ci': 'mock_ci_value',
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _onAuthSuccess(mockData);
  }

  void _simulateFailure() {
    _onAuthFailure('사용자가 인증을 취소했습니다.');
  }

  void _showTestModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('테스트 모드'),
        content: Text(
          _isTestMode
              ? '테스트 모드가 활성화되었습니다. 하단의 시뮬레이션 버튼을 사용할 수 있습니다.'
              : '테스트 모드가 비활성화되었습니다. 실제 OmniOne CX 연동을 시도합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_authStatus.contains('성공')) return Colors.green;
    if (_authStatus.contains('실패')) return Colors.red;
    if (_authStatus.contains('오류')) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon() {
    if (_authStatus.contains('성공')) return Icons.check_circle;
    if (_authStatus.contains('실패')) return Icons.error;
    if (_authStatus.contains('오류')) return Icons.warning;
    return Icons.security;
  }
}
