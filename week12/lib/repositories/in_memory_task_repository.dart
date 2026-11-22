import '../models/task_item.dart';
import 'task_repository.dart';

/// Implementasi InMemory Repository untuk Penggunaan Normal Aplikasi
class InMemoryTaskRepository implements TaskRepository {
  final List<TaskItem> _tasks = [
    TaskItem(
      id: 'task-1',
      title: 'Mengerjakan Praktikum Testing Minggu 12',
      description: 'Menulis unit test, widget test, dan integration test',
      isCompleted: false,
      priority: 'Tinggi',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TaskItem(
      id: 'task-2',
      title: 'Mempelajari Code Coverage Flutter',
      description: 'Menjalankan flutter test --coverage dan menganalisis lcov.info',
      isCompleted: true,
      priority: 'Sedang',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TaskItem(
      id: 'task-3',
      title: 'Review Clean Architecture & Repository Pattern',
      description: 'Memisahkan UI dari akses database/API',
      isCompleted: false,
      priority: 'Rendah',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<List<TaskItem>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulasi I/O
    return List.unmodifiable(_tasks);
  }

  @override
  Future<TaskItem> addTask(TaskItem task) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _tasks.insert(0, task);
    return task;
  }

  @override
  Future<TaskItem> toggleTaskStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw Exception('Tugas tidak ditemukan');
    final updated = _tasks[index].copyWith(
      isCompleted: !_tasks[index].isCompleted,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _tasks.removeWhere((t) => t.id == id);
  }
}
