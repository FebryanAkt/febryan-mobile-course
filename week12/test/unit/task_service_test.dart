import 'package:flutter_test/flutter_test.dart';
import 'package:week12_testing_qa/models/task_item.dart';
import 'package:week12_testing_qa/repositories/fake_task_repository.dart';
import 'package:week12_testing_qa/services/task_service.dart';

void main() {
  late FakeTaskRepository fakeRepository;
  late TaskService taskService;

  setUp(() {
    fakeRepository = FakeTaskRepository(
      initialTasks: [
        TaskItem(
          id: 'test-1',
          title: 'Praktikum Testing',
          description: 'Modul 12',
          isCompleted: false,
          priority: 'Tinggi',
          createdAt: DateTime.now(),
        ),
        TaskItem(
          id: 'test-2',
          title: 'Review Code Coverage',
          description: 'Lcov report',
          isCompleted: true,
          priority: 'Sedang',
          createdAt: DateTime.now(),
        ),
      ],
    );
    taskService = TaskService(fakeRepository);
  });

  group('TaskService dengan FakeTaskRepository (Pengujian Dependensi & Logika)', () {
    test('loadTasks mengembalikan seluruh daftar tugas dari fake repository', () async {
      // Act
      final tasks = await taskService.loadTasks();

      // Assert
      expect(tasks.length, equals(2));
      expect(tasks.first.title, equals('Praktikum Testing'));
    });

    test('createTask berhasil menambahkan tugas valid ke repository', () async {
      // Act
      final created = await taskService.createTask(
        title: 'Mempersiapkan Presentasi Akhir',
        description: 'Slide 1-15',
        priority: 'Tinggi',
      );

      // Assert
      expect(created.id, startsWith('task-'));
      expect(created.title, equals('Mempersiapkan Presentasi Akhir'));
      expect(created.isCompleted, isFalse);
      expect(fakeRepository.taskCount, equals(3));
    });

    test('createTask melempar ArgumentError jika judul tidak valid', () async {
      // Assert & Act
      expect(
        () => taskService.createTask(title: '  '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => taskService.createTask(title: 'AB'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createTask melempar ArgumentError jika deskripsi melebihi batas', () async {
      final longDesc = 'A' * 205;
      expect(
        () => taskService.createTask(title: 'Tugas Valid', description: longDesc),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toggleCompletion membalik status penyelesaian tugas', () async {
      // Initial: test-1 isCompleted = false
      final updated = await taskService.toggleCompletion('test-1');
      expect(updated.isCompleted, isTrue);

      // Toggle kembali: isCompleted = false
      final reverted = await taskService.toggleCompletion('test-1');
      expect(reverted.isCompleted, isFalse);
    });

    test('removeTask menghapus tugas dari repository', () async {
      await taskService.removeTask('test-1');
      expect(fakeRepository.taskCount, equals(1));
      expect(fakeRepository.currentTasks.any((t) => t.id == 'test-1'), isFalse);
    });

    test('FakeTaskRepository menangani simulasi kegagalan server (Network Exception)', () async {
      // Arrange: Konfigurasikan fake repository untuk melempar error
      fakeRepository.shouldThrowError = Exception('500 Internal Server Error');

      // Act & Assert
      expect(
        () => taskService.loadTasks(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TaskService.filterTasks - Filtering & Search Logic', () {
    test('filterTasks mencari berdasarkan kata kunci title (case-insensitive)', () {
      final all = fakeRepository.currentTasks;
      final results = taskService.filterTasks(all, query: 'testing');

      expect(results.length, equals(1));
      expect(results.first.id, equals('test-1'));
    });

    test('filterTasks mencari berdasarkan kata kunci di description', () {
      final all = fakeRepository.currentTasks;
      final results = taskService.filterTasks(all, query: 'coverage');

      expect(results.length, equals(1));
      expect(results.first.id, equals('test-2'));
    });

    test('filterTasks menyaring berdasarkan status selesai (completedOnly)', () {
      final all = fakeRepository.currentTasks;
      final completed = taskService.filterTasks(all, completedOnly: true);
      final active = taskService.filterTasks(all, completedOnly: false);

      expect(completed.length, equals(1));
      expect(completed.first.id, equals('test-2'));

      expect(active.length, equals(1));
      expect(active.first.id, equals('test-1'));
    });
  });
}
