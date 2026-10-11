import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  // ---------------------------------------------------------------
  // Inisialisasi token FCM, listener pembaruan token, dan topic kampus.
  //
  // [BERBEDA Android 13+] POST_NOTIFICATIONS runtime permission wajib —
  //   requestPermission() harus dipanggil, jika ditolak token tetap ada
  //   tapi notifikasi tidak tampil.
  // [BERBEDA iOS] Dialog izin sistem muncul dari requestPermission();
  //   tanpa grant, APNs token tidak dikirim ke FCM.
  // ---------------------------------------------------------------
  static Future<void> initFcmToken({
    required Dio dio,
    required Future<void> Function(String token) onToken,
  }) async {
    final messaging = FirebaseMessaging.instance;

    // Minta izin — wajib Android 13+ (API 33) dan iOS
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FcmService] Izin notifikasi ditolak oleh pengguna');
      return;
    }

    // Ambil token awal dan kirim ke backend
    final token = await messaging.getToken();
    if (token != null) {
      // Keamanan: hanya log 6 karakter terakhir, bukan token penuh
      debugPrint('[FcmService] Token diperoleh: ...${_tail(token)}');
      await onToken(token);
    }

    // onTokenRefresh: kirim token baru ke backend (BUKAN hanya dicetak ke log)
    // Token bisa berganti saat: uninstall-reinstall, clear data, restore backup,
    // atau Firebase memrotasi token secara periodik.
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FcmService] Token diperbarui: ...${_tail(newToken)}');
      await onToken(newToken); // ← mengirim ke backend, bukan hanya log
    });

    // Subscribe ke topik broadcast pengumuman kampus
    await subscribeToTopic('pengumuman-kampus');
  }

  /// Kirim FCM token ke backend via POST /devices.
  /// Hanya status code yang dicatat pada error — token TIDAK di-log penuh.
  static Future<void> sendTokenToBackend(Dio dio, String token) async {
    final platform = Platform.isAndroid ? 'android' : 'ios';
    try {
      await dio.post<void>(
        '/devices',
        data: {
          'fcm_token': token,
          'platform': platform,
        },
      );
      debugPrint('[FcmService] Token berhasil dikirim ke backend ($platform)');
    } on DioException catch (e) {
      // Hanya log status code — JANGAN log token untuk keamanan
      debugPrint(
        '[FcmService] Gagal kirim token: HTTP ${e.response?.statusCode} '
        '— ${e.message}',
      );
    }
  }

  /// Subscribe ke topik broadcast, seperti semua mahasiswa atau satu kelas.
  /// Pesan personal harus dikirim backend ke token perangkat langsung.
  static Future<void> subscribeToTopic(String topic) async {
    _validateTopic(topic);
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[FcmService] Subscribe ke topik: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    _validateTopic(topic);
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('[FcmService] Unsubscribe dari topik: $topic');
  }

  static void _validateTopic(String topic) {
    if (topic.trim().isEmpty || topic.contains(RegExp(r'\s'))) {
      throw ArgumentError.value(
        topic,
        'topic',
        'Nama topik tidak boleh kosong atau mengandung spasi.',
      );
    }
  }

  /// Kembalikan 6 karakter terakhir token untuk keperluan log.
  static String _tail(String token) =>
      token.length > 6 ? token.substring(token.length - 6) : token;
}
