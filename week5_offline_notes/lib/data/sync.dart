import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'repositories/note_repository.dart';

/// Cache-first read untuk data API (Praktikum 3 Langkah 1).
/// Tampilkan cache lokal seketika, refresh dari jaringan di background,
/// simpan hasilnya untuk kunjungan berikutnya.
Future<List<Map<String, dynamic>>> loadPostsCacheFirst({
  required Future<Database> Function() openDb,
  required Future<List<Map<String, dynamic>>> Function() fetchFromNetwork,
  void Function()? onRefreshDone,
}) async {
  final db = await openDb();
  final cached = await readCachedPosts(db);

  // Di background: fetch network -> simpan ke cached_posts -> callback.
  refreshPostsInBackground(
    db: db,
    fetchFromNetwork: fetchFromNetwork,
    onDone: onRefreshDone,
  );

  return cached;
}

Future<List<Map<String, dynamic>>> readCachedPosts(Database db) async {
  final rows = await db.query('cached_posts', orderBy: 'id ASC');
  return rows.map((r) {
    return jsonDecode(r['payload'] as String) as Map<String, dynamic>;
  }).toList();
}

Future<void> refreshPostsInBackground({
  required Database db,
  required Future<List<Map<String, dynamic>>> Function() fetchFromNetwork,
  void Function()? onDone,
}) async {
  try {
    final posts = await fetchFromNetwork();
    await db.delete('cached_posts');
    for (final post in posts) {
      await db.insert('cached_posts', {
        'id': post['id'],
        'payload': jsonEncode(post),
        'cached_at': DateTime.now().toIso8601String(),
      });
    }
    onDone?.call();
  } catch (_) {
    // Offline atau error jaringan — abaikan, cache tetap dipakai.
  }
}

/// Sinkronisasi catatan kotor / dirty (Praktikum 3 Langkah 2).
/// Simulasi upload: pada project nyata, kirim tiap catatan dirty
/// ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
