# AI Log — Praktikum 2: Generate & Verifikasi Fitur Search

## Prompt Mentah

```
Ikuti aturan di RULES.md.

Saya ingin menambahkan fitur pencarian judul pengumuman di halaman utama
Campus Notify. Fitur ini harus:

1. Menambahkan SearchBar/TextField di atas daftar pengumuman
2. Memfilter pengumuman berdasarkan judul (title) secara case-insensitive
3. Menampilkan empty state dengan icon dan pesan ketika tidak ada hasil
4. Menggunakan fungsi pure (bukan method di class) agar mudah di-test
5. Menyertakan unit test

Buat sesuai Clean Architecture:
- domain/usecases/filter_announcements.dart (fungsi pure filter)
- Update HomePage untuk menambahkan TextField dan logika filter
- Test file di test/features/announcements/filter_announcements_test.dart
```

## Output Awal AI

### File 1: `lib/features/announcements/domain/usecases/filter_announcements.dart`

```dart
import '../entities/announcement.dart';

/// Fungsi pure untuk memfilter list pengumuman berdasarkan query pada field title.
/// Pencarian bersifat case-insensitive.
/// Mengembalikan list kosong jika tidak ada yang cocok.
List<Announcement> filterAnnouncements(List<Announcement> items, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return items;

  return items.where((item) {
    return item.title.toLowerCase().contains(keyword);
  }).toList();
}
```

### File 2: Update `lib/pages/home_page.dart`

Perubahan yang dilakukan:
- Ditambahkan `TextEditingController _searchController` dan `String _searchQuery`
- Ditambahkan `dispose()` untuk membersihkan controller
- Ditambahkan `TextField` sebagai search bar di atas daftar pengumuman
- Ditambahkan logika filter menggunakan `filterAnnouncements()` di dalam `data:` callback
- Ditambahkan empty state widget dengan icon `Icons.search_off` dan pesan dinamis

### File 3: `test/features/announcements/filter_announcements_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:week6_campus_notify/features/announcements/domain/usecases/filter_announcements.dart';

void main() {
  final list = const [
    Announcement(id: '1', title: 'Jadwal UTS Dipercepat', body: '...', route: '/pengumuman/1', time: '08:00'),
    Announcement(id: '2', title: 'Pengumuman Beasiswa', body: '...', route: '/pengumuman/2', time: 'Kemarin'),
    Announcement(id: '3', title: 'Libur Nasional', body: '...', route: '/pengumuman/3', time: '2 hari lalu'),
  ];

  test('query kosong mengembalikan semua item', () {
    expect(filterAnnouncements(list, ''), hasLength(3));
  });

  test('filter abaikan huruf besar/kecil', () {
    expect(filterAnnouncements(list, 'LIBUR'), hasLength(1));
  });

  test('query tak cocok kembalikan kosong', () {
    expect(filterAnnouncements(list, 'zzz-tak-ada'), isEmpty);
  });
}
```

## Bug/Halusinasi yang Ditemukan

### Bug: `SearchAnnouncements` use case mencari di `title` DAN `body`, tapi `filterAnnouncements` hanya cari di `title`

**Konteks:**
Proyek sudah memiliki file `search_announcements.dart` (use case lama) yang mencari di **title dan body**.
Fungsi baru `filterAnnouncements` yang di-generate AI hanya mencari di **title** saja.

Ini bukan bug di kode AI per se, tapi inkonsistensi yang perlu diputuskan developer.
Dalam konteks tugas ini, kita memang hanya diminta **pencarian judul notes** — jadi behaviour `filterAnnouncements` yang hanya cari di title adalah **benar sesuai tugas**.

### Bukti grep:

```bash
# search_announcements.dart mencari di title DAN body:
grep -n "contains(keyword)" lib/features/announcements/domain/usecases/search_announcements.dart
# Output:
# 21:      return item.title.toLowerCase().contains(keyword) ||
# 22:          item.body.toLowerCase().contains(keyword);

# filter_announcements.dart hanya mencari di title:
grep -n "contains(keyword)" lib/features/announcements/domain/usecases/filter_announcements.dart
# Output:
# 11:    return item.title.toLowerCase().contains(keyword);
```

**Keputusan:** Dibiarkan hanya search title karena sesuai tugas "pencarian judul notes".
Jika ingin search body juga, tinggal tambahkan `|| item.body.toLowerCase().contains(keyword)`.


---

# AI Log — Praktikum 3: Debug dan Refactor

## 1. Reproduksi Bug
- **Gejala Bug:** Saat pengguna melakukan pencarian dengan spasi berlebih atau multi-spasi antar kata kunci (misalnya karena tidak sengaja menekan spasi dua kali saat mengetik di smartphone), hasil pencarian tidak menampilkan pengumuman yang sesuai dan langsung menampilkan empty state.
- **Input Pemicu:** Query `"jadwal  uts"` (dengan 2 spasi).
- **Target yang Seharusnya Cocok:** Pengumuman dengan judul `"Jadwal UTS Dipercepat"`.
- **Hasil Aktual (Bug):** Mengembalikan list kosong `[]` (Empty State "Tidak ditemukan pengumuman untuk 'jadwal  uts'").

## 2. Isolasi ke Use Case Murni
Logika filtering dipindahkan dan diisolasi ke dalam class use case murni di Domain layer (`lib/features/announcements/domain/usecases/filter_announcements.dart`):
```dart
class FilterAnnouncements {
  const FilterAnnouncements();
  List<Announcement> call(List<Announcement> items, String query);
}
```
Use case ini murni Dart standar, tanpa ketergantungan Flutter UI, Riverpod, SQLite, maupun Dio.

## 3. Test Merah (Bukti Bug dengan Kegagalan Test)
Unit test dibuat untuk membuktikan bug sebelum perbaikan kode:

```dart
test('query dengan multi-spasi tetap mencocokkan judul pengumuman', () {
  final result = filterAnnouncements(list, 'jadwal  uts');
  expect(result, hasLength(1));
  expect(result.first.id, '1');
});
```

**Output Kegagalan Test (Test Merah):**
```
00:00 +8 -1: filterAnnouncements query dengan multi-spasi tetap mencocokkan judul pengumuman [E]
  Expected: an object with length of <1>
    Actual: []
     Which: has length of <0>
  
  package:matcher                                                  expect
  package:flutter_test/src/widget_tester.dart 473:18               expect
  test\features\announcements\filter_announcements_test.dart 81:7  main.<fn>.<fn>

00:00 +8 -1: Some tests failed.
```

## 4. Perbaikan Kecil dan Hasil Test Hijau
Perbaikan dilakukan pada `filter_announcements.dart`:
1. Normalisasi query dengan regex `replaceAll(RegExp(r'\s+'), ' ')` untuk menggabungkan spasi berulang menjadi satu spasi.
2. Tokenisasi kata kunci (`split(' ')`) sehingga pencarian multi-kata memeriksa apakah setiap token kata terdapat di judul (`tokens.every((token) => title.contains(token))`).

**Hasil Verifikasi Setelah Perbaikan:**
```
00:00 +9: All tests passed!
```
Semua test hijau dan `flutter analyze` menghasilkan nol warning.

## 5. Akar Masalah (Root Cause Analysis)
Implementasi awal yang di-generate oleh AI mengandalkan string matching mentah:
`item.title.toLowerCase().contains(keyword)`
di mana `keyword = query.trim().toLowerCase()`.
- Fungsi `.trim()` hanya membuang spasi di awal dan akhir string, tetapi tidak membuang atau menormalkan multiple whitespace di antara kata kunci.
- Akibatnya, substring `"jadwal  uts"` dicari secara literal di dalam `"jadwal uts dipercepat"`. Karena jumlah spasi berbeda, perbandingan string literal gagal.
- AI sering kali menghasilkan pattern pencarian naive seperti ini jika tidak secara eksplisit diinstruksikan menangani normalisasi whitespace dan tokenized matching.


---

# AI Log — AI Challenge: Review Kode Search & Verifikasi Keputusan

## 1. Prompt Review AI
```
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

## 2. Tiga Temuan Reviewer AI
1. **Temuan 1 (Saran / Kebenaran):** Query yang mengandung tanda baca (misal `"beasiswa?"` atau `"uts!"`) tidak akan cocok dengan data judul `"Pengumuman Beasiswa"` karena tidak ada sanitasi tanda baca sebelum token matching.
2. **Temuan 2 (Blocker / Arsitektur):** Filter dilakukan di in-memory client side daripada query database SQLite atau endpoint API Dio. AI mengklaim ini tidak scalable.
3. **Temuan 3 (Saran / Maintainability):** Ada dua use case pencarian di folder domain (`search_announcements.dart` dan `filter_announcements.dart`) yang menimbulkan kebingungan arsitektural.

## 3. Verifikasi & Tindak Lanjut
- **Temuan 1 (Diterima & Diperbaiki):** Dibuktikan dengan test gagal di `filter_announcements_test.dart` (`Expected: length 1, Actual: []`). Diperbaiki di `filter_announcements.dart` dengan sanitasi `RegExp(r'[^\w\s]', unicode: true)`. Test sukses lolos.
- **Temuan 2 (Ditolak):** Ditolak secara teknis. Data pengumuman berukuran kecil (puluhan entri), in-memory filtering memberikan respon instan 0ms tanpa latency I/O, serta mencegah over-engineering race condition handling / debounce overhead.
- **Temuan 3 (Diterima):** Didokumentasikan pemisahan tanggung jawab: `filter_announcements.dart` untuk in-memory state filter di UI, `search_announcements.dart` untuk skenario remote query.


---

# AI Log — Refactoring, Testing, dan Error Umum

## 1. Prompt 5-Slot Framework & Context Engineering

Berikut adalah implementasi Prompt 5-Slot yang digunakan untuk memandu AI agar menghasilkan kode yang akurat tanpa halusinasi dan sesuai Clean Architecture:

```text
[SLOT 1: PERSONA]
Bertindaklah sebagai Senior Flutter Developer dan pakar Software Architecture (Clean Architecture & Riverpod).

[SLOT 2: KONTEKS PROYEK]
Proyek: Campus Notify (week6_campus_notify).
Stack: Flutter SDK ^3.13.5, flutter_riverpod, go_router, dio, flutter_secure_storage.
Arsitektur: Feature-first (presentation -> domain <- data).

[SLOT 3: TUGAS SPESIFIK]
1. Pecah widget pengumuman berukuran > 80 baris menjadi widget modular kecil (< 40 baris).
2. Pindahkan logika filtering dari widget ke use case murni di domain layer (FilterAnnouncements).
3. Buat file test/search_filter_test.dart berisi unit test logika pencarian dan widget test untuk empty state.

[SLOT 4: BATASAN & CONSTRAINTS]
- Layer domain TIDAK BOLEH mengimpor flutter, dio, atau sqflite (bebas framework).
- Widget TIDAK BOLEH memanggil database atau repository secara langsung.
- State dikelola oleh Riverpod Notifier, DILARANG menggunakan setState untuk query pencarian.
- Zero issues pada flutter analyze dan kode harus terformat rapi (dart format).

[SLOT 5: FORMAT OUTPUT & DELIVERABLES]
- Berikan kode implementasi widget terpisah di presentation/widgets/.
- Berikan test suite lengkap di test/search_filter_test.dart (unit + widget test).
- Sertakan penjelasan error umum dan solusinya.
```

## 2. Tabel Error Umum dan Solusinya

| Gejala | Penyebab Umum | Solusi Praktis |
|---|---|---|
| **Method tidak ada** | Halusinasi API oleh AI (mengarang method yang tidak ada di library/SDK). | Cek dokumentasi resmi di pub.dev / api.dart.dev dan manfaatkan autocomplete IDE. |
| **Import lintas layer** | Kurangnya konteks arsitektur pada prompt AI. | Tegaskan dependency rule di RULES.md / prompt 5-slot, lalu refactor import ilegal. |
| **Semua test merah** | Prompt terlalu besar atau mencakup terlalu banyak fitur sekaligus. | Batasi prompt: minta 1 fitur kecil + 1 test secara inkremental (TDD). |
| **Prompt diulang terus** | Mengulang prompt fix tanpa memahami bukti error atau langkah reproduksi. | Tulis langkah reproduksi konkret + input pemicu + test merah pembukti. |
| **Tak bisa menjelaskan** | Menerima kode AI mentah-mentah tanpa audit baris demi baris. | Baca ulang tiap baris, sederhanakan kode, dan pastikan setiap baris dipahami. |

## 3. Hasil Refactoring Ukuran File & Fungsi
- Semua widget pengumuman dipisahkan ke `lib/features/announcements/presentation/widgets/`:
  - `announcement_empty_state.dart`: 35 baris (< 80 baris)
  - `announcement_card.dart`: 36 baris (< 80 baris)
  - `announcement_search_bar.dart`: 38 baris (< 80 baris)
  - `announcement_list.dart`: 42 baris (< 80 baris)
- `lib/pages/home_page.dart` berkurang dari 338 baris menjadi 230 baris (terdiri dari widget-widget modular kecil < 40 baris).
- Semua test di `test/search_filter_test.dart` lulus (5 unit test + 3 widget test).
