import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/ticket_models.dart';

class StadiumBackgroundLayout extends StatelessWidget {
  final SessionSeatInfo? sessionSeatInfo;
  final String? selectedZone;
  final Function(String) onZoneSelected;

  const StadiumBackgroundLayout({
    super.key,
    required this.sessionSeatInfo,
    required this.selectedZone,
    required this.onZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSectionTitle(),
        SizedBox(height: 16),
        _buildStadiumImageWithTouchZones(context),
        SizedBox(height: 16),
        _buildSectionLegend(),
        if (selectedZone != null) ...[
          SizedBox(height: 16),
          _buildSelectedZoneInfo(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            '좌석배치도',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '원하는 구역을 터치해주세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStadiumImageWithTouchZones(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 배경 이미지
            Image.asset(
              'lib/features/ticketing/presentation/widgets/좌석배치도.png',
              width: double.infinity,
              height: 400,
              fit: BoxFit.contain,
            ),
            // 터치 오버레이
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) => _handleImageTap(details, context),
                child: Container(
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: SelectionOverlayPainter(
                      selectedZone: selectedZone,
                      sessionSeatInfo: sessionSeatInfo,
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

  void _handleImageTap(TapDownDetails details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = details.localPosition;
    final imageWidth = renderBox.size.width - 32; // padding 제외
    final imageHeight = 400;

    // 이미지 내부의 상대적 위치 계산 (0.0 ~ 1.0)
    final relativeX = (localPosition.dx - 16) / imageWidth;
    final relativeY = localPosition.dy / imageHeight;

    final zone = _getZoneFromPosition(relativeX, relativeY);
    if (zone != null) {
      final zoneInfo = _getZoneInfo(zone);
      // 서버에서 받아온 구역(1,2,3,4)만 실제 선택 가능
      if (zoneInfo != null && zoneInfo.isAvailable) {
        onZoneSelected(zone);
      } else {
        // 다른 구역도 선택은 되지만 정보만 표시
        onZoneSelected(zone);
      }
    }
  }

  String? _getZoneFromPosition(double x, double y) {
    // 순서를 바꿔서 더 구체적인 영역부터 체크 (VIP 구역 우선)
    
    // VIP 구역들 먼저 체크 (더 구체적인 영역)
    // VIP 구역 F1 (좌상)
    if (y >= 0.30 && y <= 0.46 && x >= 0.23 && x <= 0.37) {
      return 'F1';
    }

    // VIP 구역 F2 (우상)
    if (y >= 0.30 && y <= 0.46 && x >= 0.63 && x <= 0.77) {
      return 'F2';
    }

    // VIP 구역 F3 (좌하)
    if (y >= 0.50 && y <= 0.66 && x >= 0.23 && x <= 0.37) {
      return 'F3';
    }

    // VIP 구역 F4 (우하)
    if (y >= 0.50 && y <= 0.66 && x >= 0.63 && x <= 0.77) {
      return 'F4';
    }

    // 상단 구역 (15, 14, 13, 12, 1, 2, 3, 4)
    if (y >= 0.15 && y <= 0.30) {
      if (x >= 0.06 && x <= 0.14) return '15';
      if (x >= 0.14 && x <= 0.22) return '14';
      if (x >= 0.22 && x <= 0.30) return '13';
      if (x >= 0.30 && x <= 0.38) return '12';
      // 무대 영역 건너뛰기 (x: 0.38 ~ 0.62)
      if (x >= 0.62 && x <= 0.70) return '1';
      if (x >= 0.70 && x <= 0.78) return '2';
      if (x >= 0.78 && x <= 0.86) return '3';
      if (x >= 0.86 && x <= 0.94) return '4';
    }

    // 좌측 구역 (43, 42, 41, 40)
    if (x >= 0.06 && x <= 0.19) {
      if (y >= 0.30 && y <= 0.38) return '43';
      if (y >= 0.38 && y <= 0.46) return '42';
      if (y >= 0.46 && y <= 0.54) return '41';
      if (y >= 0.54 && y <= 0.62) return '40';
    }

    // 우측 구역 (24, 25, 26, 27, 28)
    if (x >= 0.81 && x <= 0.94) {
      if (y >= 0.30 && y <= 0.38) return '24';
      if (y >= 0.38 && y <= 0.46) return '25';
      if (y >= 0.46 && y <= 0.54) return '26';
      if (y >= 0.54 && y <= 0.62) return '27';
      if (y >= 0.62 && y <= 0.70) return '28';
    }

    // 중간 하단 구역 (11, 10, 9, 8, 7, 6, 5) - VIP 구역과 겹치지 않게 위치 조정
    if (y >= 0.66 && y <= 0.76) {
      if (x >= 0.19 && x <= 0.27) return '11';
      if (x >= 0.27 && x <= 0.35) return '10';
      if (x >= 0.35 && x <= 0.43) return '9';
      if (x >= 0.43 && x <= 0.51) return '8';
      if (x >= 0.51 && x <= 0.59) return '7';
      if (x >= 0.59 && x <= 0.67) return '6';
      if (x >= 0.67 && x <= 0.75) return '5';
    }

    // 최하단 구역 (39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29)
    if (y >= 0.76 && y <= 0.92) {
      if (x >= 0.06 && x <= 0.14) return '39';
      if (x >= 0.14 && x <= 0.22) return '38';
      if (x >= 0.22 && x <= 0.30) return '37';
      if (x >= 0.30 && x <= 0.38) return '36';
      if (x >= 0.38 && x <= 0.46) return '35';
      if (x >= 0.46 && x <= 0.54) return '34';
      if (x >= 0.54 && x <= 0.62) return '33';
      if (x >= 0.62 && x <= 0.70) return '32';
      if (x >= 0.70 && x <= 0.78) return '31';
      if (x >= 0.78 && x <= 0.86) return '30';
      if (x >= 0.86 && x <= 0.94) return '29';
    }

    return null;
  }

  Widget _buildSectionLegend() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            '구역 안내',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildLegendItem('VIP석 (STANDING)', Color(0xFFD32F2F)),
              _buildLegendItem('일반석 (SEATED)', Color(0xFFFFC107)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedZoneInfo() {
    if (selectedZone == null) return SizedBox.shrink();

    final zoneInfo = _getZoneInfo(selectedZone!);
    final isActive = zoneInfo != null && zoneInfo.isAvailable;
    final isVipZone = selectedZone!.startsWith('F');

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive 
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
            ? AppColors.primary.withValues(alpha: 0.3)
            : AppColors.gray300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_seat, 
            color: isActive ? AppColors.primary : AppColors.gray500, 
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택된 구역: $selectedZone',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : AppColors.gray600,
                  ),
                ),
                SizedBox(height: 4),
                if (isActive && zoneInfo != null) ...[
                  Text(
                    '${zoneInfo.seatGrade} - ${zoneInfo.priceDisplay}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  Text(
                    isVipZone ? 'VIP석 (서버 미지원)' : '일반석 (서버 미지원)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    '곧 이용 가능할 예정입니다',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isActive) ...[
            Icon(
              Icons.info_outline,
              color: AppColors.gray400,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  SeatPricingInfo? _getZoneInfo(String zone) {
    if (sessionSeatInfo == null) return null;
    return sessionSeatInfo!.seatPricingInfo
        .where((zoneInfo) => zoneInfo.seatZone == zone)
        .firstOrNull;
  }
}

class SelectionOverlayPainter extends CustomPainter {
  final String? selectedZone;
  final SessionSeatInfo? sessionSeatInfo;

  SelectionOverlayPainter({
    required this.selectedZone,
    required this.sessionSeatInfo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedZone == null) return;

    // 선택된 구역에 오버레이 표시
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final overlayRect = _getZoneRect(selectedZone!, size);
    if (overlayRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(overlayRect, Radius.circular(8)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(overlayRect, Radius.circular(8)),
        borderPaint,
      );
    }
  }

  Rect? _getZoneRect(String zone, Size size) {
    // 터치 영역과 정확히 일치하는 오버레이 사각형 반환 (크기 축소)
    switch (zone) {
      // VIP 구역들 - 터치 영역과 정확히 매칭
      case 'F1':
        return Rect.fromLTWH(
          size.width * 0.23, size.height * 0.30,
          size.width * 0.14, size.height * 0.16,
        );
      case 'F2':
        return Rect.fromLTWH(
          size.width * 0.63, size.height * 0.30,
          size.width * 0.14, size.height * 0.16,
        );
      case 'F3':
        return Rect.fromLTWH(
          size.width * 0.23, size.height * 0.50,
          size.width * 0.14, size.height * 0.16,
        );
      case 'F4':
        return Rect.fromLTWH(
          size.width * 0.63, size.height * 0.50,
          size.width * 0.14, size.height * 0.16,
        );

      // 상단 구역들
      case '15':
        return Rect.fromLTWH(size.width * 0.06, size.height * 0.15, size.width * 0.08, size.height * 0.15);
      case '14':
        return Rect.fromLTWH(size.width * 0.14, size.height * 0.15, size.width * 0.08, size.height * 0.15);
      case '13':
        return Rect.fromLTWH(size.width * 0.22, size.height * 0.15, size.width * 0.08, size.height * 0.15);
      case '12':
        return Rect.fromLTWH(size.width * 0.30, size.height * 0.15, size.width * 0.08, size.height * 0.15);
      case '1':
        return Rect.fromLTWH(size.width * 0.62, size.height * 0.15, size.width * 0.08, size.height * 0.15);
      case '2':
        return Rect.fromLTWH(size.width * 0.70, size.height * 0.15, size.width * 0.08, size.height * 0.15);
      case '3':
        return Rect.fromLTWH(size.width * 0.78, size.height * 0.15, size.width * 0.08, size.height * 0.15);
      case '4':
        return Rect.fromLTWH(size.width * 0.86, size.height * 0.15, size.width * 0.08, size.height * 0.15);

      // 좌측 구역들
      case '43':
        return Rect.fromLTWH(size.width * 0.06, size.height * 0.30, size.width * 0.13, size.height * 0.08);
      case '42':
        return Rect.fromLTWH(size.width * 0.06, size.height * 0.38, size.width * 0.13, size.height * 0.08);
      case '41':
        return Rect.fromLTWH(size.width * 0.06, size.height * 0.46, size.width * 0.13, size.height * 0.08);
      case '40':
        return Rect.fromLTWH(size.width * 0.06, size.height * 0.54, size.width * 0.13, size.height * 0.08);

      // 우측 구역들
      case '24':
        return Rect.fromLTWH(size.width * 0.81, size.height * 0.30, size.width * 0.13, size.height * 0.08);
      case '25':
        return Rect.fromLTWH(size.width * 0.81, size.height * 0.38, size.width * 0.13, size.height * 0.08);
      case '26':
        return Rect.fromLTWH(size.width * 0.81, size.height * 0.46, size.width * 0.13, size.height * 0.08);
      case '27':
        return Rect.fromLTWH(size.width * 0.81, size.height * 0.54, size.width * 0.13, size.height * 0.08);
      case '28':
        return Rect.fromLTWH(size.width * 0.81, size.height * 0.62, size.width * 0.13, size.height * 0.08);

      // 중간 하단 구역들
      case '11':
        return Rect.fromLTWH(size.width * 0.19, size.height * 0.66, size.width * 0.08, size.height * 0.10);
      case '10':
        return Rect.fromLTWH(size.width * 0.27, size.height * 0.66, size.width * 0.08, size.height * 0.10);
      case '9':
        return Rect.fromLTWH(size.width * 0.35, size.height * 0.66, size.width * 0.08, size.height * 0.10);
      case '8':
        return Rect.fromLTWH(size.width * 0.43, size.height * 0.66, size.width * 0.08, size.height * 0.10);
      case '7':
        return Rect.fromLTWH(size.width * 0.51, size.height * 0.66, size.width * 0.08, size.height * 0.10);
      case '6':
        return Rect.fromLTWH(size.width * 0.59, size.height * 0.66, size.width * 0.08, size.height * 0.10);
      case '5':
        return Rect.fromLTWH(size.width * 0.67, size.height * 0.66, size.width * 0.08, size.height * 0.10);

      // 최하단 구역들
      case '39':
        return Rect.fromLTWH(size.width * 0.06, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '38':
        return Rect.fromLTWH(size.width * 0.14, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '37':
        return Rect.fromLTWH(size.width * 0.22, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '36':
        return Rect.fromLTWH(size.width * 0.30, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '35':
        return Rect.fromLTWH(size.width * 0.38, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '34':
        return Rect.fromLTWH(size.width * 0.46, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '33':
        return Rect.fromLTWH(size.width * 0.54, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '32':
        return Rect.fromLTWH(size.width * 0.62, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '31':
        return Rect.fromLTWH(size.width * 0.70, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '30':
        return Rect.fromLTWH(size.width * 0.78, size.height * 0.76, size.width * 0.08, size.height * 0.16);
      case '29':
        return Rect.fromLTWH(size.width * 0.86, size.height * 0.76, size.width * 0.08, size.height * 0.16);

      default:
        return null; // 정의되지 않은 구역은 오버레이 없음
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}