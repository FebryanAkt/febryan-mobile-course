import 'package:dio/dio.dart';

/// Memetakan DioException menjadi pesan ramah pengguna (401, timeout, offline)
String mapDioExceptionToMessage(DioException error) {
  if (error.response?.statusCode == 401) {
    return 'Sesi telah berakhir atau kredensial tidak valid (401).';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Waktu koneksi habis. Silakan periksa jaringan dan coba lagi.';
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server. Anda sedang offline atau koneksi terputus.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      if (code == 401) {
        return 'Sesi telah berakhir atau kredensial tidak valid (401).';
      }
      return 'Terjadi kesalahan pada respon server ($code).';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat keamanan tidak valid.';
    case DioExceptionType.unknown:
    default:
      return 'Terjadi kesalahan jaringan atau perangkat sedang offline.';
  }
}

/// Helper umum untuk mengonversi error (DioException atau lainnya) ke pesan pengguna
String mapApiError(Object error) {
  if (error is DioException) {
    return mapDioExceptionToMessage(error);
  }
  return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
