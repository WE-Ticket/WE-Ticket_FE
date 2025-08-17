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
  // 실제 이미지 크기 기준 (857x692)
  static const double imageWidth = 857.0;
  static const double imageHeight = 692.0;
  
  static final List<ZonePolygon> zones = [
    // VIP 구역들 (image-map.net에서 추출한 정확한 다각형 좌표)
    ZonePolygon('F1', [
      Offset(275, 184),
      Offset(256, 231),
      Offset(256, 261),
      Offset(283, 282),
      Offset(319, 281),
      Offset(324, 229),
      Offset(390, 225),
      Offset(389, 205),
      Offset(367, 183),
    ]),
    
    ZonePolygon('F2', [
      Offset(471, 224),
      Offset(546, 227),
      Offset(541, 287),
      Offset(583, 283),
      Offset(608, 263),
      Offset(607, 241),
      Offset(586, 182),
      Offset(500, 181),
      Offset(473, 197),
      Offset(473, 199),
    ]),
    
    ZonePolygon('F3', [
      Offset(267, 299),
      Offset(262, 314),
      Offset(287, 358),
      Offset(318, 389),
      Offset(322, 370),
      Offset(350, 368),
      Offset(386, 387),
      Offset(420, 386),
      Offset(420, 336),
      Offset(324, 332),
      Offset(322, 298),
    ]),
    
    ZonePolygon('F4', [
      Offset(443, 331),
      Offset(442, 385),
      Offset(479, 390),
      Offset(516, 369),
      Offset(541, 366),
      Offset(542, 393),
      Offset(581, 356),
      Offset(597, 318),
      Offset(593, 294),
      Offset(540, 298),
      Offset(540, 327),
    ]),
    
    // 일반석 구역들 (image-map.net에서 추출한 정확한 다각형 좌표)
    ZonePolygon('15', [
      Offset(166, 148),
      Offset(148, 200),
      Offset(234, 218),
      Offset(241, 186),
    ]),
    
    ZonePolygon('14', [
      Offset(148, 213),
      Offset(146, 271),
      Offset(228, 263),
      Offset(233, 223),
    ]),
    
    ZonePolygon('13', [
      Offset(148, 280),
      Offset(161, 335),
      Offset(237, 310),
      Offset(227, 273),
    ]),
    
    ZonePolygon('12', [
      Offset(161, 344),
      Offset(186, 398),
      Offset(252, 357),
      Offset(238, 322),
    ]),
    
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
    
    // 좌측 일반석 구역들
    ZonePolygon('43', [
      Offset(54, 109),
      Offset(34, 172),
      Offset(131, 192),
      Offset(139, 150),
    ]),
    
    ZonePolygon('42', [
      Offset(30, 184),
      Offset(24, 251),
      Offset(118, 252),
      Offset(125, 206),
    ]),
    
    ZonePolygon('41', [
      Offset(24, 265),
      Offset(33, 336),
      Offset(130, 311),
      Offset(122, 263),
    ]),
    
    ZonePolygon('40', [
      Offset(34, 347),
      Offset(55, 412),
      Offset(147, 374),
      Offset(130, 327),
    ]),
    
    // 우측 일반석 구역들
    ZonePolygon('24', [
      Offset(722, 142),
      Offset(739, 193),
      Offset(828, 168),
      Offset(810, 104),
    ]),
    
    ZonePolygon('25', [
      Offset(741, 204),
      Offset(743, 246),
      Offset(838, 248),
      Offset(834, 185),
    ]),
    
    ZonePolygon('26', [
      Offset(828, 324),
      Offset(838, 263),
      Offset(747, 260),
      Offset(740, 312),
    ]),
    
    ZonePolygon('27', [
      Offset(810, 405),
      Offset(831, 339),
      Offset(740, 323),
      Offset(722, 371),
    ]),
    
    ZonePolygon('28', [
      Offset(773, 476),
      Offset(803, 415),
      Offset(714, 380),
      Offset(695, 422),
    ]),
    
    // 중간 하단 구역들 (5-11)
    ZonePolygon('11', [
      Offset(283, 395),
      Offset(222, 445),
      Offset(268, 486),
      Offset(315, 421),
    ]),
    
    ZonePolygon('10', [
      Offset(271, 492),
      Offset(324, 522),
      Offset(355, 443),
      Offset(321, 425),
    ]),
    
    ZonePolygon('9', [
      Offset(336, 525),
      Offset(396, 539),
      Offset(404, 458),
      Offset(368, 447),
    ]),
    
    ZonePolygon('8', [
      Offset(406, 538),
      Offset(465, 536),
      Offset(455, 459),
      Offset(414, 459),
    ]),
    
    ZonePolygon('7', [
      Offset(475, 536),
      Offset(536, 521),
      Offset(505, 444),
      Offset(465, 458),
    ]),
    
    ZonePolygon('6', [
      Offset(545, 519),
      Offset(596, 490),
      Offset(549, 424),
      Offset(513, 441),
    ]),
    
    ZonePolygon('5', [
      Offset(604, 485),
      Offset(647, 446),
      Offset(586, 392),
      Offset(556, 418),
    ]),
    
    // 최하단 원형 구역들 (29-39)
    ZonePolygon('39', [
      Offset(65, 421),
      Offset(94, 483),
      Offset(172, 425),
      Offset(151, 385),
    ]),
    
    ZonePolygon('38', [
      Offset(99, 488),
      Offset(144, 540),
      Offset(212, 475),
      Offset(178, 434),
    ]),
    
    ZonePolygon('37', [
      Offset(153, 551),
      Offset(203, 591),
      Offset(256, 516),
      Offset(219, 485),
    ]),
    
    ZonePolygon('36', [
      Offset(216, 604),
      Offset(272, 630),
      Offset(311, 542),
      Offset(268, 520),
    ]),
    
    ZonePolygon('35', [
      Offset(289, 636),
      Offset(345, 655),
      Offset(368, 561),
      Offset(322, 545),
    ]),
    
    ZonePolygon('34', [
      Offset(364, 657),
      Offset(429, 664),
      Offset(426, 573),
      Offset(377, 563),
    ]),
    
    ZonePolygon('33', [
      Offset(440, 659),
      Offset(506, 656),
      Offset(488, 564),
      Offset(441, 571),
    ]),
    
    ZonePolygon('32', [
      Offset(517, 655),
      Offset(583, 631),
      Offset(546, 546),
      Offset(494, 558),
    ]),
    
    ZonePolygon('31', [
      Offset(593, 627),
      Offset(656, 594),
      Offset(602, 521),
      Offset(553, 541),
    ]),
    
    ZonePolygon('30', [
      Offset(666, 589),
      Offset(715, 550),
      Offset(647, 481),
      Offset(611, 513),
    ]),
    
    ZonePolygon('29', [
      Offset(723, 535),
      Offset(766, 490),
      Offset(689, 436),
      Offset(653, 476),
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
        
        textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2));
      }
    }
  }
}