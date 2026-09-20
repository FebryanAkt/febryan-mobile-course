import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';
import 'providers.dart'; // Reuse dioProvider yang sudah ada

// ─────────────────────────────────────────────────────────────
// 1. REPOSITORY PROVIDER
// ─────────────────────────────────────────────────────────────

/// Provider untuk [CommentRepository].
///
/// Menggunakan [dioProvider] yang sudah dikonfigurasi terpusat
/// di api_client.dart (baseUrl, timeout 10 detik, interceptor).
/// Dengan begitu, konfigurasi jaringan tidak tersebar di tiap method.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

// ─────────────────────────────────────────────────────────────
// 2. ASYNC NOTIFIER — state management untuk list komentar
// ─────────────────────────────────────────────────────────────

/// Notifier yang mengelola state daftar komentar berdasarkan postId.
///
/// Menggunakan [AsyncNotifier] agar:
/// - State otomatis dimulai sebagai [AsyncLoading].
/// - Jika [fetchComments] berhasil → state menjadi [AsyncData].
/// - Jika terjadi exception → state otomatis menjadi [AsyncError].
///
/// UI tinggal pakai `.when(loading:, error:, data:)` tanpa
/// perlu try-catch manual.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  /// postId yang sedang ditampilkan. Di-set sebelum provider digunakan.
  int _postId = 1;

  /// Dipanggil otomatis saat provider pertama kali dibaca.
  /// Exception dari repository **otomatis** menjadi AsyncError
  /// tanpa perlu try-catch di sini.
  @override
  Future<List<Comment>> build() async {
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(_postId);
  }

  /// Memuat ulang komentar untuk [postId] tertentu.
  ///
  /// Flow:
  /// 1. Set state ke AsyncLoading → UI tampilkan spinner.
  /// 2. Panggil repository.fetchComments().
  /// 3. Jika sukses → AsyncData, jika gagal → AsyncError.
  Future<void> loadComments(int postId) async {
    _postId = postId;
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      // Exception ditangkap di sini agar state menjadi AsyncError
      // dan UI bisa menampilkan pesan error via friendlyErrorMessage.
      state = AsyncError(e, st);
    }
  }

  /// Refresh data komentar (postId tetap sama).
  Future<void> refresh() async {
    await loadComments(_postId);
  }
}

// ─────────────────────────────────────────────────────────────
// 3. PROVIDER GLOBAL — digunakan oleh UI
// ─────────────────────────────────────────────────────────────

/// Provider utama untuk daftar komentar.
///
/// UI menggunakan: `ref.watch(commentListProvider)`
/// dan mendapat [AsyncValue<List<Comment>>] yang bisa di-handle
/// dengan `.when(loading:, error:, data:)`.
///
/// retry: null → nonaktifkan retry otomatis Riverpod 3
/// agar error langsung final dan mudah diuji.
final commentListProvider =
    AsyncNotifierProvider<CommentListNotifier, List<Comment>>(
  CommentListNotifier.new,
  retry: (retryCount, error) => null,
);

// ─────────────────────────────────────────────────────────────
// 4. FUNGSI PESAN ERROR RAMAH PENGGUNA
// ─────────────────────────────────────────────────────────────

/// Mengubah exception teknis menjadi pesan yang bisa ditampilkan ke user.
///
/// Memetakan semua tipe [DioExceptionType] yang umum terjadi:
/// - **connectionTimeout / sendTimeout / receiveTimeout** → pesan timeout
/// - **connectionError** → tidak bisa terhubung ke server
/// - **badResponse 404** → data tidak ditemukan
/// - **badResponse 500** → server error
/// - **badResponse 401/403** → akses ditolak
/// - **default** → fallback pesan umum jaringan
///
/// Jika bukan DioException, tampilkan pesan generik.
String commentFriendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      // Timeout: koneksi terlalu lama (>10 detik sesuai config)
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa internet Anda dan coba lagi.';

      // Tidak bisa terhubung sama sekali (WiFi mati, DNS gagal, dll)
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';

      // Server merespons dengan status code error
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) {
          return 'Komentar tidak ditemukan (404).';
        }
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        if (code != null && code >= 500) {
          return 'Server sedang bermasalah ($code). Coba lagi nanti.';
        }
        return 'Terjadi kesalahan dari server ($code).';

      // Cancel, badCertificate, unknown, dll
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  // Bukan DioException — error tak terduga (parsing, dll)
  return 'Terjadi kesalahan tak terduga: $error';
}
