import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/ticket_models.dart';
import 'stadium_zone_polygons.dart';

class StadiumPolygonLayout extends StatelessWidget {
  final SessionSeatInfo? sessionSeatInfo;
  final String? selectedZone;
  final Function(String) onZoneSelected;
  final bool debugMode; // 디버그 모드 (구역 경계선 표시)

  const StadiumPolygonLayout({
    super.key,
    required this.sessionSeatInfo,
    required this.selectedZone,
    required this.onZoneSelected,
    this.debugMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSectionTitle(),
        SizedBox(height: 16),
        _buildStadiumImageWithPolygons(context),
        SizedBox(height: 16),
        _buildSectionLegend(),
        if (debugMode) _buildDebugInfo(),
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
          Row(
            children: [
              Text(
                '좌석배치도 ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (debugMode)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DEBUG',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '원하는 구역을 터치해주세요 (다각형 기반 정확한 인식)',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStadiumImageWithPolygons(BuildContext context) {
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
            // 배경 이미지 (857×692 비율에 맞춤)
            Image.asset(
              'lib/features/ticketing/presentation/widgets/좌석배치도.png',
              width: double.infinity,
              height: 240, // 857×692 비율에 맞춘 높이
              fit: BoxFit.contain,
            ),
            // 다각형 터치 오버레이
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) => _handlePolygonTap(details, context),
                child: SizedBox(
                  width: double.infinity,
                  height: 240, // 이미지와 동일한 높이
                  child: CustomPaint(
                    painter: PolygonOverlayPainter(
                      selectedZone: selectedZone,
                      sessionSeatInfo: sessionSeatInfo,
                      debugMode: debugMode,
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

  void _handlePolygonTap(TapDownDetails details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = details.localPosition;

    // CustomPaint 영역의 크기 (패딩 제외한 실제 크기)
    final paintWidth = renderBox.size.width - 32; // 좌우 패딩 16*2 제외
    final paintHeight = 240; // 857×692 비율에 맞춘 높이

    // CustomPaint와 동일한 스케일링 계산
    final scaleX = paintWidth / StadiumZonePolygons.imageWidth;
    final scaleY = paintHeight / StadiumZonePolygons.imageHeight;

    // 터치 좌표를 이미지 좌표로 변환 (패딩 16 제외)
    final imageX = (localPosition.dx - 16) / scaleX;
    final imageY = localPosition.dy / scaleY;

    // 이미지 영역 밖이면 무시
    if (imageX < 0 ||
        imageX > StadiumZonePolygons.imageWidth ||
        imageY < 0 ||
        imageY > StadiumZonePolygons.imageHeight) {
      return;
    }

    final tapPoint = Offset(imageX, imageY);
    final zone = StadiumZonePolygons.findZoneAt(tapPoint);

    if (zone != null) {
      final zoneInfo = _getZoneInfo(zone);
      // 서버에서 받아온 구역(1,2,3,4)만 실제 선택 가능, 나머지는 정보만 표시
      if (zoneInfo != null && zoneInfo.isAvailable) {
        onZoneSelected(zone);
      } else {
        // 다른 구역도 선택은 되지만 정보만 표시
        onZoneSelected(zone);
      }
    }
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
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 디버그 모드',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• 빨간 선: 구역 경계\n• 빨간 텍스트: 구역 번호\n• 터치하여 정확도 확인',
            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
          ),
        ],
      ),
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
                    style: TextStyle(fontSize: 11, color: AppColors.gray400),
                  ),
                ],
              ],
            ),
          ),
          if (!isActive) ...[
            Icon(Icons.info_outline, color: AppColors.gray400, size: 16),
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

class PolygonOverlayPainter extends CustomPainter {
  final String? selectedZone;
  final SessionSeatInfo? sessionSeatInfo;
  final bool debugMode;

  PolygonOverlayPainter({
    required this.selectedZone,
    required this.sessionSeatInfo,
    required this.debugMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 터치 핸들러와 동일한 스케일링 계산
    final scaleX = size.width / StadiumZonePolygons.imageWidth;
    final scaleY = size.height / StadiumZonePolygons.imageHeight;

    if (debugMode) {
      // 디버그 모드: 모든 구역의 경계선 표시
      canvas.save();
      canvas.scale(scaleX, scaleY);
      StadiumZonePolygons.drawDebugBoundaries(canvas, size);
      canvas.restore();
    }

    // 선택된 구역 하이라이트
    if (selectedZone != null) {
      final zonePolygon = StadiumZonePolygons.getZonePolygon(selectedZone!);
      if (zonePolygon != null) {
        final path = Path();
        final scaledPoints = zonePolygon.points
            .map((point) => Offset(point.dx * scaleX, point.dy * scaleY))
            .toList();

        if (scaledPoints.isNotEmpty) {
          path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
          for (int i = 1; i < scaledPoints.length; i++) {
            path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
          }
          path.close();

          final fillPaint = Paint()
            ..color = AppColors.primary.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;

          final borderPaint = Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, borderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
