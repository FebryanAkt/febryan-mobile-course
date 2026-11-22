import 'package:flutter/material.dart';
import '../validators/task_validator.dart';

/// Form Input Penambahan Tugas Baru dengan Validasi Input Interaktif
class TaskInputForm extends StatefulWidget {
  final Future<void> Function(String title, String description, String priority) onSave;

  const TaskInputForm({super.key, required this.onSave});

  @override
  State<TaskInputForm> createState() => _TaskInputFormState();
}

class _TaskInputFormState extends State<TaskInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = 'Sedang';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedPriority,
      );
      if (mounted) {
        _titleController.clear();
        _descController.clear();
        setState(() => _selectedPriority = 'Sedang');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tambah Tugas Baru',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('task-title-field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas *',
                hintText: 'Misal: Selesaikan Codelab QA',
                prefixIcon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
              ),
              validator: TaskValidator.validateTaskTitle,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('task-desc-field'),
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Tambahkan detail tugas...',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              validator: TaskValidator.validateDescription,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('task-priority-dropdown'),
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Prioritas',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Rendah', child: Text('Rendah')),
                      DropdownMenuItem(value: 'Sedang', child: Text('Sedang')),
                      DropdownMenuItem(value: 'Tinggi', child: Text('Tinggi')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPriority = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  key: const Key('save-task-button'),
                  onPressed: _isSaving ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
