/// Model data untuk respons GET /comments dari JSONPlaceholder.
///
/// Contoh JSON:
/// ```json
/// {
///   "postId": 1,
///   "id": 1,
///   "name": "id labore ex et quam laborum",
///   "email": "Eliseo@gardner.biz",
///   "body": "laudantium enim quasi est..."
/// }
/// ```
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// ID post induk yang memiliki komentar ini.
  final int postId;

  /// ID unik komentar.
  final int id;

  /// Nama pengirim komentar.
  final String name;

  /// Email pengirim komentar.
  final String email;

  /// Isi teks komentar.
  final String body;

  /// Factory constructor untuk mengubah JSON menjadi objek [Comment].
  ///
  /// Menggunakan **defensive cast** (`as num?`, `as String?`) diikuti
  /// null-coalescing (`?? 0`, `?? ''`) agar tidak crash saat:
  /// - field hilang dari respons API (null),
  /// - tipe data tidak sesuai ekspektasi.
  ///
  /// Pola ini mencegah error umum:
  /// `type 'Null' is not a subtype of type 'int'`
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // `as num?` menangani kasus int maupun double dari server,
      // `?.toInt()` konversi ke int, `?? 0` fallback jika null.
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,

      // `as String?` aman jika field null atau hilang,
      // `?? ''` berikan string kosong sebagai fallback.
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengubah objek [Comment] kembali ke Map JSON.
  /// Berguna untuk keperluan debugging atau pengiriman data.
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
