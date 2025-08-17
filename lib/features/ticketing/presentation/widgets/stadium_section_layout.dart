import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/ticket_models.dart';

class StadiumSectionLayout extends StatelessWidget {
  final SessionSeatInfo? sessionSeatInfo;
  final String? selectedZone;
  final Function(String) onZoneSelected;

  const StadiumSectionLayout({
    super.key,
    required this.sessionSeatInfo,
    required this.selectedZone,
    required this.onZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStageIndicator(),
        SizedBox(height: 20),
        _buildStadiumLayout(context),
        SizedBox(height: 16),
        _buildSectionLegend(),
      ],
    );
  }

  Widget _buildStageIndicator() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.gray600,
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
          child: Text(
            'STAGE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '무대',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStadiumLayout(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: CustomPaint(
        painter: StadiumLayoutPainter(
          sessionSeatInfo: sessionSeatInfo,
          selectedZone: selectedZone,
          onZoneSelected: onZoneSelected,
        ),
        child: GestureDetector(
          onTapDown: (details) {
            _handleTap(context, details.localPosition);
          },
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, Offset position) {
    final size = Size(MediaQuery.of(context).size.width - 32, 400);
    
    // VIP 구역 체크 (무대 주변)
    final vipSections = _getVipSectionPositions(size);
    for (var entry in vipSections.entries) {
      final sectionPos = entry.value;
      final distance = (position - sectionPos).distance;
      if (distance <= 30) {
        final zoneInfo = _getZoneInfo(entry.key);
        if (zoneInfo != null && zoneInfo.isAvailable) {
          onZoneSelected(entry.key);
        }
        return;
      }
    }

    // 일반석 구역 체크 (원형 배치)
    final generalSections = _getGeneralSectionPositions(size);
    for (var entry in generalSections.entries) {
      final sectionPos = entry.value;
      final distance = (position - sectionPos).distance;
      if (distance <= 25) {
        final zoneInfo = _getZoneInfo(entry.key);
        if (zoneInfo != null && zoneInfo.isAvailable) {
          onZoneSelected(entry.key);
        }
        return;
      }
    }
  }

  Map<String, Offset> _getVipSectionPositions(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    return {
      'F1': Offset(center.dx - 60, center.dy - 20),
      'F2': Offset(center.dx + 60, center.dy - 20),
      'F3': Offset(center.dx - 60, center.dy + 40),
      'F4': Offset(center.dx + 60, center.dy + 40),
    };
  }

  Map<String, Offset> _getGeneralSectionPositions(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final Map<String, Offset> positions = {};
    
    // 상단 좌석 (1-5)
    for (int i = 1; i <= 5; i++) {
      final x = center.dx + (i - 3) * 45;
      positions['$i'] = Offset(x, center.dy - 120);
    }
    
    // 무대 가까운 하단 좌석 (6-11)
    for (int i = 6; i <= 11; i++) {
      final x = center.dx + (i - 8.5) * 35;
      positions['$i'] = Offset(x, center.dy + 80);
    }
    
    // 좌측 상단 좌석 (12-15)
    for (int i = 12; i <= 15; i++) {
      final angle = (i - 12) * 20 + 120;
      final radian = angle * math.pi / 180;
      final x = center.dx + 120 * math.cos(radian);
      final y = center.dy + 120 * math.sin(radian);
      positions['$i'] = Offset(x, y);
    }
    
    // 우측 상단 좌석 (24-30)
    for (int i = 24; i <= 30; i++) {
      final angle = (i - 24) * 20 - 60;
      final radian = angle * math.pi / 180;
      final x = center.dx + 120 * math.cos(radian);
      final y = center.dy + 120 * math.sin(radian);
      positions['$i'] = Offset(x, y);
    }
    
    // 우측 좌석 (25-27)
    for (int i = 25; i <= 27; i++) {
      final y = center.dy + (i - 26) * 35;
      positions['$i'] = Offset(center.dx + 140, y);
    }
    
    // 하단 좌석 (31-39)
    for (int i = 31; i <= 39; i++) {
      final angle = (i - 35) * 20;
      final radian = (angle + 90) * math.pi / 180;
      final x = center.dx + 120 * math.cos(radian);
      final y = center.dy + 120 * math.sin(radian);
      positions['$i'] = Offset(x, y);
    }
    
    // 좌측 좌석 (40-43)
    for (int i = 40; i <= 43; i++) {
      final y = center.dy + (i - 41.5) * 35;
      positions['$i'] = Offset(center.dx - 140, y);
    }
    
    return positions;
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
  final Function(String) onZoneSelected;

  StadiumLayoutPainter({
    required this.sessionSeatInfo,
    required this.selectedZone,
    required this.onZoneSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 무대 영역 그리기
    _drawStageArea(canvas, size);
    
    // VIP 구역 그리기
    _drawVipSections(canvas, size);
    
    // 일반석 구역 그리기
    _drawGeneralSections(canvas, size);
  }

  void _drawStageArea(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stageRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - 60),
      width: 180,
      height: 60,
    );
    
    final stagePaint = Paint()
      ..color = AppColors.gray600
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(stageRect, Radius.circular(8)),
      stagePaint,
    );
  }

  void _drawVipSections(Canvas canvas, Size size) {
    final vipPositions = _getVipSectionPositions(size);
    final vipColor = Color(0xFFD32F2F);
    
    for (var entry in vipPositions.entries) {
      final zone = entry.key;
      final position = entry.value;
      final isSelected = selectedZone == zone;
      final zoneInfo = _getZoneInfo(zone);
      final isAvailable = zoneInfo?.isAvailable ?? false;
      
      _drawSectionCircle(
        canvas,
        position,
        zone,
        vipColor,
        isSelected,
        isAvailable,
        30,
      );
    }
  }

  void _drawGeneralSections(Canvas canvas, Size size) {
    final generalPositions = _getGeneralSectionPositions(size);
    final generalColor = Color(0xFFFFC107);
    
    for (var entry in generalPositions.entries) {
      final zone = entry.key;
      final position = entry.value;
      final isSelected = selectedZone == zone;
      final zoneInfo = _getZoneInfo(zone);
      final isAvailable = zoneInfo?.isAvailable ?? false;
      
      _drawSectionCircle(
        canvas,
        position,
        zone,
        generalColor,
        isSelected,
        isAvailable,
        25,
      );
    }
  }

  void _drawSectionCircle(
    Canvas canvas,
    Offset position,
    String zone,
    Color baseColor,
    bool isSelected,
    bool isAvailable,
    double radius,
  ) {
    final circlePaint = Paint()
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;

    if (!isAvailable) {
      circlePaint.color = AppColors.gray300;
      borderPaint.color = AppColors.gray400;
    } else if (isSelected) {
      circlePaint.color = baseColor.withValues(alpha: 0.8);
      borderPaint.color = AppColors.primary;
    } else {
      circlePaint.color = baseColor.withValues(alpha: 0.3);
      borderPaint.color = baseColor;
    }

    // 구역 원 그리기
    canvas.drawCircle(position, radius, circlePaint);
    canvas.drawCircle(position, radius, borderPaint);

    // 구역 번호 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: zone,
        style: TextStyle(
          color: isAvailable ? AppColors.textPrimary : AppColors.gray500,
          fontSize: zone.startsWith('F') ? 14 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  Map<String, Offset> _getVipSectionPositions(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    return {
      'F1': Offset(center.dx - 60, center.dy - 20),
      'F2': Offset(center.dx + 60, center.dy - 20),
      'F3': Offset(center.dx - 60, center.dy + 40),
      'F4': Offset(center.dx + 60, center.dy + 40),
    };
  }

  Map<String, Offset> _getGeneralSectionPositions(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final Map<String, Offset> positions = {};
    
    // 상단 좌석 (1-5)
    for (int i = 1; i <= 5; i++) {
      final x = center.dx + (i - 3) * 45;
      positions['$i'] = Offset(x, center.dy - 120);
    }
    
    // 무대 가까운 하단 좌석 (6-11)
    for (int i = 6; i <= 11; i++) {
      final x = center.dx + (i - 8.5) * 35;
      positions['$i'] = Offset(x, center.dy + 80);
    }
    
    // 좌측 상단 좌석 (12-15)
    for (int i = 12; i <= 15; i++) {
      final angle = (i - 12) * 20 + 120;
      final radian = angle * math.pi / 180;
      final x = center.dx + 120 * math.cos(radian);
      final y = center.dy + 120 * math.sin(radian);
      positions['$i'] = Offset(x, y);
    }
    
    // 우측 상단 좌석 (24-30)
    for (int i = 24; i <= 30; i++) {
      final angle = (i - 24) * 20 - 60;
      final radian = angle * math.pi / 180;
      final x = center.dx + 120 * math.cos(radian);
      final y = center.dy + 120 * math.sin(radian);
      positions['$i'] = Offset(x, y);
    }
    
    // 우측 좌석 (25-27)
    for (int i = 25; i <= 27; i++) {
      final y = center.dy + (i - 26) * 35;
      positions['$i'] = Offset(center.dx + 140, y);
    }
    
    // 하단 좌석 (31-39)
    for (int i = 31; i <= 39; i++) {
      final angle = (i - 35) * 20;
      final radian = (angle + 90) * math.pi / 180;
      final x = center.dx + 120 * math.cos(radian);
      final y = center.dy + 120 * math.sin(radian);
      positions['$i'] = Offset(x, y);
    }
    
    // 좌측 좌석 (40-43)
    for (int i = 40; i <= 43; i++) {
      final y = center.dy + (i - 41.5) * 35;
      positions['$i'] = Offset(center.dx - 140, y);
    }
    
    return positions;
  }

  SeatPricingInfo? _getZoneInfo(String zone) {
    if (sessionSeatInfo == null) return null;
    return sessionSeatInfo!.seatPricingInfo
        .where((zoneInfo) => zoneInfo.seatZone == zone)
        .firstOrNull;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}