import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({List<AnnouncementModel>? initialData})
    : _data = initialData ?? _defaultAnnouncements;

  final List<AnnouncementModel> _data;

  static const _defaultAnnouncements = [
    AnnouncementModel(
      id: '1',
      title: 'Jadwal UTS Dipercepat',
      body: 'UTS Pemrograman Mobile dimajukan ke 18 Oktober 2026.',
      route: '/pengumuman/1',
      time: '08:00',
    ),
    AnnouncementModel(
      id: '2',
      title: 'Pengumuman Beasiswa',
      body: 'Pendaftaran beasiswa prestasi dibuka hingga 30 Oktober 2026.',
      route: '/pengumuman/2',
      time: 'Kemarin',
    ),
    AnnouncementModel(
      id: '3',
      title: 'Libur Nasional',
      body: 'Kampus libur pada 28 Oktober 2026 (Hari Sumpah Pemuda).',
      route: '/pengumuman/3',
      time: '2 hari lalu',
    ),
  ];

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    try {
      final announcements = _data.map((m) => m.toEntity()).toList();
      return (announcements: announcements, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    try {
      final found = _data.where((m) => m.id == id).toList();
      if (found.isEmpty) {
        return (
          announcement: null,
          failure: const LocalFailure('Pengumuman tidak ditemukan'),
        );
      }
      return (announcement: found.first.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Gagal memuat detail pengumuman: $e'),
      );
    }
  }
}
