import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/announcement.dart';

/// Card individual untuk satu pengumuman dalam daftar.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.notifications, color: Colors.white),
        ),
        title: Text(item.title),
        subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(
          item.time,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        onTap: () => context.go(item.route),
      ),
    );
  }
}
