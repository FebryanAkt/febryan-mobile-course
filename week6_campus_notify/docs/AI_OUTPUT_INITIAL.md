# Output Awal AI & Temuan

**Tanggal Review:** 11 Oktober 2026  
**File yang Dianalisis:** Kode awal sebelum perbaikan manual

---

## Apa yang Sudah Benar dari Draft AI

| # | Elemen | Status Awal |
|---|--------|-------------|
| 1 | `@pragma('vm:entry-point')` pada background handler | ✅ Sudah ada |
| 2 | Background handler adalah fungsi top-level (bukan method kelas) | ✅ Sudah benar |
| 3 | `requestPermission()` dipanggil dengan parameter lengkap | ✅ Ada di `FcmService` |
| 4 | `onTokenRefresh` memanggil callback `onToken` | ✅ Ada, tapi... |
| 5 | `subscribeToTopic('pengumuman-kampus')` | ✅ Ada |
| 6 | `flutter_local_notifications` untuk foreground | ✅ Ada |
| 7 | `getInitialMessage()` untuk terminated state | ✅ Ada |
| 8 | `pendingDeepLink` untuk local notification tap | ✅ Ada |

---

## Bug dan Masalah yang Ditemukan

### 🔴 Bug Kritis

#### Bug #1 — `sendTokenToBackend` Hanya `debugPrint` (Tidak Kirim ke Backend)
```dart
// KODE AI AWAL (fcm_service.dart)
static Future<void> sendTokenToBackend(String token) async {
  // TODO: Ganti blok ini dengan panggilan HTTP Dio/Client ke API backend kampus jika endpoint sudah siap.
  debugPrint('-->  Mengirim FCM Token ke Backend: $token (Platform: $platformName)');
}
```
**Masalah:** `onTokenRefresh` memanggil `onToken` yang memanggil `sendTokenToBackend`, tetapi fungsi ini **hanya mencetak ke log** — token tidak pernah sampai ke backend. Ini berarti saat token diperbarui Firebase (misal setelah reinstall), backend tidak tahu dan kirim notifikasi ke token lama → **pesan hilang**.

#### Bug #2 — Token Dicetak Penuh ke Log
```dart
debugPrint('FCM Registration Token: $token');  // ❌ Token penuh di log
debugPrint('FCM Token Refreshed: $newToken');   // ❌ Token penuh di log
debugPrint('-->  Mengirim FCM Token ke Backend: $token ...');  // ❌ Token penuh di log
```
**Masalah:** Token FCM adalah credential perangkat. Siapapun yang membaca logcat/Xcode console bisa menyalinnya dan mengirim notifikasi palsu ke perangkat tersebut.

#### Bug #3 — Dio Tidak Diinjeksikan ke `sendTokenToBackend`
```dart
// AI tidak menyediakan instance Dio pada FcmService
// sehingga tidak ada cara untuk melakukan HTTP request nyata
```
**Masalah:** Tanpa Dio yang dikonfigurasi dengan auth header (Bearer token), POST /devices akan gagal 401 atau tidak bisa dibuat sama sekali.

### 🟡 Masalah Desain

#### Masalah #4 — `main.dart` Tidak Menggunakan GoRouter
AI menghasilkan `MaterialApp` dengan `navigatorKey` dan `MaterialPageRoute` manual, padahal stack sudah menyertakan `go_router`. Ini menyebabkan navigasi dari notifikasi tidak konsisten dengan navigasi internal app.

#### Masalah #5 — Tidak Ada Auth Redirect
Tidak ada mekanisme redirect otomatis ke `/login` jika pengguna belum terautentikasi. Pengguna yang mengklik notifikasi dari terminated state bisa masuk ke halaman `/pengumuman/:id` tanpa login.

#### Masalah #6 — `listenForeground` dan `handleTerminated` Dipanggil Terlalu Awal
```dart
// main.dart awal
WidgetsBinding.instance.addPostFrameCallback((_) {
  listenForeground(_openPushRoute);
  handleTerminated(_openPushRoute);
});
```
Dipanggil di `addPostFrameCallback` **setelah** `runApp`, tapi `_navigatorKey.currentState` mungkin masih null karena router belum selesai mount. Untuk GoRouter, perlu dipastikan context tersedia.

#### Masalah #7 — Tidak Ada iOS `DarwinNotificationDetails` di Foreground
```dart
// Hanya Android details, iOS tidak ditangani
const NotificationDetails(android: androidDetails)
```
Pada iOS foreground, `flutter_local_notifications` memerlukan `DarwinNotificationDetails` dengan `presentAlert: true` agar banner benar-benar tampil.

#### Masalah #8 — Halaman Kosong (Login, Home, Announcement)
AI tidak mengisi ketiga file halaman yang sudah dibuat strukturnya.

### 🟢 Yang Tidak Perlu Diperbaiki

- Background handler sudah top-level dengan `@pragma` — **DITERIMA**
- `_validateTopic()` sudah baik — **DITERIMA**
- `initLocalNotifications()` sudah membuat channel Android — **DITERIMA**
- `pendingDeepLink` global untuk terminated local notification — **DITERIMA** (pola yang umum digunakan)
