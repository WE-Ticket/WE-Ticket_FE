import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/ticket_models.dart';
import 'stadium_zone_polygons.dart';

class StadiumPurePolygonLayout extends StatelessWidget {
  final SessionSeatInfo? sessionSeatInfo;
  final String? selectedZone;
  final Function(String) onZoneSelected;
  final bool debugMode;

  const StadiumPurePolygonLayout({
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
        // _buildSectionTitle(),
        SizedBox(height: 16),
        _buildPurePolygonStadium(context),
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

  Widget _buildPurePolygonStadium(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(
      //   color: AppColors.surface,
      //   borderRadius: BorderRadius.circular(16),
      //   boxShadow: [
      //     BoxShadow(
      //       color: AppColors.shadowLight,
      //       spreadRadius: 2,
      //       blurRadius: 8,
      //       offset: Offset(0, 4),
      //     ),
      //   ],
      // ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 화면 너비에서 좌우 여백을 최소화 (10px씩만 남김)
            final availableWidth = constraints.maxWidth - 20;

            // 857:692 비율 유지하면서 높이 계산
            final aspectRatio =
                StadiumZonePolygons.imageWidth /
                StadiumZonePolygons.imageHeight;
            final stadiumHeight = availableWidth / aspectRatio;

            return Container(
              width: constraints.maxWidth,
              height: stadiumHeight,
              child: Center(
                child: SizedBox(
                  width: availableWidth,
                  height: stadiumHeight,
                  child: GestureDetector(
                    onTapDown: (details) => _handlePolygonTapWithSize(
                      details,
                      availableWidth,
                      stadiumHeight,
                    ),
                    child: CustomPaint(
                      painter: PurePolygonStadiumPainter(
                        selectedZone: selectedZone,
                        sessionSeatInfo: sessionSeatInfo,
                        debugMode: debugMode,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handlePolygonTapWithSize(
    TapDownDetails details,
    double canvasWidth,
    double canvasHeight,
  ) {
    final localPosition = details.localPosition;

    // 좌표 변환: Canvas 좌표를 이미지 좌표로 변환
    final scaleX = canvasWidth / StadiumZonePolygons.imageWidth;
    final scaleY = canvasHeight / StadiumZonePolygons.imageHeight;

    final imageX = localPosition.dx / scaleX;
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

    if (zone != null && zone != 'Stage') {
      // Stage는 선택 불가
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
      width: double.infinity,
      // decoration: BoxDecoration(
      //   color: AppColors.surface,
      //   borderRadius: BorderRadius.circular(12),
      //   boxShadow: [
      //     BoxShadow(
      //       color: AppColors.shadowLight,
      //       spreadRadius: 1,
      //       blurRadius: 4,
      //       offset: Offset(0, 2),
      //     ),
      //   ],
      // ),
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
              _buildLegendItem('무대 (STAGE)', Color(0xFF4A4A4A)),
              _buildLegendItem(
                'VIP석 (STANDING)',
                Color.fromRGBO(181, 101, 101, 1.0),
              ),
              _buildLegendItem(
                '일반석 (SEATED)',
                Color.fromRGBO(240, 234, 138, 1.0),
              ),
              _buildLegendItem('선택된 구역', AppColors.primary),
              if (debugMode) _buildLegendItem('구역 경계', Colors.red),
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
            '• 빨간 선: 구역 경계\\n• 구역 번호: 중앙 표시\\n• VIP석: 빨간색, 일반석: 주황색',
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

class PurePolygonStadiumPainter extends CustomPainter {
  final String? selectedZone;
  final SessionSeatInfo? sessionSeatInfo;
  final bool debugMode;

  PurePolygonStadiumPainter({
    required this.selectedZone,
    required this.sessionSeatInfo,
    required this.debugMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 스케일 계산
    final scaleX = size.width / StadiumZonePolygons.imageWidth;
    final scaleY = size.height / StadiumZonePolygons.imageHeight;

    // 배경 그리기 (흰색)
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // 모든 구역 그리기
    for (final zone in StadiumZonePolygons.zones) {
      _drawZone(canvas, zone, scaleX, scaleY);
    }

    // 디버그 모드: 경계선 표시
    if (debugMode) {
      canvas.save();
      canvas.scale(scaleX, scaleY);
      StadiumZonePolygons.drawDebugBoundaries(canvas, size);
      canvas.restore();
    }

    // 선택된 구역 하이라이트
    if (selectedZone != null) {
      _drawSelectedZoneHighlight(canvas, selectedZone!, scaleX, scaleY);
    }
  }

  void _drawZone(
    Canvas canvas,
    ZonePolygon zone,
    double scaleX,
    double scaleY,
  ) {
    if (zone.points.isEmpty) return;

    final path = Path();
    final scaledPoints = zone.points
        .map((point) => Offset(point.dx * scaleX, point.dy * scaleY))
        .toList();

    // 다각형 경로 만들기
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }
    path.close();

    // 구역 타입에 따른 색상 결정
    final isVipZone = zone.zoneId.startsWith('F');
    final isSelectedZone = zone.zoneId == selectedZone;
    final isStage = zone.zoneId == 'Stage';

    Color fillColor;
    if (isSelectedZone && !isStage) {
      fillColor = AppColors.primary.withValues(alpha: 0.8);
    } else if (isStage) {
      fillColor = Color(0xFF4A4A4A).withValues(alpha: 0.9); // 무대: 다크 회색
    } else if (isVipZone) {
      fillColor = Color.fromRGBO(181, 101, 101, 0.9); // VIP: RGB(181,101,101)
    } else {
      fillColor = Color.fromRGBO(240, 234, 138, 0.9); // 일반석: RGB(240,234,138)
    }

    // 구역 채우기
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 구역 테두리
    final borderPaint = Paint()
      ..color = isSelectedZone && !isStage
          ? AppColors.primary
          : (isStage
                ? Color(0xFF4A4A4A)
                : (isVipZone
                      ? Color.fromRGBO(181, 101, 101, 1.0)
                      : Color.fromRGBO(240, 234, 138, 1.0)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelectedZone ? 1.5 : 1.0; // 더 얇은 테두리
    canvas.drawPath(path, borderPaint);

    // 구역 번호 텍스트 그리기 (무대가 아닌 경우만)
    if (!isStage) {
      _drawZoneLabel(canvas, zone.zoneId, scaledPoints, isSelectedZone);
    } else {
      _drawStageLabel(canvas, scaledPoints);
    }
  }

  void _drawZoneLabel(
    Canvas canvas,
    String zoneId,
    List<Offset> scaledPoints,
    bool isSelected,
  ) {
    // 다각형 중심점 계산
    double centerX = 0, centerY = 0;
    for (final point in scaledPoints) {
      centerX += point.dx;
      centerY += point.dy;
    }
    centerX /= scaledPoints.length;
    centerY /= scaledPoints.length;

    // VIP 구역별 텍스트 위치 조정
    if (zoneId == 'F1' || zoneId == 'F2') {
      centerY -= 8; // F1, F2는 위로 올림
    } else if (zoneId == 'F3' || zoneId == 'F4') {
      centerY += 8; // F3, F4는 아래로 내림
    }

    final textStyle = TextStyle(
      color: isSelected ? Colors.white : Colors.grey[700], // 다크 그레이 텍스트
      fontSize: zoneId.startsWith('F') ? 14 : 12,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: zoneId, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );
  }

  void _drawStageLabel(Canvas canvas, List<Offset> scaledPoints) {
    // 무대의 상단 부분 찾기 (Y 좌표가 가장 작은 지점들의 평균)
    final topPoints = scaledPoints
        .where(
          (point) =>
              point.dy <=
              scaledPoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b) +
                  30,
        )
        .toList();

    double centerX = 0, centerY = 0;
    if (topPoints.isNotEmpty) {
      for (final point in topPoints) {
        centerX += point.dx;
        centerY += point.dy;
      }
      centerX /= topPoints.length;
      centerY /= topPoints.length;
      centerY += 15; // 조금 아래로 이동
    } else {
      // fallback: 전체 중심점
      for (final point in scaledPoints) {
        centerX += point.dx;
        centerY += point.dy;
      }
      centerX /= scaledPoints.length;
      centerY /= scaledPoints.length;
    }

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: 'STAGE', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );
  }

  void _drawSelectedZoneHighlight(
    Canvas canvas,
    String zoneId,
    double scaleX,
    double scaleY,
  ) {
    final zonePolygon = StadiumZonePolygons.getZonePolygon(zoneId);
    if (zonePolygon == null) return;

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

      // 선택 하이라이트 애니메이션 효과
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2; // 더 얇은 하이라이트

      canvas.drawPath(path, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
