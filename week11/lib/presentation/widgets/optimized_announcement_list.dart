import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/performance_tracker.dart';
import '../providers/optimized_announcement_providers.dart';
import 'optimized_announcement_card.dart';

/// Daftar Pengumuman Teroptimasi:
/// 1. Menggunakan `ListView.builder` lazy rendering untuk mendaur ulang elemen viewport.
/// 2. Integrasi `ScrollController` listener untuk infinite scrolling pagination otomatis.
/// 3. Pemantauan state melalui `select` sehingga loader footer tidak memicu rebuild list item.
class OptimizedAnnouncementList extends ConsumerStatefulWidget {
  final ValueChanged<String>? onSelectRoute;

  const OptimizedAnnouncementList({
    super.key,
    this.onSelectRoute,
  });

  @override
  ConsumerState<OptimizedAnnouncementList> createState() =>
      _OptimizedAnnouncementListState();
}

class _OptimizedAnnouncementListState
    extends ConsumerState<OptimizedAnnouncementList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (mounted) {
        ref.read(paginatedAnnouncementsProvider.notifier).loadInitialPage();
      }
    });
  }

  @override
  void dispose() {
    // Cegah memory leak: selalu dispose ScrollController
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Picu pemuatan halaman berikutnya bila sisa scroll <= 200 pixel dari bawah
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedAnnouncementsProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    PerformanceTracker.instance.recordRebuild('OptimizedAnnouncementList_build');

    final items = ref.watch(filteredOptimizedAnnouncementsProvider);
    // Hanya pantau flag hasMore dan isLoading untuk indikator pagination bawah
    final hasMore = ref.watch(
      paginatedAnnouncementsProvider.select((s) => s.hasMore),
    );
    final isLoading = ref.watch(
      paginatedAnnouncementsProvider.select((s) => s.isLoading),
    );

    if (items.isEmpty && isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.search_off, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Tidak ada pengumuman yang sesuai',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(paginatedAnnouncementsProvider.notifier)
            .loadInitialPage();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final item = items[index];
          return OptimizedAnnouncementCard(
            key: ValueKey(item.id),
            item: item,
            onTap: widget.onSelectRoute,
          );
        },
      ),
    );
  }
}
