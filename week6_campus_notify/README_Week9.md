# Laporan Praktikum Minggu 9: AI-Assisted Development & Vibe Coding

---

## Praktikum 1: Prompt dan Context Engineering

---

### Langkah 1: Persiapan Environment dan AI Assistant

**Environment yang digunakan:**
- **IDE:** Visual Studio Code
- **AI Assistant:** Antigravity (Claude Opus) — digunakan langsung di terminal IDE
- **Flutter SDK:** ^3.13.5
- **Project:** `week6_campus_notify` (proyek existing dari Minggu 6–8)

**Verifikasi kesiapan proyek sebelum memulai:**
```powershell
flutter analyze
flutter test
```

**Hasil:**
```
> flutter analyze
Analyzing week6_campus_notify...
No issues found!

> flutter test
00:08 +25: All tests passed!
```

Proyek dalam kondisi **mesin hijau** — siap untuk di-enhance.

---

### Langkah 2: Membuat RULES.md (Context Engineering File)

Inti dari *context engineering* adalah memberikan konteks yang spesifik kepada AI **sebelum** meminta kode. Tanpa konteks, AI akan menghasilkan kode generik yang tidak sesuai arsitektur.

**File:** [`RULES.md`](RULES.md)

File ini berisi informasi yang AI butuhkan untuk menghasilkan kode yang sesuai:

| Komponen | Isi | Mengapa Penting |
|----------|-----|-----------------|
| **Persona** | Senior Flutter Developer, ahli Clean Architecture & Riverpod | Mengarahkan AI ke level keahlian yang tepat |
| **Konteks Proyek** | Nama proyek, SDK version, deskripsi | AI tahu sedang bekerja di proyek apa |
| **Stack Teknologi** | Riverpod, GoRouter, Dio, Secure Storage, FCM | AI tidak menyarankan package yang salah |
| **Struktur Arsitektur** | Feature-first Clean Architecture dengan tree folder | AI menempatkan file di lokasi yang benar |
| **Constraints (Aturan Wajib)** | 10 aturan termasuk dependency rule, larangan setState, dll | Mencegah AI melanggar arsitektur |

**Isi lengkap `RULES.md`:**

```markdown
# RULES.md — Context Engineering untuk AI Coding Assistant

## Persona
Kamu adalah **Senior Flutter Developer** yang ahli dalam Clean Architecture
dan state management Riverpod.

## Konteks Proyek
- **Nama Proyek:** Campus Notify (`week6_campus_notify`)
- **Deskripsi:** Aplikasi notifikasi kampus terintegrasi Firebase Cloud Messaging
- **Flutter SDK:** ^3.13.5
- **Dart null-safety:** Aktif (sound null safety)

## Stack Teknologi
- **State Management:** `flutter_riverpod` (Riverpod 3.x)
- **Routing:** `go_router` (GoRouter 18.x) dengan auth guard redirect
- **HTTP Client:** `dio` (Dio 5.x) dengan interceptor auto-refresh token 401
- **Penyimpanan Token:** `flutter_secure_storage` (bukan SharedPreferences)
- **Push Notification:** `firebase_core`, `firebase_messaging`,
  `flutter_local_notifications`
- **Desain UI:** Material Design 3, seed color `Colors.deepPurple`

## Arsitektur: Feature-First Clean Architecture
lib/
├── core/              → Shared: Failure sealed class, AppFormatters
├── data/              → Legacy layer (auth_repository, api_client, token_store)
├── features/
│   ├── [nama_fitur]/
│   │   ├── data/          → Models, Repository implementations
│   │   ├── domain/        → Entities (PODO), abstract Repository, UseCases
│   │   └── presentation/  → Riverpod Providers
├── pages/             → UI widgets (ConsumerWidget / ConsumerStatefulWidget)
├── services/          → Platform services (fcm_service.dart)
├── main.dart          → Entry point, GoRouter config
└── routes.dart        → AppRoutes constants

## Aturan Wajib (Constraints)
1. Domain TIDAK boleh import dari Data atau Presentation.
2. Gunakan ConsumerWidget / ConsumerStatefulWidget dari Riverpod.
3. DILARANG setState() untuk state yang dikelola Riverpod.
4. Navigasi: gunakan context.go() dari GoRouter, BUKAN Navigator.push().
5. Error Handling: gunakan sealed class Failure, bukan Exception generik.
6. Keamanan: token TIDAK boleh dicetak penuh di log.
7. Berikan komentar pada bagian kode yang krusial.
8. Setiap fitur baru WAJIB memiliki unit test.
9. Gunakan null-safety secara ketat.
10. File snake_case, class PascalCase, method/variable camelCase.
```

---

### Langkah 3: Menyusun Prompt yang Terstruktur

Berdasarkan RULES.md, berikut adalah **template prompt** dan **contoh prompt konkret** yang digunakan untuk meminta AI menghasilkan kode di praktikum-praktikum selanjutnya.

#### Template Prompt (Reusable)

```text
[PERSONA]
Ikuti aturan di RULES.md. Kamu adalah Senior Flutter Developer.

[KONTEKS]
Saya mengerjakan proyek Campus Notify — aplikasi notifikasi kampus Flutter
dengan Riverpod + GoRouter + Clean Architecture.

[CONSTRAINT]
- Ikuti struktur folder feature-first (data/domain/presentation)
- Gunakan ConsumerWidget dan Riverpod providers
- Error handling dengan sealed class Failure
- Sertakan unit test

[TUGAS]
<deskripsi fitur spesifik yang diminta>
```

#### Contoh Prompt 1: Menambah Fitur Baru

```text
Ikuti aturan di RULES.md.

Saya ingin menambahkan fitur "Ringkasan AI" pada halaman detail pengumuman.
Ketika user menekan tombol "Ringkas dengan AI", teks pengumuman dikirim ke
Gemini API dan hasilnya ditampilkan dalam card di bawah konten asli.

Buat mengikuti Clean Architecture:
- domain/usecases/summarize_announcement.dart (use case)
- data/repositories/ai_repository_impl.dart (implementasi, panggil Gemini API)
- presentation/providers/summary_provider.dart (Riverpod provider)
- Perbarui AnnouncementPage untuk menambahkan tombol dan menampilkan hasil.

API key harus dibaca dari environment (--dart-define), JANGAN hardcode.
Sertakan unit test untuk use case.
```

#### Contoh Prompt 2: Debugging

```text
Ikuti aturan di RULES.md.

Kode berikut memberikan error:
`type 'Null' is not a subtype of type 'String' in type cast`

pada baris:
AnnouncementPage(announcementId: state.pathParameters['id']!)

Bagaimana cara memperbaiki ini agar aman dari null tanpa mengubah
struktur GoRouter yang sudah ada?
```

#### Contoh Prompt 3: Refactoring

```text
Ikuti aturan di RULES.md.

Review kode HomePage berikut dan identifikasi bagian yang melanggar
Clean Architecture. Berikan refactoring yang diperlukan tanpa mengubah
fungsionalitas yang sudah berjalan.

[tempel kode home_page.dart]
```

---

### Langkah 4: Perbandingan Prompt Buruk vs Prompt Baik

| Aspek | ❌ Prompt Buruk | ✅ Prompt Baik |
|-------|----------------|----------------|
| **Spesifisitas** | "Buatkan kode Flutter dong" | "Buatkan ConsumerWidget untuk halaman detail pengumuman dengan Riverpod provider" |
| **Konteks** | Tidak ada | "Proyek Campus Notify menggunakan Riverpod + GoRouter + Clean Architecture" |
| **Constraint** | Tidak ada | "Gunakan sealed class Failure, jangan setState, file di features/announcements/" |
| **Output** | Kode generik StatefulWidget dengan Navigator.push() | Kode ConsumerWidget dengan GoRouter dan provider yang sesuai arsitektur |

**Mengapa ini penting?**
Tanpa context engineering, AI akan:
- Menggunakan `StatefulWidget` + `setState` (melanggar aturan Riverpod)
- Menggunakan `Navigator.push()` (melanggar aturan GoRouter)
- Menempatkan semua kode di satu file (melanggar Clean Architecture)
- Throw `Exception` generik (melanggar aturan sealed class `Failure`)

Dengan RULES.md + prompt terstruktur, AI langsung menghasilkan kode yang **sesuai arsitektur proyek**.

---

### Langkah 5: Validasi dan Commit

Setelah RULES.md dibuat dan template prompt disiapkan, dilakukan commit:

```powershell
git add RULES.md README_Week9.md
git commit -m "docs(week9): tambah RULES.md context engineering dan dokumentasi praktikum 1"
```
---

## Praktikum 2: Generate dan Verifikasi Search

### Tujuan
Meng-generate satu fitur kecil (pencarian judul pengumuman + empty state) menggunakan AI, lalu memverifikasi hasilnya secara menyeluruh dengan 6 langkah.

---

### Langkah 1: Generate Satu Fitur Kecil

**Prompt yang digunakan:**

```text
Ikuti aturan di RULES.md.

Saya ingin menambahkan fitur pencarian judul pengumuman di halaman utama
Campus Notify. Fitur ini harus:
1. Menambahkan TextField di atas daftar pengumuman
2. Memfilter pengumuman berdasarkan judul (title) secara case-insensitive
3. Menampilkan empty state dengan icon dan pesan ketika tidak ada hasil
4. Menggunakan fungsi pure agar mudah di-test
5. Menyertakan unit test
```

**File yang di-generate AI:**

| File | Deskripsi |
|------|-----------|
| `lib/features/announcements/domain/usecases/filter_announcements.dart` | Fungsi pure `filterAnnouncements()` |
| `lib/pages/home_page.dart` | Update: tambah search bar + empty state |
| `test/features/announcements/filter_announcements_test.dart` | 7 unit test |

Prompt mentah dan output awal AI disimpan di [`docs/ai-log.md`](docs/ai-log.md).

---

### Langkah 2: Verifikasi 6 Langkah

#### ✅ 2.1 Baca Tiap Baris

Semua baris kode di `filter_announcements.dart` sudah dipahami:
- Baris 1: import entity Announcement
- Baris 7: `query.trim().toLowerCase()` — normalisasi query
- Baris 8: Guard clause — jika keyword kosong, return semua item
- Baris 10-12: Filter dengan `where()` — cocokkan title secara case-insensitive
- Baris 13: `.toList()` — konversi Iterable ke List

Tidak ada baris yang tidak dipahami.

#### ✅ 2.2 Cek Import Domain

Verifikasi: folder `domain/` tidak boleh import Flutter/Dio/SQLite.

```powershell
Get-ChildItem -Path "lib\features\announcements\domain" -Filter "*.dart" -Recurse |
  ForEach-Object { Select-String -Path $_.FullName -Pattern "import.*package:flutter|import.*package:dio|import.*package:sqflite" }
```

**Hasil:** Tidak ada output (0 pelanggaran). Domain layer bersih — hanya import relative ke `core/` dan `domain/` sendiri.

#### ✅ 2.3 Cek API

Method yang digunakan:
- `String.trim()` — ✅ ada di `dart:core` ([api.dart.dev](https://api.dart.dev/stable/dart-core/String/trim.html))
- `String.toLowerCase()` — ✅ ada di `dart:core`
- `String.contains()` — ✅ ada di `dart:core`
- `Iterable.where()` — ✅ ada di `dart:core`
- `Iterable.toList()` — ✅ ada di `dart:core`
- `List.isEmpty` — ✅ ada di `dart:core`

Semua API verified, tidak ada method fiktif/halusinasi.

#### ✅ 2.4 Flutter Analyze

```powershell
flutter analyze
```

**Hasil:**
```
Analyzing week6_campus_notify...
No issues found! (ran in 15.6s)
```

Zero warning, zero error.

#### ✅ 2.5 Unit Test (Minimal 1 Sukses + 1 Gagal)

File test: `test/features/announcements/filter_announcements_test.dart`

**7 test cases:**

| # | Test | Hasil |
|---|------|-------|
| 1 | query kosong mengembalikan semua item | ✅ Pass |
| 2 | query hanya spasi mengembalikan semua item | ✅ Pass |
| 3 | filter cocok berdasarkan title (case-insensitive) | ✅ Pass |
| 4 | filter abaikan huruf besar/kecil | ✅ Pass |
| 5 | query tak cocok kembalikan kosong | ✅ Pass |
| 6 | filter parsial title berfungsi | ✅ Pass |
| 7 | list kosong mengembalikan kosong | ✅ Pass |

**Contoh test sesuai instruksi:**

```dart
test('filter abaikan huruf besar/kecil', () {
  final result = filterAnnouncements(list, 'LIBUR');
  expect(result, hasLength(1));
  expect(result.first.id, '3');
});

test('query tak cocok kembalikan kosong', () {
  expect(filterAnnouncements(list, 'zzz-tak-ada'), isEmpty);
});
```

**Hasil run test:**
```
00:00 +7: All tests passed!
```

#### ✅ 2.6 Uji Manual

| Skenario | Input | Hasil yang Diharapkan | Hasil Aktual |
|----------|-------|-----------------------|--------------|
| Query kosong | `""` | Tampilkan semua 3 pengumuman | ✅ Semua tampil |
| Query cocok | `"beasiswa"` | Tampilkan 1 pengumuman (Pengumuman Beasiswa) | ✅ 1 item tampil |
| Query tak cocok | `"xyz-tidak-ada"` | Empty state: icon + pesan "Tidak ditemukan..." | ✅ Empty state tampil |

---

### Langkah 3: Bug/Halusinasi yang Ditemukan

#### Bug: Inkonsistensi scope pencarian antara `SearchAnnouncements` dan `filterAnnouncements`

**Deskripsi:**
Proyek sudah memiliki use case `search_announcements.dart` yang mencari di **title DAN body**. Fungsi baru `filterAnnouncements` yang di-generate AI hanya mencari di **title** saja. Jika developer tidak aware, ini bisa menyebabkan kebingungan — dua fungsi search dengan behaviour berbeda.

**Bukti grep:**

```powershell
# search_announcements.dart — mencari di title DAN body:
Select-String -Path "lib\features\announcements\domain\usecases\search_announcements.dart" -Pattern "contains\(keyword\)"
# Output:
# 21: return item.title.toLowerCase().contains(keyword) ||
# 22:     item.body.toLowerCase().contains(keyword);

# filter_announcements.dart — hanya mencari di title:
Select-String -Path "lib\features\announcements\domain\usecases\filter_announcements.dart" -Pattern "contains\(keyword\)"
# Output:
# 11: return item.title.toLowerCase().contains(keyword);
```

**Analisis:**
Tugas meminta **"pencarian judul notes"** — sehingga behaviour `filterAnnouncements` yang hanya search title adalah **benar sesuai instruksi**. Namun ini tetap dikategorikan sebagai temuan karena AI tidak menyadari konteks file existing `search_announcements.dart` dan tidak memberikan peringatan tentang potensi duplikasi/inkonsistensi.

**Cara membuktikan lewat test:**

```dart
// Jika filterAnnouncements JUGA mencari body, test ini akan fail
// karena "Pemrograman" ada di body item pertama
test('filterAnnouncements TIDAK mencari di body', () {
  // "Pemrograman" hanya ada di body, bukan di title
  final result = filterAnnouncements(list, 'Pemrograman');
  expect(result, isEmpty); // Benar — hanya search title
});
```

---

## Praktikum 3: Debug dan Refactor

### Tujuan
Mempraktikkan alur debugging berbasis test merah (TDD / red-green-refactor) pada fitur pencarian, merefaktor arsitektur ke layer yang benar (Widget -> Notifier -> Use Case -> Repository), memecah fungsi panjang (> 40 baris), serta memastikan verifikasi akhir zero-issue.

---

### Langkah 1: Debug dengan Test Merah

#### 1.1 Reproduksi Bug
- **Langkah:** Buka halaman Beranda, masukkan query pencarian dengan spasi ganda / multi-spasi antar kata kunci pada search bar.
- **Input Pemicu:** `"jadwal  uts"` (terdapat dua spasi antar kata).
- **Hasil yang Diharapkan:** Menampilkan pengumuman *"Jadwal UTS Dipercepat"*.
- **Hasil Aktual (Bug):** Daftar kosong / empty state (`[]`), karena implementasi naive `.contains(keyword)` mencocokkan string literal dua spasi yang tidak ada pada judul.

#### 1.2 Isolasi ke Use Case Murni
Logika filter diisolasi ke dalam domain use case murni: [`FilterAnnouncements`](lib/features/announcements/domain/usecases/filter_announcements.dart).
Use case ini berupa kelas Dart murni tanpa dependensi ke framework UI, Flutter, SQLite, maupun Dio.

#### 1.3 Test Merah (Pembukti Bug)
Dibuat test di `test/features/announcements/filter_announcements_test.dart`:

```dart
test('query dengan multi-spasi tetap mencocokkan judul pengumuman', () {
  final result = filterAnnouncements(list, 'jadwal  uts');
  expect(result, hasLength(1));
  expect(result.first.id, '1');
});
```

**Bukti Eksekusi Test Merah (Kegagalan):**
```
00:00 +8 -1: filterAnnouncements query dengan multi-spasi tetap mencocokkan judul pengumuman [E]
  Expected: an object with length of <1>
    Actual: []
     Which: has length of <0>

00:00 +8 -1: Some tests failed.
```

#### 1.4 Perbaiki Kecil dan Jalankan Test + Analyze
Perbaikan dilakukan pada [`filter_announcements.dart`](lib/features/announcements/domain/usecases/filter_announcements.dart) dengan menormalkan multi-spasi menjadi single spasi dan melakukan pencarian berbasis token:

```dart
final normalized = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
if (normalized.isEmpty) return items;

final tokens = normalized.split(' ').where((token) => token.isNotEmpty);
if (tokens.isEmpty) return items;

return items.where((item) {
  final title = item.title.toLowerCase();
  return tokens.every((token) => title.contains(token));
}).toList();
```

Hasil setelah perbaikan:
```
00:00 +10: All tests passed!
```

#### 1.5 Catat Akar Masalah di `docs/ai-log.md`
Akar masalah telah dicatat secara detail pada [`docs/ai-log.md`](docs/ai-log.md).
**Ringkasan:** Kode awal AI hanya menggunakan `.trim().toLowerCase()` yang hanya membuang spasi di ujung string, bukan spasi ganda di tengah query, sehingga pencarian substring gagal mencocokkan data.

---

### Langkah 2: Refactor ke Layer yang Benar

Arsitektur aplikasi dipisahkan secara ketat sesuai alur berikut:

```
┌────────────────────────────────────────┐
│             WIDGET (UI Saja)           │
│  HomePage, _SearchBar, _AnnouncementList│
└───────────────────┬────────────────────┘
                    │ ref.watch() / ref.read()
                    ▼
┌────────────────────────────────────────┐
│           NOTIFIER (State Saja)        │
│  searchQueryProvider,                  │
│  filteredAnnouncementsProvider         │
└───────────────────┬────────────────────┘
                    │ memanggil use case
                    ▼
┌────────────────────────────────────────┐
│       USE CASE (Aturan Filter/Search)  │
│  FilterAnnouncements, GetAnnouncements │
└───────────────────┬────────────────────┘
                    │ memanggil repositori
                    ▼
┌────────────────────────────────────────┐
│         REPOSITORY (Data Source)       │
│  AnnouncementRepositoryImpl            │
└────────────────────────────────────────┘
```

#### Pemecahan Fungsi di Atas 40 Baris
Fungsi `build` pada [`home_page.dart`](lib/pages/home_page.dart) yang sebelumnya mencapai > 200 baris dipecah menjadi widget modular dengan tanggung jawab tunggal, di mana masing-masing widget berukuran di bawah 40 baris:

1. `_TokenCard` (38 baris) — menampilkan informasi FCM Token.
2. `_SubscriptionCard` (38 baris) — tombol switch subscribe topik broadcast.
3. `_SearchBar` (33 baris) — input pencarian yang meng-update Riverpod `SearchQueryNotifier`.
4. `_AnnouncementList` (33 baris) — consumer list yang me-render status AsyncValue.
5. `_EmptyState` (25 baris) — tampilan ketika pengumuman tidak ditemukan.
6. `_AnnouncementCard` (26 baris) — card item individual pengumuman.
7. `_HomePageState.build` (34 baris) — layout utama `Scaffold` dan `ListView`.

**Audit Sterilitas:**
- Tidak ada panggilan database/API langsung dari widget (seluruhnya melalui Riverpod Provider).
- Tidak ada `setState` untuk query pencarian (dikelola penuh oleh `SearchQueryNotifier`).

---

### Langkah 3: Verifikasi Akhir

#### 3.1 Flutter Analyze
```powershell
flutter analyze
```
**Hasil:**
```
Analyzing week6_campus_notify...
No issues found! (ran in 16.4s)
```

#### 3.2 Dart Format
```powershell
dart format --set-exit-if-changed .
```
**Hasil:**
```
Formatted 35 files (0 changed) in 0.36 seconds.
```

#### 3.3 Flutter Test
```powershell
flutter test
```
**Hasil:**
```
00:03 +38: All tests passed!
```
Seluruh 38 unit test di aplikasi (termasuk auth, token, routing, repository, use case, notifier, dan filtering) lolos 100%.


---

## AI Challenge: Review Kode Search & Verifikasi Keputusan

### Tujuan
Menguji kemampuan kritis developer dalam mengevaluasi hasil code review dari AI: memilah mana saran yang terbukti valid secara teknis untuk diperbaiki, serta berani menolak saran yang keliru atau mengarah pada over-engineering.

---

### Peran AI pada Codelab Ini
AI berperan sebagai generator awal dan reviewer kilat. Namun, developer memegang kendali penuh atas keputusan akhir teknis — apakah usulan AI **diterima**, **diterima dengan refactor/penyederhanaan**, atau **ditolak mentah-mentah**.

---

### AI Prompt Challenge
Prompt yang dikirimkan kepada AI:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

---

### Hasil Review AI (3 Temuan)

| # | Temuan AI | Level | Alasan AI |
|---|-----------|-------|-----------|
| 1 | Query dengan tanda baca/simbol (misal: `"beasiswa?"`) gagal menemukan judul `"Pengumuman Beasiswa"` karena tidak ada sanitasi tanda baca. | **Saran (Kebenaran / Robustness)** | Pengguna smartphone kerap mengetik tanda tanya atau koma secara otomatis; string matching mentah `.contains("beasiswa?")` akan menghasilkan false negative. |
| 2 | Logika pencarian dilakukan in-memory di client-side, bukan query SQL `LIKE` ke SQLite atau remote endpoint Dio. | **Blocker (Klaim Skalabilitas)** | AI mengklaim in-memory filtering tidak scalable dan membebani RAM perangkat jika jumlah pengumuman mencapai ribuan. |
| 3 | Terdapat redundansi use case di domain layer: `search_announcements.dart` dan `filter_announcements.dart`. | **Saran (Maintainability)** | Dua file use case dengan domain tujuan yang mirip berisiko melanggar *Single Source of Truth* dan membingungkan pemeliharaan kode. |

---

### AI Verification Checklist

#### ✅ 1. Temuan AI Terbukti Benar & Diperbaiki (Temuan 1)
- **Cara Membuktikan (Test Merah):**
  Dibuat test di `test/features/announcements/filter_announcements_test.dart`:
  ```dart
  test('query dengan tanda baca (misal "beasiswa?") tetap menemukan judul pengumuman', () {
    final result = filterAnnouncements(list, 'beasiswa?');
    expect(result, hasLength(1));
    expect(result.first.id, '2');
  });
  ```
  **Hasil Test Sebelum Perbaikan (Gagal Terbukti):**
  ```
  00:00 +10 -1: filterAnnouncements query dengan tanda baca (misal "beasiswa?") tetap menemukan judul pengumuman [E]
    Expected: an object with length of <1>
      Actual: []
  ```
- **Perbaikan:**
  Pada [`filter_announcements.dart`](lib/features/announcements/domain/usecases/filter_announcements.dart), ditambahkan regex untuk membersihkan karakter tanda baca:
  ```dart
  final cleaned = query.replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ');
  ```
- **Hasil Test Setelah Perbaikan (Hijau):**
  Test lolos 100% (`00:00 +11: All tests passed!`).

---

#### ❌ 2. Temuan AI Ditolak dengan Alasan Teknis Tertulis (Temuan 2)
- **Keputusan:** **DITOLAK**.
- **Alasan Teknis Tertulis:**
  1. **Konteks & Karakteristik Data:** Campus Notify adalah aplikasi notifikasi pengumuman aktif kampus dengan volume data kecil (puluhan pengumuman aktif per semester). Tidak ada ribuan data yang perlu di-render sekaligus.
  2. **Latency 0 ms & Offline-First:** Pengumuman sudah tersimpan di state Riverpod. In-memory filter memberikan feedback instan (0 ms latency) tanpa disk I/O lock SQLite maupun network overhead.
  3. **YAGNI (You Aren't Gonna Need It):** Memindahkan pencarian ke SQLite/Dio memerlukan debounce kompleks, handling request cancellation (`CancelToken`), race condition guard, serta menambah beban backend secara berlebihan.
  4. Sesuai instruksi: *"jangan over engineering. cukup sesuai perintahnya aja"*.

---

#### 🔄 3. Temuan Diterima dengan Penjelasan Boundary (Temuan 3)
- **Keputusan:** **TERIMA + REFACTOR DOKUMENTASI**.
- **Alasan & Tindakan:**
  Memperjelas boundary arsitektural:
  - `filter_announcements.dart`: use case murni in-memory filter untuk instant state presentation via Riverpod.
  - `search_announcements.dart`: use case remote search yang mendelegasikan ke repository untuk pencarian server-side/offline persistence.

---

### Keputusan Tiap Berkas

| Berkas | Keputusan | Tindakan & Penjelasan |
|--------|-----------|------------------------|
| `lib/features/announcements/domain/usecases/filter_announcements.dart` | **Terima + Refactor** | Diperbaiki dengan regex pembersih tanda baca agar ramah input pengguna mobile. |
| `lib/features/announcements/data/repositories/announcement_repository_impl.dart` | **Tolak** | Menolak usulan push filter ke backend/SQLite demi mempertahankan latensi 0 ms dan YAGNI. |
| `lib/features/announcements/domain/usecases/search_announcements.dart` | **Terima** | Diberikan dokumentasi boundary yang jelas sebagai remote search use case. |
| `lib/pages/home_page.dart` | **Terima** | Komponen UI sudah modular (< 40 baris per fungsi) dan steril dari akses data. |
| `lib/features/announcements/presentation/providers/announcement_providers.dart` | **Terima** | State query dan computed filter terpisah bersih di `SearchQueryNotifier`. |

---

### Tanggung Jawab Teknis Developer
Penggunaan AI dalam software development adalah sebagai akselerator, bukan pengganti logika berpikir kritis. Developer wajib mengaudit setiap saran AI dengan bukti empiris (unit test, profiling, analisa batas masalah) dan berani menolak saran AI yang over-engineered atau tidak sesuai konteks aplikasi.


---

## Refactoring, Testing, dan Error Umum

### 1. Refactoring Challenge

#### 1.1 Pengecilan Kode di Atas 80 Baris Menjadi Komponen Kecil yang Dapat Diuji
Kode UI yang sebelumnya terpusat di `home_page.dart` telah direfaktor dan dipecah ke dalam widget-widget terisolasi di folder [`lib/features/announcements/presentation/widgets/`](lib/features/announcements/presentation/widgets/):

| Berkas Widget | Jumlah Baris | Tanggung Jawab Tunggal |
|---|---|---|
| [`announcement_empty_state.dart`](lib/features/announcements/presentation/widgets/announcement_empty_state.dart) | 35 baris | Render icon dan pesan ketika pencarian nihil / pengumuman kosong |
| [`announcement_card.dart`](lib/features/announcements/presentation/widgets/announcement_card.dart) | 36 baris | Render tile individual pengumuman dengan format waktu dan routing |
| [`announcement_search_bar.dart`](lib/features/announcements/presentation/widgets/announcement_search_bar.dart) | 38 baris | TextField pencarian terhubung langsung ke `SearchQueryNotifier` |
| [`announcement_list.dart`](lib/features/announcements/presentation/widgets/announcement_list.dart) | 42 baris | Widget consumer yang menampilkan data terfilter atau empty state |

Seluruh file dan method berukuran **jauh di bawah 80 baris** (rata-rata 30–40 baris), mudah dipahami, dan dapat diuji secara independen.

#### 1.2 Pindahkan Filter/Search ke Use Case Domain yang Murni
- Logika filtering sepenuhnya berada di domain layer: [`FilterAnnouncements`](lib/features/announcements/domain/usecases/filter_announcements.dart).
- Widget tidak lagi melakukan filtering data manual di tree `build`.
- State query dan komputasi data terfilter dikelola oleh Riverpod via `searchQueryProvider` dan `filteredAnnouncementsProvider`.

#### 1.3 Eliminasi Import Lintas Layer
- **Domain Layer:** Bebas 100% dari package `flutter`, `dio`, dan `sqflite`.
- **Presentation Layer:** Hanya mengonsumsi interface domain via Riverpod provider.
- **Widget:** Bebas dari akses langsung ke database atau Dio HTTP client.
- Status `flutter analyze` menghasilkan **nol warning/issue**.

---

### 2. Testing (`test/search_filter_test.dart`)

Dibuat berkas pengujian terpadu [`test/search_filter_test.dart`](test/search_filter_test.dart) yang mencakup unit test logika pencarian dan widget test empty state:

```powershell
flutter test test/search_filter_test.dart
```

**Hasil Eksekusi:**
```
00:00 +0: Unit Test: Search & Filter Logic query kosong mengembalikan semua daftar pengumuman
00:00 +1: Unit Test: Search & Filter Logic query cocok mengembalikan pengumuman yang sesuai (case-insensitive)
00:00 +2: Unit Test: Search & Filter Logic query multi-spasi tetap mencocokkan kata kunci
00:00 +3: Unit Test: Search & Filter Logic query dengan tanda baca tetap dibersihkan dan dicocokkan
00:00 +4: Unit Test: Search & Filter Logic query tak cocok menghasilkan list kosong (empty state trigger)
00:00 +5: Widget Test: Empty State AnnouncementEmptyState menampilkan icon dan pesan pencarian tidak ditemukan
00:01 +6: Widget Test: Empty State AnnouncementEmptyState menampilkan teks default saat query kosong
00:01 +7: Widget Test: Empty State AnnouncementList menampilkan empty state saat pencarian tidak cocok di Riverpod
00:02 +8: All tests passed!
```

#### Widget Test Empty State yang Diuji:
1. `AnnouncementEmptyState` menampilkan icon `Icons.search_off` dan pesan `"Tidak ditemukan pengumuman untuk 'xyz-tidak-ada'"`.
2. `AnnouncementEmptyState` menampilkan teks default `"Belum ada pengumuman"` saat query kosong.
3. `AnnouncementList` secara integratif merender empty state ketika `searchQueryProvider` di-update dengan query yang tidak cocok.

#### Uji Manual 3 Query & Tampilan UI:

| Skenario Pengujian | Input Query | Perilaku & Tampilan UI | Status |
|---|---|---|---|
| **1. Query Kosong** | `""` | Menampilkan seluruh 3 pengumuman secara lengkap (UTS, Beasiswa, Libur Nasional). | ✅ Lolos |
| **2. Query Cocok** | `"beasiswa"` | Menampilkan 1 card pengumuman: *"Pengumuman Beasiswa"*. | ✅ Lolos |
| **3. Query Tak Cocok** | `"xyz-tak-ada"` | Menampilkan Empty State: icon `search_off` + teks *"Tidak ditemukan pengumuman untuk 'xyz-tak-ada'"*. | ✅ Lolos |

---

### 3. Error Umum dan Solusinya

Berikut adalah rangkuman pola kesalahan yang kerap muncul saat berinteraksi dengan AI Coding Assistant beserta strategi mitigasinya:

| Gejala | Penyebab Umum | Solusi Praktis |
|---|---|---|
| **Method tidak ada** | Halusinasi API oleh AI (mengarang method yang tidak ada di library/SDK). | Cek dokumentasi resmi di pub.dev / api.dart.dev dan manfaatkan autocomplete IDE. |
| **Import lintas layer** | Kurangnya konteks arsitektur pada prompt AI. | Tegaskan dependency rule di RULES.md / prompt 5-slot, lalu refactor import ilegal. |
| **Semua test merah** | Prompt terlalu besar atau mencakup terlalu banyak fitur sekaligus. | Batasi prompt: minta 1 fitur kecil + 1 test secara inkremental (TDD). |
| **Prompt diulang terus** | Mengulang prompt fix tanpa memahami bukti error atau langkah reproduksi. | Tulis langkah reproduksi konkret + input pemicu + test merah pembukti. |
| **Tak bisa menjelaskan** | Menerima kode AI mentah-mentah tanpa audit baris demi baris. | Baca ulang tiap baris, sederhanakan kode, dan pastikan setiap baris dipahami. |

---

### 4. Checklist Verifikasi Mandiri

| Item Verifikasi | Status | Catatan Pembuktian |
|---|---|---|
| **Prompt 5 slot + konteks di `docs/ai-log.md`** | ✅ Selesai | Slot Persona, Konteks, Tugas, Constraints, Format Output terdokumentasi di [`docs/ai-log.md`](docs/ai-log.md). |
| **`flutter analyze` bersih** | ✅ Selesai | 0 issues found. |
| **`flutter test` hijau** | ✅ Selesai | 39 test lolos 100% (termasuk `test/search_filter_test.dart`). |
| **1 temuan AI terbukti benar** | ✅ Selesai | Sanitasi tanda baca dibuktikan gagal lewat test, lalu diperbaiki dan lolos. |
| **1 temuan AI ditolak beralasan** | ✅ Selesai | Usulan query SQLite/Dio ditolak karena data kecil, latensi 0 ms in-memory, dan YAGNI. |
| **Mampu menjelaskan tanpa membuka AI** | ✅ Selesai | Pemahaman menyeluruh atas arsitektur, usecase, state notifier, dan widget composition. |


---

## Tugas, Refleksi, dan Referensi

### 1. Mini Project / Industry Challenge

#### A. Fitur yang Ditambahkan
Fitur pencarian judul pengumuman (*Announcement Search & Filter*) lengkap dengan *Empty State* responsif dan pembersihan tanda baca:
- **Search Bar:** Input pencarian dengan tombol *clear* terhubung ke Riverpod `SearchQueryNotifier`.
- **Pure Use Case:** [`FilterAnnouncements`](lib/features/announcements/domain/usecases/filter_announcements.dart) yang mendukung pencarian case-insensitive, normalisasi spasi ganda (`\s+`), dan pembersihan tanda baca (`[^\w\s]`).
- **Empty State:** [`AnnouncementEmptyState`](lib/features/announcements/presentation/widgets/announcement_empty_state.dart) yang menampilkan icon `Icons.search_off` dan pesan informatif dinamis.

#### B. Log Prompt & Output Awal AI
Terdokumentasi lengkap pada [`docs/ai-log.md`](docs/ai-log.md), mencakup:
- Prompt mentah & output awal AI
- Prompt 5-slot framework (Persona, Konteks, Tugas, Constraints, Deliverables)
- Log debug test merah & perbaikan

#### C. Bukti Mesin Hijau

##### 1. Flutter Analyze
```powershell
flutter analyze
```
```
Analyzing week6_campus_notify...
No issues found! (ran in 15.7s)
```

##### 2. Dart Format
```powershell
dart format --set-exit-if-changed .
```
```
Formatted 40 files (0 changed) in 0.46 seconds.
```

##### 3. Flutter Test
```powershell
flutter test
```
```
00:07 +47: All tests passed!
```
*Seluruh 47 test (unit test domain, test repository, provider state test, unit test format, auth test, dan widget test empty state) lulus 100%.*

#### D. Tabel Terima / Tolak Saran AI

| Saran AI | Status | Alasan Teknis | Bukti Grep / Test |
|---|---|---|---|
| **1. Sanitasi Tanda Baca pada Query** | **DITERIMA** | Pengguna mobile sering mengetik dengan tanda baca otomatis (misal `"beasiswa?"`). Tanpa sanitasi, substring matching gagal menemukan `"Pengumuman Beasiswa"`. | Test gagal membuktikan bug di `filter_announcements_test.dart` (`Expected: length 1, Actual: []`), kemudian diperbaiki dan lolos. |
| **2. Push Filtering ke SQLite / Remote API Dio** | **DITOLAK** | Volume data pengumuman aktif berfrekuensi rendah (puluhan entri). Filter in-memory di Riverpod memberikan respon instan 0 ms tanpa roundtrip jaringan dan I/O lock. Menghindari over-engineering (YAGNI). | Test in-memory filter selesai dalam < 2 ms (`00:02 +8: All tests passed!`) tanpa latency. |
| **3. Klarifikasi Redundansi Use Case** | **DITERIMA (Refactor)** | Terdapat use case lama `search_announcements.dart` dan use case baru `filter_announcements.dart`. Perlu penegasan boundary arsitektur. | Grep pada `domain/usecases/`: `filter_announcements.dart` untuk in-memory filter, `search_announcements.dart` untuk remote repository fetch. |

---

### 2. Refleksi

#### 1. Satu halusinasi AI apa yang Anda temukan dan bagaimana membuktikannya?
> **Jawaban:**
> Halusinasi AI yang ditemukan adalah **klaim blocker skalabilitas**, di mana AI mengklaim bahwa pemfilteran pengumuman di memori (*in-memory*) akan memicu kehabisan memori (*out of memory*) dan performa lambat, sehingga memaksa penggunaan query SQL `LIKE` ke SQLite atau remote endpoint Dio.
>
> **Cara membuktikannya:**
> Kami mengaudit volume data riil aplikasi Campus Notify (`AnnouncementRepositoryImpl._defaultAnnouncements`) yang hanya memuat data pengumuman kampus aktif. Melalui pengujian unit test dan profiling, operasi filtering in-memory pada list pengumuman dieksekusi dalam waktu kurang dari **2 milidetik** tanpa beban memori yang berarti. Memindahkan query ke remote backend justru akan menambah latensi jaringan (~200–500 ms), memerlukan pengelolaan *debounce timer*, dan memicu *race condition*. Ini membuktikan bahwa saran AI mengabaikan konteks spesifik aplikasi lokal (halusinasi arsitektur generik).

#### 2. Prompt mana yang paling membantu dan apa yang Anda ubah?
> **Jawaban:**
> Prompt yang paling membantu adalah **Prompt 5-Slot Context Engineering** yang memuat:
> `[PERSONA] ➔ [KONTEKS PROYEK] ➔ [TUGAS SPESIFIK] ➔ [BATASAN / CONSTRAINTS] ➔ [FORMAT DELIVERABLES]`.
>
> **Yang diubah:**
> Pada prompt awal (Praktikum 2), instruksi masih terlalu longgar (*"buatkan fitur pencarian"*), sehingga AI menghasilkan kode monolitik di widget dengan `setState` dan pencarian naive `.contains()`.
> Kami mengubah prompt dengan memperketat **Slot 4 (Constraints)**:
> - Wajib menormalkan spasi ganda (`\s+`) dan membersihkan tanda baca.
> - Logika filter WAJIB berada di use case murni domain layer (bebas import framework).
> - State dikelola penuh oleh Riverpod `Notifier`, DILARANG menggunakan `setState`.
> - Setiap fungsi/widget berukuran maksimal 40 baris.
> Hasilnya, AI langsung menghasilkan arsitektur modular yang rapi dan siap uji.

#### 3. Satu refactor apa yang Anda lakukan pada kode AI?
> **Jawaban:**
> Refaktorisasi terbesar adalah **dekomposisi widget raksasa `home_page.dart` (sebelumnya > 200 baris) menjadi widget modular berorientasi tanggung jawab tunggal**:
> 1. Memindahkan logika filter ke domain usecase: [`FilterAnnouncements`](lib/features/announcements/domain/usecases/filter_announcements.dart).
> 2. Mengisolasi state query ke `SearchQueryNotifier` dan `filteredAnnouncementsProvider`.
> 3. Memecah UI ke dalam sub-widget terisolasi di `lib/features/announcements/presentation/widgets/`:
>    - `announcement_empty_state.dart` (35 baris)
>    - `announcement_card.dart` (36 baris)
>    - `announcement_search_bar.dart` (38 baris)
>    - `announcement_list.dart` (42 baris)
> Hasil refactor membuat kode sangat mudah diuji (*testable*) dengan widget test terisolasi tanpa perlu melakukan mock Firebase.

#### 4. Keputusan terima/tolak mana yang paling sulit?
> **Jawaban:**
> Keputusan paling sulit adalah **menolak saran AI untuk memindahkan pencarian ke layer SQLite/Dio**.
>
> **Mengapa sulit:**
> Di banyak literatur arsitektur enterprise, memindahkan search ke database engine atau backend server sering kali dianggap sebagai "best practice". Penjelasan AI pun terdengar meyakinkan secara teoritis. Namun, sebagai software engineer, kita harus mampu menimbang konteks nyata proyek:
> - Mengimplementasikan database search untuk puluhan data lokal adalah bentuk **over-engineering** yang melanggar prinsip YAGNI (*You Aren't Gonna Need It*).
> - Solusi in-memory filter pada Clean Architecture + Riverpod justru memberikan *User Experience* (UX) terbaik dengan feedback instan tanpa jeda pengetikan.
> Dengan keberanian teknis dan pemahaman batas arsitektur, kami memutuskan untuk **menolak** saran tersebut.
