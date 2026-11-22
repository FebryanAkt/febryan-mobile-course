import 'dart:async';
import 'package:dio/dio.dart';

/// Dio Interceptor untuk mekanisme retry otomatis dengan strategi Exponential Backoff
class PerformanceRetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  PerformanceRetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    List<Duration>? retryDelays,
  }) : retryDelays = retryDelays ??
            const [
              Duration(seconds: 1),
              Duration(seconds: 2),
              Duration(seconds: 4),
            ];

  bool _shouldRetry(DioException error) {
    // Retry jika terjadi timeout koneksi atau kegagalan server transien (500, 502, 503, 504)
    final type = error.type;
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    return false;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    var attempt = (err.requestOptions.extra['retry_attempt'] as int? ?? 0);

    if (attempt < maxRetries && _shouldRetry(err)) {
      attempt++;
      err.requestOptions.extra['retry_attempt'] = attempt;

      final delay = attempt - 1 < retryDelays.length
          ? retryDelays[attempt - 1]
          : retryDelays.last;

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }

    return handler.next(err);
  }
}
