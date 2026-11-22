import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week12_testing_qa/models/task_item.dart';
import 'package:week12_testing_qa/pages/task_page.dart';
import 'package:week12_testing_qa/repositories/fake_task_repository.dart';
import 'package:week12_testing_qa/services/task_service.dart';

void main() {
  late FakeTaskRepository fakeRepository;
  late TaskService taskService;

  setUp(() {
    fakeRepository = FakeTaskRepository(
      initialTasks: [
        TaskItem(
          id: 'widget-task-1',
          title: 'Tugas Praktikum Awal',
          description: 'Deskripsi tugas pengujian UI',
          isCompleted: false,
          priority: 'Sedang',
          createdAt: DateTime.now(),
        ),
      ],
    );
    taskService = TaskService(fakeRepository);
  });

  Widget createTestWidget({TaskService? service}) {
    return MaterialApp(
      home: TaskPage(taskService: service ?? taskService),
    );
  }

  group('Widget Testing - TaskPage UI & User Interactions', () {
    testWidgets('1. Menampilkan elemen struktur UI: AppBar, Form Input, dan List Item', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert elemen terlihat
      expect(find.byKey(const Key('app-bar-title')), findsOneWidget);
      expect(find.byKey(const Key('task-title-field')), findsOneWidget);
      expect(find.byKey(const Key('save-task-button')), findsOneWidget);
      expect(find.text('Tugas Praktikum Awal'), findsOneWidget);
    });

    testWidgets('2. Validasi Form: Menampilkan pesan error saat judul tugas kosong', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act: Tap tombol simpan tanpa mengisi judul
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert: Muncul pesan error validasi
      expect(find.text('Judul tugas tidak boleh kosong'), findsOneWidget);
      // Jumlah item tidak bertambah
      expect(fakeRepository.taskCount, equals(1));
    });

    testWidgets('3. Interaksi Pengguna: Mengetik judul valid dan menambah tugas ke daftar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act: Masukkan judul ke field
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Tugas Baru dari Widget Test',
      );
      await tester.pump();

      // Tap tombol Simpan
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert: Item baru muncul di layar dan input field bersih
      expect(find.text('Tugas Baru dari Widget Test'), findsOneWidget);
      expect(fakeRepository.taskCount, equals(2));
    });

    testWidgets('4. Interaksi Checkbox: Mengubah status tugas selesai', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(const Key('task-checkbox-widget-task-1'));
      expect(checkboxFinder, findsOneWidget);

      // Act: Tap checkbox
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Assert: Item di repository terupdate statusnya
      expect(fakeRepository.currentTasks.first.isCompleted, isTrue);
    });

    testWidgets('5. Interaksi Delete: Menghapus tugas dari daftar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final deleteFinder = find.byKey(const Key('task-delete-widget-task-1'));
      expect(deleteFinder, findsOneWidget);

      // Act: Tap tombol delete
      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();

      // Assert: Item terhapus dan tampil empty state
      expect(find.text('Tugas Praktikum Awal'), findsNothing);
      expect(find.byKey(const Key('empty-task-state')), findsOneWidget);
      expect(fakeRepository.taskCount, equals(0));
    });

    testWidgets('6. Error Handling UI: Menampilkan pesan error dan tombol Coba Lagi saat repository gagal', (tester) async {
      // Arrange: Fake repo yang selalu melempar error
      final failingRepo = FakeTaskRepository(
        shouldThrowError: Exception('Koneksi database terputus'),
      );
      final failingService = TaskService(failingRepo);

      await tester.pumpWidget(createTestWidget(service: failingService));
      await tester.pumpAndSettle();

      // Assert: Muncul error state dan retry button
      expect(find.byKey(const Key('error-task-state')), findsOneWidget);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
      expect(find.textContaining('Koneksi database terputus'), findsOneWidget);

      // Act: Perbaiki repo lalu tekan retry
      failingRepo.shouldThrowError = null;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();

      // Assert: Kembali ke kondisi normal (empty state karena 0 data)
      expect(find.byKey(const Key('empty-task-state')), findsOneWidget);
    });
  });
}
