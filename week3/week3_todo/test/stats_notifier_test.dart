import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/stats_provider.dart';

// ──────────────────────────────────────────────────────────────────
// Unit test untuk StatsNotifier.
//
// Menggunakan ProviderContainer untuk membuat environment Riverpod
// tanpa widget (headless). Ini memungkinkan kita menguji logic
// notifier secara terpisah dari UI.
// ──────────────────────────────────────────────────────────────────

void main() {
  // Buat ProviderContainer baru untuk setiap test agar state
  // tidak bocor antar test case (isolasi).
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  // Selalu dispose container setelah test selesai
  // untuk mencegah memory leak.
  tearDown(() {
    container.dispose();
  });

  // ── Test 1: State awal harus AsyncLoading ──
  // Saat provider pertama kali dibaca, build() belum selesai,
  // jadi state seharusnya loading.
  test('state awal adalah AsyncLoading', () {
    // Membaca provider memicu build() yang async
    final state = container.read(statsProvider);

    // Sebelum Future selesai, state harus loading
    expect(state, isA<AsyncLoading<List<StatItem>>>());
  });

  // ── Test 2: Setelah build() selesai, state harus data ATAU error ──
  // Karena ada 30% kemungkinan gagal, kita hanya bisa memastikan
  // state bukan loading lagi setelah menunggu.
  test('setelah build selesai, state adalah AsyncData atau AsyncError', () async {
    // Listen agar provider tetap aktif dan tidak di-dispose.
    // Gunakan Completer untuk menunggu state berubah dari loading
    // alih-alih mengandalkan delay tetap (menghindari race condition).
    AsyncValue<List<StatItem>>? finalState;

    container.listen(statsProvider, (prev, next) {
      finalState = next;
    });

    // Tunggu hingga state bukan loading lagi (max 10 detik sebagai safety net)
    for (var i = 0; i < 100; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (finalState != null && !finalState!.isLoading) break;
    }

    final state = container.read(statsProvider);

    // Harus salah satu: data atau error
    expect(
      state is AsyncData<List<StatItem>> || state is AsyncError<List<StatItem>>,
      isTrue,
      reason: 'State harus AsyncData atau AsyncError setelah build selesai, got: $state',
    );
  });

  // ── Test 3: Jika berhasil, data harus berisi 3 StatItem ──
  // Kita jalankan berkali-kali sampai dapat hasil sukses,
  // lalu verifikasi isi datanya.
  test('data sukses berisi 3 StatItem dengan nilai yang benar', () async {
    List<StatItem>? result;

    // Coba hingga 10 kali karena ada kemungkinan gagal 30%
    for (var i = 0; i < 10; i++) {
      final testContainer = ProviderContainer();
      testContainer.listen(statsProvider, (_, _) {});

      await Future.delayed(const Duration(seconds: 3));

      final state = testContainer.read(statsProvider);
      if (state is AsyncData<List<StatItem>>) {
        result = state.value;
        testContainer.dispose();
        break;
      }
      testContainer.dispose();
    }

    // Pastikan setidaknya satu percobaan berhasil
    expect(result, isNotNull, reason: 'Seharusnya berhasil setidaknya 1x dari 10 percobaan');

    // Verifikasi jumlah item
    expect(result!.length, equals(3));

    // Verifikasi isi data (immutable, selalu sama jika sukses)
    expect(result[0], equals(const StatItem(label: 'Pengguna Aktif', value: 1250)));
    expect(result[1], equals(const StatItem(label: 'Transaksi Hari Ini', value: 340)));
    expect(result[2], equals(const StatItem(label: 'Pendapatan (Juta)', value: 75)));
  });

  // ── Test 4: refresh() mengubah state ke loading lalu ke hasil baru ──
  test('refresh() mengembalikan state ke loading lalu resolve', () async {
    container.listen(statsProvider, (_, _) {});

    // Tunggu build() awal selesai
    await Future.delayed(const Duration(seconds: 3));

    // Panggil refresh pada notifier (ref.read di callback, bukan ref.watch)
    final notifier = container.read(statsProvider.notifier);

    // refresh() akan set state ke AsyncLoading, lalu fetch ulang
    // Kita tidak await agar bisa cek state loading
    final refreshFuture = notifier.refresh();

    // Sesaat setelah refresh(), state harus loading
    expect(container.read(statsProvider).isLoading, isTrue);

    // Tunggu refresh selesai
    await refreshFuture;

    // Setelah refresh, state harus data atau error (bukan loading)
    final stateAfter = container.read(statsProvider);
    expect(stateAfter.isLoading, isFalse);
  });

  // ── Test 5: StatItem equality (immutability check) ──
  // Memastikan objek StatItem dengan nilai sama dianggap equal.
  // Ini penting karena Riverpod membandingkan state lama vs baru
  // untuk menentukan apakah perlu rebuild widget.
  test('StatItem equality bekerja dengan benar', () {
    const a = StatItem(label: 'Test', value: 42);
    const b = StatItem(label: 'Test', value: 42);
    const c = StatItem(label: 'Lain', value: 99);

    expect(a, equals(b)); // Sama label & value → equal
    expect(a, isNot(equals(c))); // Beda → not equal
  });

  // ── Test 6: State diubah secara immutable ──
  // Memverifikasi bahwa notifier tidak memutasi state secara langsung.
  test('state berubah secara immutable (objek baru, bukan mutasi)', () async {
    container.listen(statsProvider, (_, _) {});
    await Future.delayed(const Duration(seconds: 3));

    final stateBefore = container.read(statsProvider);

    // Refresh untuk mendapat state baru
    await container.read(statsProvider.notifier).refresh();

    final stateAfter = container.read(statsProvider);

    // State harus objek yang berbeda (bukan referensi yang sama)
    // karena kita selalu membuat AsyncValue baru
    expect(identical(stateBefore, stateAfter), isFalse);
  });
}
