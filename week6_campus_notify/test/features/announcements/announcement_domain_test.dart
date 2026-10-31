import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/core/failures.dart';
import 'package:week6_campus_notify/features/announcements/data/models/announcement_model.dart';
import 'package:week6_campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:week6_campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:week6_campus_notify/features/announcements/domain/usecases/get_announcements.dart';

void main() {
  group('Announcement Entity & Model', () {
    test('Entity preserves properties', () {
      const entity = Announcement(
        id: '1',
        title: 'Judul',
        body: 'Isi',
        route: '/pengumuman/1',
        time: '10:00',
      );
      expect(entity.id, '1');
      expect(entity.title, 'Judul');
      expect(entity.body, 'Isi');
      expect(entity.route, '/pengumuman/1');
      expect(entity.time, '10:00');
    });

    test('Model converts toMap and fromMap correctly', () {
      const model = AnnouncementModel(
        id: '10',
        title: 'Info Beasiswa',
        body: 'Pendaftaran dibuka',
        route: '/pengumuman/10',
        time: 'Kemarin',
      );

      final map = model.toMap();
      expect(map['id'], '10');
      expect(map['title'], 'Info Beasiswa');

      final fromMap = AnnouncementModel.fromMap(map);
      expect(fromMap.id, '10');
      expect(fromMap.title, 'Info Beasiswa');
      expect(fromMap.body, 'Pendaftaran dibuka');

      final entity = fromMap.toEntity();
      expect(entity, isA<Announcement>());
      expect(entity.id, '10');
    });
  });

  group('AnnouncementRepositoryImpl & UseCase', () {
    late AnnouncementRepositoryImpl repository;

    setUp(() {
      repository = AnnouncementRepositoryImpl();
    });

    test('fetchAnnouncements returns non-empty list without failure', () async {
      final result = await repository.fetchAnnouncements();
      expect(result.failure, isNull);
      expect(result.announcements.isNotEmpty, isTrue);
      expect(result.announcements.first.id, '1');
    });

    test('getAnnouncementById returns matching announcement', () async {
      final result = await repository.getAnnouncementById('1');
      expect(result.failure, isNull);
      expect(result.announcement, isNotNull);
      expect(result.announcement?.title, 'Jadwal UTS Dipercepat');
    });

    test('getAnnouncementById returns failure when id not found', () async {
      final result = await repository.getAnnouncementById('999');
      expect(result.announcement, isNull);
      expect(result.failure, isA<LocalFailure>());
    });

    test(
      'GetAnnouncements usecase calls repository.fetchAnnouncements',
      () async {
        final useCase = GetAnnouncements(repository);
        final result = await useCase();
        expect(result.failure, isNull);
        expect(result.announcements.length, 3);
      },
    );
  });
}
