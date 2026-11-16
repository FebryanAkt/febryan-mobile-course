import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case untuk mencari pengumuman berdasarkan keyword.
/// Pencarian dilakukan pada field title dan body (case-insensitive).
class SearchAnnouncements {
  const SearchAnnouncements(this._repository);
  final AnnouncementRepository _repository;

  Future<({List<Announcement> announcements, Failure? failure})> call(
    String query,
  ) async {
    final result = await _repository.fetchAnnouncements();
    if (result.failure != null) return result;

    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return result;

    final filtered = result.announcements.where((item) {
      return item.title.toLowerCase().contains(keyword) ||
          item.body.toLowerCase().contains(keyword);
    }).toList();

    return (announcements: filtered, failure: null);
  }
}
