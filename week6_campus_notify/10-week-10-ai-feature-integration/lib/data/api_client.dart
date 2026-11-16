import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'auth_repository.dart';
import 'token_store.dart';

/// Creates a Dio client that retries an unauthorized request once after refresh.
Dio buildApiClient(
  SessionTokenStore store,
  AuthRepository auth, {
  Future<void> Function()? onSessionExpired,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://example-campus-api.test',
      ),
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;

  const retryKey = 'retried_after_refresh';
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        // A second 401 means the one allowed retry failed; end the session.
        if (error.requestOptions.extra[retryKey] == true) {
          await _expireSession(store, onSessionExpired);
          return handler.next(error);
        }

        final refresh = await store.readRefresh();
        if (refresh == null || refresh.trim().isEmpty) {
          await _expireSession(store, onSessionExpired);
          return handler.next(error);
        }

        late final String renewedAccess;
        try {
          renewedAccess = await auth.refresh(refresh);
        } catch (_) {
          await _expireSession(store, onSessionExpired);
          return handler.next(error);
        }

        await store.save(access: renewedAccess, refresh: refresh);
        final extra = Map<String, dynamic>.from(error.requestOptions.extra)
          ..[retryKey] = true;
        final retryRequest = error.requestOptions.copyWith(
          headers: {
            ...error.requestOptions.headers,
            'Authorization': 'Bearer $renewedAccess',
          },
          extra: extra,
        );
        try {
          final response = await dio.fetch<dynamic>(retryRequest);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          // A retry 401 has already expired the session in its own handler.
          return handler.next(retryError);
        }
      },
    ),
  );

  return dio;
}

Future<void> _expireSession(
  SessionTokenStore store,
  Future<void> Function()? onSessionExpired,
) async {
  await store.clear();
  await onSessionExpired?.call();
}

final apiClientProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final auth = ref.watch(authRepositoryProvider);
  return buildApiClient(
    store,
    auth,
    onSessionExpired: () => ref.read(authStateProvider.notifier).logout(),
  );
});
