import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/data/api_client.dart';
import 'package:week6_campus_notify/data/auth_repository.dart';
import 'package:week6_campus_notify/data/token_store.dart';
import 'package:week6_campus_notify/routes.dart';

void main() {
  test('routeFromMessage parses announcement payloads safely', () {
    expect(
      routeFromMessage({'route': '/pengumuman/3', 'id': '3'}),
      '/pengumuman/3',
    );
    expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    expect(routeFromMessage({}), AppRoutes.root);
    expect(routeFromMessage({'route': ''}), AppRoutes.root);
  });

  test(
    '401 refreshes once and retries the request with the new access token',
    () async {
      final store = _MemoryTokenStore()
        ..access = 'expired-access'
        ..refresh = 'valid-refresh';
      final auth = _FakeAuthRepository();
      final adapter = _SequenceAdapter([401, 200]);
      final dio = buildApiClient(store, auth, adapter: adapter);

      final response = await dio.get<Map<String, dynamic>>('/protected');

      expect(response.statusCode, 200);
      expect(auth.refreshCalls, 1);
      expect(adapter.requestCount, 2);
      expect(store.access, 'renewed-access');
      dio.close();
    },
  );

  test(
    'dead refresh token clears session and invokes logout callback',
    () async {
      final store = _MemoryTokenStore()
        ..access = 'expired-access'
        ..refresh = 'revoked-refresh';
      final auth = _FakeAuthRepository()..shouldFailRefresh = true;
      final adapter = _SequenceAdapter([401]);
      var logoutCalls = 0;
      final dio = buildApiClient(
        store,
        auth,
        adapter: adapter,
        onSessionExpired: () async {
          logoutCalls++;
        },
      );

      await expectLater(
        dio.get<void>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(auth.refreshCalls, 1);
      expect(adapter.requestCount, 1);
      expect(store.access, isNull);
      expect(store.refresh, isNull);
      expect(logoutCalls, 1);
      dio.close();
    },
  );
}

class _MemoryTokenStore implements SessionTokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class _FakeAuthRepository extends AuthRepository {
  int refreshCalls = 0;
  bool shouldFailRefresh = false;

  @override
  Future<String> refresh(String refreshToken) async {
    refreshCalls++;
    if (shouldFailRefresh) throw Exception('Refresh token revoked');
    return 'renewed-access';
  }
}

class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this.statuses);

  final List<int> statuses;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = requestCount++;
    final status =
        statuses[index < statuses.length ? index : statuses.length - 1];
    final body = status == 200 ? '{"ok":true}' : '{"error":"unauthorized"}';
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
