# Daftar Perbaikan Manual dari Draft AI

**Tanggal:** 11 Oktober 2026  
**Reviewer:** Developer (verifikasi terhadap AI Verification Checklist)

---

## Perbaikan #1 — `sendTokenToBackend`: Stub → Real HTTP POST

**File:** `lib/services/fcm_service.dart`

**Sebelum (AI):**
```dart
static Future<void> sendTokenToBackend(String token) async {
  final platformName = Platform.isAndroid ? 'android' : 'ios';
  // TODO: Ganti blok ini dengan panggilan HTTP Dio
  debugPrint('-->  Mengirim FCM Token ke Backend: $token (Platform: $platformName)');
}
```

**Sesudah (Manual):**
```dart
static Future<void> sendTokenToBackend(Dio dio, String token) async {
  final platform = Platform.isAndroid ? 'android' : 'ios';
  try {
    await dio.post<void>(
      '/devices',
      data: {'fcm_token': token, 'platform': platform},
    );
  } on DioException catch (e) {
    // Hanya log status code — JANGAN log token penuh
    debugPrint('[FcmService] Gagal kirim token: HTTP ${e.response?.statusCode}');
  }
}
```

**Alasan:** Token basi adalah bug FCM paling mahal. Jika token berganti tapi backend tidak tahu, semua pesan selanjutnya hilang tanpa error di sisi pengirim. `onTokenRefresh` memanggil fungsi ini, sehingga HARUS benar-benar HTTP POST.

---

## Perbaikan #2 — Injeksi Dio ke `initFcmToken`

**File:** `lib/services/fcm_service.dart`

**Sebelum (AI):**
```dart
static Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async { ... }
```

**Sesudah (Manual):**
```dart
static Future<void> initFcmToken({
  required Dio dio,
  required Future<void> Function(String token) onToken,
}) async { ... }
```

**Alasan:** Tanpa Dio yang dikonfigurasi (dengan Bearer token dari `TokenStore`), tidak bisa membuat HTTP request yang terautentikasi. Dio diambil dari `apiClientProvider` Riverpod agar tidak perlu singleton global yang sulit dites.

---

## Perbaikan #3 — Masking Token di Log

**File:** `lib/services/fcm_service.dart`

**Sebelum (AI):**
```dart
debugPrint('FCM Registration Token: $token');       // ❌ Full token
debugPrint('FCM Token Refreshed: $newToken');        // ❌ Full token
debugPrint('-->  Mengirim FCM Token ke Backend: $token'); // ❌ Full token
```

**Sesudah (Manual):**
```dart
debugPrint('[FcmService] Token diperoleh: ...${_tail(token)}');    // ✅ 6 char
debugPrint('[FcmService] Token diperbarui: ...${_tail(newToken)}'); // ✅ 6 char

static String _tail(String token) =>
    token.length > 6 ? token.substring(token.length - 6) : token;
```

**Alasan:** FCM token adalah credential perangkat. Log penuh memungkinkan siapapun dengan akses logcat mengirim notifikasi palsu ke perangkat. Keputusan ini berbeda dari saran AI yang mencetak token penuh "untuk debugging".

---

## Perbaikan #4 — Tambah `DarwinNotificationDetails` di Foreground

**File:** `lib/messaging/push_service.dart`

**Sebelum (AI):**
```dart
const NotificationDetails(android: androidDetails)
// iOS tidak ditangani → banner tidak muncul di iOS foreground
```

**Sesudah (Manual):**
```dart
const iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
);
const NotificationDetails(android: androidDetails, iOS: iosDetails)
```

**Alasan:** iOS foreground notification memerlukan `presentAlert: true` secara eksplisit. Tanpa ini, suara dan badge mungkin muncul tapi banner tidak tampil — pengalaman pengguna buruk.

---

## Perbaikan #5 — Ganti `MaterialApp` + `navigatorKey` Manual dengan `GoRouter`

**File:** `lib/main.dart`

**Sebelum (AI):**
```dart
MaterialApp(
  navigatorKey: _navigatorKey,
  home: const MyHomePage(title: 'Campus Notify'),
)
// navigasi dengan MaterialPageRoute manual dari callback
_navigatorKey.currentState?.push(MaterialPageRoute(...))
```

**Sesudah (Manual):**
```dart
// routerProvider dengan GoRouter + auth redirect
MaterialApp.router(routerConfig: router)
// navigasi dari callback FCM
ctx.go(route) // menggunakan GoRouter
```

**Alasan:** Stack sudah include `go_router`. Navigasi manual dengan `MaterialPageRoute` dari FCM callback menyebabkan klik nyasar (stack tidak konsisten, `back` button membawa ke halaman tak terduga). `GoRouter` dengan `context.go()` me-reset stack secara deterministik.

---

## Perbaikan #6 — Auth Redirect di GoRouter

**File:** `lib/main.dart`

**Sebelum (AI):** Tidak ada redirect — pengguna bisa akses `/pengumuman/:id` dari tap notifikasi tanpa login.

**Sesudah (Manual):**
```dart
redirect: (context, state) {
  if (authAsync.isLoading) return null;
  final isLoggedIn = authAsync.valueOrNull ?? false;
  if (!isLoggedIn && state.matchedLocation != '/login') return '/login';
  if (isLoggedIn && state.matchedLocation == '/login') return '/home';
  return null;
},
```

**Alasan:** Keamanan dasar — notifikasi dari background/terminated bisa membuka deep link langsung ke konten. Tanpa guard, konten terlindungi terekspos tanpa autentikasi. GoRouter redirect adalah tempat yang tepat karena dijalankan sebelum render.

---

## Perbaikan #7 — `safeRoute()` Helper untuk Mencegah Navigasi ke `'/'`

**File:** `lib/messaging/push_service.dart`

**Sebelum (AI):**
```dart
go(message.data['route'] as String? ?? '/');
// Jika route adalah '/', navigasi ke root tanpa makna
```

**Sesudah (Manual):**
```dart
String safeRoute(String? route) =>
    (route == null || route.trim().isEmpty) ? '/' : route;

// Di _openPushRoute (main.dart):
void _openPushRoute(String route) {
  if (route == '/' || route.isEmpty) return; // Abaikan jika tidak ada route
  ...
}
```

**Alasan:** Notifikasi tanpa `data.route` (misalnya notifikasi informational saja) seharusnya tidak memaksa navigasi. Klik nyasar ke `'/'` menyebabkan pengguna kehilangan posisi mereka di app.

---

## Perbaikan #8 — Isi Halaman yang Kosong

**Files:** `login_page.dart`, `home_page.dart`, `announcement_page.dart`

AI tidak mengisi konten ketiga halaman ini. Halaman dibuat lengkap secara manual dengan:
- `LoginPage`: Form email/password dengan validasi, loading state, error handling
- `HomePage`: Token display (6 char), topic subscription toggle, riwayat notifikasi
- `AnnouncementPage`: Detail pengumuman dengan safe back navigation

---

## Perbaikan #9 — Base URL dari `dart-define` bukan Hardcode

**File:** `lib/data/api_client.dart`

**Sebelum (AI):**
```dart
baseUrl: 'https://example-campus-api.test'  // ❌ Hardcoded
```

**Sesudah (Manual):**
```dart
baseUrl: const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://example-campus-api.test',
)
```

**Alasan:** URL backend tidak boleh di-commit ke source code. Dengan `dart-define`, URL diset saat build:
```bash
flutter run --dart-define=API_BASE_URL=https://api.kampus.ac.id
```

---

## Ringkasan Keputusan Teknis (berbeda dari saran AI)

| Keputusan | Saran AI | Keputusan Final | Alasan |
|-----------|---------|-----------------|--------|
| Navigasi | `MaterialPageRoute` manual | `GoRouter context.go()` | Stack konsisten, no klik nyasar |
| Token log | Log penuh | 6 karakter terakhir | Keamanan credential |
| sendTokenToBackend | TODO stub | Real Dio POST | Token basi = pesan hilang |
| Dio injection | Singleton/static | Parameter injection | Testable, no global state |
| iOS foreground | Tidak ditangani | `DarwinNotificationDetails` | Banner muncul di iOS |
| Auth guard | Tidak ada | GoRouter redirect | Konten terlindungi |
