import 'package:equatable/equatable.dart';
import 'performance.dart';

/// Domain entity for performance hot items (featured performances)
class PerformanceHot extends Equatable {
  final int id;
  final String title;
  final String performerName;
  final String? imageUrl;
  final int viewCount;
  final bool isFeatured;

  const PerformanceHot({
    required this.id,
    required this.title,
    required this.performerName,
    this.imageUrl,
    required this.viewCount,
    this.isFeatured = false,
  });

  @override
  List<Object?> get props => [id, title, performerName, imageUrl, viewCount, isFeatured];

  @override
  String toString() => 'PerformanceHot(id: $id, title: $title)';
}

/// Domain entity for available performances (bookable performances)
class PerformanceAvailable extends Equatable {
  final int id;
  final String title;
  final String performerName;
  final String? imageUrl;
  final DateTime? nextShowDate;
  final int availableSeats;
  final bool canBook;

  const PerformanceAvailable({
    required this.id,
    required this.title,
    required this.performerName,
    this.imageUrl,
    this.nextShowDate,
    required this.availableSeats,
    required this.canBook,
  });

  /// Check if performance has available seats
  bool get hasAvailableSeats => availableSeats > 0;

  /// Get formatted next show date
  String get nextShowDateFormatted {
    if (nextShowDate == null) return '일정 미정';
    final date = nextShowDate!;
    return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        performerName,
        imageUrl,
        nextShowDate,
        availableSeats,
        canBook,
      ];

  @override
  String toString() => 'PerformanceAvailable(id: $id, title: $title)';
}

/// Domain entity for detailed performance information
class PerformanceDetail extends Equatable {
  final int id;
  final String title;
  final String performerName;
  final String genre;
  final String? description;
  final String? imageUrl;
  final String venueName;
  final String? venueAddress;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool canBook;
  final Duration? duration;
  final String? ageRating;
  final List<String> tags;
  final int minPrice;
  final int maxPrice;

  const PerformanceDetail({
    required this.id,
    required this.title,
    required this.performerName,
    required this.genre,
    this.description,
    this.imageUrl,
    required this.venueName,
    this.venueAddress,
    this.startDate,
    this.endDate,
    required this.canBook,
    this.duration,
    this.ageRating,
    this.tags = const [],
    required this.minPrice,
    required this.maxPrice,
  });

  /// Get formatted duration
  String get durationText {
    if (duration == null) return '정보 없음';
    final minutes = duration!.inMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}시간 ${remainingMinutes}분';
    }
    return '${remainingMinutes}분';
  }

  /// Get price range display
  String get priceRangeDisplay {
    if (minPrice == maxPrice) {
      return '${_formatPrice(minPrice)}원';
    }
    return '${_formatPrice(minPrice)}원 - ${_formatPrice(maxPrice)}원';
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]!},',
    );
  }

  /// Get formatted date range
  String get dateRange {
    if (startDate == null) return '날짜 미정';
    if (endDate == null) return _formatDate(startDate!);
    if (_isSameDay(startDate!, endDate!)) return _formatDate(startDate!);
    return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        performerName,
        genre,
        description,
        imageUrl,
        venueName,
        venueAddress,
        startDate,
        endDate,
        canBook,
        duration,
        ageRating,
        tags,
        minPrice,
        maxPrice,
      ];

  @override
  String toString() => 'PerformanceDetail(id: $id, title: $title, venue: $venueName)';
}

/// Domain entity for paginated performance list
class PerformanceList extends Equatable {
  final List<Performance> performances;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PerformanceList({
    required this.performances,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Check if list is empty
  bool get isEmpty => performances.isEmpty;

  /// Check if list is not empty
  bool get isNotEmpty => performances.isNotEmpty;

  @override
  List<Object?> get props => [
        performances,
        totalCount,
        currentPage,
        totalPages,
        hasNext,
        hasPrevious,
      ];

  @override
  String toString() => 'PerformanceList(count: $totalCount, page: $currentPage)';
}