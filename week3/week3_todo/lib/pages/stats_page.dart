import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// ──────────────────────────────────────────────────────────────────
// StatsPage — ConsumerWidget yang menampilkan data statistik.
//
// Menggunakan ref.watch() di dalam build() untuk mendengarkan
// perubahan state secara reaktif. Ketiga state AsyncValue
// (loading, error, data) ditangani secara eksplisit via .when().
// ──────────────────────────────────────────────────────────────────
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── ref.watch: hanya boleh dipanggil di dalam build() ──
    // Setiap kali state statsProvider berubah (loading → data/error),
    // widget ini akan di-rebuild secara otomatis.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistik'),
        actions: [
          // ── ref.read: dipakai di callback, bukan di build() ──
          // Tombol refresh di AppBar untuk memuat ulang data
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: () => ref.read(statsProvider.notifier).refresh(),
          ),
        ],
      ),

      // ────────────────────────────────────────────────────────────
      // AsyncValue.when() — menangani KETIGA state secara eksplisit:
      //
      // 1. loading → CircularProgressIndicator (spinner)
      // 2. error   → pesan error + tombol "Coba lagi"
      // 3. data    → ListView menampilkan 3 item statistik
      //
      // Ini memastikan tidak ada state yang terlewat (exhaustive).
      // ────────────────────────────────────────────────────────────
      body: statsAsync.when(
        // ── STATE: LOADING ──
        // Ditampilkan saat pertama kali fetch atau saat refresh
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat statistik...'),
            ],
          ),
        ),

        // ── STATE: ERROR ──
        // Ditampilkan saat fetch gagal (30% kemungkinan)
        // Menyediakan pesan error dan tombol retry
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat: $err',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                // ref.invalidate() membuang state lama dan memicu
                // build() ulang pada notifier — mirip "force refresh"
                FilledButton.icon(
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),

        // ── STATE: DATA (SUCCESS) ──
        // Ditampilkan saat fetch berhasil, menampilkan ListView
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final item = stats[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(item.label),
                trailing: Text(
                  '${item.value}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
