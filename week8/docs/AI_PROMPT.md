# AI Prompt yang Digunakan (AI Challenge Week 6)

**Tanggal:** 11 Oktober 2026  
**Model:** Claude Sonnet (Thinking)  
**Konteks:** Flutter Campus Notification App — AI Challenge Codelab

---

## Prompt Asli

```
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.

Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')

Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

---

## Konteks Tambahan yang Diberikan

- Codebase awal sudah ada: `push_service.dart`, `fcm_service.dart`, `api_client.dart`, `auth_provider.dart`, `token_store.dart`, `auth_repository.dart`
- Halaman (login, home, announcement) masih kosong
- `main.dart` masih menggunakan `MaterialApp` biasa dengan `navigatorKey` manual
- `sendTokenToBackend` masih berupa `TODO` stub (hanya `debugPrint`)

---

## Yang Diminta AI Challenge

1. Buat draft PushService sesuai spesifikasi di atas
2. Verifikasi sendiri terhadap AI Verification Checklist
3. Dokumentasikan perbaikan manual yang dilakukan
4. Catat tabel hasil uji tiga app state
5. Jelaskan alasan teknis dari setiap keputusan
