import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository untuk mengakses endpoint komentar di JSONPlaceholder.
///
/// Repository adalah **satu-satunya pintu** ke sumber data (API).
/// UI tidak boleh memanggil Dio secara langsung — harus lewat sini.
///
/// Timeout sudah dikonfigurasi terpusat di [createDio] (api_client.dart),
/// jadi setiap request otomatis menggunakan timeout 10 detik.
class CommentRepository {
  /// Menerima instance [Dio] melalui constructor injection.
  /// Ini memudahkan testing — kita bisa inject mock Dio saat test.
  CommentRepository(this._dio);
  final Dio _dio;

  /// Mengambil daftar komentar berdasarkan [postId].
  ///
  /// Memanggil endpoint: `GET /comments?postId={postId}`
  ///
  /// Return: `Future<List<Comment>>` — list komentar yang sudah
  /// dikonversi dari JSON ke model Dart.
  ///
  /// Exception **tidak ditangkap** di sini — dibiarkan naik
  /// agar provider Riverpod otomatis mengubahnya menjadi [AsyncError].
  Future<List<Comment>> fetchComments(int postId) async {
    // Dio.get dengan queryParameters agar URL tetap bersih.
    // Hasilnya: GET /comments?postId=1
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // response.data bisa null jika server mengembalikan body kosong.
    final data = response.data ?? [];

    // whereType memfilter elemen yang bukan Map (safety tambahan),
    // lalu map ke model Comment via fromJson.
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
