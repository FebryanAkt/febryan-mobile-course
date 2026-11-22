import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../repositories/in_memory_task_repository.dart';
import '../services/task_service.dart';
import '../widgets/task_input_form.dart';
import '../widgets/task_tile.dart';

/// Halaman Utama Pengujian Kualitas dan Manajemen Tugas
class TaskPage extends StatefulWidget {
  final TaskService? taskService;

  const TaskPage({super.key, this.taskService});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late final TaskService _service;
  final TextEditingController _searchController = TextEditingController();

  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _filterCompleted;

  @override
  void initState() {
    super.initState();
    _service = widget.taskService ?? TaskService(InMemoryTaskRepository());
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _service.loadTasks();
      if (mounted) {
        setState(() {
          _tasks = List<TaskItem>.from(items);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat tugas: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddTask(String title, String description, String priority) async {
    try {
      final created = await _service.createTask(
        title: title,
        description: description,
        priority: priority,
      );
      if (mounted) {
        setState(() {
          _tasks = [created, ..._tasks];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas "${created.title}" berhasil ditambahkan!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleTask(String id) async {
    try {
      final updated = await _service.toggleCompletion(id);
      if (mounted) {
        setState(() {
          _tasks = _tasks.map((t) => t.id == id ? updated : t).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteTask(String id) async {
    try {
      await _service.removeTask(id);
      if (mounted) {
        setState(() {
          _tasks = _tasks.where((t) => t.id != id).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tugas berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus tugas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _service.filterTasks(
      _tasks,
      query: _searchQuery,
      completedOnly: _filterCompleted,
    );

    return Scaffold(
      appBar: AppBar(
        key: const Key('app-bar-title'),
        title: const Text('Manajemen Tugas — Minggu 12'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Section Input Form
          Padding(
            padding: const EdgeInsets.all(16),
            child: TaskInputForm(onSave: _handleAddTask),
          ),

          // Section Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('search-task-field'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari tugas...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Selesai'),
                  selected: _filterCompleted == true,
                  onSelected: (val) {
                    setState(() => _filterCompleted = val ? true : null);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Section List Content
          Expanded(
            child: _buildListContent(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(List<TaskItem> filteredList) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('loading-indicator')),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                key: const Key('error-task-state'),
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                key: const Key('retry-button'),
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredList.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            key: const Key('empty-task-state'),
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.task_alt, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Belum ada tugas dalam daftar',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final task = filteredList[index];
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          onToggle: (_) => _handleToggleTask(task.id),
          onDelete: () => _handleDeleteTask(task.id),
        );
      },
    );
  }
}
