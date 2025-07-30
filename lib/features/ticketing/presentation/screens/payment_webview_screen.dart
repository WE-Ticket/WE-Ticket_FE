import 'package:flutter/material.dart';
import 'package:we_ticket/features/ticketing/data/models/patment_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:we_ticket/features/ticketing/presentation/screens/nft_issuance_screen.dart';
import '../../../../core/constants/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final PaymentData paymentData;

  const PaymentWebViewScreen({Key? key, required this.paymentData})
    : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
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
          },
          onNavigationRequest: (NavigationRequest request) {
            // 결제 완료 URL 체크
            if (request.url.startsWith('weticket://')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_generatePaymentHTML());
  }

  String _generatePaymentHTML() {
    final name = widget.paymentData.displayTitle;
    final amount = widget.paymentData.amount;
    final merchantUid = widget.paymentData.merchantUid;
    final isTransfer = widget.paymentData.paymentType == 'transfer';

    // 추가 정보 생성
    String additionalInfo = '';
    if (isTransfer && widget.paymentData is TransferPaymentData) {
      final transferData = widget.paymentData as TransferPaymentData;
      additionalInfo =
          '''
        <p><strong>공연:</strong> ${transferData.performanceTitle}</p>
        <p><strong>좌석:</strong> ${transferData.seatNumber} (${transferData.seatGrade})</p>
        <p><strong>양도가격:</strong> ${transferData.transferPriceDisplay}</p>
        <p><strong>구매자 수수료:</strong> ${transferData.buyerFeeDisplay}</p>
      ''';
    } else if (widget.paymentData is TicketingPaymentData) {
      final ticketData = widget.paymentData as TicketingPaymentData;
      final concertInfo = ticketData.concertInfo;
      final selectedSeat = ticketData.selectedSeat;
      additionalInfo =
          '''
        <p><strong>아티스트:</strong> ${concertInfo['artist'] ?? ''}</p>
        <p><strong>좌석:</strong> ${ticketData.selectedZone}구역 ${selectedSeat['seatRow'] ?? ''}행 ${selectedSeat['seatCol'] ?? ''}번</p>
        <p><strong>좌석등급:</strong> ${ticketData.seatGrade}</p>
      ''';
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>결제하기</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .payment-container {
                background: white;
                border-radius: 12px;
                padding: 24px;
                margin: 20px 0;
                box-shadow: 0 2px 12px rgba(0,0,0,0.1);
            }
            .payment-info {
                margin-bottom: 20px;
                padding-bottom: 20px;
                border-bottom: 1px solid #eee;
            }
            .additional-info {
                background-color: #f8f9fa;
                border-radius: 8px;
                padding: 16px;
                margin: 16px 0;
                border-left: 4px solid ${isTransfer ? '#FFA500' : '#1E3A8A'};
            }
            .payment-method {
                margin: 16px 0;
                padding: 12px;
                border: 1px solid #ddd;
                border-radius: 8px;
                cursor: pointer;
            }
            .payment-method.selected {
                border-color: #1E3A8A;
                background-color: #f0f4ff;
            }
            .pay-button {
                width: 100%;
                padding: 16px;
                background-color: ${isTransfer ? '#FFA500' : '#1E3A8A'};
                color: white;
                border: none;
                border-radius: 12px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                margin-top: 20px;
            }
            .pay-button:hover {
                background-color: ${isTransfer ? '#FF8C00' : '#1E40AF'};
            }
            .loading {
                display: none;
                text-align: center;
                padding: 20px;
            }
            .transfer-badge {
                display: inline-block;
                background-color: #FFA500;
                color: white;
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 12px;
                font-weight: 600;
                margin-left: 8px;
            }
        </style>
    </head>
    <body>
        <div class="payment-container">
            <h2>${isTransfer ? '양도 티켓 구매' : '티켓 결제'}</h2>
            <div class="payment-info">
                <p><strong>상품명:</strong> $name ${isTransfer ? '<span class="transfer-badge">양도</span>' : ''}</p>
                <p><strong>결제금액:</strong> ${_formatPrice(amount)}원</p>
                <p><strong>주문번호:</strong> $merchantUid</p>
            </div>
            
            <div class="additional-info">
                <h4>${isTransfer ? '양도 상품 정보' : '공연 정보'}</h4>
                $additionalInfo
            </div>
            
            <h3>결제 수단 선택</h3>
            <div class="payment-method selected" onclick="selectPayment('card')">
                <strong>신용/체크카드</strong>
                <p>간편하고 안전한 카드 결제</p>
            </div>
            
            <div class="payment-method" onclick="selectPayment('trans')">
                <strong>계좌이체</strong>
                <p>실시간 계좌이체</p>
            </div>
            
            <div class="payment-method" onclick="selectPayment('vbank')">
                <strong>무통장입금</strong>
                <p>가상계좌 입금</p>
            </div>
            
            <button class="pay-button" onclick="processPayment()">
                ${_formatPrice(amount)}원 ${isTransfer ? '양도 구매하기' : '결제하기'}
            </button>
            
            <div class="loading" id="loading">
                <p>${isTransfer ? '양도 처리 중...' : '결제 처리 중...'}</p>
            </div>
        </div>
        
        <script>
            let selectedMethod = 'card';
            
            function selectPayment(method) {
                selectedMethod = method;
                document.querySelectorAll('.payment-method').forEach(el => {
                    el.classList.remove('selected');
                });
                event.target.closest('.payment-method').classList.add('selected');
            }
            
            function processPayment() {
                document.getElementById('loading').style.display = 'block';
                document.querySelector('.pay-button').style.display = 'none';
                
                // 실제 환경에서는 여기서 PG사 결제 모듈을 호출
                // 테스트용으로 2초 후 성공 처리
                setTimeout(() => {
                    const result = {
                        success: true,
                        merchant_uid: '$merchantUid',
                        imp_uid: 'imp_' + Date.now(),
                        pay_method: selectedMethod,
                        amount: $amount
                    };
                    
                    // 앱으로 결과 전달
                    window.location.href = 'weticket://payment/success?' + 
                        'merchant_uid=' + result.merchant_uid + 
                        '&imp_uid=' + result.imp_uid +
                        '&success=true';
                }, 2000);
            }
        </script>
    </body>
    </html>
    ''';
  }

  String _formatPrice(int? price) {
    if (price == null) return '0';
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _handlePaymentResult(String url) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    final result = {
      'success': params['success'] == 'true',
      'merchant_uid': params['merchant_uid'],
      'imp_uid': params['imp_uid'],
      'error_msg': params['error_msg'],
    };

    if (result['success'] == true) {
      // 결제 성공 - NFT 발행/양도 처리 화면으로 이동
      _navigateToProcessing();
    } else {
      // 결제 실패
      Navigator.pop(context, result);
    }
  }

  void _navigateToProcessing() {
    final isTransfer = widget.paymentData.paymentType == 'transfer';

    // 결제 성공 토스트 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.white, size: 20),
            SizedBox(width: 12),
            Text(
              isTransfer
                  ? '결제가 완료되었습니다! 양도를 처리합니다.'
                  : '결제가 완료되었습니다! NFT 티켓을 발행합니다.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 1초 후 처리 화면으로 이동
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NFTIssuanceScreen(paymentData: widget.paymentData),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = widget.paymentData.paymentType == 'transfer';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTransfer ? '양도 구매' : '결제하기'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context, {'success': false}),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
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
    );
  }
}
