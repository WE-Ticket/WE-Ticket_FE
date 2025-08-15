import 'package:equatable/equatable.dart';

/// Domain entity representing a performance
class Performance extends Equatable {
  final int id;
  final String title;
  final String performerName;
  final String venueName;
  final String venueLocation;
  final String mainImage;
  final String? detailImage;
  final DateTime startDate;
  final DateTime endDate;
  final int runtime;
  final PerformanceGenre genre;
  final AgeRating ageRating;
  final int minPrice;
  final bool isHot;
  final bool isTicketOpen;
  final bool isSoldOut;
  final bool isAvailable;
  final DateTime? ticketOpenDateTime;
  final List<String> tags;
  final List<String> sessions;

  const Performance({
    required this.id,
    required this.title,
    required this.performerName,
    required this.venueName,
    required this.venueLocation,
    required this.mainImage,
    this.detailImage,
    required this.startDate,
    required this.endDate,
    required this.runtime,
    required this.genre,
    required this.ageRating,
    required this.minPrice,
    required this.isHot,
    required this.isTicketOpen,
    required this.isSoldOut,
    required this.isAvailable,
    this.ticketOpenDateTime,
    required this.tags,
    required this.sessions,
  });

  /// Create a copy of this performance with updated fields
  Performance copyWith({
    int? id,
    String? title,
    String? performerName,
    String? venueName,
    String? venueLocation,
    String? mainImage,
    String? detailImage,
    DateTime? startDate,
    DateTime? endDate,
    int? runtime,
    PerformanceGenre? genre,
    AgeRating? ageRating,
    int? minPrice,
    bool? isHot,
    bool? isTicketOpen,
    bool? isSoldOut,
    bool? isAvailable,
    DateTime? ticketOpenDateTime,
    List<String>? tags,
    List<String>? sessions,
  }) {
    return Performance(
      id: id ?? this.id,
      title: title ?? this.title,
      performerName: performerName ?? this.performerName,
      venueName: venueName ?? this.venueName,
      venueLocation: venueLocation ?? this.venueLocation,
      mainImage: mainImage ?? this.mainImage,
      detailImage: detailImage ?? this.detailImage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      runtime: runtime ?? this.runtime,
      genre: genre ?? this.genre,
      ageRating: ageRating ?? this.ageRating,
      minPrice: minPrice ?? this.minPrice,
      isHot: isHot ?? this.isHot,
      isTicketOpen: isTicketOpen ?? this.isTicketOpen,
      isSoldOut: isSoldOut ?? this.isSoldOut,
      isAvailable: isAvailable ?? this.isAvailable,
      ticketOpenDateTime: ticketOpenDateTime ?? this.ticketOpenDateTime,
      tags: tags ?? this.tags,
      sessions: sessions ?? this.sessions,
    );
  }

  /// Get formatted price display
  String get priceDisplay {
    return '${minPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원부터';
  }

  /// Get performance status text
  String get statusText {
    if (isSoldOut) return '매진';
    if (!isTicketOpen) return '오픈 예정';
    return '예매 가능';
  }

  /// Check if user can book this performance
  bool get canBook => isAvailable && isTicketOpen && !isSoldOut;

  /// Get performance duration in hours and minutes
  String get durationText {
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}시간 ${minutes}분';
    } else if (hours > 0) {
      return '${hours}시간';
    } else {
      return '${minutes}분';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        performerName,
        venueName,
        venueLocation,
        mainImage,
        detailImage,
        startDate,
        endDate,
        runtime,
        genre,
        ageRating,
        minPrice,
        isHot,
        isTicketOpen,
        isSoldOut,
        isAvailable,
        ticketOpenDateTime,
        tags,
        sessions,
      ];

  @override
  String toString() => 'Performance(id: $id, title: $title, performer: $performerName)';
}

/// Enum representing performance genres
enum PerformanceGenre {
  musical('musical', '뮤지컬'),
  concert('concert', '콘서트'),
  classic('classic', '클래식'),
  opera('opera', '오페라'),
  dance('dance', '무용'),
  theater('theater', '연극'),
  family('family', '가족'),
  exhibition('exhibition', '전시'),
  other('other', '기타');

  const PerformanceGenre(this.value, this.displayName);

  final String value;
  final String displayName;

  static PerformanceGenre fromString(String value) {
    switch (value.toLowerCase()) {
      case 'musical':
        return PerformanceGenre.musical;
      case 'concert':
        return PerformanceGenre.concert;
      case 'classic':
        return PerformanceGenre.classic;
      case 'opera':
        return PerformanceGenre.opera;
      case 'dance':
        return PerformanceGenre.dance;
      case 'theater':
        return PerformanceGenre.theater;
      case 'family':
        return PerformanceGenre.family;
      case 'exhibition':
        return PerformanceGenre.exhibition;
      default:
        return PerformanceGenre.other;
    }
  }
}

/// Enum representing age ratings
enum AgeRating {
  all('전체관람가', '전체관람가'),
  age7('7세이상', '7세 이상 관람가'),
  age12('12세이상', '12세 이상 관람가'),
  age15('15세이상', '15세 이상 관람가'),
  age18('18세이상', '18세 이상 관람가'),
  r('R', 'R등급');

  const AgeRating(this.value, this.displayName);

  final String value;
  final String displayName;

  static AgeRating fromString(String value) {
    switch (value) {
      case '전체관람가':
        return AgeRating.all;
      case '7세이상':
        return AgeRating.age7;
      case '12세이상':
        return AgeRating.age12;
      case '15세이상':
        return AgeRating.age15;
      case '18세이상':
        return AgeRating.age18;
      case 'R':
        return AgeRating.r;
      default:
        return AgeRating.all;
    }
  }
}