import 'package:flutter/material.dart';
import '../models/task_item.dart';

/// Widget Kartu Baris Tugas dengan Tombol Selesai dan Hapus
class TaskTile extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Tinggi':
        return Colors.red.shade600;
      case 'Rendah':
        return Colors.green.shade600;
      case 'Sedang':
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: task.isCompleted ? 0.5 : 2.0,
      color: task.isCompleted ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.isCompleted ? Colors.grey.shade300 : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          key: Key('task-checkbox-${task.id}'),
          value: task.isCompleted,
          onChanged: onToggle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
        subtitle: task.description.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.priority,
                style: TextStyle(
                  color: _getPriorityColor(task.priority),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            IconButton(
              key: Key('task-delete-${task.id}'),
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              tooltip: 'Hapus Tugas',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
