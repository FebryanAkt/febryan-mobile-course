import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/performance_tracker.dart';
import 'interceptors/cache_interceptor.dart';

/// Model Pengumuman Kampus yang mendukung serialisasi cepat
class AnnouncementItem {
  final String id;
  final String title;
  final String body;
  final String route;
  final String time;
  final String? imageUrl;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.time,
    this.imageUrl,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      route: json['route'] as String? ?? '/pengumuman/${json['id']}',
      time: json['time'] as String? ?? 'Baru saja',
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'route': route,
        'time': time,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

/// Kontrak Repository Pengumuman dengan fitur optimasi cache dan pagination
abstract class CachedAnnouncementRepository {
  Future<List<AnnouncementItem>> fetchAnnouncements({
    bool forceRefresh = false,
    CachePolicy policy = CachePolicy.staleWhileRevalidate,
  });

  Future<List<AnnouncementItem>> fetchPaginated({
    required int page,
    int pageSize = 10,
  });

  void clearCache();
}

/// Implementasi Repository yang mengintegrasikan Stale-While-Revalidate Caching,
/// Pagination bertahap, dan penanganan fallback lokal
class CachedAnnouncementRepositoryImpl implements CachedAnnouncementRepository {
  final Dio _dio;
  final InMemoryCacheStore _cacheStore;

  // Master data simulasi lokal untuk fallback offline-first
  static const List<AnnouncementItem> _mockDatabase = [
    AnnouncementItem(
      id: '1',
      title: 'Jadwal UTS Dipercepat',
      body: 'UTS Pemrograman Mobile dimajukan ke 18 Oktober 2026. Harap persiapkan modul 1-10.',
      route: '/pengumuman/1',
      time: '08:00',
      imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=300',
    ),
    AnnouncementItem(
      id: '2',
      title: 'Pengumuman Beasiswa Prestasi JTI',
      body: 'Pendaftaran beasiswa prestasi dibuka hingga 30 Oktober 2026 bagi mahasiswa aktif D4 TI.',
      route: '/pengumuman/2',
      time: 'Kemarin',
      imageUrl: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=300',
    ),
    AnnouncementItem(
      id: '3',
      title: 'Libur Nasional Sumpah Pemuda',
      body: 'Seluruh kegiatan perkuliahan ditiadakan pada 28 Oktober 2026.',
      route: '/pengumuman/3',
      time: '2 hari lalu',
      imageUrl: 'https://images.unsplash.com/photo-1532619675605-1ede6c2ed2b0?w=300',
    ),
    AnnouncementItem(
      id: '4',
      title: 'Workshop Flutter DevTools & Profiling',
      body: 'Pelatihan optimasi render pipeline, deteksi jank, dan flame chart bersama Google Developer Expert.',
      route: '/pengumuman/4',
      time: '3 hari lalu',
      imageUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=300',
    ),
    AnnouncementItem(
      id: '5',
      title: 'Pemeliharaan Server Siakad',
      body: 'Layanan KRS dan KHS akan dinonaktifkan sementara pada Sabtu pukul 22:00 - 04:00 WIB.',
      route: '/pengumuman/5',
      time: '4 hari lalu',
      imageUrl: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=300',
    ),
    AnnouncementItem(
      id: '6',
      title: 'Seminar Nasional Teknologi Informasi',
      body: 'Call for papers dan pendaftaran peserta dibuka untuk mahasiswa semester 5 ke atas.',
      route: '/pengumuman/6',
      time: '5 hari lalu',
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=300',
    ),
    AnnouncementItem(
      id: '7',
      title: 'Kompetisi Pemrograman Mobile Mahasiswa',
      body: 'Menangkan total hadiah 25 juta rupiah dalam ajang inovasi aplikasi cerdas kampus.',
      route: '/pengumuman/7',
      time: '6 hari lalu',
      imageUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=300',
    ),
    AnnouncementItem(
      id: '8',
      title: 'Pengembalian Buku Perpustakaan JTI',
      body: 'Batas akhir bebas denda keterlambatan buku semester ganjil adalah akhir bulan ini.',
      route: '/pengumuman/8',
      time: '1 minggu lalu',
      imageUrl: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=300',
    ),
    AnnouncementItem(
      id: '9',
      title: 'Sosialisasi Program Magang Industri (MBKM)',
      body: 'Daftarkan diri Anda pada mitra teknologi ternama untuk konversi 20 SKS penuh.',
      route: '/pengumuman/9',
      time: '1 minggu lalu',
      imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=300',
    ),
    AnnouncementItem(
      id: '10',
      title: 'Pembaruan Fasilitas Laboratorium Komputer',
      body: 'Lab Visi Komputer dan Lab Mobile kini dilengkapi workstation performa tinggi.',
      route: '/pengumuman/10',
      time: '2 minggu lalu',
      imageUrl: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300',
    ),
    AnnouncementItem(
      id: '11',
      title: 'Layanan Konseling Akademik & Karir',
      body: 'Sesi konsultasi dengan dosen pembimbing akademik dibuka setiap hari Selasa & Kamis.',
      route: '/pengumuman/11',
      time: '2 minggu lalu',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300',
    ),
    AnnouncementItem(
      id: '12',
      title: 'Pendaftaran Sidang Tugas Akhir Tahap I',
      body: 'Pengumpulan berkas draft skripsi dibuka hingga tanggal 15 bulan depan.',
      route: '/pengumuman/12',
      time: '3 minggu lalu',
      imageUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=300',
    ),
  ];

  CachedAnnouncementRepositoryImpl({
    Dio? dio,
    InMemoryCacheStore? cacheStore,
  })  : _dio = dio ?? Dio(),
        _cacheStore = cacheStore ?? InMemoryCacheStore();

  Dio get dio => _dio;

  @override
  Future<List<AnnouncementItem>> fetchAnnouncements({
    bool forceRefresh = false,
    CachePolicy policy = CachePolicy.staleWhileRevalidate,
  }) async {
    const cacheKey = 'announcements_all';

    // 1. Jika tidak force refresh, periksa in-memory cache store
    if (!forceRefresh) {
      final cached = _cacheStore.get(cacheKey);
      if (cached != null) {
        PerformanceTracker.instance.recordCacheHit(cacheKey);
        final list = (cached.data as List)
            .map((item) => item is AnnouncementItem ? item : AnnouncementItem.fromJson(item))
            .toList();
        return list;
      }
    }

    PerformanceTracker.instance.recordCacheMiss(cacheKey);
    PerformanceTracker.instance.recordNetworkRequest('/api/announcements');

    // 2. Simulasi network fetch dengan latensi terkendali
    await Future.delayed(const Duration(milliseconds: 150));
    final freshData = List<AnnouncementItem>.from(_mockDatabase);

    // 3. Simpan ke cache store (TTL 10 menit)
    _cacheStore.set(cacheKey, freshData, ttl: const Duration(minutes: 10));

    return freshData;
  }

  @override
  Future<List<AnnouncementItem>> fetchPaginated({
    required int page,
    int pageSize = 4,
  }) async {
    PerformanceTracker.instance.recordNetworkRequest('/api/announcements?page=$page&pageSize=$pageSize');

    // Simulasi respons API cepat
    await Future.delayed(const Duration(milliseconds: 100));

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= _mockDatabase.length) {
      return <AnnouncementItem>[];
    }

    final endIndex = (startIndex + pageSize > _mockDatabase.length)
        ? _mockDatabase.length
        : startIndex + pageSize;

    return _mockDatabase.sublist(startIndex, endIndex);
  }

  @override
  void clearCache() {
    _cacheStore.clear();
  }
}
