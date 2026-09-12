# #03 | Navigation & State Management — ToDo App



---

## Langkah-Langkah Pengerjaan

### Praktikum 1 — Navigasi Multi-Page dengan GoRouter

Membuat project `week3_navigation` dengan GoRouter untuk memahami konsep dasar navigasi deklaratif.

**Hasil Praktikum 1:**

| Home Page | Detail Page |
|:---------:|:-----------:|
| ![Home Page](screenshots/1.jpeg) | ![Detail Page](screenshots/2.jpeg) |

> Halaman Home menampilkan 10 item. Tap item → navigasi ke Detail dengan path parameter (`:id`). Path berubah mengikuti layar aktif.

---

### Praktikum 2 — State Management dengan Riverpod

Menambahkan Riverpod ke project `week3_todo` untuk mengelola state ToDo secara global.

**Provider yang dibuat:**

| Provider | Tipe | Fungsi |
|----------|------|--------|
| `todoListProvider` | `NotifierProvider<TodoListNotifier, List<Todo>>` | Menyimpan daftar tugas (add, toggle, remove) |
| `todoFilterProvider` | `NotifierProvider<TodoFilterNotifier, TodoFilter>` | Menyimpan filter aktif (semua/pending/completed) |
| `filteredTodoIndicesProvider` | `Provider<List<int>>` | Derived provider — menghitung index tugas terfilter |
| `uncompletedTodosProvider` | `Provider<List<Todo>>` | Derived provider — daftar tugas belum selesai |

**Hasil Praktikum 2:**

| State Kosong | Dialog Tambah | Input Tugas |
|:------------:|:-------------:|:-----------:|
| ![Kosong](screenshots/3.jpeg) | ![Dialog](screenshots/5.jpeg) | ![Input](screenshots/6.jpeg) |

| Tugas Ditambahkan | Toggle Selesai |
|:-----------------:|:--------------:|
| ![Ditambahkan](screenshots/7.jpeg) | ![Toggle](screenshots/8.jpeg) |

---

### Praktikum 3 — AsyncValue & Simulasi Asinkron

Membuat halaman Statistik yang menggunakan `AsyncNotifier` untuk mensimulasikan pengambilan data async.


**Hasil Praktikum 3:**

| Statistik (Data Lama) | Statistik (Data Baru — dari ToDo) |
|:---------------------:|:---------------------------------:|
| ![Stats Lama](screenshots/12.jpeg) | ![Stats Baru](screenshots/13.jpeg) |

> **Sebelum refactoring:** Stats menampilkan data statis generik (Pengguna Aktif, Transaksi).  
> **Sesudah refactoring:** Stats dihitung dari data ToDo sesungguhnya + progress bar.

---

### Praktikum 4 — Refactoring & GoRouter + NavigationBar

Mengintegrasikan semua fitur: GoRouter dengan `StatefulShellRoute`, NavigationBar, TodoTile terpisah, dan filter.

**Hasil Praktikum 4:**

| TodoPage + NavigationBar | Filter Dropdown | Statistik + Progress |
|:------------------------:|:---------------:|:--------------------:|
| ![Todo Nav](screenshots/9.jpeg) | ![Filter](screenshots/11.jpeg) | ![Stats Progress](screenshots/13.jpeg) |

| State Kosong Tab Stats | Tambah Tugas | Tugas Ditambahkan |
|:----------------------:|:------------:|:-----------------:|
| ![Stats Empty](screenshots/13.jpeg) | ![Add Dialog](screenshots/14.jpeg) | ![Added](screenshots/15.jpeg) |

---

### Praktikum 5 — Testing

Menulis unit test dan widget test untuk memverifikasi fungsionalitas.

**Widget Test (6 test):**

| No | Test | Verifikasi |
|---|------|------------|
| 1 | `menambah tugas baru` | FAB → dialog → tambah → muncul di list |
| 2 | `toggle tugas selesai` | Checkbox unchecked → checked |
| 3 | `hapus tugas` | Tap delete → item hilang → "Belum ada tugas" |
| 4 | `navigasi antar tab` | Tab ToDo ↔ Statistik via NavigationBar |
| 5 | `state bertahan saat pindah tab` | Tugas masih ada setelah pindah tab & kembali |
| 6 | `filter hanya menampilkan tugas belum selesai` | Toggle → filter "Belum selesai" → yang selesai tersembunyi |

**Unit Test (6 test):**

| No | Test | Verifikasi |
|---|------|------------|
| 1 | `state awal adalah AsyncLoading` | Provider baru → loading |
| 2 | `state setelah build selesai` | AsyncData ATAU AsyncError (karena 30% gagal) |
| 3 | `data sukses menghitung stats dari todo list` | 3 todo (1 selesai) → Total=3, Selesai=1, Pending=2 |
| 4 | `refresh() mengembalikan state ke loading` | State loading → resolve → bukan loading |
| 5 | `StatItem equality` | Objek dengan nilai sama dianggap equal |
| 6 | `state berubah secara immutable` | State sebelum ≠ state sesudah (referensi berbeda) |

**Hasil Testing:**

![Added](screenshots/16.png)

---

## AI Challenge


### Prompt yang Digunakan

**Prompt 1 — StatsPage (AsyncValue):**
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

**Prompt 2 — Refactoring & GoRouter:**
```
Refactoring Challenge:
- Pisahkan widget bar ToDo menjadi TodoTile tersendiri
- Ekstrak logika filter menjadi Provider turunan
- Integrasikan dengan GoRouter: / untuk daftar dan /stats untuk statistik
- Tambahkan NavigationBar dan widget test
```

### Perbaikan dari Output AI

| No | Output Awal AI | Masalah | Perbaikan |
|---|---------------|---------|-----------|
| 1 | `main.dart` import `product_page.dart` & `stats_page.dart` | Unused import warning | Hapus — navigasi dikelola `router.dart` |
| 2 | Test listener `(_, __)` | `unnecessary_underscores` di Dart 3 | Ganti ke `(_, _)` |
| 3 | Test 2 `Future.delayed(3s)` | Race condition: state masih loading | Polling loop tiap 100ms (max 10 detik) |
| 4 | `StateProvider<TodoFilter>` | `StateProvider` dihapus di Riverpod v3 | Ganti ke `NotifierProvider<TodoFilterNotifier, TodoFilter>` |
| 5 | `switch (filter) { case: ... }` statement | `body_might_complete_normally` | Ganti ke Dart 3 switch expression `return switch (filter) { ... }` |
| 6 | Widget test `pump()` setelah tap "Tambah" | Dialog TextField belum tertutup, teks ditemukan ganda | Tambahkan `controller.clear()` sebelum `Navigator.pop()` |

### AI Verification Checklist

- ✅ **State diubah secara immutable**, Tidak ada `state.add()` atau mutasi langsung
- ✅ **ref.watch hanya di build(), ref.read di callback**, Pola konsisten di seluruh app
- ✅ **Ketiga state AsyncValue ditangani**, loading, error, data` via `.when()
- ✅ **Provider dideklarasikan dengan tipe eksplisit**, Tidak ada ambiguitas
- ✅ **Tidak menggunakan API Riverpod usang**, Semua pola Riverpod v3
- ✅ **GoRouter berfungsi**, StatefulShellRoute + NavigationBar
- ✅ **flutter analyze tanpa issue, semua test lulus**, 12/12 passed

### Keputusan Teknis

| Keputusan | Alasan |
|-----------|--------|
| Menggunakan `StatefulShellRoute` bukan `GoRoute` biasa | Agar state tiap tab bertahan saat berpindah (tidak di-rebuild) |
| `Notifier` bukan `StateNotifier` | `StateNotifier` sudah deprecated di Riverpod v3 |
| Derived provider `filteredTodoIndicesProvider` mengembalikan `List<int>` (index) | Agar TodoTile bisa pakai index asli untuk toggle/remove tanpa mapping ulang |
| `StatsNotifier` sebagai `AsyncNotifier` yang `ref.watch(todoListProvider)` | Stats dihitung dari data real, bukan hardcoded — lebih kohesif |
| TodoTile diekstrak sebagai `ConsumerWidget` terpisah | Build() lebih bersih, bisa diuji independen, optimasi rebuild |

---

##  Hasil yang Dicapai

| Kriteria | Status |
|----------|--------|
| Minimal 2 halaman GoRouter | ✅ TodoPage (`/`) + StatsPage (`/stats`) |
| State Riverpod (Notifier) | ✅ `TodoListNotifier`, `TodoFilterNotifier`, `StatsNotifier` |
| UI menggunakan ConsumerWidget | ✅ `TodoPage`, `StatsPage`, `TodoTile` |
| AsyncValue: loading, error, success | ✅ StatsProvider — 2s delay, 30% error, `.when()` di UI |
| Minimal 1 unit/widget test lulus | ✅ **12/12 tests passed** |
| AI Challenge terdokumentasi | ✅ Prompt, hasil, perbaikan, dan keputusan teknis |
| Struktur `lib/`, `test/`, `README.md`, `screenshots/` | ✅ Lengkap |

---

##  Refleksi

### 1. Kapan `setState` masih cukup, dan kapan state harus naik ke Riverpod?

`setState` cukup untuk state **lokal satu widget** (animasi, show/hide password, form sementara). State harus naik ke Riverpod ketika **diakses lintas halaman** (ToDo list dibaca di TodoPage & StatsPage), **harus bertahan saat navigasi** (pindah tab tidak kehilangan data), atau **perlu di-test tanpa UI** (`ProviderContainer`).

### 2. Apa perbedaan `context.go` dan `context.push`?

| | `context.go` | `context.push` |
|-|-------------|----------------|
| **Stack** | Mengganti (reset) | Menumpuk (tambah) |
| **Back** | Tidak bisa kembali | Bisa kembali |
| **Contoh** | Login → Home, pindah tab | Home → Detail item |

Di project ini, perpindahan tab menggunakan `goBranch()` (varian `go`) karena berpindah section utama, bukan menumpuk halaman.

### 3. Bagaimana `AsyncValue` mencegah bug dibanding tiga boolean terpisah?

Tiga boolean (`isLoading`, `hasError`, `data`) bisa menghasilkan **state tidak valid** (loading + error bersamaan) dan **tidak exhaustive** (lupa handle error → UI blank). `AsyncValue` menjamin **mutual exclusivity** (hanya satu state aktif) dan `.when()` **memaksa** ketiga state ditangani saat compile-time. Di project ini, StatsNotifier 30% gagal — tanpa `AsyncValue`, error bisa tidak tertangani.

### 4. Bagian mana dari hasil AI yang diperbaiki?

| No | Masalah | Perbaikan |
|---|---------|-----------|
| 1 | `StateProvider` dihapus di Riverpod v3 | Ganti ke `NotifierProvider` |
| 2 | Switch statement warning `body_might_complete_normally` | Ganti ke Dart 3 switch expression |
| 3 | `(_, __)` lint error di Dart 3 | Ganti ke `(_, _)` |
| 4 | `Future.delayed(3s)` race condition di test | Polling loop 100ms (max 10 detik) |
| 5 | Widget test `findsOneWidget` gagal (teks ganda) | `controller.clear()` sebelum `Navigator.pop()` |
| 6 | Unused import di `main.dart` | Hapus import yang tidak terpakai |


