import '../entities/announcement.dart';

/// Use case murni (domain layer) untuk memfilter pengumuman berdasarkan kata kunci judul.
/// Mendukung pencarian case-insensitive, penanganan multi-spasi, dan pembersihan tanda baca.
class FilterAnnouncements {
  const FilterAnnouncements();

  List<Announcement> call(List<Announcement> items, String query) {
    return filterAnnouncements(items, query);
  }
}

/// Fungsi pure untuk memfilter list pengumuman berdasarkan query pada field title.
/// Pencarian bersifat case-insensitive, menormalkan multi-spasi, dan membersihkan tanda baca.
/// Mengembalikan list kosong jika tidak ada yang cocok.
List<Announcement> filterAnnouncements(List<Announcement> items, String query) {
  // Bersihkan tanda baca yang sering terbawa saat mengetik (misal tanda tanya, seru, dll)
  final cleaned = query.replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ');
  final normalized = cleaned.trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  if (normalized.isEmpty) return items;

  final tokens = normalized.split(' ').where((token) => token.isNotEmpty);
  if (tokens.isEmpty) return items;

  return items.where((item) {
    final title = item.title.toLowerCase();
    return tokens.every((token) => title.contains(token));
  }).toList();
}
