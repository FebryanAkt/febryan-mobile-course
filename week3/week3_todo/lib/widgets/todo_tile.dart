import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

// ──────────────────────────────────────────────────────────────────
// TodoTile — Widget terpisah untuk satu item ToDo.
//
// Diekstrak dari TodoPage agar:
// 1. build() TodoPage lebih pendek dan mudah dibaca.
// 2. Widget ini bisa diuji secara independen.
// 3. Hanya tile yang berubah yang di-rebuild (optimasi performa).
//
// Menggunakan ConsumerWidget agar bisa mengakses ref langsung
// untuk toggle dan remove tanpa meneruskan callback dari parent.
// ──────────────────────────────────────────────────────────────────
class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.index});

  /// Index todo dalam list — digunakan untuk toggle/remove.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch di build() — reaktif, rebuild saat todo berubah
    final todo = ref.watch(todoListProvider)[index];

    return ListTile(
      leading: Checkbox(
        value: todo.done,
        // ref.read di callback — tidak reaktif, hanya aksi sekali jalan
        onChanged: (_) => ref.read(todoListProvider.notifier).toggle(index),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        // ref.read di callback — hapus item
        onPressed: () => ref.read(todoListProvider.notifier).remove(index),
      ),
    );
  }
}
