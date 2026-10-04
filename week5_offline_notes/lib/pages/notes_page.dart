import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';



final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).countDirty();
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          // Badge dirty count
          dirtyAsync.when(
            data: (count) => count > 0
                ? TextButton.icon(
                    onPressed: () async {
                      final repo = ref.read(noteRepositoryProvider);
                      final synced = await syncNotes(repo);
                      ref.invalidate(notesProvider);
                      ref.invalidate(dirtyCountProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$synced catatan disinkronkan')),
                        );
                      }
                    },
                    icon: Badge(
                      label: Text('$count'),
                      child: const Icon(Icons.sync, color: Colors.white),
                    ),
                    label: const Text('Sync', style: TextStyle(color: Colors.white)),
                  )
                : const Icon(Icons.cloud_done, color: Colors.white),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) => notes.isEmpty
            ? const Center(child: Text('Belum ada catatan'))
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return NoteTile(
                    note: note,
                    onTap: () {
                      if (note.id != null) {
                        context.push('/note/${note.id}');
                      }
                    },
                    onDelete: () async {
                      await ref.read(noteRepositoryProvider).deleteNote(note.id!);
                      ref.invalidate(notesProvider);
                      ref.invalidate(dirtyCountProvider);
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul')),
            TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Isi')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ref.read(noteRepositoryProvider).addNote(
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                  );
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
