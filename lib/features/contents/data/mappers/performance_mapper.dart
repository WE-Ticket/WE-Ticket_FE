import '../performance_models.dart' as data_models;
import '../../domain/entities/performance.dart';
import '../../domain/entities/performance_list.dart';

/// Mapper class to convert between data models and domain entities
class PerformanceMapper {
  /// Convert PerformanceHotItem (data) to PerformanceHot (domain)
  PerformanceHot hotItemToDomain(data_models.PerformanceHotItem model) {
    return PerformanceHot(
      id: model.performanceId,
      title: model.title,
      performerName: _getPerformerName(model.performer),
      imageUrl: model.mainImage,
      viewCount: 0, // Not available in current model
      isFeatured: model.isHot,
    );
  }

  /// Convert PerformanceAvailableItem (data) to PerformanceAvailable (domain)
  PerformanceAvailable availableItemToDomain(
    data_models.PerformanceAvailableItem model,
  ) {
    return PerformanceAvailable(
      id: model.performanceId,
      title: model.title,
      performerName: model.performerName,
      imageUrl: model.mainImage,
      startDate: _parseDateTime(model.startDate),
      endDate: _parseDateTime(model.endDate),
      venueName: model.venueName,
      availableSeats: 100, // Dummy value - not available in model
      canBook: true, // Available items are bookable by default
    );
  }

  /// Convert PerformanceListItem (data) to Performance (domain)
  Performance listItemToDomain(data_models.PerformanceListItem model) {
    return Performance(
      id: model.performanceId,
      title: model.title,
      performerName: model.performerName,
      venueName: model.venueName,
      venueLocation: '', // Not available in list item model
      mainImage: model.mainImage,
      detailImage: '', // Not available in list item model
      startDate: _parseDateTime(model.startDate),
      endDate: _parseDateTime(model.endDate),
      runtime: 120, // Default runtime - not available in list item model
      genre: PerformanceGenre.fromString(model.genre),
      ageRating: AgeRating.all, // Default - not available in list item model
      minPrice: model.minPrice,
      isHot: model.isHot,
      isTicketOpen: model.isTicketOpen,
      isSoldOut: model.isSoldOut,
      isAvailable: !model.isSoldOut && model.isTicketOpen,
      ticketOpenDateTime: null, // Not available in list item model
      tags: model.tags,
      sessions: [], // Not available in list item model
    );
  }

  /// Convert PerformanceDetail (data) to PerformanceDetail (domain)
  PerformanceDetail detailToDomain(data_models.PerformanceDetail model) {
    return PerformanceDetail(
      id: model.performanceId,
      title: model.title,
      performerName: model.performerName,
      genre: model.genre,
      description: null, // Not available in current model
      imageUrl: model.mainImage,
      venueName: model.venueName,
      venueAddress: model.venueLocation,
      startDate: _parseDateTime(model.startDate),
      endDate: _parseDateTime(model.endDate),
      canBook: model.canBook,
      duration: null, // Not available in current model
      ageRating: model.ageRating,
      tags: model.tags,
      minPrice: model.minPrice,
      maxPrice: model.minPrice, // Use min price as max price placeholder
    );
  }

  /// Convert PerformanceListResponse (data) to PerformanceList (domain)
  PerformanceList listResponseToDomain(
    data_models.PerformanceListResponse model,
  ) {
    final performances = model.results
        .map((item) => listItemToDomain(item))
        .toList();

    return PerformanceList(
      performances: performances,
      totalCount: model.count,
      currentPage: 1, // Default - not available in current model
      totalPages: (model.count / 20).ceil(), // Calculate based on default limit
      hasNext: model.next != null,
      hasPrevious: model.previous != null,
    );
  }

  /// Helper method to get performer name from ID
  String _getPerformerName(int performerId) {
    // This would typically fetch from a performer repository
    // For now, return a placeholder
    return 'Performer $performerId';
  }

  /// Helper method to parse date string to DateTime
  DateTime _parseDateTime(String dateStr) {
    try {
      // Assuming date format is YYYY-MM-DD or similar
      return DateTime.parse(dateStr);
    } catch (e) {
      // Return current date as fallback
      return DateTime.now();
    }
  }
}
