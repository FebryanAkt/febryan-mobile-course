/// Fungsi murni untuk memformat rute dan waktu tanpa dependensi UI Flutter.
class AppFormatters {
  /// Ekstrak dan normalisasi rute dari payload data FCM
  static String parseRoute(Map<String, dynamic> data) {
    final route = data['route']?.toString().trim() ?? '';
    if (route.isEmpty) return '/';
    return route.startsWith('/') ? route : '/$route';
  }

  /// Ekstrak id dari payload rute atau data
  static String extractId(Map<String, dynamic> data) {
    if (data.containsKey('id') && data['id'] != null) {
      return data['id'].toString();
    }
    final route = parseRoute(data);
    final segments = route.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : '';
  }

  /// Format waktu relatif sederhana (murni Dart)
  static String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(dateTime);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}
