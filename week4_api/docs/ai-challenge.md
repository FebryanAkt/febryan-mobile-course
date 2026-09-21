# Dokumentasi AI Challenge — Minggu 4: Networking & REST API

## 1. Prompt yang Digunakan

Prompt berikut diberikan ke AI coding assistant:

```
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

---

## 2. Output Awal AI

AI menghasilkan 4 file berikut:

### a. `lib/data/models/comment.dart`

```dart
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
```

### b. `lib/data/repositories/comment_repository.dart`

```dart
import 'package:dio/dio.dart';
import '../models/comment.dart';

class CommentRepository {
  CommentRepository(this._dio);
  final Dio _dio;

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
```

### c. `lib/data/comment_providers.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';
import 'providers.dart';

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  int _postId = 1;

  @override
  Future<List<Comment>> build() async {
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(_postId);
  }

  Future<void> loadComments(int postId) async {
    _postId = postId;
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    await loadComments(_postId);
  }
}

final commentListProvider =
    AsyncNotifierProvider<CommentListNotifier, List<Comment>>(
  CommentListNotifier.new,
  retry: (retryCount, error) => null,
);

String commentFriendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa internet Anda dan coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Komentar tidak ditemukan (404).';
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        if (code != null && code >= 500) {
          return 'Server sedang bermasalah ($code). Coba lagi nanti.';
        }
        return 'Terjadi kesalahan dari server ($code).';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
```

### d. `test/comment_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment.fromJson', () {
    test('menghasilkan Comment yang benar dari JSON lengkap', () {
      final json = {
        'postId': 1,
        'id': 5,
        'name': 'vero eaque aliquid',
        'email': 'Hayden@althea.biz',
        'body': 'harum non quasi et ratione',
      };
      final comment = Comment.fromJson(json);
      expect(comment.postId, 1);
      expect(comment.id, 5);
      expect(comment.name, 'vero eaque aliquid');
      expect(comment.email, 'Hayden@althea.biz');
      expect(comment.body, 'harum non quasi et ratione');
    });

    test('memberikan default value saat field hilang (tidak crash)', () {
      final json = <String, dynamic>{};
      final comment = Comment.fromJson(json);
      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });
  });
}
```

---

## 3. Perbaikan yang Dilakukan

### a. Menambahkan komentar/dokumentasi lengkap
Output awal AI sudah cukup baik, namun komentar Dart doc (`///`) ditambahkan pada
setiap class, field, dan method di `comment.dart` dan `comment_repository.dart`
agar kode lebih mudah dibaca dan didokumentasi otomatis.

### b. Menambahkan edge case pada test
AI hanya menghasilkan 2 test (happy path + field hilang). Ditambahkan 4 test lagi:

| No | Test yang ditambahkan manual | Alasan |
|----|------------------------------|--------|
| 3 | Field bernilai `null` eksplisit | Beda dari field hilang — key ada tapi value `null` |
| 4 | Sebagian field hilang, sebagian ada | Skenario realistis saat API berubah versi |
| 5 | `postId` dan `id` bertipe `double` | Beberapa server mengembalikan `1.0` bukan `1` |
| 6 | `toJson` menghasilkan Map yang benar | Memastikan serialisasi balik juga berfungsi |

### c. Menambahkan `retry: null` pada provider
Output awal AI tidak menyertakan `retry: (retryCount, error) => null`. Tanpa ini,
Riverpod 3 otomatis me-retry provider saat error, sehingga test akan menunggu
(hang) dan error tidak langsung final. Ditambahkan untuk konsistensi dengan
`postListProvider`.

### d. Penanganan status code 500+ pada error message
Output awal hanya cek `code == 500`. Diperbaiki menjadi `code >= 500` agar semua
server error (502 Bad Gateway, 503 Service Unavailable, dll.) tertangani.

---

## 4. AI Verification Checklist

| No | Pertanyaan | Hasil Verifikasi |
|----|-----------|-----------------|
| 1 | Apakah UI memanggil Dio secara langsung? | ❌ Tidak. UI hanya lewat `ref.watch(commentListProvider)`. Dio hanya diakses oleh `CommentRepository`. |
| 2 | Apakah `fromJson` aman null? | ✅ Ya. Menggunakan pola `as num?` + `?.toInt()` + `?? 0` dan `as String?` + `?? ''`. |
| 3 | Apakah semua tipe `DioExceptionType` dipetakan? | ✅ Ya. `connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, `badResponse` (404, 401/403, 500+), dan `default` semua dipetakan. |
| 4 | Apakah baseUrl/timeout terpusat? | ✅ Ya. Semua konfigurasi ada di `api_client.dart` (`createDio()`). Repository hanya menerima instance Dio via constructor. |
| 5 | Apakah test menguji kasus field hilang? | ✅ Ya. Test 2 menguji JSON kosong, Test 3 menguji field `null`, Test 4 menguji sebagian hilang. Test 5 (edge case double) ditambahkan manual. |
| 6 | Apakah `flutter analyze` dan `flutter test` lolos? | ✅ Ya. `flutter analyze` → No issues found. `flutter test` → All 10 tests passed. |

---

## 5. Keputusan Teknis

### Mengapa `as num?` bukan `as int?`?
Beberapa API/server mengembalikan angka sebagai `double` (contoh: `1.0` bukan `1`).
Cast `as num?` menangani kedua kasus (`int` dan `double`), lalu `.toInt()` mengonversi
ke int. Jika langsung `as int?`, maka response `1.0` akan crash.

### Mengapa `whereType<Map<String, dynamic>>()` pada repository?
Safety tambahan jika respons API mengandung elemen yang bukan Map (misalnya `null`
di dalam list). `whereType` memfilter elemen yang tidak valid tanpa crash.

### Mengapa timeout 10 detik?
Cukup untuk koneksi normal tapi tidak terlalu lama menunggu pada jaringan buruk.
Standar umum untuk mobile app. Dikonfigurasi terpusat di `createDio()`.

### Mengapa `retry: null` pada provider?
Riverpod 3 punya fitur auto-retry. Jika tidak dinonaktifkan, test yang menguji
error state akan hang karena provider terus me-retry. Untuk production, bisa
diaktifkan kembali dengan delay strategy.

---

## 6. Hasil Testing

```
$ flutter analyze
Analyzing week4_api...
No issues found!

$ flutter test
00:00 +0: comment_test.dart: Comment.fromJson menghasilkan Comment yang benar dari JSON lengkap
00:00 +1: comment_test.dart: Comment.fromJson memberikan default value saat field hilang (tidak crash)
00:00 +2: comment_test.dart: Comment.fromJson memberikan default value saat field bernilai null
00:00 +3: comment_test.dart: Comment.fromJson menangani JSON dengan sebagian field hilang
00:00 +4: comment_test.dart: Comment.fromJson menangani postId dan id bertipe double dari server
00:00 +5: comment_test.dart: Comment.fromJson toJson menghasilkan Map yang sesuai
00:00 +6: post_test.dart: fromJson aman terhadap field yang hilang
00:00 +7: post_test.dart: friendlyErrorMessage untuk connection error
00:00 +8: post_test.dart: provider sukses dengan repository palsu
00:00 +9: post_test.dart: provider error dengan repository palsu
00:01 +10: All tests passed!
```
