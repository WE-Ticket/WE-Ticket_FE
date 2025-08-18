import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/ticket_models.dart';

class StadiumImageLayout extends StatelessWidget {
  final SessionSeatInfo? sessionSeatInfo;
  final String? selectedZone;
  final Function(String) onZoneSelected;

  const StadiumImageLayout({
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
        _buildStadiumImage(context),
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

  Widget _buildStadiumImage(BuildContext context) {
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
        child: GestureDetector(
          onTapDown: (details) => _handleImageTap(details, context),
          child: SizedBox(
            width: double.infinity,
            height: 400,
            child: CustomPaint(
              painter: StadiumLayoutPainter(
                sessionSeatInfo: sessionSeatInfo,
                selectedZone: selectedZone,
              ),
            ),
          ),
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
    final relativeX = (localPosition.dx - 16) / imageWidth; // 16은 좌측 패딩
    final relativeY = localPosition.dy / imageHeight;

    final zone = _getZoneFromPosition(relativeX, relativeY);
    if (zone != null) {
      final zoneInfo = _getZoneInfo(zone);
      if (zoneInfo != null && zoneInfo.isAvailable) {
        onZoneSelected(zone);
      }
    }
  }

  String? _getZoneFromPosition(double x, double y) {
    // 무대 영역 (상단 중앙)
    if (y >= 0.05 && y <= 0.25 && x >= 0.3 && x <= 0.7) {
      return null; // 무대는 선택 불가
    }

    // VIP 구역 (F1, F2, F3, F4) - 무대 주변
    if (y >= 0.25 && y <= 0.55) {
      if (x >= 0.25 && x <= 0.4) {
        return y <= 0.4 ? 'F1' : 'F3'; // 좌측 VIP
      }
      if (x >= 0.6 && x <= 0.75) {
        return y <= 0.4 ? 'F2' : 'F4'; // 우측 VIP
      }
    }

    // 상단 일반석 (1-5)
    if (y >= 0.1 && y <= 0.25) {
      if (x >= 0.1 && x <= 0.25) return '15';
      if (x >= 0.25 && x <= 0.35) return '14';
      if (x >= 0.35 && x <= 0.45) return '13';
      if (x >= 0.45 && x <= 0.55) return '12';
      if (x >= 0.55 && x <= 0.65) return '1';
      if (x >= 0.65 && x <= 0.75) return '2';
      if (x >= 0.75 && x <= 0.85) return '3';
      if (x >= 0.85 && x <= 0.95) return '4';
    }

    // 좌측 일반석 (40-43, 12-15)
    if (x >= 0.05 && x <= 0.25) {
      if (y >= 0.25 && y <= 0.35) return '43';
      if (y >= 0.35 && y <= 0.45) return '42';
      if (y >= 0.45 && y <= 0.55) return '41';
      if (y >= 0.55 && y <= 0.65) return '40';
      if (y >= 0.65 && y <= 0.75) return '39';
      if (y >= 0.75 && y <= 0.85) return '38';
    }

    // 우측 일반석 (24-30)
    if (x >= 0.75 && x <= 0.95) {
      if (y >= 0.25 && y <= 0.35) return '24';
      if (y >= 0.35 && y <= 0.45) return '25';
      if (y >= 0.45 && y <= 0.55) return '26';
      if (y >= 0.55 && y <= 0.65) return '27';
      if (y >= 0.65 && y <= 0.75) return '28';
      if (y >= 0.75 && y <= 0.85) return '29';
      if (y >= 0.85 && y <= 0.95) return '30';
    }

    // 하단 일반석 (6-11, 31-39)
    if (y >= 0.55 && y <= 0.75) {
      if (x >= 0.15 && x <= 0.25) return '11';
      if (x >= 0.25 && x <= 0.35) return '10';
      if (x >= 0.35 && x <= 0.45) return '9';
      if (x >= 0.45 && x <= 0.55) return '8';
      if (x >= 0.55 && x <= 0.65) return '7';
      if (x >= 0.65 && x <= 0.75) return '6';
      if (x >= 0.75 && x <= 0.85) return '5';
    }

    // 최하단 일반석 (31-37)
    if (y >= 0.75 && y <= 0.95) {
      if (x >= 0.15 && x <= 0.25) return '37';
      if (x >= 0.25 && x <= 0.35) return '36';
      if (x >= 0.35 && x <= 0.45) return '35';
      if (x >= 0.45 && x <= 0.55) return '34';
      if (x >= 0.55 && x <= 0.65) return '33';
      if (x >= 0.65 && x <= 0.75) return '32';
      if (x >= 0.75 && x <= 0.85) return '31';
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
    if (zoneInfo == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_seat, color: AppColors.primary, size: 20),
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
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${zoneInfo.seatGrade} - ${zoneInfo.priceDisplay}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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

class StadiumLayoutPainter extends CustomPainter {
  final SessionSeatInfo? sessionSeatInfo;
  final String? selectedZone;

  StadiumLayoutPainter({
    required this.sessionSeatInfo,
    required this.selectedZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 배경
    paint.color = Color(0xFFF5F5F5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 무대 그리기
    _drawStage(canvas, size);

    // VIP 구역 그리기
    _drawVipSections(canvas, size);

    // 일반석 구역 그리기
    _drawGeneralSections(canvas, size);

    // 구역 번호 표시
    _drawSectionLabels(canvas, size);
  }

  void _drawStage(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(0xFF424242);
    final stageRect = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.05,
      size.width * 0.4,
      size.height * 0.2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(stageRect, Radius.circular(8)),
      paint,
    );

    // STAGE 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'STAGE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        stageRect.center.dx - textPainter.width / 2,
        stageRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawVipSections(Canvas canvas, Size size) {
    final vipColor = Color(0xFFD32F2F);
    final paint = Paint()..color = vipColor.withValues(alpha: 0.7);
    final borderPaint = Paint()
      ..color = vipColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // F1 (좌상)
    final f1Rect = Rect.fromLTWH(
      size.width * 0.25,
      size.height * 0.25,
      size.width * 0.15,
      size.height * 0.15,
    );
    if (selectedZone == 'F1') {
      paint.color = vipColor;
      borderPaint.strokeWidth = 3;
    } else {
      paint.color = vipColor.withValues(alpha: 0.3);
      borderPaint.strokeWidth = 2;
    }
    canvas.drawRRect(RRect.fromRectAndRadius(f1Rect, Radius.circular(8)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(f1Rect, Radius.circular(8)), borderPaint);

    // F2 (우상)
    final f2Rect = Rect.fromLTWH(
      size.width * 0.6,
      size.height * 0.25,
      size.width * 0.15,
      size.height * 0.15,
    );
    if (selectedZone == 'F2') {
      paint.color = vipColor;
      borderPaint.strokeWidth = 3;
    } else {
      paint.color = vipColor.withValues(alpha: 0.3);
      borderPaint.strokeWidth = 2;
    }
    canvas.drawRRect(RRect.fromRectAndRadius(f2Rect, Radius.circular(8)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(f2Rect, Radius.circular(8)), borderPaint);

    // F3 (좌하)
    final f3Rect = Rect.fromLTWH(
      size.width * 0.25,
      size.height * 0.4,
      size.width * 0.15,
      size.height * 0.15,
    );
    if (selectedZone == 'F3') {
      paint.color = vipColor;
      borderPaint.strokeWidth = 3;
    } else {
      paint.color = vipColor.withValues(alpha: 0.3);
      borderPaint.strokeWidth = 2;
    }
    canvas.drawRRect(RRect.fromRectAndRadius(f3Rect, Radius.circular(8)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(f3Rect, Radius.circular(8)), borderPaint);

    // F4 (우하)
    final f4Rect = Rect.fromLTWH(
      size.width * 0.6,
      size.height * 0.4,
      size.width * 0.15,
      size.height * 0.15,
    );
    if (selectedZone == 'F4') {
      paint.color = vipColor;
      borderPaint.strokeWidth = 3;
    } else {
      paint.color = vipColor.withValues(alpha: 0.3);
      borderPaint.strokeWidth = 2;
    }
    canvas.drawRRect(RRect.fromRectAndRadius(f4Rect, Radius.circular(8)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(f4Rect, Radius.circular(8)), borderPaint);
  }

  void _drawGeneralSections(Canvas canvas, Size size) {
    final generalColor = Color(0xFFFFC107);
    final paint = Paint();
    final borderPaint = Paint()
      ..color = generalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 상단 일반석들
    final topSections = ['15', '14', '13', '12', '1', '2', '3', '4'];
    for (int i = 0; i < topSections.length; i++) {
      final section = topSections[i];
      final rect = Rect.fromLTWH(
        size.width * (0.1 + i * 0.1),
        size.height * 0.1,
        size.width * 0.08,
        size.height * 0.12,
      );

      if (selectedZone == section) {
        paint.color = generalColor;
      } else {
        paint.color = generalColor.withValues(alpha: 0.3);
      }

      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), borderPaint);
    }

    // 좌측 일반석들
    final leftSections = ['43', '42', '41', '40', '39', '38'];
    for (int i = 0; i < leftSections.length; i++) {
      final section = leftSections[i];
      final rect = Rect.fromLTWH(
        size.width * 0.05,
        size.height * (0.25 + i * 0.1),
        size.width * 0.15,
        size.height * 0.08,
      );

      if (selectedZone == section) {
        paint.color = generalColor;
      } else {
        paint.color = generalColor.withValues(alpha: 0.3);
      }

      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), borderPaint);
    }

    // 우측 일반석들
    final rightSections = ['24', '25', '26', '27', '28', '29', '30'];
    for (int i = 0; i < rightSections.length; i++) {
      final section = rightSections[i];
      final rect = Rect.fromLTWH(
        size.width * 0.8,
        size.height * (0.25 + i * 0.1),
        size.width * 0.15,
        size.height * 0.08,
      );

      if (selectedZone == section) {
        paint.color = generalColor;
      } else {
        paint.color = generalColor.withValues(alpha: 0.3);
      }

      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), borderPaint);
    }

    // 하단 일반석들 (6-11, 31-37)
    final bottomSections1 = ['11', '10', '9', '8', '7', '6', '5'];
    for (int i = 0; i < bottomSections1.length; i++) {
      final section = bottomSections1[i];
      final rect = Rect.fromLTWH(
        size.width * (0.15 + i * 0.1),
        size.height * 0.55,
        size.width * 0.08,
        size.height * 0.12,
      );

      if (selectedZone == section) {
        paint.color = generalColor;
      } else {
        paint.color = generalColor.withValues(alpha: 0.3);
      }

      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), borderPaint);
    }

    // 최하단 일반석들
    final bottomSections2 = ['37', '36', '35', '34', '33', '32', '31'];
    for (int i = 0; i < bottomSections2.length; i++) {
      final section = bottomSections2[i];
      final rect = Rect.fromLTWH(
        size.width * (0.15 + i * 0.1),
        size.height * 0.75,
        size.width * 0.08,
        size.height * 0.12,
      );

      if (selectedZone == section) {
        paint.color = generalColor;
      } else {
        paint.color = generalColor.withValues(alpha: 0.3);
      }

      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), borderPaint);
    }
  }

  void _drawSectionLabels(Canvas canvas, Size size) {
    // VIP 라벨들
    _drawLabel(canvas, 'F1', Offset(size.width * 0.325, size.height * 0.325));
    _drawLabel(canvas, 'F2', Offset(size.width * 0.675, size.height * 0.325));
    _drawLabel(canvas, 'F3', Offset(size.width * 0.325, size.height * 0.475));
    _drawLabel(canvas, 'F4', Offset(size.width * 0.675, size.height * 0.475));

    // 상단 일반석 라벨들
    final topSections = ['15', '14', '13', '12', '1', '2', '3', '4'];
    for (int i = 0; i < topSections.length; i++) {
      _drawLabel(canvas, topSections[i], Offset(size.width * (0.14 + i * 0.1), size.height * 0.16));
    }

    // 좌측 일반석 라벨들
    final leftSections = ['43', '42', '41', '40', '39', '38'];
    for (int i = 0; i < leftSections.length; i++) {
      _drawLabel(canvas, leftSections[i], Offset(size.width * 0.125, size.height * (0.29 + i * 0.1)));
    }

    // 우측 일반석 라벨들
    final rightSections = ['24', '25', '26', '27', '28', '29', '30'];
    for (int i = 0; i < rightSections.length; i++) {
      _drawLabel(canvas, rightSections[i], Offset(size.width * 0.875, size.height * (0.29 + i * 0.1)));
    }

    // 하단 일반석 라벨들
    final bottomSections1 = ['11', '10', '9', '8', '7', '6', '5'];
    for (int i = 0; i < bottomSections1.length; i++) {
      _drawLabel(canvas, bottomSections1[i], Offset(size.width * (0.19 + i * 0.1), size.height * 0.61));
    }

    // 최하단 일반석 라벨들
    final bottomSections2 = ['37', '36', '35', '34', '33', '32', '31'];
    for (int i = 0; i < bottomSections2.length; i++) {
      _drawLabel(canvas, bottomSections2[i], Offset(size.width * (0.19 + i * 0.1), size.height * 0.81));
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: text.startsWith('F') ? 14 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}