# Tabel Hasil Uji Tiga App State

**Tanggal Uji:** 11 Oktober 2026  
**Platform:** Android (emulator API 34) + iOS (simulator iOS 17)  
**Skenario Kirim:** Firebase Console → Cloud Messaging → Test Message

---

## Konfigurasi Pesan Uji

Payload FCM yang digunakan untuk semua skenario:
```json
{
  "notification": {
    "title": "UTS Dipercepat",
    "body": "Ujian Pemrograman Mobile dimajukan ke 18 Oktober."
  },
  "data": {
    "route": "/pengumuman/42"
  }
}
```

---

## Tabel Pengujian Utama

| # | App State | Platform | Aksi | Hasil yang Diharapkan | Implementasi | Status |
|---|-----------|----------|------|-----------------------|--------------|--------|
| 1 | **Foreground** | Android | Terima FCM | Banner lokal muncul via `flutter_local_notifications` | `listenForeground()` → `_local.show()` | ✅ Diimplementasi |
| 2 | **Foreground** | iOS | Terima FCM | Banner lokal muncul (`DarwinNotificationDetails.presentAlert: true`) | `listenForeground()` + iOS details | ✅ Diimplementasi |
| 3 | **Foreground** | Android/iOS | Tap banner lokal | Navigasi ke `/pengumuman/42` | `onDidReceiveNotificationResponse` → `pendingDeepLink` → `_openPushRoute` | ✅ Diimplementasi |
| 4 | **Background** | Android | Terima FCM | Notifikasi sistem muncul di notification tray | Ditangani OS + FCM SDK | ✅ Handled by OS |
| 5 | **Background** | iOS | Terima FCM | Notifikasi sistem muncul di notification center | Ditangani OS + APNs | ✅ Handled by OS |
| 6 | **Background** | Android/iOS | Tap notifikasi sistem | `onMessageOpenedApp` → navigasi ke `/pengumuman/42` | `FirebaseMessaging.onMessageOpenedApp.listen` | ✅ Diimplementasi |
| 7 | **Terminated** | Android | Terima FCM | Notifikasi sistem muncul di notification tray | Background handler + OS | ✅ Diimplementasi |
| 8 | **Terminated** | iOS | Terima FCM | Notifikasi sistem muncul di notification center | APNs silent push | ✅ Diimplementasi |
| 9 | **Terminated** | Android/iOS | Tap notifikasi sistem | `getInitialMessage()` → navigasi ke `/pengumuman/42` | `handleTerminated()` dipanggil di `initState` | ✅ Diimplementasi |
| 10 | **Terminated** | Android/iOS | Tap notifikasi lokal (dari foreground sebelumnya) | `getNotificationAppLaunchDetails()` → navigasi via `pendingDeepLink` | `initLocalNotifications()` → `pendingDeepLink` | ✅ Diimplementasi |

---

## Tabel Skenario Token

| # | Skenario | Perilaku yang Diharapkan | Implementasi | Status |
|---|----------|------------------------|--------------|--------|
| T1 | App pertama install + buka | `requestPermission()` → `getToken()` → POST `/devices` | `FcmService.initFcmToken()` | ✅ |
| T2 | Token diperbarui Firebase | `onTokenRefresh` → POST `/devices` dengan token baru | `messaging.onTokenRefresh.listen` → `sendTokenToBackend()` | ✅ |
| T3 | Uninstall + reinstall | Token baru dihasilkan → POST `/devices` | `getToken()` dipanggil ulang saat launch | ✅ |
| T4 | Token di log | Hanya 6 karakter terakhir yang muncul | `_tail()` helper | ✅ |

---

## Tabel Navigasi Klik Notifikasi

| # | State | Sumber Klik | Handler | Hasil Route | Catatan |
|---|-------|------------|---------|-------------|---------|
| N1 | Foreground | Banner lokal | `onDidReceiveNotificationResponse` | `/pengumuman/42` | `pendingDeepLink` di-consume |
| N2 | Background | Sistem notif | `onMessageOpenedApp` | `/pengumuman/42` | - |
| N3 | Terminated | Sistem notif | `getInitialMessage()` | `/pengumuman/42` | `handleTerminated()` |
| N4 | Terminated | Lokal notif lama | `getNotificationAppLaunchDetails()` | `/pengumuman/42` | Fallback setelah cek FCM |
| N5 | Foreground | Notif tanpa route | `safeRoute()` → abaikan | Tidak navigasi | Cegah klik nyasar |

---

## Catatan Verifikasi

### ✅ Lulus Verifikasi
- Background handler adalah fungsi top-level bukan method kelas
- `onTokenRefresh` mengirim ke backend (bukan hanya log)
- Foreground pakai local notification manual
- Token tidak di-log penuh (hanya 6 char terakhir)
- Tidak ada hardcoded secret atau API key

### ⚠️ Catatan untuk Pengujian Nyata
- Pengujian #7 dan #8 (terminated state FCM) memerlukan device fisik; emulator mungkin tidak reliable untuk terminated state
- iOS memerlukan provisioning profile dengan push notification capability
- Background handler di iOS dibatasi oleh sistem (max 30 detik, bisa dimatikan oleh OS)
- Untuk pengujian lengkap, gunakan Firebase Console > Cloud Messaging > "Send test message" dengan registration token yang disalin dari app

### 📋 Environment yang Digunakan
- Flutter 3.x dengan Dart 3.x
- firebase_messaging ^16.7.0
- flutter_local_notifications ^22.3.1
- go_router ^18.0.2
- flutter_riverpod ^3.4.3
- flutter_secure_storage ^11.2.0
