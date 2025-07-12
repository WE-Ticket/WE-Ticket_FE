import 'package:flutter/material.dart';
import '../../core/dio_client.dart';
import '../../services/performance_service.dart';
import '../../utils/app_colors.dart';

class ApiTestScreen extends StatefulWidget {
  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  late PerformanceService _performanceService;
  String _output = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _performanceService = PerformanceService(DioClient());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('API 테스트'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API 테스트',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20),

            // 테스트 버튼들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testHotPerformances,
                  child: Text('HOT 공연'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testAvailablePerformances,
                  child: Text('예매 가능한 공연'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testAllPerformances,
                  child: Text('전체 공연 목록'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testPerformanceDetail,
                  child: Text('공연 상세 (ID: 1)'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearOutput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray400,
                  ),
                  child: Text('Clear'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // 로딩 인디케이터
            if (_isLoading)
              Row(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(width: 16),
                  Text('API 호출 중...'),
                ],
              ),

            SizedBox(height: 16),

            // 결과 출력
            Text(
              '결과:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? 'API 테스트 버튼을 눌러주세요.' : _output,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testHotPerformances() async {
    setState(() {
      _isLoading = true;
      _output = '🔥 HOT 공연 API 호출 중...\n';
    });

    try {
      final performances = await _performanceService.getHotPerformances();
      setState(() {
        _output += '✅ 성공! ${performances.length}개의 HOT 공연 조회\n\n';
        for (int i = 0; i < performances.length; i++) {
          final p = performances[i];
          _output += '${i + 1}. ${p.title}\n';
          _output += '   - ID: ${p.performanceId}\n';
          _output += '   - 장르: ${p.genre}\n';
          _output += '   - 장소: ${p.venueName}\n';
          _output += '   - 날짜: ${p.startDate}\n';
          _output += '   - HOT: ${p.isHot}\n';
          _output += '   - 태그: ${p.tags.join(', ')}\n\n';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output += '❌ 실패: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAvailablePerformances() async {
    setState(() {
      _isLoading = true;
      _output = '🎫 예매 가능한 공연 API 호출 중...\n';
    });

    try {
      final performances = await _performanceService.getAvailablePerformances();
      setState(() {
        _output += '✅ 성공! ${performances.length}개의 예매 가능한 공연 조회\n\n';
        for (int i = 0; i < performances.length; i++) {
          final p = performances[i];
          _output += '${i + 1}. ${p.title}\n';
          _output += '   - ID: ${p.performanceId}\n';
          _output += '   - 장르: ${p.genre}\n';
          _output += '   - 장소: ${p.venueName}\n';
          _output += '   - 날짜: ${p.startDate} ~ ${p.endDate}\n';
          _output += '   - 주최: ${p.agencyName}\n\n';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output += '❌ 실패: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAllPerformances() async {
    setState(() {
      _isLoading = true;
      _output = '📋 전체 공연 목록 API 호출 중...\n';
    });

    try {
      final result = await _performanceService.getAllPerformances();
      setState(() {
        _output += '✅ 성공! 전체 공연 목록 조회\n\n';
        _output += '전체 개수: ${result['count']}\n';
        _output += '다음 페이지: ${result['next'] ?? 'null'}\n';
        _output += '이전 페이지: ${result['previous'] ?? 'null'}\n\n';

        final results = result['results'] as List;
        _output += '현재 페이지 공연 수: ${results.length}\n\n';

        for (int i = 0; i < results.length && i < 3; i++) {
          // 처음 3개만 출력
          final p = results[i];
          _output += '${i + 1}. ${p['title']}\n';
          _output += '   - ID: ${p['performance_id']}\n';
          _output += '   - 장르: ${p['genre']}\n';
          _output += '   - 공연자: ${p['performer_name']}\n';
          _output += '   - 최소 가격: ${p['min_price']}원\n';
          _output += '   - 예매 오픈: ${p['is_ticket_open']}\n';
          _output += '   - 매진: ${p['is_sold_out']}\n\n';
        }

        if (results.length > 3) {
          _output += '... 외 ${results.length - 3}개 더\n';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output += '❌ 실패: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testPerformanceDetail() async {
    setState(() {
      _isLoading = true;
      _output = '🎭 공연 상세 정보 API 호출 중 (ID: 1)...\n';
    });

    try {
      final performance = await _performanceService.getPerformanceDetail(1);
      setState(() {
        _output += '✅ 성공! 공연 상세 정보 조회\n\n';
        _output += '제목: ${performance.title}\n';
        _output += 'ID: ${performance.performanceId}\n';
        _output += '장르: ${performance.genre}\n';
        _output += '시작일: ${performance.startDate}\n';
        _output += '종료일: ${performance.endDate}\n';
        _output += '런타임: ${performance.runtime}분\n';
        _output += '연령 제한: ${performance.ageRating}\n';
        _output += '장소: ${performance.venueName}\n';
        _output += '위치: ${performance.venueLocation}\n';
        _output += '주최: ${performance.agencyName}\n';
        _output += 'HOT 여부: ${performance.isHot}\n';
        _output += '태그: ${performance.tags.join(', ')}\n';
        _output += '메인 이미지: ${performance.mainImage}\n';
        _output += '상세 이미지: ${performance.detailImage}\n';
        _output += '티켓 오픈: ${performance.ticketOpenDatetime}\n';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output += '❌ 실패: $e\n';
        _isLoading = false;
      });
    }
  }

  void _clearOutput() {
    setState(() {
      _output = '';
    });
  }
}
