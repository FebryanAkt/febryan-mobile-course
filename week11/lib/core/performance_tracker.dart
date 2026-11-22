import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Telemetri dan pelacak performa ringan untuk mencatat metrik build,
/// latency frame, dan cache hit/miss pada mode Profile dan Debug.
class PerformanceTracker {
  PerformanceTracker._();
  static final PerformanceTracker instance = PerformanceTracker._();

  int _rebuildCount = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _networkRequests = 0;
  final List<double> _frameTimesMs = [];

  int get rebuildCount => _rebuildCount;
  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;
  int get networkRequests => _networkRequests;
  List<double> get frameTimesMs => List.unmodifiable(_frameTimesMs);

  /// Catat event rebuild widget untuk analisis overhead
  void recordRebuild(String widgetName) {
    _rebuildCount++;
    if (kDebugMode) {
      developer.log(
        'Widget Rebuilt: $widgetName (Total rebuilds: $_rebuildCount)',
        name: 'PerformanceTracker',
      );
    }
  }

  /// Catat event cache hit
  void recordCacheHit(String key) {
    _cacheHits++;
    developer.log('Cache HIT for key: $key', name: 'PerformanceTracker');
  }

  /// Catat event cache miss
  void recordCacheMiss(String key) {
    _cacheMisses++;
    developer.log('Cache MISS for key: $key', name: 'PerformanceTracker');
  }

  /// Catat pemanggilan request jaringan
  void recordNetworkRequest(String url) {
    _networkRequests++;
    developer.log('Network Request: $url', name: 'PerformanceTracker');
  }

  /// Catat waktu frame rendering
  void recordFrameTime(double durationMs) {
    _frameTimesMs.add(durationMs);
    // Pertahankan maksimal 100 sampel terakhir
    if (_frameTimesMs.length > 100) {
      _frameTimesMs.removeAt(0);
    }
  }

  /// Hitung rata-rata frame time (target: < 16.67 ms untuk 60 FPS)
  double get averageFrameTimeMs {
    if (_frameTimesMs.isEmpty) return 0.0;
    final sum = _frameTimesMs.reduce((a, b) => a + b);
    return sum / _frameTimesMs.length;
  }

  /// Reset semua metrik untuk pengujian terisolasi
  void reset() {
    _rebuildCount = 0;
    _cacheHits = 0;
    _cacheMisses = 0;
    _networkRequests = 0;
    _frameTimesMs.clear();
  }
}
