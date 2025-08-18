import 'package:flutter/material.dart';
import 'package:we_ticket/shared/data/models/patment_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:we_ticket/shared/presentation/screens/nft_issuance_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_logger.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final PaymentData paymentData;

  const PaymentWebViewScreen({Key? key, required this.paymentData})
    : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // progress 디바운스용
  int _lastProgressBucket = -1;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    // WebViewController는 별도 dispose 필요 없음.
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..enableZoom(false)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      // JavaScriptChannel 추가 (omnioneCX 방식)
      ..addJavaScriptChannel(
        'FlutterPayment',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePaymentMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;

            // 10% 단위로만 로딩 상태 갱신 (과도한 rebuild 방지)
            final bucket = (progress / 10).floor();
            if (progress >= 100) {
              if (_isLoading) {
                setState(() {
                  _isLoading = false;
                  _lastProgressBucket = 10;
                });
              }
              return;
            }
            if (bucket != _lastProgressBucket) {
              _lastProgressBucket = bucket;
              if (!_isLoading) {
                setState(() {
                  _isLoading = true;
                });
              }
            }
          },
          onPageStarted: (String url) {
            if (!mounted) return;
            if (!_isLoading) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            if (_isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            AppLogger.info('Navigation request: ${request.url}', 'PAYMENT');

            // 결제 완료 URL 체크
            if (request.url.startsWith('weticket://payment/')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }

            // 외부 앱 스킴 처리 (카카오페이, 카드 앱 등)
            if (_isExternalScheme(request.url)) {
              AppLogger.info(
                'External app scheme detected: ${request.url}',
                'PAYMENT',
              );
              _launchExternalApp(request.url);
              return NavigationDecision.prevent; // 외부 앱 스킴은 WebView에서 처리하지 않음
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error('WebView 에러', error.description, null, 'PAYMENT');
            if (!mounted) return;
            setState(() {
              _hasError = true;
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
        ),
      );

    _loadPaymentHTML();
  }

  Future<void> _loadPaymentHTML() async {
    try {
      final html = await _generatePaymentHTML();
      await _controller.loadHtmlString(html);

      // Payment target 비동기 로드 시작
      Future.delayed(Duration(milliseconds: 500), () {
        _loadPaymentTarget();
      });
    } catch (e) {
      AppLogger.error('HTML 로딩 에러', e, null, 'PAYMENT');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handlePaymentMessage(String message) {
    try {
      final data = jsonDecode(message);

      switch (data['type']) {
        case 'portone_ready':
          AppLogger.info('PortOne SDK loaded successfully', 'PAYMENT');
          break;
        case 'payment_result':
          _handlePortOneResult(data);
          break;
        default:
          AppLogger.info('Unknown payment message: ${data['type']}', 'PAYMENT');
      }
    } catch (e) {
      AppLogger.error('Payment message parsing error', e, null, 'PAYMENT');
    }
  }

  Future<void> _loadPaymentTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';
    final userId = prefs.getInt('user_id') ?? 0;

    try {
      final isTransfer = widget.paymentData.paymentType == 'transfer';
      final url = isTransfer
          ? 'http://43.201.185.8:8000/api/transfers/payment-target'
          : 'http://43.201.185.8:8000/api/tickets/payment-target';

      final requestData = isTransfer
          ? {
              'transfer_ticket_id': widget.paymentData is TransferPaymentData
                  ? (widget.paymentData as TransferPaymentData).transferTicketId
                  : 0,
              'buyer_user_id': widget.paymentData is TransferPaymentData
                  ? (widget.paymentData as TransferPaymentData).buyerUserId != 0
                        ? (widget.paymentData as TransferPaymentData)
                              .buyerUserId
                        : userId
                  : userId,
            }
          : {
              'performance_session_id':
                  widget.paymentData is TicketingPaymentData
                  ? (widget.paymentData as TicketingPaymentData)
                        .performanceSessionId
                  : 0,
              'seat_id': widget.paymentData is TicketingPaymentData
                  ? (widget.paymentData as TicketingPaymentData)
                            .selectedSeat['seat_id'] ??
                        (widget.paymentData as TicketingPaymentData)
                            .selectedSeat['id'] ??
                        1
                  : 1,
              'user_id': userId,
            };

      // API 요청 로그
      AppLogger.info('Payment target API request: $url', 'PAYMENT');
      AppLogger.info('Request data: ${jsonEncode(requestData)}', 'PAYMENT');

      // HTTP 요청 수행
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final paymentTarget = jsonDecode(response.body);
        AppLogger.info('Payment target loaded successfully', 'PAYMENT');
        AppLogger.info('paymet-target response : ${response.body}');

        // paymentId에서 특수문자 제거 (PortOne 요구사항)
        // final cleanPaymentNumber = paymentTarget['payment_number'].toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        // paymentTarget['payment_number'] = cleanPaymentNumber;

        // JavaScript에 결과 전달
        _controller.runJavaScript('''
          if (window.initPaymentData) {
            window.initPaymentData(${jsonEncode(paymentTarget)});
          }
        ''');
      } else {
        AppLogger.error(
          'Payment target API failed',
          'Status: ${response.statusCode}, Body: ${response.body}',
          null,
          'PAYMENT',
        );
        throw Exception('Payment target API failed: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Payment target loading error', e, null, 'PAYMENT');
      // 오류 시에도 기본 데이터 전달
      final cleanMerchantUid = widget.paymentData.merchantUid.replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '',
      );
      _controller.runJavaScript('''
        if (window.initPaymentData) {
          window.initPaymentData(${jsonEncode({'name': widget.paymentData.displayTitle, 'price': widget.paymentData.amount, 'currency': 'KRW', 'payment_number': cleanMerchantUid})});
        }
      ''');
    }
  }

  void _handlePortOneResult(Map<String, dynamic> data) async {
    AppLogger.info('PortOne result received: ${jsonEncode(data)}', 'PAYMENT');

    if (data['success'] == true) {
      AppLogger.info('Payment success, processing completion...', 'PAYMENT');
      // 결제 완료 API 호출을 Flutter에서 처리
      final completed = await _processPaymentCompletion(data['paymentId']);
      if (completed) {
        AppLogger.info('Payment completion successful', 'PAYMENT');
        _navigateToProcessing();
      } else {
        AppLogger.error('Payment completion failed', null, null, 'PAYMENT');
        if (mounted) {
          Navigator.pop(context, {
            'success': false,
            'error': 'Payment completion failed',
          });
        }
      }
    } else {
      AppLogger.error('Payment failed', data['error'], null, 'PAYMENT');
      if (mounted) {
        Navigator.pop(context, {'success': false, 'error': data['error']});
      }
    }
  }

  Future<bool> _processPaymentCompletion(String paymentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';
      final userId = prefs.getInt('user_id') ?? 0;

      AppLogger.info(
        'Processing payment completion for paymentId: $paymentId',
        'PAYMENT',
      );
      AppLogger.info(
        'User ID: $userId, Access Token length: ${accessToken.length}',
        'PAYMENT',
      );

      final isTransfer = widget.paymentData.paymentType == 'transfer';
      final url = isTransfer
          ? 'http://43.201.185.8:8000/api/transfers/transfer-process/'
          : 'http://43.201.185.8:8000/api/tickets/create/';

      final requestData = isTransfer
          ? {
              'payment_number': paymentId,
              'transfer_ticket_id': widget.paymentData is TransferPaymentData
                  ? (widget.paymentData as TransferPaymentData).transferTicketId
                  : 0,
              'buyer_user_id': widget.paymentData is TransferPaymentData
                  ? (widget.paymentData as TransferPaymentData).buyerUserId != 0
                        ? (widget.paymentData as TransferPaymentData)
                              .buyerUserId
                        : userId
                  : userId,
            }
          : {
              'payment_number': paymentId,
              'performance_session_id':
                  widget.paymentData is TicketingPaymentData
                  ? (widget.paymentData as TicketingPaymentData)
                        .performanceSessionId
                  : 0,
              'seat_id': widget.paymentData is TicketingPaymentData
                  ? (widget.paymentData as TicketingPaymentData)
                            .selectedSeat['seat_id'] ??
                        (widget.paymentData as TicketingPaymentData)
                            .selectedSeat['id'] ??
                        1
                  : 1,
              'user_id': userId,
            };

      AppLogger.info('Payment completion API URL: $url', 'PAYMENT');
      AppLogger.info(
        'Payment completion request data: ${jsonEncode(requestData)}',
        'PAYMENT',
      );

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestData),
      );

      AppLogger.info(
        'Payment completion response status: ${response.statusCode}',
        'PAYMENT',
      );
      AppLogger.info(
        'Payment completion response body: ${response.body}',
        'PAYMENT',
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final isPaid = result['status'] == 'PAID';
        AppLogger.info(
          'Payment completion result: isPaid=$isPaid, status=${result['status']}',
          'PAYMENT',
        );
        return isPaid;
      } else {
        AppLogger.error(
          'Payment completion API failed',
          'Status: ${response.statusCode}, Body: ${response.body}',
          null,
          'PAYMENT',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Payment completion error', e, null, 'PAYMENT');
      return false;
    }
  }

  Future<String> _generatePaymentHTML() async {
    return '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
      </head>
      <body style="margin:0;padding:0;background:#f9fafb;font-family:system-ui;">
        <div style="background:white;margin:20px;border-radius:8px;padding:20px;text-align:center;">
          <div id="status">결제 준비 중...</div>
          <div id="info" style="display:none;margin:20px 0;"></div>
          <button id="pay" onclick="pay()" style="display:none;width:100%;padding:16px;background:#1e3a8a;color:white;border:none;border-radius:8px;font-size:16px;">결제하기</button>
        </div>
        
        <script>
          let data = null;
          
          window.initPaymentData = function(d) {
            data = d;
            document.getElementById('status').textContent = '';
            document.getElementById('info').innerHTML = '<div>' + (d.name||'') + '</div><div style="font-weight:bold;color:#1e3a8a;margin:10px 0;">' + ((d.price||0).toLocaleString()) + '원</div>';
            document.getElementById('info').style.display = 'block';
            document.getElementById('pay').style.display = 'block';
          };
          
          function pay() {
            if (!data || !window.PortOne) return;
            document.getElementById('pay').disabled = true;
            document.getElementById('pay').textContent = '결제 중...';
            
            PortOne.requestPayment({
              storeId: 'store-1f64a474-19e0-4390-ae06-058509cd01c5',
              channelKey: 'channel-key-0e75745a-6c0f-4099-9b55-0d54f62fec0d',
              paymentId: data.payment_number,
              orderName: data.name,
              totalAmount: data.price,
              currency: 'KRW',
              payMethod: 'CARD',
              redirectUrl: 'weticket://payment/complete',
              appScheme: 'weticket://payment/complete'
            }).then(function(r) {
              FlutterPayment.postMessage(JSON.stringify({
                type: 'payment_result',
                success: !r.code,
                error: r.message || r.code,
                paymentId: r.paymentId
              }));
            }).catch(function(error) {
              FlutterPayment.postMessage(JSON.stringify({
                type: 'payment_result',
                success: false,
                error: error.message || 'Payment error',
                paymentId: null
              }));
            });
          }
          
          setTimeout(function() {
            if (window.PortOne) FlutterPayment.postMessage(JSON.stringify({type: 'portone_ready'}));
          }, 500);
        </script>
      </body>
    </html>
    ''';
  }

  void _handlePaymentResult(String url) {
    AppLogger.info('Payment result URL received: $url', 'PAYMENT');

    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    // PortOne의 경우 paymentId가 있으면 성공으로 간주
    final paymentId = params['paymentId'];
    final transactionType = params['transactionType'];

    AppLogger.info('Payment result params: ${params.toString()}', 'PAYMENT');

    if (paymentId != null && transactionType == 'PAYMENT') {
      AppLogger.info(
        'Payment successful via redirect URL, paymentId: $paymentId',
        'PAYMENT',
      );

      // Flutter 메시지 채널을 통해 결제 성공 처리
      _handlePortOneResult({
        'type': 'payment_result',
        'success': true,
        'paymentId': paymentId,
      });
    } else {
      AppLogger.error(
        'Payment failed via redirect URL',
        params.toString(),
        null,
        'PAYMENT',
      );

      final result = {
        'success': false,
        'merchant_uid': params['merchant_uid'],
        'imp_uid': params['imp_uid'],
        'error_msg': params['error_msg'] ?? 'Payment failed',
      };

      if (mounted) {
        Navigator.pop(context, result);
      }
    }
  }

  void _navigateToProcessing() {
    final isTransfer = widget.paymentData.paymentType == 'transfer';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                isTransfer
                    ? '결제가 완료되었습니다! 양도를 처리합니다.'
                    : '결제가 완료되었습니다! NFT 티켓을 발행합니다.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NFTIssuanceScreen(paymentData: widget.paymentData),
        ),
      );
    });
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '결제 페이지 로딩 중 오류가 발생했습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '알 수 없는 오류',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                  _isLoading = true;
                  _lastProgressBucket = -1;
                });
                _loadPaymentHTML();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('다시 시도'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, {'success': false}),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 요구사항
    final isTransfer = widget.paymentData.paymentType == 'transfer';

    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text(isTransfer ? '양도 구매' : '결제하기'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, {'success': false}),
          ),
        ),
        body: Stack(
          children: [
            if (_hasError)
              _buildErrorView()
            else
              // WebView 렌더링 최적화: 경계 명시적 설정
              Positioned.fill(child: WebViewWidget(controller: _controller)),
            if (_isLoading && !_hasError)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text('결제 페이지 로딩 중...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 외부 앱 스킴인지 확인
  bool _isExternalScheme(String url) {
    // HTTP/HTTPS는 WebView에서 처리
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return false;
    }

    // weticket 스킴은 내부 처리
    if (url.startsWith('weticket://')) {
      return false;
    }

    // 결제 관련 외부 앱 스킴들
    final externalSchemes = [
      'kakaotalk://',
      'kakaopay://',
      'intent://',
      'market://',
      'supertoss://',
      'toss://',
      'kb-acp://',
      'kbbank://',
      'nhappcardansimclick://',
      'nhbank://',
      'mpocket.online.ansimclick://',
      'lottesmartpay://',
      'cloudpay://',
      'payco://',
      'tswansimclick://',
      'shinhan-sr-ansimclick://',
      'hanabank://',
      'wooribank://',
      'citimobileapp://',
      'com.wooricard.wcard://',
      'lguthepay://',
      'newsmartpib://',
      'wooripay://',
    ];

    // 특정 스킴들 확인
    for (String scheme in externalSchemes) {
      if (url.startsWith(scheme)) {
        return true;
      }
    }

    // 일반적인 커스텀 스킴 패턴 확인 (://를 포함하지만 http/https가 아닌 경우)
    if (url.contains('://') &&
        !url.startsWith('http') &&
        !url.startsWith('weticket')) {
      return true;
    }

    return false;
  }

  // 외부 앱 실행
  Future<void> _launchExternalApp(String url) async {
    try {
      AppLogger.info('Attempting to launch external app: $url', 'PAYMENT');

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          AppLogger.info('Successfully launched external app', 'PAYMENT');
        } else {
          AppLogger.error(
            'Failed to launch external app',
            url,
            null,
            'PAYMENT',
          );
        }
      } else {
        AppLogger.error('Cannot launch URL', url, null, 'PAYMENT');

        // Intent URL인 경우 Google Play Store로 리다이렉트 시도
        if (url.startsWith('intent://')) {
          await _handleIntentUrl(url);
        }
      }
    } catch (e) {
      AppLogger.error('Error launching external app', e, null, 'PAYMENT');
    }
  }

  // Intent URL 처리
  Future<void> _handleIntentUrl(String intentUrl) async {
    try {
      // Intent URL에서 패키지명 추출
      final uri = Uri.parse(intentUrl);
      final packageName = uri.queryParameters['package'];

      if (packageName != null) {
        final playStoreUrl =
            'https://play.google.com/store/apps/details?id=$packageName';
        final playStoreUri = Uri.parse(playStoreUrl);

        if (await canLaunchUrl(playStoreUri)) {
          await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
          AppLogger.info(
            'Redirected to Play Store for package: $packageName',
            'PAYMENT',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error handling intent URL', e, null, 'PAYMENT');
    }
  }
}
