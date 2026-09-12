import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// ──────────────────────────────────────────────────────────────────
// StatsPage — ConsumerWidget yang menampilkan statistik ToDo.
//
// Menggunakan ref.watch() di dalam build() untuk mendengarkan
// perubahan state secara reaktif. Ketiga state AsyncValue
// (loading, error, data) ditangani secara eksplisit via .when().
// ──────────────────────────────────────────────────────────────────
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  /// Map icon name string ke IconData untuk tampilan
  IconData _iconFor(String? iconName) => switch (iconName) {
    'assignment' => Icons.assignment,
    'check_circle' => Icons.check_circle,
    'pending' => Icons.pending_actions,
    _ => Icons.analytics,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── ref.watch: hanya boleh dipanggil di dalam build() ──
    // Setiap kali state statsProvider berubah (loading → data/error),
    // widget ini akan di-rebuild secara otomatis.
    final statsAsync = ref.watch(statsProvider);
    final theme = Theme.of(context);

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
      // 3. data    → statistik ToDo + progress bar
      // ────────────────────────────────────────────────────────────
      body: statsAsync.when(
        // ── STATE: LOADING ──
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
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
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
        data: (stats) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Ringkasan Tugas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Stats cards
              ...stats.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      _iconFor(item.icon),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(item.label),
                  trailing: Text(
                    '${item.value}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 24),

              // Completion progress bar (hanya tampil jika ada tugas)
              if (stats.isNotEmpty && stats.first.value > 0) ...[
                Text(
                  'Progress Penyelesaian',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stats[1].value / stats[0].value,
                    minHeight: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${((stats[1].value / stats[0].value) * 100).toStringAsFixed(0)}% selesai',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Text(
                      'Tambahkan tugas untuk melihat progress!',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
