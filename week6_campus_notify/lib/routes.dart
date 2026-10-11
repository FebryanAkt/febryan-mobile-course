import 'core/format.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const announcement = '/pengumuman/:id';
  static const root = '/';

  static String announcementDetail(String id) => '/pengumuman/$id';
}

/// Fungsi murni untuk mengekstrak dan memformat route dari payload data notifikasi
String routeFromMessage(Map<String, dynamic> data) =>
    AppFormatters.parseRoute(data);

