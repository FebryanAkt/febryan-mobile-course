import '../models/task_item.dart';

/// Kontrak Abstraksi Sumber Data Tugas (Repository Pattern)
abstract interface class TaskRepository {
  Future<List<TaskItem>> getTasks();
  Future<TaskItem> addTask(TaskItem task);
  Future<TaskItem> toggleTaskStatus(String id);
  Future<void> deleteTask(String id);
}
