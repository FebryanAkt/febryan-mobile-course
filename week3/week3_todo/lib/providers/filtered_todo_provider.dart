import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_provider.dart';

// ──────────────────────────────────────────────────────────────────
// Enum untuk mode filter tampilan ToDo.
// ──────────────────────────────────────────────────────────────────
enum TodoFilter {
  all,        // Tampilkan semua tugas
  pending,    // Hanya tugas yang belum selesai
  completed,  // Hanya tugas yang sudah selesai
}

// ──────────────────────────────────────────────────────────────────
// Notifier untuk menyimpan filter yang sedang aktif.
// Menggunakan Notifier (bukan StateProvider yang sudah dihapus
// di Riverpod v3) untuk state enum sederhana.
// ──────────────────────────────────────────────────────────────────
class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  /// Ubah filter aktif — state diganti secara immutable
  void setFilter(TodoFilter filter) => state = filter;
}

final todoFilterProvider =
    NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

// ──────────────────────────────────────────────────────────────────
// Provider turunan (derived provider) yang membaca todoListProvider
// dan todoFilterProvider, lalu mengembalikan list yang sudah difilter.
//
// Ini adalah pola "computed/derived state" di Riverpod:
// - Tidak menyimpan state sendiri, hanya menghitung dari provider lain.
// - Otomatis di-rebuild saat salah satu provider sumber berubah.
// - Mengembalikan List<int> (index) agar TodoTile bisa menggunakan
//   index asli untuk toggle/remove.
// ──────────────────────────────────────────────────────────────────
final filteredTodoIndicesProvider = Provider<List<int>>((ref) {
  // ref.watch — reaktif: provider ini otomatis di-rebuild
  // ketika todoListProvider atau todoFilterProvider berubah
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  // Switch expression (Dart 3) — exhaustive, compiler memastikan
  // semua case enum ditangani sehingga tidak mungkin return null.
  return switch (filter) {
    TodoFilter.all => List.generate(todos.length, (i) => i),
    TodoFilter.pending => [
        for (var i = 0; i < todos.length; i++)
          if (!todos[i].done) i,
      ],
    TodoFilter.completed => [
        for (var i = 0; i < todos.length; i++)
          if (todos[i].done) i,
      ],
  };
});

/// Provider turunan yang membaca todoListProvider dan hanya
/// mengembalikan daftar tugas yang belum selesai (misal sesuai contoh modul).
final uncompletedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => !todo.done).toList();
});
