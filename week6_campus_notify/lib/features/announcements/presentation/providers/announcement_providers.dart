import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';

// Data layer: repository disuntikkan (memudahkan mocking / replacement saat testing)
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

// Domain layer: use case menerima abstraksi interface, bukan implementasi konkret
final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

// Presentation layer: state asynchronous untuk dikonsumsi oleh UI widget
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.announcements;
});
