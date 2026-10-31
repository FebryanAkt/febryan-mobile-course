import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/core/failures.dart';
import 'package:week6_campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:week6_campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:week6_campus_notify/features/announcements/domain/usecases/get_announcements.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: const LocalFailure('simulasi gagal memuat pengumuman'),
      );
    }
    return (announcements: items, failure: null);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    if (fail) {
      return (
        announcement: null,
        failure: const LocalFailure('simulasi gagal mengambil detail'),
      );
    }
    final found = items.where((item) => item.id == id).toList();
    if (found.isEmpty) {
      return (
        announcement: null,
        failure: const LocalFailure('pengumuman tidak ditemukan'),
      );
    }
    return (announcement: found.first, failure: null);
  }
}

void main() {
  group('GetAnnouncements Use Case (Pure Domain Test)', () {
    test(
      'GetAnnouncements meneruskan daftar pengumuman dari repository palsu',
      () async {
        final fakeRepo = FakeAnnouncementRepository(
          items: const [
            Announcement(
              id: '1',
              title: 'Jadwal Kuliah',
              body: 'Ruang A pindah',
              route: '/pengumuman/1',
              time: '08:00',
            ),
          ],
        );

        final useCase = GetAnnouncements(fakeRepo);
        final result = await useCase();

        expect(result.failure, isNull);
        expect(result.announcements.length, 1);
        expect(result.announcements.first.title, 'Jadwal Kuliah');
      },
    );

    test(
      'GetAnnouncements meneruskan failure tanpa melempar exception mentah',
      () async {
        final fakeRepo = FakeAnnouncementRepository(fail: true);

        final useCase = GetAnnouncements(fakeRepo);
        final result = await useCase();

        expect(result.failure, isA<LocalFailure>());
        expect(result.failure?.message, 'simulasi gagal memuat pengumuman');
        expect(result.announcements, isEmpty);
      },
    );
  });
}
