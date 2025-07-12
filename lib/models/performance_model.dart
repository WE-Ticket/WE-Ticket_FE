class PerformanceModel {
  final int performanceId;
  final String title;
  final String startDate;
  final String endDate;
  final int runtime;
  final String ageRating;
  final String genre;
  final String venueName;
  final String venueLocation;
  final String mainImage;
  final String detailImage;
  final String agencyName;
  final String ticketOpenDatetime;
  final bool isHot;
  final List<String> tags;
  final int performer;

  PerformanceModel({
    required this.performanceId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.runtime,
    required this.ageRating,
    required this.genre,
    required this.venueName,
    required this.venueLocation,
    required this.mainImage,
    required this.detailImage,
    required this.agencyName,
    required this.ticketOpenDatetime,
    required this.isHot,
    required this.tags,
    required this.performer,
  });

  factory PerformanceModel.fromJson(Map<String, dynamic> json) {
    return PerformanceModel(
      performanceId: _parseToInt(json['performance_id']),
      title: _parseToString(json['title']),
      startDate: _parseToString(json['start_date']),
      endDate: _parseToString(json['end_date']),
      runtime: _parseToInt(json['runtime']),
      ageRating: _parseToString(json['age_rating']),
      genre: _parseToString(json['genre']),
      venueName: _parseToString(json['venue_name']),
      venueLocation: _parseToString(json['venue_location']),
      mainImage: _parseToString(json['main_image']),
      detailImage: _parseToString(json['detail_image']),
      agencyName: _parseToString(json['agency_name']),
      ticketOpenDatetime: _parseToString(json['ticket_open_datetime']),
      isHot: _parseToBool(json['is_hot']),
      tags: _parseToStringList(json['tags']),
      performer: _parseToInt(json['performer']),
    );
  }

  // 안전한 파싱 헬퍼 메서드들
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static bool _parseToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }

  static List<String> _parseToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'performance_id': performanceId,
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'runtime': runtime,
      'age_rating': ageRating,
      'genre': genre,
      'venue_name': venueName,
      'venue_location': venueLocation,
      'main_image': mainImage,
      'detail_image': detailImage,
      'agency_name': agencyName,
      'ticket_open_datetime': ticketOpenDatetime,
      'is_hot': isHot,
      'tags': tags,
      'performer': performer,
    };
  }
}
