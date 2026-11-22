import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/performance_tracker.dart';
import '../presentation/providers/optimized_announcement_providers.dart';
import '../presentation/widgets/optimized_announcement_list.dart';

/// Halaman Beranda Utama Praktikum Minggu 11:
/// Menggabungkan seluruh teknik optimasi:
/// - Pengurangan rebuild widget (Search bar menggunakan local controller + debouncing)
/// - Lazy Loading & Infinite Scrolling dengan viewport recycling
/// - Isolasi repaint boundary
/// - Manajemen siklus hidup controller tanpa memory leak
class OptimizedHomePage extends ConsumerStatefulWidget {
  const OptimizedHomePage({super.key});

  @override
  ConsumerState<OptimizedHomePage> createState() => _OptimizedHomePageState();
}

class _OptimizedHomePageState extends ConsumerState<OptimizedHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Bersihkan listener dan dispose controller demi mencegah memory leak
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(searchQueryProvider.notifier)
        .setQuery(_searchController.text);
  }

  void _handleNavigate(String route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigasi cepat ke: $route'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    PerformanceTracker.instance.recordRebuild('OptimizedHomePage_build');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify — Minggu 11'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Cache & Pagination',
            onPressed: () {
              ref
                  .read(paginatedAnnouncementsProvider.notifier)
                  .loadInitialPage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Metrik Performa',
            onPressed: _showPerformanceStats,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-widget search bar terisolasi
          _OptimizedSearchBar(
            controller: _searchController,
            onClear: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).clear();
            },
          ),
          const Divider(height: 1),
          // List teroptimasi menempati sisa viewport
          Expanded(
            child: OptimizedAnnouncementList(
              onSelectRoute: _handleNavigate,
            ),
          ),
        ],
      ),
    );
  }

  void _showPerformanceStats() {
    final tracker = PerformanceTracker.instance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.speed, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Statistik Performa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Total Widget Rebuilds: ${tracker.rebuildCount}'),
            Text('• Cache Hits: ${tracker.cacheHits}'),
            Text('• Cache Misses: ${tracker.cacheMisses}'),
            Text('• Network Requests: ${tracker.networkRequests}'),
            Text('• Avg Frame Time: ${tracker.averageFrameTimeMs.toStringAsFixed(2)} ms'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

/// Widget pencarian terisolasi agar keyboard typing tidak merebuild list
class _OptimizedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _OptimizedSearchBar({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Cari pengumuman kampus...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: onClear,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
