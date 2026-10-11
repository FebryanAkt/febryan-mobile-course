// ============================================================
// push_service.dart
// Semua fungsi di file ini adalah TOP-LEVEL (bukan method kelas)
// sehingga dapat dipanggil oleh Dart isolate background FCM.
//
// ANDROID 13+ vs iOS:
//   - Android 13+ (API 33): requestPermission() wajib untuk POST_NOTIFICATIONS.
//     Sebelum Android 13, izin otomatis diberikan saat install.
//   - iOS: Dialog izin selalu muncul pertama kali; tanpa grant, token tetap
//     bisa didapat tetapi notifikasi tidak tampil ke pengguna.
//
// LARANGAN AKSES BuildContext:
//   - firebaseMessagingBackgroundHandler() berjalan di Dart isolate terpisah
//     tanpa Flutter widget tree, sehingga TIDAK BOLEH mengakses BuildContext,
//     Navigator, atau Provider manapun.
//   - initLocalNotifications(), listenForeground(), handleTerminated() pun
//     tidak menerima BuildContext — navigasi dilakukan lewat callback `go`
//     yang disediakan pemanggil (main.dart).
// ============================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// --------------- Plugin singleton ---------------
final _local = FlutterLocalNotificationsPlugin();

// --------------- Channel Android ---------------
const _kChannelId = 'pengumuman';
const _kChannelName = 'Pengumuman Kampus';
const _kChannelDesc = 'Notifikasi pengumuman resmi kampus';

// ---------------------------------------------------------------
// BACKGROUND HANDLER — HARUS fungsi top-level (bukan method kelas)
// @pragma diperlukan agar tree-shaker tidak menghapus fungsi ini
// pada build release, karena dipanggil dari native layer.
// ---------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jaga agar pekerjaan background tetap ringan.
  // JANGAN akses BuildContext, Navigator, atau Riverpod di sini.
  // Navigasi akan ditangani oleh onMessageOpenedApp / getInitialMessage
  // saat pengguna mengetuk notifikasi.
  debugPrint(
    '[BGHandler] FCM id=${message.messageId} '
    'route=${message.data["route"]}',
  );
}

/// Daftarkan background handler ke FirebaseMessaging.
/// Dipanggil sebelum runApp().
void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ---------------------------------------------------------------
// LOCAL NOTIFICATIONS — inisialisasi satu kali saat startup
// flutter_local_notifications ^22.x menggunakan named parameters
// ---------------------------------------------------------------
Future<void> initLocalNotifications() async {
  // Android: gunakan ikon dari res/mipmap
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS / macOS: aktifkan alert, badge, dan sound
  // [BERBEDA iOS] Tidak perlu buat channel; sistem iOS mengelola sendiri.
  const darwin = DarwinInitializationSettings(
    requestAlertPermission: false, // sudah diminta lewat FirebaseMessaging
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // v22+: initialize() menggunakan named parameter 'settings'
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: darwin),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground → simpan payload untuk diproses router.
      pendingDeepLink = response.payload;
    },
  );

  // Cek apakah app diluncurkan dari tap notifikasi lokal (state Terminated).
  final launchDetails = await _local.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    pendingDeepLink = launchDetails?.notificationResponse?.payload;
  }

  // [BERBEDA Android] Buat notification channel; iOS tidak menggunakan ini.
  const channel = AndroidNotificationChannel(
    _kChannelId,
    _kChannelName,
    description: _kChannelDesc,
    importance: Importance.high,
  );
  await _local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

// ---------------------------------------------------------------
// Global pending deep-link dari tap notifikasi lokal
// ---------------------------------------------------------------
String? pendingDeepLink;

// ---------------------------------------------------------------
// Helper: kembalikan '/' jika route null atau kosong
// ---------------------------------------------------------------
String safeRoute(String? route) =>
    (route == null || route.trim().isEmpty) ? '/' : route;

// ---------------------------------------------------------------
// FOREGROUND LISTENER
// Foreground FCM TIDAK menampilkan banner secara otomatis —
// kita HARUS tampilkan manual lewat flutter_local_notifications.
// ---------------------------------------------------------------
void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = safeRoute(message.data['route'] as String?);

    // [BERBEDA Android] AndroidNotificationDetails wajib untuk menyebut channel.
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    // [BERBEDA iOS] DarwinNotificationDetails mengatur banner secara mandiri.
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // v22+: show() menggunakan named parameters
    await _local.show(
      id: message.hashCode, // ID unik agar tidak overwrite banner sebelumnya
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: route,
    );
  });

  // STATE BACKGROUND → tap → app dibuka (bukan dari mati total)
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(safeRoute(message.data['route'] as String?));
  });
}

// ---------------------------------------------------------------
// TERMINATED STATE HANDLER
// Dipanggil setelah router siap (dalam addPostFrameCallback).
// ---------------------------------------------------------------
Future<void> handleTerminated(void Function(String route) go) async {
  // FCM: app diluncurkan dari tap notifikasi sistem (state Terminated)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    go(safeRoute(initialMessage.data['route'] as String?));
    return; // Prioritaskan FCM; hindari navigasi ganda
  }

  // Local notification: app diluncurkan dari tap banner lokal
  final localRoute = pendingDeepLink;
  pendingDeepLink = null;
  if (localRoute != null) {
    go(safeRoute(localRoute));
  }
}
