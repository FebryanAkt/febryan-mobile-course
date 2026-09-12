# Dokumentasi AI — StatsPage (AsyncValue + Riverpod)

## Prompt yang Digunakan

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

## File yang Dihasilkan AI

| File | Deskripsi |
|------|-----------|
| `lib/providers/stats_provider.dart` | `StatsNotifier` (AsyncNotifier) + model `StatItem` + provider declaration |
| `lib/pages/stats_page.dart` | `StatsPage` (ConsumerWidget) dengan penanganan 3 state |
| `test/stats_notifier_test.dart` | 6 unit test untuk notifier |

## AI Verification Checklist

### ✅ 1. State diubah secara immutable?
**YA** — Tidak ada `state.add()` atau mutasi list langsung. Setiap perubahan state
menggunakan assignment baru (`state = const AsyncLoading(...)`, `state = await AsyncValue.guard(...)`).
List yang dikembalikan `_fetch()` juga `const`.

### ✅ 2. `ref.watch` hanya di `build()`, `ref.read` di callback?
**YA** —
- `ref.watch(statsProvider)` → dipanggil di dalam `build()` (baris 22, stats_page.dart)
- `ref.read(statsProvider.notifier).refresh()` → dipanggil di `onPressed` callback (baris 34)
- `ref.invalidate(statsProvider)` → dipanggil di `onPressed` callback (baris 82)

### ✅ 3. Ketiga state AsyncValue ditangani?
**YA** — `statsAsync.when()` menangani:
- `loading:` → `CircularProgressIndicator` + teks "Memuat statistik..."
- `error:` → Icon error + pesan + tombol "Coba lagi"
- `data:` → `ListView.builder` menampilkan 3 `StatItem`

### ✅ 4. Provider dideklarasikan dengan tipe eksplisit, tidak duplikat?
**YA** — `AsyncNotifierProvider<StatsNotifier, List<StatItem>>` dideklarasikan
dengan tipe generik lengkap. Tidak ada duplikasi dengan provider lain
(`todoListProvider` bertipe `NotifierProvider<TodoListNotifier, List<Todo>>`).

### ✅ 5. Tidak menggunakan API Riverpod usang?
**YA** — Kode menggunakan pola modern Riverpod v2/v3:
- `AsyncNotifier` (bukan `StateNotifier`)
- `AsyncNotifierProvider` (bukan `StateNotifierProvider`)
- `ConsumerWidget` (bukan `Consumer` bertingkat)
- Tidak ada `StateProvider`

### ✅ 6. `flutter analyze` dan `flutter test` lolos?
Jalankan perintah berikut untuk memverifikasi:
```bash
flutter analyze
flutter test test/stats_notifier_test.dart
```

## Perbaikan yang Dilakukan

| # | Output Awal AI | Perbaikan |
|---|---------------|-----------|
| 1 | `main.dart` import `product_page.dart` & `stats_page.dart` yang tidak dipakai | Hapus unused import (navigasi dilakukan di `todo_page.dart`) |
| 2 | Test menggunakan `(_, __)` pada listener callback | Ganti ke `(_, _)` — Dart 3 tidak perlu double underscore |
| 3 | Test 2 gagal karena race condition: `Future.delayed(3s)` tidak cukup menunggu state berubah | Ganti ke polling-based wait: loop cek `isLoading` tiap 100ms (max 10 detik) |

## Hasil Testing

```
flutter analyze → No issues found! (ran in 4.1s)

flutter test   → 00:00 +1: state awal adalah AsyncLoading
                 00:02 +2: setelah build selesai, state adalah AsyncData atau AsyncError
                 00:08 +3: data sukses berisi 3 StatItem dengan nilai yang benar
                 00:13 +4: refresh() mengembalikan state ke loading lalu resolve
                 00:13 +5: StatItem equality bekerja dengan benar
                 00:18 +6: All tests passed!
```

## Penjelasan Arsitektur

```
┌─────────────────────────────────────────────┐
│                 StatsPage                   │
│            (ConsumerWidget)                 │
│                                             │
│  ref.watch(statsProvider) ──► AsyncValue    │
│                                             │
│  .when(                                     │
│    loading → Spinner                        │
│    error   → Error msg + Retry button       │
│    data    → ListView 3 items               │
│  )                                          │
└──────────────────┬──────────────────────────┘
                   │ watches
                   ▼
┌─────────────────────────────────────────────┐
│          statsProvider                      │
│  AsyncNotifierProvider<StatsNotifier,       │
│                        List<StatItem>>      │
└──────────────────┬──────────────────────────┘
                   │ creates
                   ▼
┌─────────────────────────────────────────────┐
│          StatsNotifier                      │
│        (AsyncNotifier)                      │
│                                             │
│  build()   → delay 2s, 30% fail             │
│  refresh() → AsyncLoading → guard(_fetch)   │
│  _fetch()  → delay 2s, 30% fail, return 3   │
└─────────────────────────────────────────────┘
```
