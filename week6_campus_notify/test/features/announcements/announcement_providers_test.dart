import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/features/announcements/presentation/providers/announcement_providers.dart';

void main() {
  group('SearchQueryNotifier & filteredAnnouncementsProvider', () {
    test('searchQueryProvider default bernilai kosong', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(searchQueryProvider), isEmpty);
    });

    test('updateQuery dan clear mengubah state searchQueryProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).updateQuery('uts');
      expect(container.read(searchQueryProvider), 'uts');

      container.read(searchQueryProvider.notifier).clear();
      expect(container.read(searchQueryProvider), isEmpty);
    });

    test(
      'filteredAnnouncementsProvider menyaring hasil sesuai searchQuery',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Tunggu hingga data awal termuat
        final initial = await container.read(announcementsProvider.future);
        expect(initial.length, 3);

        // Set query pencarian
        container.read(searchQueryProvider.notifier).updateQuery('beasiswa');

        final filtered = container.read(filteredAnnouncementsProvider);
        expect(filtered.value?.length, 1);
        expect(filtered.value?.first.title, 'Pengumuman Beasiswa');
      },
    );
  });
}
