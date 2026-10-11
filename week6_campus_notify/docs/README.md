# Campus Notify — Dokumentasi Teknis

**Proyek:** Week 6 Campus Notification App  
**Stack:** Flutter · Firebase Messaging · flutter_local_notifications · GoRouter · Riverpod · flutter_secure_storage

---

## AI Verification Checklist

### ✅ 1. Background Handler Top-Level dengan `@pragma`

**Status: LULUS**

```dart
// lib/messaging/push_service.dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[BGHandler] FCM id=${message.messageId}');
}
```

- Fungsi **top-level** (bukan method kelas) ✅  
- `@pragma('vm:entry-point')` mencegah tree-shaker menghapus fungsi di release build ✅  
- Tidak mengakses `BuildContext`, `Navigator`, atau `Riverpod` ✅

---

### ✅ 2. `onTokenRefresh` Benar-Benar Kirim ke Backend

**Status: LULUS** (setelah perbaikan manual)

```dart
// lib/services/fcm_service.dart
messaging.onTokenRefresh.listen((newToken) async {
  debugPrint('[FcmService] Token diperbarui: ...${_tail(newToken)}');
  await onToken(newToken); // ← memanggil sendTokenToBackend(dio, newToken)
});

static Future<void> sendTokenToBackend(Dio dio, String token) async {
  await dio.post<void>('/devices', data: {'fcm_token': token, 'platform': platform});
}
```

**Alasan teknis:** Token FCM bisa berubah saat:
- Uninstall & reinstall app
- User melakukan clear data
- Firebase merotasi token secara periodik
- Restore dari backup

Jika backend tidak diperbarui → pesan dikirim ke token lama → **silent failure** (FCM tidak error, tapi pesan tidak terkirim).

---

### ✅ 3. Foreground Memakai Local Notification Manual

**Status: LULUS**

```dart
// lib/messaging/push_service.dart
void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    // FCM foreground TIDAK menampilkan banner otomatis
    // → WAJIB tampilkan manual via flutter_local_notifications
    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'Pengumuman',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: route,
    );
  });
}
```

**Kenapa perlu?** Firebase SDK pada foreground memanggil `onMessage` tapi **tidak** menampilkan banner sistem. Tanpa `_local.show()`, pengguna tidak melihat notifikasi sama sekali saat app terbuka.

---

### ✅ 4. Ketiga State Navigasi ke Route yang Benar

**Status: LULUS**

| State | Handler | Route Payload Diambil Dari |
|-------|---------|--------------------------|
| Foreground | `onDidReceiveNotificationResponse` | `response.payload` |
| Background | `onMessageOpenedApp` | `message.data['route']` |
| Terminated | `getInitialMessage()` | `message.data['route']` |

Lihat [TEST_RESULTS.md](./TEST_RESULTS.md) untuk tabel lengkap.

---

### ✅ 5. Token/Secret Tidak Hardcode dan Tidak Di-Log Penuh

**Status: LULUS** (setelah perbaikan manual)

- Token FCM: hanya 6 karakter terakhir yang di-log
- Base URL: menggunakan `dart-define` environment variable
- Auth token (JWT): disimpan di `FlutterSecureStorage`, tidak pernah di-log
- Tidak ada API key atau secret yang di-commit ke source code

---

## Lifecycle Token FCM

```
Install App
    ↓
getToken() → Token A
    ↓
POST /devices {fcm_token: "A", platform: "android"}
    ↓
Backend menyimpan Token A
    ↓
[Firebase merotasi token / user reinstall]
    ↓
onTokenRefresh callback → Token B
    ↓
POST /devices {fcm_token: "B", platform: "android"}  ← KRITIS: HARUS terjadi!
    ↓
Backend memperbarui ke Token B
    ↓
Kirim notifikasi ke Token B → Berhasil ✅
```

**Jika `onTokenRefresh` tidak mengirim ke backend:**
```
Token A masih di backend
    ↓
Kirim notifikasi ke Token A → FCM: "registration-token-not-registered"
    ↓
Pesan hilang, tidak ada error di pengirim ← Bug paling mahal!
```

---

## Android 13+ vs iOS — Perbedaan Utama

### Permission (Izin Notifikasi)

| Aspek | Android < 13 | Android 13+ (API 33+) | iOS |
|-------|-------------|----------------------|-----|
| Izin otomatis | ✅ Ya | ❌ Tidak | ❌ Tidak |
| Runtime dialog | Tidak perlu | **Wajib** `requestPermission()` | **Wajib** `requestPermission()` |
| Jika ditolak | N/A | Notifikasi tidak tampil | Notifikasi tidak tampil |
| Token tetap ada? | N/A | ✅ Ya (tapi notif tidak tampil) | ❌ Tidak (APNs token tidak dikirim) |

### Notification Channel

| Aspek | Android | iOS |
|-------|---------|-----|
| Channel wajib | ✅ Ya (API 26+) | ❌ Tidak pakai channel |
| Kode | `createNotificationChannel()` | Tidak ada |
| Konfigurasi suara | Per-channel | Per-notifikasi |

### Foreground Notification Details

| Aspek | Android | iOS |
|-------|---------|-----|
| Class | `AndroidNotificationDetails` | `DarwinNotificationDetails` |
| Wajib channel ID | ✅ Ya | ❌ Tidak |
| `presentAlert` | N/A | Harus `true` untuk banner |

---

## Bagian yang TIDAK BOLEH Mengakses `BuildContext`

| Fungsi/Callback | Mengapa Dilarang |
|-----------------|-----------------|
| `firebaseMessagingBackgroundHandler()` | Berjalan di Dart isolate terpisah; widget tree tidak ada |
| `onTokenRefresh` listener | Bisa dipanggil kapan saja, bahkan saat widget tidak di-mount |
| `FcmService.initFcmToken()` | Static method, dipanggil sebelum `runApp` selesai |
| `FcmService.sendTokenToBackend()` | Dipanggil dari berbagai konteks, tidak boleh bergantung widget |

**Solusi:** Gunakan callback pattern (`void Function(String route) go`) yang disediakan oleh `main.dart`, bukan akses langsung ke context.

---

## Arsitektur Navigasi Notifikasi

```
FCM Message
    │
    ├── App FOREGROUND
    │       onMessage → _local.show() → banner → tap
    │                                              ↓
    │                             onDidReceiveNotificationResponse
    │                                              ↓
    │                                    pendingDeepLink = route
    │                                              ↓
    │                                    _openPushRoute(route)
    │
    ├── App BACKGROUND
    │       OS menampilkan notifikasi sistem
    │                    ↓ tap
    │       onMessageOpenedApp → _openPushRoute(route)
    │
    └── App TERMINATED
            OS menampilkan notifikasi sistem
                         ↓ tap
            getInitialMessage() → _openPushRoute(route)
            (dipanggil di handleTerminated setelah router ready)
```

---

## Struktur File

```
lib/
├── main.dart                    # Entry point, GoRouter, FCM init
├── messaging/
│   └── push_service.dart        # Background handler, local notif, listeners
├── services/
│   └── fcm_service.dart         # Token management, topic subscription
├── data/
│   ├── api_client.dart          # Dio client dengan auth interceptor
│   ├── auth_repository.dart     # Login/refresh logic
│   └── token_store.dart         # FlutterSecureStorage wrapper
├── providers/
│   └── auth_provider.dart       # Riverpod providers
└── pages/
    ├── login_page.dart          # Halaman login
    ├── home_page.dart           # Dashboard + topic management
    └── announcement_page.dart   # Detail pengumuman

docs/
├── README.md                    # Dokumentasi ini
├── AI_PROMPT.md                 # Prompt yang digunakan
├── AI_OUTPUT_INITIAL.md         # Temuan bug pada draft AI
├── MANUAL_FIXES.md              # Daftar perbaikan manual
└── TEST_RESULTS.md              # Tabel hasil uji 3 app state
```

---

## Cara Build dengan Environment Variable

```bash
# Development
flutter run --dart-define=API_BASE_URL=https://dev-api.kampus.ac.id

# Production
flutter build apk --dart-define=API_BASE_URL=https://api.kampus.ac.id

# Staging
flutter run --dart-define=API_BASE_URL=https://staging-api.kampus.ac.id
```

---

## Keputusan Final (berbeda dari saran AI)

> **Token tidak boleh di-log penuh.** AI mencetak token lengkap "untuk kemudahan debugging". Keputusan: hanya 6 char terakhir. Alasan: token adalah credential perangkat — siapapun dengan logcat access bisa mengirim notifikasi palsu ke perangkat tersebut.

> **Navigasi menggunakan GoRouter `context.go()`, bukan `MaterialPageRoute` manual.** AI menghasilkan `MaterialPageRoute` push. Keputusan: `context.go()` dari GoRouter. Alasan: konsistensi stack navigasi; `push()` menyebabkan klik nyasar saat pengguna menekan back berkali-kali.

> **`sendTokenToBackend` wajib real HTTP, bukan TODO.** AI meninggalkan stub. Keputusan: implementasi Dio POST segera. Alasan: token basi adalah bug yang tidak terlihat dari kode — backend tidak error, tapi pesan tidak sampai.
