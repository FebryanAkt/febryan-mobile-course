# Dokumentasi AI — Refactoring & Testing (Week 3 ToDo)

## Prompt yang Digunakan

### Prompt 1: StatsPage (AsyncValue)
```
Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.
```

### Prompt 2: Refactoring & GoRouter
```
Refactoring Challenge:
- Pisahkan widget bar ToDo menjadi TodoTile tersendiri
- Ekstrak logika filter menjadi Provider turunan
- Integrasikan dengan GoRouter: / untuk daftar dan /stats untuk statistik
- Tambahkan NavigationBar dan widget test
```

---

## File yang Dihasilkan / Diubah

| File | Deskripsi |
|------|-----------|
| `lib/providers/stats_provider.dart` | `StatsNotifier` (AsyncNotifier) + model `StatItem` |
| `lib/providers/filtered_todo_provider.dart` | **BARU** — Derived provider: `TodoFilterNotifier` + `filteredTodoIndicesProvider` |
| `lib/widgets/todo_tile.dart` | **BARU** — Widget `TodoTile` diekstrak dari TodoPage |
| `lib/router.dart` | **BARU** — GoRouter config dengan `StatefulShellRoute` + NavigationBar |
| `lib/main.dart` | **DIUBAH** — `MaterialApp` → `MaterialApp.router` dengan GoRouter |
| `lib/pages/todo_page.dart` | **DIUBAH** — Gunakan `TodoTile`, filter dropdown, hapus navigasi manual |
| `lib/pages/stats_page.dart` | Halaman statistik dengan AsyncValue.when() |
| `test/stats_notifier_test.dart` | 6 unit test untuk StatsNotifier |
| `test/widget_test.dart` | **BARU** — 5 widget test (CRUD + navigasi + state persistence) |

---

## AI Verification Checklist

### ✅ 1. State diubah secara immutable?
**YA** — Tidak ada `state.add()` atau mutasi list langsung.
- `TodoListNotifier`: `state = [...state, Todo(title)]` (list baru)
- `StatsNotifier`: `state = const AsyncLoading()` / `state = await AsyncValue.guard(...)`
- `TodoFilterNotifier`: `state = filter` (enum, selalu immutable)

### ✅ 2. `ref.watch` hanya di `build()`, `ref.read` di callback?
**YA** —
- `ref.watch(statsProvider)` → di `build()` StatsPage
- `ref.watch(filteredTodoIndicesProvider)` → di `build()` TodoPage
- `ref.watch(todoListProvider)` → di `build()` TodoTile
- `ref.read(statsProvider.notifier).refresh()` → di `onPressed`
- `ref.read(todoFilterProvider.notifier).setFilter(...)` → di `onSelected`

### ✅ 3. Ketiga state AsyncValue ditangani (bukan hanya success)?
**YA** — `statsAsync.when()` menangani:
- `loading:` → `CircularProgressIndicator` + teks
- `error:` → Icon error + pesan + tombol "Coba lagi"
- `data:` → `ListView.builder`

### ✅ 4. Provider dideklarasikan dengan tipe eksplisit, tidak duplikat?
**YA** —
- `AsyncNotifierProvider<StatsNotifier, List<StatItem>>`
- `NotifierProvider<TodoListNotifier, List<Todo>>`
- `NotifierProvider<TodoFilterNotifier, TodoFilter>`
- `Provider<List<int>>` (filteredTodoIndicesProvider)
- Tidak ada duplikasi antar provider.

### ✅ 5. Tidak menggunakan API Riverpod usang?
**YA** — Semua menggunakan pola Riverpod v3:
- `Notifier` / `AsyncNotifier` (bukan `StateNotifier`)
- `NotifierProvider` / `AsyncNotifierProvider` (bukan `StateNotifierProvider`)
- `ConsumerWidget` (bukan `Consumer` bertingkat)
- ~~`StateProvider`~~ → diganti `NotifierProvider` (sudah dihapus di v3)

### ✅ 6. Navigasi GoRouter bekerja?
**YA** —
- `StatefulShellRoute.indexedStack` dengan NavigationBar
- `/` → TodoPage, `/stats` → StatsPage
- State bertahan saat pindah tab (dibuktikan widget test)

### ✅ 7. `flutter analyze` tanpa issue dan semua test lulus?
**YA** — Lihat hasil di bawah.

---

## Perbaikan yang Dilakukan dari Output AI

| # | Output Awal AI | Masalah | Perbaikan |
|---|---------------|---------|-----------|
| 1 | `main.dart` import `product_page.dart` & `stats_page.dart` | Unused import warning | Hapus — navigasi di `todo_page.dart` |
| 2 | Test listener `(_, __)` | `unnecessary_underscores` di Dart 3 | Ganti ke `(_, _)` |
| 3 | Test 2 `Future.delayed(3s)` | Race condition: state masih loading | Polling loop tiap 100ms (max 10 detik) |
| 4 | `StateProvider<TodoFilter>` | `StateProvider` dihapus di Riverpod v3 | Ganti ke `NotifierProvider<TodoFilterNotifier, TodoFilter>` |
| 5 | `switch (filter) { case: ... }` statement | `body_might_complete_normally` | Ganti ke Dart 3 switch expression `return switch (filter) { ... }` |
| 6 | Widget test `pump()` setelah tap "Tambah" | Dialog TextField belum tertutup sehingga teks ditemukan ganda | Tambahkan `controller.clear()` sebelum `Navigator.pop()` sehingga `pump()` langsung lulus sesuai modul |

---

## Hasil Testing

```
flutter analyze → No issues found!

flutter test →
  All 12 tests passed! (6 unit test StatsNotifier + 6 widget test UI/GoRouter/Riverpod)
```

---

## Arsitektur Setelah Refactoring

```
┌──────────────────────────────────────────────────────┐
│              ProviderScope (root)                    │
│    State bertahan di sini, di atas router             │
├──────────────────────────────────────────────────────┤
│          MaterialApp.router (GoRouter)               │
├──────────────────────────────────────────────────────┤
│        StatefulShellRoute + NavigationBar             │
│  ┌────────────────┐    ┌────────────────────────┐    │
│  │  / (ToDo tab)  │    │  /stats (Stats tab)    │    │
│  │                │    │                        │    │
│  │  TodoPage      │    │  StatsPage             │    │
│  │  ├─ TodoTile   │    │  └─ AsyncValue.when()  │    │
│  │  ├─ TodoTile   │    │     ├─ loading          │    │
│  │  └─ TodoTile   │    │     ├─ error            │    │
│  │                │    │     └─ data             │    │
│  └───────┬────────┘    └──────────┬─────────────┘    │
│          │                        │                   │
│  ┌───────▼────────┐    ┌──────────▼─────────────┐    │
│  │ todoListProvider│    │ statsProvider           │    │
│  │ todoFilterProv. │    │ (AsyncNotifier)         │    │
│  │ filteredIndices │    │                        │    │
│  └────────────────┘    └────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

## Struktur Folder Final

```
lib/
├── main.dart                          ← Entry point + MaterialApp.router
├── router.dart                        ← GoRouter + StatefulShellRoute
├── pages/
│   ├── todo_page.dart                 ← ToDo list + filter dropdown
│   ├── product_page.dart              ← Produk (AsyncValue demo)
│   └── stats_page.dart                ← Statistik (AsyncValue demo)
├── providers/
│   ├── todo_provider.dart             ← TodoListNotifier (Notifier)
│   ├── filtered_todo_provider.dart    ← Filter enum + derived provider
│   ├── products_provider.dart         ← ProductsNotifier (AsyncNotifier)
│   └── stats_provider.dart            ← StatsNotifier (AsyncNotifier)
└── widgets/
    └── todo_tile.dart                 ← Extracted TodoTile widget

test/
├── stats_notifier_test.dart           ← 6 unit test
└── widget_test.dart                   ← 5 widget test

docs/
└── README.md                          ← Dokumentasi ini
```
