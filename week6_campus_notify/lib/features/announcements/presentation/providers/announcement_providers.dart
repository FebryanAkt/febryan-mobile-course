import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/filter_announcements.dart';
import '../../domain/usecases/get_announcements.dart';

// Data layer: repository disuntikkan (memudahkan mocking / replacement saat testing)
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

// Domain layer: use case menerima abstraksi interface, bukan implementasi konkret
final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

// Domain layer: use case murni aturan filter/search
final filterAnnouncementsUseCaseProvider = Provider<FilterAnnouncements>((ref) {
  return const FilterAnnouncements();
});

// Presentation layer: state asynchronous untuk daftar seluruh pengumuman dari repository
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  if (result.failure != null) {
    throw result
        .failure!; // Pertahankan tipe Failure agar UI bisa pattern-match
  }
  return result.announcements;
});

// Presentation layer: Notifier mengelola query pencarian (State saja)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// Presentation layer: komputasi daftar pengumuman yang tersaring berdasarkan query
final filteredAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>((
  ref,
) {
  final announcementsAsync = ref.watch(announcementsProvider);
  final query = ref.watch(searchQueryProvider);
  final filterUseCase = ref.watch(filterAnnouncementsUseCaseProvider);

  return announcementsAsync.whenData((items) => filterUseCase(items, query));
});
