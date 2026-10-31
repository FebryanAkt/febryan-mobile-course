import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:week6_campus_notify/features/announcements/domain/usecases/filter_announcements.dart';

void main() {
  // Data dummy untuk testing
  final list = const [
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

  group('filterAnnouncements', () {
    test('query kosong mengembalikan semua item', () {
      final result = filterAnnouncements(list, '');
      expect(result, hasLength(3));
    });

    test('query hanya spasi mengembalikan semua item', () {
      final result = filterAnnouncements(list, '   ');
      expect(result, hasLength(3));
    });

    test('filter cocok berdasarkan title (case-insensitive)', () {
      final result = filterAnnouncements(list, 'beasiswa');
      expect(result, hasLength(1));
      expect(result.first.title, 'Pengumuman Beasiswa');
    });

    test('filter abaikan huruf besar/kecil', () {
      final result = filterAnnouncements(list, 'LIBUR');
      expect(result, hasLength(1));
      expect(result.first.id, '3');
    });

    test('query tak cocok kembalikan kosong', () {
      expect(filterAnnouncements(list, 'zzz-tak-ada'), isEmpty);
    });

    test('filter parsial title berfungsi', () {
      // "UTS" ada di title "Jadwal UTS Dipercepat"
      final result = filterAnnouncements(list, 'uts');
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('list kosong mengembalikan kosong', () {
      final result = filterAnnouncements([], 'apapun');
      expect(result, isEmpty);
    });

    test('filterAnnouncements TIDAK mencari di body (hanya title)', () {
      // "Pemrograman" hanya ada di body item 1, bukan di title
      final result = filterAnnouncements(list, 'Pemrograman');
      expect(result, isEmpty);
    });

    // TEST MERAH: Bug reproduksi - multi-spasi / spasi ganda antar kata
    test('query dengan multi-spasi tetap mencocokkan judul pengumuman', () {
      // Input pemicu: "jadwal  uts" (dua spasi)
      // Ekspektasi: menemukan item id '1' ("Jadwal UTS Dipercepat")
      final result = filterAnnouncements(list, 'jadwal  uts');
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('FilterAnnouncements usecase class murni memanggil filter', () {
      const useCase = FilterAnnouncements();
      final result = useCase(list, 'beasiswa');
      expect(result, hasLength(1));
      expect(result.first.title, 'Pengumuman Beasiswa');
    });

    // AI Challenge - Test Bukti Temuan 1: Punctuation / Simbol pada query
    test('query dengan tanda baca (misal "beasiswa?") tetap menemukan judul pengumuman', () {
      final result = filterAnnouncements(list, 'beasiswa?');
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });
  });
}
