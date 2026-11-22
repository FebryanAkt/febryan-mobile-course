import '../models/task_item.dart';
import 'task_repository.dart';

/// Implementasi Fake Repository untuk Pengujian Terisolasi (Test Double)
/// Memungkinkan simulasi skenario sukses, kegagalan jaringan, dan latensi terkontrol
class FakeTaskRepository implements TaskRepository {
  final List<TaskItem> _tasks;
  Exception? shouldThrowError;
  Duration delay;

  FakeTaskRepository({
    List<TaskItem>? initialTasks,
    this.shouldThrowError,
    this.delay = Duration.zero,
  }) : _tasks = List<TaskItem>.from(initialTasks ?? []);

  @override
  Future<List<TaskItem>> getTasks() async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (shouldThrowError != null) throw shouldThrowError!;
    return List.unmodifiable(_tasks);
  }

  @override
  Future<TaskItem> addTask(TaskItem task) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (shouldThrowError != null) throw shouldThrowError!;
    _tasks.add(task);
    return task;
  }

  @override
  Future<TaskItem> toggleTaskStatus(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (shouldThrowError != null) throw shouldThrowError!;
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Tugas dengan ID $id tidak ditemukan');
    }
    final updated = _tasks[index].copyWith(
      isCompleted: !_tasks[index].isCompleted,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (shouldThrowError != null) throw shouldThrowError!;
    _tasks.removeWhere((t) => t.id == id);
  }

  // Helper untuk mempermudah assert saat testing
  int get taskCount => _tasks.length;
  List<TaskItem> get currentTasks => List.unmodifiable(_tasks);
}
