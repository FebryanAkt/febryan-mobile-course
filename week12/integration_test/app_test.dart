import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week12_testing_qa/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pengujian Integrasi: Alur Lengkap Penambahan Tugas dan Verifikasi Daftar', (tester) async {
    // 1. Jalankan aplikasi dari entry point utama
    app.main();
    await tester.pumpAndSettle();

    // 2. Verifikasi halaman utama termuat
    expect(find.byKey(const Key('app-bar-title')), findsOneWidget);
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);

    // 3. Masukkan teks judul tugas baru
    const newTaskTitle = 'Menyelesaikan Seluruh Modul QA Minggu 12';
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      newTaskTitle,
    );
    await tester.pumpAndSettle();

    // 4. Masukkan deskripsi tugas
    await tester.enterText(
      find.byKey(const Key('task-desc-field')),
      'Unit test, Widget test, Integration test, dan Code Coverage',
    );
    await tester.pumpAndSettle();

    // 5. Tekan tombol Simpan
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    // 6. Verifikasi tugas baru muncul di daftar UI
    expect(find.text(newTaskTitle), findsOneWidget);
    expect(find.textContaining('Unit test, Widget test'), findsOneWidget);

    // 7. Uji fitur pencarian (Search Filter)
    await tester.enterText(
      find.byKey(const Key('search-task-field')),
      'Modul QA',
    );
    await tester.pumpAndSettle();

    // Pastikan item yang cocok tetap tampak
    expect(find.text(newTaskTitle), findsOneWidget);

    // Bersihkan filter pencarian
    await tester.enterText(
      find.byKey(const Key('search-task-field')),
      '',
    );
    await tester.pumpAndSettle();
  });
}
