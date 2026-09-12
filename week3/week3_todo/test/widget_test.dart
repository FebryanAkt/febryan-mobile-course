import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';

// ──────────────────────────────────────────────────────────────────
// Widget test untuk memastikan UI bereaksi terhadap perubahan
// state provider.
//
// Menggunakan ProviderScope agar semua provider tersedia di tree.
// pumpWidget → render awal, pump → proses satu frame,
// pumpAndSettle → tunggu semua animasi selesai.
// ──────────────────────────────────────────────────────────────────

void main() {
  // ── Test 1: Menambah tugas baru ──
  // Verifikasi bahwa menambah tugas lewat dialog benar-benar
  // memperbarui UI (dari "Belum ada tugas" → menampilkan item).
  testWidgets('menambah tugas baru', (tester) async {
    // Render aplikasi lengkap dalam ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // State awal: belum ada tugas
    expect(find.text('Belum ada tugas'), findsOneWidget);

    // Tap tombol FAB (+) untuk membuka dialog tambah tugas
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // Tunggu dialog terbuka

    // Ketik judul tugas di TextField dialog
    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');

    // Tap tombol "Tambah" untuk menyimpan tugas
    await tester.tap(find.text('Tambah'));
    await tester.pump();

    // Verifikasi: tugas baru muncul di list
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
    // Verifikasi: teks "Belum ada tugas" sudah hilang
    expect(find.text('Belum ada tugas'), findsNothing);
  });

  // ── Test 2: Toggle tugas selesai ──
  // Verifikasi bahwa checkbox bisa dicentang/uncentang.
  testWidgets('toggle tugas selesai', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Tambah tugas dulu
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas testing');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Checkbox awal: unchecked
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);

    // Tap checkbox untuk toggle
    await tester.tap(checkboxFinder);
    await tester.pump();

    // Verifikasi: checkbox sekarang checked
    final checkbox = tester.widget<Checkbox>(checkboxFinder);
    expect(checkbox.value, isTrue);
  });

  // ── Test 3: Hapus tugas ──
  // Verifikasi bahwa tombol delete menghapus tugas dari list.
  testWidgets('hapus tugas', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Tambah tugas
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas akan dihapus');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Tugas akan dihapus'), findsOneWidget);

    // Tap tombol delete
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    // Verifikasi: tugas sudah hilang, kembali ke state kosong
    expect(find.text('Tugas akan dihapus'), findsNothing);
    expect(find.text('Belum ada tugas'), findsOneWidget);
  });

  // ── Test 4: Navigasi GoRouter antar tab ──
  // Verifikasi NavigationBar berfungsi: pindah ke Stats dan kembali.
  testWidgets('navigasi antar tab ToDo dan Statistik', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Awal: halaman ToDo aktif
    expect(find.text('ToDo Riverpod'), findsOneWidget);

    // Tap tab "Statistik" di NavigationBar
    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();

    // Verifikasi: halaman Stats tampil
    expect(find.text('📊 Statistik'), findsOneWidget);

    // Tap kembali ke tab "ToDo"
    await tester.tap(find.text('ToDo'));
    await tester.pumpAndSettle();

    // Verifikasi: kembali ke halaman ToDo
    expect(find.text('ToDo Riverpod'), findsOneWidget);
  });

  // ── Test 5: State bertahan saat pindah tab ──
  // Verifikasi bahwa tugas tidak hilang saat berpindah ke Stats
  // dan kembali ke ToDo (karena ProviderScope di atas router).
  testWidgets('state ToDo bertahan saat pindah tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Tambah tugas
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas persistent');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Tugas persistent'), findsOneWidget);

    // Pindah ke Stats
    await tester.tap(find.text('Statistik'));
    await tester.pumpAndSettle();

    // Kembali ke ToDo
    await tester.tap(find.text('ToDo'));
    await tester.pumpAndSettle();

    // Verifikasi: tugas masih ada!
    expect(find.text('Tugas persistent'), findsOneWidget);
  });

  // ── Test 6: Filter provider turunan (belum selesai) ──
  testWidgets('filter hanya menampilkan tugas yang belum selesai', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Tambah 2 tugas
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas 1');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tugas 2');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Selesaikan tugas 1
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    // Pilih filter "Belum selesai" via menu
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belum selesai'));
    await tester.pumpAndSettle();

    // Tugas 1 (selesai) tersembunyi, Tugas 2 (belum selesai) tetap tampil
    expect(find.text('Tugas 1'), findsNothing);
    expect(find.text('Tugas 2'), findsOneWidget);
  });
}
