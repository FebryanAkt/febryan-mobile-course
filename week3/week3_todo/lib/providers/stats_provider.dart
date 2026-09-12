import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ──────────────────────────────────────────────────────────────────
// Model data statistik (immutable class).
// Setiap item statistik memiliki label dan value.
// ──────────────────────────────────────────────────────────────────
class StatItem {
  const StatItem({required this.label, required this.value});
  final String label;
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;

  @override
  String toString() => 'StatItem(label: $label, value: $value)';
}

// ──────────────────────────────────────────────────────────────────
// AsyncNotifier untuk mengelola state statistik secara asinkron.
//
// - build()  : dipanggil otomatis saat provider pertama kali dibaca.
//              Mensimulasikan fetch data dengan delay 2 detik dan
//              kemungkinan gagal 30%.
// - refresh(): me-reset state ke loading, lalu fetch ulang.
// - _fetch() : method internal yang melakukan "network call" palsu.
//
// Semua perubahan state dilakukan secara IMMUTABLE — kita selalu
// mengganti `state` dengan objek AsyncValue baru, bukan memutasi.
// ──────────────────────────────────────────────────────────────────
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  // Random instance untuk simulasi kegagalan 30%
  final Random _random = Random();

  /// Dipanggil otomatis saat provider pertama kali di-watch.
  /// Mengembalikan Future yang resolve menjadi list statistik,
  /// atau throw exception dengan probabilitas 30%.
  @override
  Future<List<StatItem>> build() async {
    return _fetch();
  }

  /// Memuat ulang data statistik.
  /// 1. Set state ke AsyncLoading agar UI menampilkan spinner.
  /// 2. Gunakan AsyncValue.guard() untuk menangkap error secara aman
  ///    tanpa try-catch manual.
  Future<void> refresh() async {
    // Set ke loading — UI akan menampilkan spinner
    state = const AsyncLoading<List<StatItem>>();
    // guard() otomatis menangkap exception dan mengubahnya
    // menjadi AsyncError, atau AsyncData jika berhasil
    state = await AsyncValue.guard(() => _fetch());
  }

  /// Simulasi network call:
  /// - Delay 2 detik (seolah-olah request ke server)
  /// - 30% kemungkinan gagal (throw exception)
  /// - 70% kemungkinan berhasil (return list 3 item)
  Future<List<StatItem>> _fetch() async {
    // Simulasi latency jaringan
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi kegagalan 30%
    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal terhubung ke server');
    }

    // Kembalikan data statistik (immutable list)
    return const [
      StatItem(label: 'Pengguna Aktif', value: 1250),
      StatItem(label: 'Transaksi Hari Ini', value: 340),
      StatItem(label: 'Pendapatan (Juta)', value: 75),
    ];
  }
}

// ──────────────────────────────────────────────────────────────────
// Provider declaration dengan tipe eksplisit.
// AsyncNotifierProvider<StatsNotifier, List<StatItem>>
// memastikan tipe notifier dan state jelas, tidak ambigu.
// ──────────────────────────────────────────────────────────────────
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
