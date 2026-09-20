import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  // ═══════════════════════════════════════════════════════════
  // TEST GROUP: Comment.fromJson
  // ═══════════════════════════════════════════════════════════
  group('Comment.fromJson', () {
    // ─────────────────────────────────────────────────────────
    // Test 1: Happy path — semua field lengkap dan valid
    // ─────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────
    // Test 2: Field hilang — WAJIB (requirement tugas)
    //
    // Simulasi: server mengembalikan JSON yang tidak lengkap.
    // fromJson harus memberikan default value, BUKAN crash.
    // ─────────────────────────────────────────────────────────
    test('memberikan default value saat field hilang (tidak crash)', () {
      // JSON kosong — tidak ada satupun field
      final json = <String, dynamic>{};

      final comment = Comment.fromJson(json);

      // Semua int harus fallback ke 0
      expect(comment.postId, 0);
      expect(comment.id, 0);
      // Semua String harus fallback ke string kosong
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    // ─────────────────────────────────────────────────────────
    // Test 3: Field null eksplisit
    //
    // Beda dengan "field hilang": di sini key ada tapi value-nya null.
    // Contoh JSON: {"postId": null, "id": null, ...}
    // ─────────────────────────────────────────────────────────
    test('memberikan default value saat field bernilai null', () {
      final json = <String, dynamic>{
        'postId': null,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    // ─────────────────────────────────────────────────────────
    // Test 4 (Edge case): Sebagian field hilang, sebagian ada
    //
    // Skenario realistis: API berubah versi, beberapa field
    // dihapus tapi yang lain masih ada.
    // ─────────────────────────────────────────────────────────
    test('menangani JSON dengan sebagian field hilang', () {
      final json = <String, dynamic>{
        'postId': 3,
        // 'id' hilang
        'name': 'partial data',
        // 'email' hilang
        // 'body' hilang
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 3); // Ada → pakai nilai asli
      expect(comment.id, 0); // Hilang → default 0
      expect(comment.name, 'partial data'); // Ada → pakai nilai asli
      expect(comment.email, ''); // Hilang → default ''
      expect(comment.body, ''); // Hilang → default ''
    });

    // ─────────────────────────────────────────────────────────
    // Test 5 (Edge case): Tipe data num (double) dari server
    //
    // Beberapa API/server mengembalikan id sebagai double (1.0)
    // bukan int (1). Pola `as num?` + `.toInt()` menangani ini.
    // ─────────────────────────────────────────────────────────
    test('menangani postId dan id bertipe double dari server', () {
      final json = <String, dynamic>{
        'postId': 2.0, // double, bukan int
        'id': 10.0, // double, bukan int
        'name': 'test double',
        'email': 'test@example.com',
        'body': 'body text',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 2); // Harus jadi int 2
      expect(comment.id, 10); // Harus jadi int 10
    });

    // ─────────────────────────────────────────────────────────
    // Test 6: toJson menghasilkan Map yang benar
    // ─────────────────────────────────────────────────────────
    test('toJson menghasilkan Map yang sesuai', () {
      const comment = Comment(
        postId: 1,
        id: 2,
        name: 'Test',
        email: 'test@mail.com',
        body: 'Hello',
      );

      final json = comment.toJson();

      expect(json['postId'], 1);
      expect(json['id'], 2);
      expect(json['name'], 'Test');
      expect(json['email'], 'test@mail.com');
      expect(json['body'], 'Hello');
    });
  });
}
