import 'package:flutter/material.dart';
import '../../core/performance_tracker.dart';
import '../../data/cached_announcement_repository.dart';
import 'optimized_image.dart';

/// Card Pengumuman dengan Optimasi Maksimal:
/// 1. `const` constructor dan pemecahan sub-widget modular.
/// 2. `RepaintBoundary` untuk mengisolasi render paint layer saat scroll.
/// 3. Tear-off callback navigation tanpa anonymous function closure.
class OptimizedAnnouncementCard extends StatelessWidget {
  final AnnouncementItem item;
  final ValueChanged<String>? onTap;

  const OptimizedAnnouncementCard({
    super.key,
    required this.item,
    this.onTap,
  });

  void _handleTap() {
    onTap?.call(item.route);
  }

  @override
  Widget build(BuildContext context) {
    // Catat build untuk pemantauan rebuild berlebih
    PerformanceTracker.instance.recordRebuild('OptimizedAnnouncementCard_${item.id}');

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OptimizedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 56,
                  height: 56,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardHeader(title: item.title, time: item.time),
                      const SizedBox(height: 6),
                      _CardBody(body: item.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sub-widget terisolasi untuk header (Title & Time)
class _CardHeader extends StatelessWidget {
  final String title;
  final String time;

  const _CardHeader({
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// Sub-widget terisolasi untuk snippet body
class _CardBody extends StatelessWidget {
  final String body;

  const _CardBody({required this.body});

  @override
  Widget build(BuildContext context) {
    return Text(
      body,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade700,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
