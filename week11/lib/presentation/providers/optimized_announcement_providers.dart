import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/performance_tracker.dart';
import '../../data/cached_announcement_repository.dart';

/// Provider instance singleton Repository
final cachedAnnouncementRepositoryProvider =
    Provider<CachedAnnouncementRepository>((ref) {
  return CachedAnnouncementRepositoryImpl();
});

/// State untuk Infinite Scrolling Pagination
class PaginatedState {
  final List<AnnouncementItem> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  const PaginatedState({
    this.items = const [],
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
  });

  PaginatedState copyWith({
    List<AnnouncementItem>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier yang mengelola pemuatan data per halaman secara lazy
class PaginatedAnnouncementsNotifier extends Notifier<PaginatedState> {
  static const int defaultPageSize = 4;

  @override
  PaginatedState build() {
    return const PaginatedState();
  }

  CachedAnnouncementRepository get _repository =>
      ref.read(cachedAnnouncementRepositoryProvider);

  /// Muat halaman pertama / Pull-to-Refresh
  Future<void> loadInitialPage() async {
    PerformanceTracker.instance.recordRebuild('PaginatedNotifier_loadInitialPage');
    state = state.copyWith(isLoading: true, page: 1, errorMessage: null);

    try {
      final initialItems = await _repository.fetchPaginated(
        page: 1,
        pageSize: defaultPageSize,
      );

      if (!ref.mounted) return;

      state = PaginatedState(
        items: initialItems,
        page: 2,
        isLoading: false,
        hasMore: initialItems.length >= defaultPageSize,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat pengumuman: $e',
      );
    }
  }

  /// Muat halaman berikutnya saat user melakukan scrolling mendekati akhir daftar
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    PerformanceTracker.instance.recordRebuild('PaginatedNotifier_loadNextPage_${state.page}');
    state = state.copyWith(isLoading: true);

    try {
      final nextItems = await _repository.fetchPaginated(
        page: state.page,
        pageSize: defaultPageSize,
      );

      if (!ref.mounted) return;

      if (nextItems.isEmpty) {
        state = state.copyWith(isLoading: false, hasMore: false);
      } else {
        state = state.copyWith(
          items: [...state.items, ...nextItems],
          page: state.page + 1,
          isLoading: false,
          hasMore: nextItems.length >= defaultPageSize,
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat halaman berikutnya: $e',
      );
    }
  }
}

final paginatedAnnouncementsProvider =
    NotifierProvider<PaginatedAnnouncementsNotifier, PaginatedState>(
  PaginatedAnnouncementsNotifier.new,
);

/// State query pencarian sederhana
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Provider yang menyaring item dengan seleksi granular.
/// Menggunakan `.select` untuk mencegah re-evaluasi bila query tidak berubah.
final filteredOptimizedAnnouncementsProvider =
    Provider<List<AnnouncementItem>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  // Hanya ambil list items dari paginatedAnnouncementsProvider
  final items = ref.watch(
    paginatedAnnouncementsProvider.select((state) => state.items),
  );

  if (query.isEmpty) return items;

  return items
      .where((item) =>
          item.title.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query))
      .toList();
});
