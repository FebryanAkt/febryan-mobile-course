import 'package:flutter/material.dart';

/// Widget untuk menampilkan pesan saat daftar pengumuman kosong
/// atau pencarian tidak membuahkan hasil.
class AnnouncementEmptyState extends StatelessWidget {
  const AnnouncementEmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            query.isEmpty
                ? 'Belum ada pengumuman'
                : 'Tidak ditemukan pengumuman untuk "$query"',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
