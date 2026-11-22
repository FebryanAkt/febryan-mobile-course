import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/performance_tracker.dart';

/// Strategi Caching HTTP
enum CachePolicy {
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
  cacheOnly,
}

/// Struktur entri data cache dengan waktu kedaluwarsa (TTL)
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.ttl = const Duration(minutes: 5),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Penyimpan cache di memori (in-memory store) yang thread-safe
class InMemoryCacheStore {
  final Map<String, CacheEntry> _storage = {};

  void set(String key, dynamic data, {Duration? ttl}) {
    _storage[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(minutes: 5),
    );
  }

  CacheEntry? get(String key) {
    final entry = _storage[key];
    if (entry == null) return null;
    return entry;
  }

  bool hasValid(String key) {
    final entry = _storage[key];
    return entry != null && !entry.isExpired;
  }

  void clear() => _storage.clear();

  int get size => _storage.length;
}

/// Dio Interceptor yang mengimplementasikan strategi Caching (Stale-While-Revalidate, Cache-First, dsb.)
class PerformanceCacheInterceptor extends Interceptor {
  final InMemoryCacheStore cacheStore;
  final CachePolicy defaultPolicy;
  final Duration defaultTtl;

  PerformanceCacheInterceptor({
    InMemoryCacheStore? cacheStore,
    this.defaultPolicy = CachePolicy.staleWhileRevalidate,
    this.defaultTtl = const Duration(minutes: 5),
  }) : cacheStore = cacheStore ?? InMemoryCacheStore();

  String _buildCacheKey(RequestOptions options) {
    return '${options.method}:${options.baseUrl}${options.path}?${jsonEncode(options.queryParameters)}';
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Hanya lakukan caching untuk HTTP GET
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final key = _buildCacheKey(options);
    final policy = options.extra['cache_policy'] as CachePolicy? ?? defaultPolicy;
    final cached = cacheStore.get(key);

    switch (policy) {
      case CachePolicy.cacheFirst:
        if (cached != null && !cached.isExpired) {
          PerformanceTracker.instance.recordCacheHit(key);
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cached.data,
              statusCode: 200,
              headers: Headers.fromMap({
                'x-cache': ['HIT-CACHE-FIRST'],
              }),
            ),
          );
        }
        PerformanceTracker.instance.recordCacheMiss(key);
        return handler.next(options);

      case CachePolicy.staleWhileRevalidate:
        if (cached != null) {
          PerformanceTracker.instance.recordCacheHit(key);
          // Bila data cache tersedia, selesaikan response segera demi kecepatan UI
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cached.data,
              statusCode: 200,
              headers: Headers.fromMap({
                'x-cache': [cached.isExpired ? 'STALE' : 'HIT'],
              }),
            ),
          );
        }
        PerformanceTracker.instance.recordCacheMiss(key);
        return handler.next(options);

      case CachePolicy.cacheOnly:
        if (cached != null) {
          PerformanceTracker.instance.recordCacheHit(key);
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cached.data,
              statusCode: 200,
              headers: Headers.fromMap({
                'x-cache': ['HIT-CACHE-ONLY'],
              }),
            ),
          );
        }
        PerformanceTracker.instance.recordCacheMiss(key);
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: 'Cache-Only policy: Data tidak ditemukan di cache lokal.',
          ),
        );

      case CachePolicy.networkFirst:
        PerformanceTracker.instance.recordNetworkRequest(options.path);
        return handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      final key = _buildCacheKey(response.requestOptions);
      cacheStore.set(key, response.data, ttl: defaultTtl);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Pada strategi network-first / stale-while-revalidate,
    // bila jaringan gagal, gunakan cache sebagai fallback darurat
    final key = _buildCacheKey(err.requestOptions);
    final cached = cacheStore.get(key);

    if (cached != null) {
      PerformanceTracker.instance.recordCacheHit(key);
      return handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          data: cached.data,
          statusCode: 200,
          headers: Headers.fromMap({
            'x-cache': ['FALLBACK-ON-ERROR'],
          }),
        ),
      );
    }

    handler.next(err);
  }
}
