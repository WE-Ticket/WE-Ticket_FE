import 'package:flutter/material.dart';

class ZonePolygon {
  final String zoneId;
  final List<Offset> points;

  ZonePolygon(this.zoneId, this.points);

  bool contains(Offset point) {
    if (points.length < 3) return false;

    bool inside = false;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      final xi = points[i].dx;
      final yi = points[i].dy;
      final xj = points[j].dx;
      final yj = points[j].dy;

      if (((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }
}

class StadiumZonePolygons {
  // 원본 이미지 크기 (857x692)
  static const double imageWidth = 857.0;
  static const double imageHeight = 692.0;

  static final List<ZonePolygon> zones = [
    // 무대 구역 (원본 좌표)
    ZonePolygon('Stage', [
      Offset(277, 42),
      Offset(590, 43),
      Offset(591, 144),
      Offset(492, 145),
      Offset(465, 170),
      Offset(451, 170),
      Offset(451, 246),
      Offset(524, 248),
      Offset(525, 314),
      Offset(344, 311),
      Offset(344, 247),
      Offset(414, 246),
      Offset(415, 170),
      Offset(401, 171),
      Offset(371, 146),
      Offset(275, 145),
    ]),

    // VIP 구역들 (원본 좌표)
    ZonePolygon('F1', [
      Offset(275, 184),
      Offset(369, 184),
      Offset(392, 202),
      Offset(392, 227),
      Offset(324, 228),
      Offset(323, 284),
      Offset(284, 282),
      Offset(257, 269),
      Offset(255, 236),
    ]),

    ZonePolygon('F2', [
      Offset(474, 203),
      Offset(497, 184),
      Offset(591, 186),
      Offset(611, 235),
      Offset(611, 264),
      Offset(585, 284),
      Offset(542, 284),
      Offset(543, 228),
      Offset(474, 228),
    ]),

    ZonePolygon('F3', [
      Offset(266, 297),
      Offset(264, 313),
      Offset(284, 355),
      Offset(321, 388),
      Offset(422, 387),
      Offset(421, 334),
      Offset(324, 334),
      Offset(324, 296),
    ]),

    ZonePolygon('F4', [
      Offset(444, 334),
      Offset(445, 387),
      Offset(545, 388),
      Offset(580, 357),
      Offset(601, 314),
      Offset(599, 296),
      Offset(545, 297),
      Offset(543, 333),
    ]),

    // 일반석 구역들 (1-15 구역, 원본 좌표)
    ZonePolygon('1', [
      Offset(630, 216),
      Offset(714, 203),
      Offset(695, 146),
      Offset(618, 181),
    ]),

    ZonePolygon('2', [
      Offset(715, 269),
      Offset(712, 215),
      Offset(632, 226),
      Offset(634, 264),
    ]),

    ZonePolygon('3', [
      Offset(704, 332),
      Offset(716, 278),
      Offset(634, 274),
      Offset(630, 308),
    ]),

    ZonePolygon('4', [
      Offset(678, 393),
      Offset(705, 345),
      Offset(627, 319),
      Offset(611, 353),
    ]),

    ZonePolygon('5', [
      Offset(604, 485),
      Offset(647, 446),
      Offset(586, 392),
      Offset(556, 418),
    ]),

    ZonePolygon('6', [
      Offset(545, 519),
      Offset(596, 490),
      Offset(549, 424),
      Offset(513, 441),
    ]),

    ZonePolygon('7', [
      Offset(475, 536),
      Offset(536, 521),
      Offset(505, 444),
      Offset(465, 458),
    ]),

    ZonePolygon('8', [
      Offset(406, 538),
      Offset(465, 536),
      Offset(455, 459),
      Offset(414, 459),
    ]),

    ZonePolygon('9', [
      Offset(336, 525),
      Offset(396, 539),
      Offset(404, 458),
      Offset(368, 447),
    ]),

    ZonePolygon('10', [
      Offset(271, 492),
      Offset(324, 522),
      Offset(355, 443),
      Offset(321, 425),
    ]),

    ZonePolygon('11', [
      Offset(220, 448),
      Offset(267, 489),
      Offset(313, 419),
      Offset(283, 392),
    ]),

    ZonePolygon('12', [
      Offset(161, 344),
      Offset(186, 398),
      Offset(252, 357),
      Offset(238, 322),
    ]),

    ZonePolygon('13', [
      Offset(148, 280),
      Offset(161, 335),
      Offset(237, 310),
      Offset(227, 273),
    ]),

    ZonePolygon('14', [
      Offset(148, 213),
      Offset(146, 271),
      Offset(228, 263),
      Offset(233, 223),
    ]),

    ZonePolygon('15', [
      Offset(166, 148),
      Offset(148, 200),
      Offset(234, 218),
      Offset(241, 186),
    ]),
  ];

  /// 주어진 위치에서 해당하는 구역 찾기
  static String? findZoneAt(Offset position) {
    for (final zone in zones) {
      if (zone.contains(position)) {
        return zone.zoneId;
      }
    }
    return null;
  }

  /// 특정 구역의 다각형 가져오기
  static ZonePolygon? getZonePolygon(String zoneId) {
    try {
      return zones.firstWhere((zone) => zone.zoneId == zoneId);
    } catch (e) {
      return null;
    }
  }

  /// 디버그용: 모든 구역의 경계선 그리기
  static void drawDebugBoundaries(Canvas canvas, Size size, {Color? color}) {
    final paint = Paint()
      ..color = color ?? Colors.red.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final zone in zones) {
      final path = Path();
      if (zone.points.isNotEmpty) {
        path.moveTo(zone.points.first.dx, zone.points.first.dy);
        for (int i = 1; i < zone.points.length; i++) {
          path.lineTo(zone.points[i].dx, zone.points[i].dy);
        }
        path.close();
        canvas.drawPath(path, paint);

        // 구역 번호 표시
        final textPainter = TextPainter(
          text: TextSpan(
            text: zone.zoneId,
            style: TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // 다각형 중심점 계산
        double centerX = 0, centerY = 0;
        for (final point in zone.points) {
          centerX += point.dx;
          centerY += point.dy;
        }
        centerX /= zone.points.length;
        centerY /= zone.points.length;

        textPainter.paint(
          canvas,
          Offset(
            centerX - textPainter.width / 2,
            centerY - textPainter.height / 2,
          ),
        );
      }
    }
  }
}
