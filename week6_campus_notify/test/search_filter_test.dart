import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:week6_campus_notify/features/announcements/domain/usecases/filter_announcements.dart';
import 'package:week6_campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:week6_campus_notify/features/announcements/presentation/widgets/announcement_empty_state.dart';
import 'package:week6_campus_notify/features/announcements/presentation/widgets/announcement_list.dart';

void main() {
  const dummyList = [
    Announcement(
      id: '1',
      title: 'Jadwal UTS Dipercepat',
      body: 'UTS Pemrograman Mobile dimajukan ke 18 Oktober 2026.',
      route: '/pengumuman/1',
      time: '08:00',
    ),
    Announcement(
      id: '2',
      title: 'Pengumuman Beasiswa',
      body: 'Pendaftaran beasiswa prestasi dibuka hingga 30 Oktober 2026.',
      route: '/pengumuman/2',
      time: 'Kemarin',
    ),
    Announcement(
      id: '3',
      title: 'Libur Nasional',
      body: 'Kampus libur pada 28 Oktober 2026 (Hari Sumpah Pemuda).',
      route: '/pengumuman/3',
      time: '2 hari lalu',
    ),
  ];

  group('Unit Test: Search & Filter Logic', () {
    test('query kosong mengembalikan semua daftar pengumuman', () {
      final result = filterAnnouncements(dummyList, '');
      expect(result, hasLength(3));
    });

    test(
      'query cocok mengembalikan pengumuman yang sesuai (case-insensitive)',
      () {
        final result = filterAnnouncements(dummyList, 'beasiswa');
        expect(result, hasLength(1));
        expect(result.first.id, '2');
        expect(result.first.title, 'Pengumuman Beasiswa');
      },
    );

    test('query multi-spasi tetap mencocokkan kata kunci', () {
      final result = filterAnnouncements(dummyList, 'jadwal   uts');
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('query dengan tanda baca tetap dibersihkan dan dicocokkan', () {
      final result = filterAnnouncements(dummyList, 'libur!');
      expect(result, hasLength(1));
      expect(result.first.id, '3');
    });

    test('query tak cocok menghasilkan list kosong (empty state trigger)', () {
      final result = filterAnnouncements(dummyList, 'zzz-tak-ada');
      expect(result, isEmpty);
    });
  });

  group('Widget Test: Empty State', () {
    testWidgets(
      'AnnouncementEmptyState menampilkan icon dan pesan pencarian tidak ditemukan',
      (tester) async {
        const testQuery = 'xyz-tidak-ada';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AnnouncementEmptyState(query: testQuery)),
          ),
        );

        // Verifikasi icon search_off
        expect(find.byIcon(Icons.search_off), findsOneWidget);

        // Verifikasi pesan informatif menyertakan query pengguna
        expect(
          find.text('Tidak ditemukan pengumuman untuk "$testQuery"'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AnnouncementEmptyState menampilkan teks default saat query kosong',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AnnouncementEmptyState(query: '')),
          ),
        );

        expect(find.byIcon(Icons.search_off), findsOneWidget);
        expect(find.text('Belum ada pengumuman'), findsOneWidget);
      },
    );

    testWidgets(
      'AnnouncementList menampilkan empty state saat pencarian tidak cocok di Riverpod',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              announcementsProvider.overrideWith((ref) async => dummyList),
            ],
            child: const MaterialApp(home: Scaffold(body: AnnouncementList())),
          ),
        );

        // Tunggu FutureProvider resolve
        await tester.pumpAndSettle();

        // Semula semua data tampil
        expect(find.text('Jadwal UTS Dipercepat'), findsOneWidget);

        // Simulasikan state query pencarian diubah ke query tak cocok
        final element = tester.element(find.byType(AnnouncementList));
        final container = ProviderScope.containerOf(element);
        container
            .read(searchQueryProvider.notifier)
            .updateQuery('non-existent-keyword');

        await tester.pumpAndSettle();

        // Sekarang empty state muncul dan card pengumuman hilang
        expect(find.byIcon(Icons.search_off), findsOneWidget);
        expect(
          find.text('Tidak ditemukan pengumuman untuk "non-existent-keyword"'),
          findsOneWidget,
        );
        expect(find.text('Jadwal UTS Dipercepat'), findsNothing);
      },
    );
  });
}
