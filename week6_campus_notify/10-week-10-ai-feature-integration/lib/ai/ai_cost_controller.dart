import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exception yang dilempar saat pengguna mencapai batas maksimum request harian
class QuotaExceededException implements Exception {
  final int dailyLimit;
  final String resetDate;

  QuotaExceededException({
    required this.dailyLimit,
    required this.resetDate,
  });

  @override
  String toString() =>
      'Batas kuota harian Anda ($dailyLimit pertanyaan/hari) telah tercapai untuk mengendalikan biaya API. Kuota akan direset pada hari berikutnya. Anda dapat menggunakan Mode Offline.';
}

/// Cache lokal untuk menyimpan pasangan query -> respons AI.
/// Berguna untuk mencegah pemanggilan API berulang dengan pertanyaan yang sama
/// sehingga menghemat kuota dan biaya pemakaian AI.
class AiResponseCache {
  final Map<String, String> _cache = {};
  int _cacheHits = 0;

  int get size => _cache.length;
  int get cacheHits => _cacheHits;

  /// Normalisasi query (lowercase, trim, hilangkan tanda baca akhir)
  String _normalizeKey(String query) {
    return query
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[?.!,]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Mengambil jawaban dari cache jika tersedia
  String? get(String query) {
    final key = _normalizeKey(query);
    final cached = _cache[key];
    if (cached != null) {
      _cacheHits++;
    }
    return cached;
  }

  /// Menyimpan jawaban AI ke dalam cache
  void put(String query, String response) {
    if (query.trim().isEmpty || response.trim().isEmpty) return;
    final key = _normalizeKey(query);
    _cache[key] = response;
  }

  /// Menghapus seluruh cache
  void clear() {
    _cache.clear();
    _cacheHits = 0;
  }
}

/// Pelacak kuota dan pembatas request harian per pengguna (Rate Limiter).
/// Memastikan biaya API tidak melonjak akibat spam request atau loop tak terduga.
class AiUsageTracker {
  final FlutterSecureStorage _storage;
  final int dailyLimit;

  static const String _keyDate = 'ai_usage_date';
  static const String _keyCount = 'ai_usage_count';

  AiUsageTracker({
    FlutterSecureStorage? storage,
    this.dailyLimit = 20,
  }) : _storage = storage ?? const FlutterSecureStorage();

  /// Mengembalikan tanggal hari ini dalam format YYYY-MM-DD
  String _todayString() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Memeriksa apakah pengguna masih memiliki sisa kuota hari ini
  Future<bool> canMakeRequest() async {
    final currentUsage = await getTodayUsage();
    return currentUsage < dailyLimit;
  }

  /// Mendapatkan jumlah request yang telah digunakan hari ini
  Future<int> getTodayUsage() async {
    final savedDate = await _storage.read(key: _keyDate);
    final today = _todayString();

    if (savedDate != today) {
      // Hari baru: reset kuota
      await _storage.write(key: _keyDate, value: today);
      await _storage.write(key: _keyCount, value: '0');
      return 0;
    }

    final countStr = await _storage.read(key: _keyCount);
    return int.tryParse(countStr ?? '0') ?? 0;
  }

  /// Menambah 1 hitungan penggunaan request setelah berhasil memanggil API
  Future<void> incrementUsage() async {
    final today = _todayString();
    final current = await getTodayUsage();
    final next = current + 1;

    await _storage.write(key: _keyDate, value: today);
    await _storage.write(key: _keyCount, value: next.toString());
  }

  /// Mendapatkan sisa kuota request hari ini
  Future<int> getRemainingQuota() async {
    final usage = await getTodayUsage();
    final remaining = dailyLimit - usage;
    return remaining < 0 ? 0 : remaining;
  }

  /// Reset penggunaan kuota secara manual (misal untuk testing)
  Future<void> resetUsage() async {
    final today = _todayString();
    await _storage.write(key: _keyDate, value: today);
    await _storage.write(key: _keyCount, value: '0');
  }
}
