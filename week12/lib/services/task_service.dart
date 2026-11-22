import '../models/task_item.dart';
import '../repositories/task_repository.dart';
import '../validators/task_validator.dart';

/// Layanan Bisnis Utama Pengelolaan Tugas (TaskService)
/// Bertanggung jawab atas aturan validasi bisnis, delegasi repository, dan filtering
class TaskService {
  final TaskRepository _repository;

  TaskService(this._repository);

  TaskRepository get repository => _repository;

  Future<List<TaskItem>> loadTasks() async {
    return _repository.getTasks();
  }

  Future<TaskItem> createTask({
    required String title,
    String description = '',
    String priority = 'Sedang',
  }) async {
    if (!TaskValidator.isValidTaskTitle(title)) {
      throw ArgumentError(
        'Judul tugas tidak valid: harus berisi minimal ${TaskValidator.minTitleLength} karakter.',
      );
    }

    final descError = TaskValidator.validateDescription(description);
    if (descError != null) {
      throw ArgumentError(descError);
    }

    final newTask = TaskItem(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      isCompleted: false,
      priority: priority,
      createdAt: DateTime.now(),
    );

    return _repository.addTask(newTask);
  }

  Future<TaskItem> toggleCompletion(String id) async {
    return _repository.toggleTaskStatus(id);
  }

  Future<void> removeTask(String id) async {
    return _repository.deleteTask(id);
  }

  /// Menyaring daftar tugas berdasarkan kata kunci dan status penyelesaian
  List<TaskItem> filterTasks(
    List<TaskItem> tasks, {
    String query = '',
    bool? completedOnly,
    String? priorityFilter,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    return tasks.where((task) {
      final matchesQuery = cleanQuery.isEmpty ||
          task.title.toLowerCase().contains(cleanQuery) ||
          task.description.toLowerCase().contains(cleanQuery);

      final matchesCompleted =
          completedOnly == null || task.isCompleted == completedOnly;

      final matchesPriority =
          priorityFilter == null || task.priority == priorityFilter;

      return matchesQuery && matchesCompleted && matchesPriority;
    }).toList();
  }
}
