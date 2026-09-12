import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../providers/filtered_todo_provider.dart';
import '../widgets/todo_tile.dart';

// ──────────────────────────────────────────────────────────────────
// TodoPage — Halaman utama daftar tugas.
//
// Setelah refactoring:
// 1. ListTile diekstrak ke TodoTile (widget terpisah).
// 2. Filter (semua/belum/selesai) menggunakan derived provider.
// 3. Navigasi diganti GoRouter + NavigationBar (di shell).
// ──────────────────────────────────────────────────────────────────
class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch di build() — reaktif
    final filteredIndices = ref.watch(filteredTodoIndicesProvider);
    final currentFilter = ref.watch(todoFilterProvider);
    final allTodos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
        actions: [
          // ── Dropdown filter ──
          // Mengubah todoFilterProvider untuk memfilter daftar
          PopupMenuButton<TodoFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (filter) {
              // ref.read di callback — set filter baru via notifier method
              ref.read(todoFilterProvider.notifier).setFilter(filter);
            },
            itemBuilder: (_) => [
              _filterMenuItem('Semua', TodoFilter.all, currentFilter),
              _filterMenuItem('Belum selesai', TodoFilter.pending, currentFilter),
              _filterMenuItem('Selesai', TodoFilter.completed, currentFilter),
            ],
          ),
        ],
      ),

      // ── Body: tampilkan list berdasarkan filter ──
      body: allTodos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : filteredIndices.isEmpty
              ? const Center(child: Text('Tidak ada tugas dengan filter ini'))
              : ListView.builder(
                  itemCount: filteredIndices.length,
                  itemBuilder: (_, i) =>
                      // Gunakan TodoTile yang sudah diekstrak
                      TodoTile(index: filteredIndices[i]),
                ),

      // ── FAB untuk tambah tugas baru ──
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Helper untuk membuat PopupMenuItem filter dengan tanda centang
  PopupMenuItem<TodoFilter> _filterMenuItem(
    String label,
    TodoFilter value,
    TodoFilter current,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            value == current ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  /// Dialog untuk menambah tugas baru
  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                // ref.read di callback — tambah tugas
                ref
                    .read(todoListProvider.notifier)
                    .add(controller.text.trim());
              }
              controller.clear();
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}