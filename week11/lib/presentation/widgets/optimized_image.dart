import 'package:flutter/material.dart';

/// Komponen Gambar Berkinerja Tinggi:
/// Menggunakan `memCacheWidth` dan `memCacheHeight` untuk mencegah decode beresolusi penuh
/// yang memboroskan memori raster thread / GPU.
class OptimizedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // Batasi ukuran buffer decode di memori sesuai ukuran tampilan (DPI aware)
        cacheWidth: (width * 2).toInt(),
        cacheHeight: (height * 2).toInt(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildLoadingShimmer();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.article_outlined, color: Colors.deepPurple),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
    );
  }
}
