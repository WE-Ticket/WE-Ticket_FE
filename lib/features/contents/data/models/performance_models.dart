import '../../../../core/utils/json_parser.dart';

/// 대시보드의 HOT 공연 슬라이더용 모델
class PerformanceHotItem {
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

  PerformanceHotItem({
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

  factory PerformanceHotItem.fromJson(Map<String, dynamic> json) {
    return PerformanceHotItem(
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      title: JsonParserUtils.parseString(json['title']),
      startDate: JsonParserUtils.parseString(json['start_date']),
      endDate: JsonParserUtils.parseString(json['end_date']),
      runtime: JsonParserUtils.parseInt(json['runtime']),
      ageRating: JsonParserUtils.parseString(json['age_rating']),
      genre: JsonParserUtils.parseString(json['genre']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      venueLocation: JsonParserUtils.parseString(json['venue_location']),
      mainImage: JsonParserUtils.parseString(json['main_image']),
      detailImage: JsonParserUtils.parseString(json['detail_image']),
      agencyName: JsonParserUtils.parseString(json['agency_name']),
      ticketOpenDatetime: JsonParserUtils.parseString(
        json['ticket_open_datetime'],
      ),
      isHot: JsonParserUtils.parseBool(json['is_hot']),
      tags: JsonParserUtils.parseStringList(json['tags']),
      performer: JsonParserUtils.parseInt(json['performer']),
    );
  }
}

/// 대시보드의 예매 가능한 공연 리스트용 모델 (available과 hot 동일한 구조)
typedef PerformanceAvailableItem = PerformanceHotItem;

/// 페이지네이션을 포함한 전체 공연 목록 응답 모델
class PerformanceListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<PerformanceListItem> results;

  PerformanceListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PerformanceListResponse.fromJson(Map<String, dynamic> json) {
    return PerformanceListResponse(
      count: JsonParserUtils.parseInt(json['count']),
      next: json['next'],
      previous: json['previous'],
      results:
          (json['results'] as List<dynamic>?)
              ?.map((item) => PerformanceListItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// 전체 공연 목록의 개별 아이템 모델
class PerformanceListItem {
  final int performanceId;
  final String genre;
  final String mainImage;
  final String title;
  final String performerName;
  final String venueName;
  final String startDate;
  final String endDate;
  final int minPrice;
  final bool isHot;
  final List<String> tags;
  final bool isTicketOpen;
  final bool isSoldOut;

  PerformanceListItem({
    required this.performanceId,
    required this.genre,
    required this.mainImage,
    required this.title,
    required this.performerName,
    required this.venueName,
    required this.startDate,
    required this.endDate,
    required this.minPrice,
    required this.isHot,
    required this.tags,
    required this.isTicketOpen,
    required this.isSoldOut,
  });

  factory PerformanceListItem.fromJson(Map<String, dynamic> json) {
    return PerformanceListItem(
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      genre: JsonParserUtils.parseString(json['genre']),
      mainImage: JsonParserUtils.parseString(json['main_image']),
      title: JsonParserUtils.parseString(json['title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      startDate: JsonParserUtils.parseString(json['start_date']),
      endDate: JsonParserUtils.parseString(json['end_date']),
      minPrice: JsonParserUtils.parseInt(json['min_price']),
      isHot: JsonParserUtils.parseBool(json['is_hot']),
      tags: JsonParserUtils.parseStringList(json['tags']),
      isTicketOpen: JsonParserUtils.parseBool(json['is_ticket_open']),
      isSoldOut: JsonParserUtils.parseBool(json['is_sold_out']),
    );
  }

  String get priceDisplay =>
      '${minPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원부터';

  String get statusText {
    if (isSoldOut) return '매진';
    if (!isTicketOpen) return '오픈 예정';
    return '예매 가능';
  }
}

/// 공연 상세 정보 모델
class PerformanceDetail {
  final int performanceId;
  final String mainImage;
  final bool isHot;
  final String title;
  final String performerName;
  final String startDate;
  final String endDate;
  final String venueName;
  final int minPrice;
  final String genre;
  final List<String> tags;
  final String detailImage;
  final bool isTicketOpen;
  final bool isSoldOut;
  final bool isAvailable;

  PerformanceDetail({
    required this.performanceId,
    required this.mainImage,
    required this.isHot,
    required this.title,
    required this.performerName,
    required this.startDate,
    required this.endDate,
    required this.venueName,
    required this.minPrice,
    required this.genre,
    required this.tags,
    required this.detailImage,
    required this.isTicketOpen,
    required this.isSoldOut,
    required this.isAvailable,
  });

  factory PerformanceDetail.fromJson(Map<String, dynamic> json) {
    return PerformanceDetail(
      performanceId: JsonParserUtils.parseInt(json['performance_id']),
      mainImage: JsonParserUtils.parseString(json['main_image']),
      isHot: JsonParserUtils.parseBool(json['is_hot']),
      title: JsonParserUtils.parseString(json['title']),
      performerName: JsonParserUtils.parseString(json['performer_name']),
      startDate: JsonParserUtils.parseString(json['start_date']),
      endDate: JsonParserUtils.parseString(json['end_date']),
      venueName: JsonParserUtils.parseString(json['venue_name']),
      minPrice: JsonParserUtils.parseInt(json['min_price']),
      genre: JsonParserUtils.parseString(json['genre']),
      tags: JsonParserUtils.parseStringList(json['tags']),
      detailImage: JsonParserUtils.parseString(json['detail_image']),
      isTicketOpen: JsonParserUtils.parseBool(json['is_ticket_open']),
      isSoldOut: JsonParserUtils.parseBool(json['is_sold_out']),
      isAvailable: JsonParserUtils.parseBool(json['is_available']),
    );
  }

  // 편의 메서드들
  String get priceDisplay =>
      '${minPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원부터';

  // FIXME 여기 좀 애매함. 더미 데이터 많이 쌓아보고 다시 테스트 해보기
  String get bookingStatus {
    if (isSoldOut) return '매진';
    if (!isTicketOpen) return '오픈 예정';
    if (isAvailable) return '예매 가능';
    return '예매 불가능';
  }

  bool get canBook => isAvailable && isTicketOpen && !isSoldOut;
}
