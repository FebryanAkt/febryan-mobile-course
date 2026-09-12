import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/todo_provider.dart';
import 'package:week3_todo/providers/stats_provider.dart';

// ──────────────────────────────────────────────────────────────────
// Unit test untuk StatsNotifier.
//
// Menggunakan ProviderContainer dengan overrides untuk menyediakan
// data todo yang deterministik (tanpa bergantung pada UI).
// ──────────────────────────────────────────────────────────────────

void main() {
  late ProviderContainer container;

  /// Helper: buat container dengan todo list yang sudah terisi
  ProviderContainer createContainer({List<Todo>? initialTodos}) {
    return ProviderContainer(
      overrides: [
        if (initialTodos != null)
          todoListProvider.overrideWith(() {
            return _SeededTodoNotifier(initialTodos);
          }),
      ],
    );
  }

  tearDown(() {
    container.dispose();
  });

  // ── Test 1: State awal harus AsyncLoading ──
  test('state awal adalah AsyncLoading', () {
    container = createContainer(
      initialTodos: [Todo('Test 1'), Todo('Test 2', done: true)],
    );
    final state = container.read(statsProvider);
    expect(state, isA<AsyncLoading<List<StatItem>>>());
  });

  // ── Test 2: Setelah build selesai, state bukan loading ──
  test('setelah build selesai, state adalah AsyncData atau AsyncError',
      () async {
    container = createContainer(
      initialTodos: [Todo('A'), Todo('B', done: true)],
    );

    AsyncValue<List<StatItem>>? finalState;
    container.listen(statsProvider, (prev, next) {
      finalState = next;
    });

    // Tunggu hingga state resolve (max 10 detik)
    for (var i = 0; i < 100; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (finalState != null && !finalState!.isLoading) break;
    }

    final state = container.read(statsProvider);
    expect(
      state is AsyncData<List<StatItem>> ||
          state is AsyncError<List<StatItem>>,
      isTrue,
      reason: 'State harus AsyncData atau AsyncError, got: $state',
    );
  });

  // ── Test 3: Data sukses berisi 3 StatItem dengan nilai benar ──
  test('data sukses menghitung stats dari todo list', () async {
    List<StatItem>? result;

    // Coba hingga 10 kali karena ada kemungkinan gagal 30%
    for (var attempt = 0; attempt < 10; attempt++) {
      final testContainer = createContainer(
        initialTodos: [
          Todo('Tugas 1'),
          Todo('Tugas 2', done: true),
          Todo('Tugas 3'),
        ],
      );
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

    expect(result, isNotNull,
        reason: 'Harus berhasil minimal 1x dari 10 percobaan');
    expect(result!.length, equals(3));

    // Verifikasi stats dihitung dari todo data (3 total, 1 selesai, 2 pending)
    expect(result[0], equals(const StatItem(label: 'Total Tugas', value: 3)));
    expect(result[1], equals(const StatItem(label: 'Selesai', value: 1)));
    expect(
        result[2], equals(const StatItem(label: 'Belum Selesai', value: 2)));
  });

  // ── Test 4: refresh() mengubah state ke loading lalu resolve ──
  test('refresh() mengembalikan state ke loading lalu resolve', () async {
    container = createContainer(
      initialTodos: [Todo('X')],
    );
    container.listen(statsProvider, (_, _) {});

    await Future.delayed(const Duration(seconds: 3));

    final notifier = container.read(statsProvider.notifier);
    final refreshFuture = notifier.refresh();

    expect(container.read(statsProvider).isLoading, isTrue);

    await refreshFuture;

    final stateAfter = container.read(statsProvider);
    expect(stateAfter.isLoading, isFalse);
  });

  // ── Test 5: StatItem equality ──
  test('StatItem equality bekerja dengan benar', () {
    const a = StatItem(label: 'Test', value: 42);
    const b = StatItem(label: 'Test', value: 42);
    const c = StatItem(label: 'Lain', value: 99);

    expect(a, equals(b));
    expect(a, isNot(equals(c)));
  });

  // ── Test 6: State immutability ──
  test('state berubah secara immutable', () async {
    container = createContainer(
      initialTodos: [Todo('Immutable test')],
    );
    container.listen(statsProvider, (_, _) {});
    await Future.delayed(const Duration(seconds: 3));

    final stateBefore = container.read(statsProvider);
    await container.read(statsProvider.notifier).refresh();
    final stateAfter = container.read(statsProvider);

    expect(identical(stateBefore, stateAfter), isFalse);
  });
}

/// Helper Notifier untuk menyediakan todo list awal di test.
class _SeededTodoNotifier extends TodoListNotifier {
  final List<Todo> _seed;
  _SeededTodoNotifier(this._seed);

  @override
  List<Todo> build() => _seed;
}
