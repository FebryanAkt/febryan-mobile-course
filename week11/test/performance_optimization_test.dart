import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week11_performance_optimization/core/performance_tracker.dart';
import 'package:week11_performance_optimization/data/cached_announcement_repository.dart';
import 'package:week11_performance_optimization/data/interceptors/cache_interceptor.dart';
import 'package:week11_performance_optimization/presentation/providers/optimized_announcement_providers.dart';

void main() {
  setUp(() {
    PerformanceTracker.instance.reset();
  });

  group('1. Network & Cache Interceptor Optimization Test', () {
    test('InMemoryCacheStore menyimpan dan mengambil entri data sebelum TTL habis', () {
      final store = InMemoryCacheStore();
      store.set('test_key', {'status': 'ok'}, ttl: const Duration(seconds: 10));

      expect(store.hasValid('test_key'), isTrue);
      final entry = store.get('test_key');
      expect(entry, isNotNull);
      expect((entry!.data as Map)['status'], equals('ok'));
    });

    test('InMemoryCacheStore menandai isExpired jika durasi TTL telah berlalu', () async {
      final store = InMemoryCacheStore();
      store.set('short_lived', 'data', ttl: const Duration(milliseconds: 50));

      expect(store.hasValid('short_lived'), isTrue);
      await Future.delayed(const Duration(milliseconds: 70));
      expect(store.hasValid('short_lived'), isFalse);
    });

    test('PerformanceCacheInterceptor mendeteksi HIT pada pemanggilan kedua', () async {
      final dio = Dio();
      final store = InMemoryCacheStore();
      final interceptor = PerformanceCacheInterceptor(
        cacheStore: store,
        defaultPolicy: CachePolicy.staleWhileRevalidate,
      );

      // Simpan data palsu di cache
      store.set(
        'GET:https://api.campus.test/items?{}',
        [{'id': '1', 'title': 'Cached Title'}],
      );

      dio.interceptors.add(interceptor);

      final response = await dio.get(
        'https://api.campus.test/items',
        options: Options(extra: {'cache_policy': CachePolicy.staleWhileRevalidate}),
      );

      expect(response.statusCode, equals(200));
      expect(response.headers.value('x-cache'), contains('HIT'));
      expect(PerformanceTracker.instance.cacheHits, equals(1));
    });
  });

  group('2. CachedAnnouncementRepository & Pagination Test', () {
    test('fetchAnnouncements mengembalikan data dan mencatat cache hit pada pemanggilan kedua', () async {
      final repo = CachedAnnouncementRepositoryImpl();

      // Panggilan 1: Miss & simpan ke cache
      final firstFetch = await repo.fetchAnnouncements();
      expect(firstFetch.isNotEmpty, isTrue);
      expect(PerformanceTracker.instance.cacheMisses, equals(1));

      // Panggilan 2: Harus Hit dari memori cache
      final secondFetch = await repo.fetchAnnouncements();
      expect(secondFetch.length, equals(firstFetch.length));
      expect(PerformanceTracker.instance.cacheHits, equals(1));
    });

    test('fetchPaginated membagi data dalam chunk terisolasi (halaman 1 vs halaman 2)', () async {
      final repo = CachedAnnouncementRepositoryImpl();

      final page1 = await repo.fetchPaginated(page: 1, pageSize: 4);
      final page2 = await repo.fetchPaginated(page: 2, pageSize: 4);

      expect(page1.length, equals(4));
      expect(page2.length, equals(4));
      // Pastikan item halaman 1 tidak bertabrakan dengan halaman 2
      expect(page1.first.id, equals('1'));
      expect(page2.first.id, equals('5'));
    });

    test('fetchPaginated mengembalikan list kosong bila indeks melebihi kapasitas data', () async {
      final repo = CachedAnnouncementRepositoryImpl();
      final emptyPage = await repo.fetchPaginated(page: 99, pageSize: 10);
      expect(emptyPage, isEmpty);
    });
  });

  group('3. Riverpod Rebuild Optimization & Select Test', () {
    test('filteredOptimizedAnnouncementsProvider hanya memfilter berdasarkan kata kunci', () async {
      final container = ProviderContainer(
        overrides: [
          cachedAnnouncementRepositoryProvider.overrideWithValue(
            CachedAnnouncementRepositoryImpl(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Tunggu inisialisasi awal
      await container.read(paginatedAnnouncementsProvider.notifier).loadInitialPage();

      var items = container.read(filteredOptimizedAnnouncementsProvider);
      expect(items.length, greaterThanOrEqualTo(4));

      // Filter query pencarian
      container.read(searchQueryProvider.notifier).setQuery('Beasiswa');
      items = container.read(filteredOptimizedAnnouncementsProvider);
      expect(items.length, equals(1));
      expect(items.first.title, contains('Beasiswa'));

      // Clear pencarian
      container.read(searchQueryProvider.notifier).clear();
      items = container.read(filteredOptimizedAnnouncementsProvider);
      expect(items.length, greaterThanOrEqualTo(4));
    });

    test('PaginatedNotifier mengubah state isLoading tanpa menghapus list yang sudah ada', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(paginatedAnnouncementsProvider.notifier);
      await notifier.loadInitialPage();

      final stateBefore = container.read(paginatedAnnouncementsProvider);
      expect(stateBefore.items.isNotEmpty, isTrue);
      expect(stateBefore.page, equals(2));

      await notifier.loadNextPage();
      final stateAfter = container.read(paginatedAnnouncementsProvider);
      expect(stateAfter.items.length, greaterThan(stateBefore.items.length));
    });
  });

  group('4. Performance Telemetry & Memory Leak Safety Check', () {
    test('PerformanceTracker mencatat dan mereset metrik dengan benar', () {
      final tracker = PerformanceTracker.instance;
      tracker.recordRebuild('CardWidget');
      tracker.recordFrameTime(12.4);
      tracker.recordFrameTime(14.8);

      expect(tracker.rebuildCount, equals(1));
      expect(tracker.averageFrameTimeMs, closeTo(13.6, 0.1));

      tracker.reset();
      expect(tracker.rebuildCount, equals(0));
      expect(tracker.averageFrameTimeMs, equals(0.0));
    });
  });
}
