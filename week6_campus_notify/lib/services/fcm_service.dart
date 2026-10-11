import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  /// Inisialisasi token FCM, listener pembaruan token, dan topic kampus
  static Future<void> initFcmToken({
    required Future<void> Function(String token) onToken,
  }) async {
    final messaging = FirebaseMessaging.instance;

    // 1. Minta izin notifikasi (wajib untuk Android 13+ dan iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Izin notifikasi ditolak oleh pengguna');
      return;
    }

    // 2. Ambil token saat ini dan kirim ke backend
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('FCM Registration Token: $token');
      await onToken(token);
    }

    // 3. Listener saat token berganti/diperbarui oleh Firebase
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token Refreshed: $newToken');
      await onToken(newToken);
    });

    // 4. Berlangganan topik kampus untuk notifikasi broadcast
    await messaging.subscribeToTopic('pengumuman-kampus');
  }

  /// Fungsi untuk kirim token ke backend API
  static Future<void> sendTokenToBackend(String token) async {
    final platformName = Platform.isAndroid ? 'android' : 'ios';

    // TODO: Ganti blok ini dengan panggilan HTTP Dio/Client ke API backend kampus jika endpoint sudah siap.
    // Contoh implementasi nyata:
    // await dio.post('/devices', data: {'fcm_token': token, 'platform': platformName});

    debugPrint('--> Mengirim FCM Token ke Backend: $token (Platform: $platformName)');
  }
}