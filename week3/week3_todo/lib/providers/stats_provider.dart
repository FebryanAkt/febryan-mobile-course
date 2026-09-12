import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_provider.dart';

// ──────────────────────────────────────────────────────────────────
// Model data statistik (immutable class).
// Setiap item statistik memiliki label, value, dan icon name.
// ──────────────────────────────────────────────────────────────────
class StatItem {
  const StatItem({required this.label, required this.value, this.icon});
  final String label;
  final int value;
  final String? icon;

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
// Statistik dihitung dari data ToDo yang sesungguhnya, tetapi
// proses "fetch" disimulasikan dengan delay dan kemungkinan error
// untuk mendemonstrasikan AsyncValue (loading, error, data).
//
// - build()  : dipanggil otomatis saat provider pertama kali dibaca.
// - refresh(): me-reset state ke loading, lalu fetch ulang.
// - _fetch() : simulasi network call yang menghitung stats dari todos.
// ──────────────────────────────────────────────────────────────────
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  final Random _random = Random();

  @override
  Future<List<StatItem>> build() async {
    // ref.watch agar stats otomatis di-rebuild saat todo berubah
    final todos = ref.watch(todoListProvider);
    return _fetch(todos);
  }

  /// Memuat ulang data statistik.
  /// 1. Set state ke AsyncLoading agar UI menampilkan spinner.
  /// 2. Gunakan AsyncValue.guard() untuk menangkap error secara aman.
  Future<void> refresh() async {
    state = const AsyncLoading<List<StatItem>>();
    final todos = ref.read(todoListProvider);
    state = await AsyncValue.guard(() => _fetch(todos));
  }

  /// Simulasi network call:
  /// - Delay 2 detik (seolah-olah menghitung di server)
  /// - 30% kemungkinan gagal (throw exception)
  /// - 70% berhasil → hitung statistik dari data ToDo sesungguhnya
  Future<List<StatItem>> _fetch(List<Todo> todos) async {
    await Future.delayed(const Duration(seconds: 2));

    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal terhubung ke server');
    }

    final total = todos.length;
    final completed = todos.where((t) => t.done).length;
    final pending = total - completed;

    return [
      StatItem(label: 'Total Tugas', value: total, icon: 'assignment'),
      StatItem(label: 'Selesai', value: completed, icon: 'check_circle'),
      StatItem(label: 'Belum Selesai', value: pending, icon: 'pending'),
    ];
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
