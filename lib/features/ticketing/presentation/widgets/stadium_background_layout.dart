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
    // 실제 이미지 기반으로 더욱 정확한 좌표 매핑
    
    // 상단 구역 (15, 14, 13, 12, 1, 2, 3, 4)
    if (y >= 0.12 && y <= 0.28) {
      if (x >= 0.05 && x <= 0.13) return '15';
      if (x >= 0.13 && x <= 0.21) return '14';
      if (x >= 0.21 && x <= 0.29) return '13';
      if (x >= 0.29 && x <= 0.37) return '12';
      // 무대 영역 건너뛰기 (x: 0.37 ~ 0.63)
      if (x >= 0.63 && x <= 0.71) return '1';
      if (x >= 0.71 && x <= 0.79) return '2';
      if (x >= 0.79 && x <= 0.87) return '3';
      if (x >= 0.87 && x <= 0.95) return '4';
    }

    // 좌측 구역 (43, 42, 41, 40)
    if (x >= 0.05 && x <= 0.18) {
      if (y >= 0.28 && y <= 0.38) return '43';
      if (y >= 0.38 && y <= 0.48) return '42';
      if (y >= 0.48 && y <= 0.58) return '41';
      if (y >= 0.58 && y <= 0.68) return '40';
    }

    // 우측 구역 (24, 25, 26, 27, 28)
    if (x >= 0.82 && x <= 0.95) {
      if (y >= 0.28 && y <= 0.38) return '24';
      if (y >= 0.38 && y <= 0.48) return '25';
      if (y >= 0.48 && y <= 0.58) return '26';
      if (y >= 0.58 && y <= 0.68) return '27';
      if (y >= 0.68 && y <= 0.78) return '28';
    }

    // VIP 구역 F1 (좌상)
    if (y >= 0.28 && y <= 0.48 && x >= 0.22 && x <= 0.38) {
      return 'F1';
    }

    // VIP 구역 F2 (우상)
    if (y >= 0.28 && y <= 0.48 && x >= 0.62 && x <= 0.78) {
      return 'F2';
    }

    // VIP 구역 F3 (좌하)
    if (y >= 0.48 && y <= 0.68 && x >= 0.22 && x <= 0.38) {
      return 'F3';
    }

    // VIP 구역 F4 (우하)
    if (y >= 0.48 && y <= 0.68 && x >= 0.62 && x <= 0.78) {
      return 'F4';
    }

    // 중간 하단 구역 (11, 10, 9, 8, 7, 6, 5)
    if (y >= 0.58 && y <= 0.73) {
      if (x >= 0.18 && x <= 0.26) return '11';
      if (x >= 0.26 && x <= 0.34) return '10';
      if (x >= 0.34 && x <= 0.42) return '9';
      if (x >= 0.42 && x <= 0.50) return '8';
      if (x >= 0.50 && x <= 0.58) return '7';
      if (x >= 0.58 && x <= 0.66) return '6';
      if (x >= 0.66 && x <= 0.74) return '5';
    }

    // 최하단 구역 (39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29)
    if (y >= 0.73 && y <= 0.95) {
      if (x >= 0.05 && x <= 0.13) return '39';
      if (x >= 0.13 && x <= 0.21) return '38';
      if (x >= 0.21 && x <= 0.29) return '37';
      if (x >= 0.29 && x <= 0.37) return '36';
      if (x >= 0.37 && x <= 0.45) return '35';
      if (x >= 0.45 && x <= 0.53) return '34';
      if (x >= 0.53 && x <= 0.61) return '33';
      if (x >= 0.61 && x <= 0.69) return '32';
      if (x >= 0.69 && x <= 0.77) return '31';
      if (x >= 0.77 && x <= 0.85) return '30';
      if (x >= 0.85 && x <= 0.95) return '29';
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
    // 선택된 구역의 영역을 반환
    switch (zone) {
      // VIP 구역들
      case 'F1':
        return Rect.fromLTWH(
          size.width * 0.25, size.height * 0.25,
          size.width * 0.15, size.height * 0.2,
        );
      case 'F2':
        return Rect.fromLTWH(
          size.width * 0.6, size.height * 0.25,
          size.width * 0.15, size.height * 0.2,
        );
      case 'F3':
        return Rect.fromLTWH(
          size.width * 0.25, size.height * 0.45,
          size.width * 0.15, size.height * 0.2,
        );
      case 'F4':
        return Rect.fromLTWH(
          size.width * 0.6, size.height * 0.45,
          size.width * 0.15, size.height * 0.2,
        );

      // 일반석 구역들 (대표적인 몇 개만)
      case '1':
        return Rect.fromLTWH(
          size.width * 0.55, size.height * 0.15,
          size.width * 0.1, size.height * 0.2,
        );
      case '4':
        return Rect.fromLTWH(
          size.width * 0.85, size.height * 0.15,
          size.width * 0.1, size.height * 0.2,
        );

      default:
        // 다른 구역들은 기본 하이라이트
        return Rect.fromLTWH(
          size.width * 0.4, size.height * 0.4,
          size.width * 0.2, size.height * 0.2,
        );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}