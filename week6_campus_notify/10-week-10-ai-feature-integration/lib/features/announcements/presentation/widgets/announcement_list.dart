import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/announcement_providers.dart';
import 'announcement_card.dart';
import 'announcement_empty_state.dart';

/// Menampilkan list pengumuman yang reaktif terhadap query pencarian.
class AnnouncementList extends ConsumerWidget {
  const AnnouncementList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnnouncements = ref.watch(filteredAnnouncementsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return asyncAnnouncements.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Gagal memuat pengumuman: $err'),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return AnnouncementEmptyState(query: currentQuery);
        }
        return Column(
          children: items.map((item) => AnnouncementCard(item: item)).toList(),
        );
      },
    );
  }
}
