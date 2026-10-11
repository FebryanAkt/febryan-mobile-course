import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'auth_repository.dart';
import 'token_store.dart';

/// Buat Dio client dengan auto-refresh JWT.
/// Base URL tidak di-hardcode — diambil dari konstanta terpisah
/// sehingga mudah diganti per lingkungan (dev / staging / prod).
Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(
    BaseOptions(
      // TODO: ganti dengan env-based config atau dart-define saat produksi
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://example-campus-api.test',
      ),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final refresh = await store.readRefresh();
          if (refresh == null) return handler.next(e);
          try {
            final renewed = await auth.refresh(refresh);
            await store.save(access: renewed, refresh: refresh);
            final retry = await dio.fetch<dynamic>(
              e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
            );
            return handler.resolve(retry);
          } catch (_) {
            // Refresh gagal → paksa login ulang
            await store.clear();
          }
        }
        handler.next(e);
      },
    ),
  );

  return dio;
}

/// Riverpod provider untuk Dio client yang sudah dikonfigurasi.
final apiClientProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final auth = ref.watch(authRepositoryProvider);
  return buildApiClient(store, auth);
});