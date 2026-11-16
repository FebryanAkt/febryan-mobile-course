import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/announcement_providers.dart';

/// Search bar widget yang terhubung langsung ke SearchQueryNotifier di Riverpod.
class AnnouncementSearchBar extends ConsumerWidget {
  const AnnouncementSearchBar({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari pengumuman...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).clear();
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (val) {
        ref.read(searchQueryProvider.notifier).updateQuery(val);
      },
    );
  }
}
