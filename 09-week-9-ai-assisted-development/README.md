# 09 — AI-Assisted Development & Vibe Coding

Repositori pengerjaan tugas Praktikum Minggu 9: Pengembangan Berbantuan AI (*AI-Assisted Development*) pada aplikasi **Campus Notify** (`week6_campus_notify`).

---

## 1. Fitur yang Dikembangkan
Fitur pencarian dan penyaringan judul pengumuman kampus (*Announcement Title Search & Filter*) lengkap dengan penanganan *Empty State*:
- **Search Bar Input:** Input teks responsif dengan tombol clear otomatis terhubung ke Riverpod.
- **Pure Use Case (`FilterAnnouncements`):** Logika penyaringan murni di domain layer yang mendukung:
  - Pencarian *case-insensitive*
  - Normalisasi *whitespace* ganda / multi-spasi (`\s+`)
  - Pembersihan dan sanitasi tanda baca (`[^\w\s]`)
- **Empty State Widget (`AnnouncementEmptyState`):** Komponen responsif yang menampilkan icon `Icons.search_off` dan pesan informatif dinamis jika query tidak menghasilkan pengumuman.

---

## 2. Tech Stack
- **Framework:** Flutter SDK ^3.13.5 (Sound Null Safety)
- **State Management:** `flutter_riverpod` (Riverpod 3.x)
- **Routing:** `go_router` (GoRouter 18.x)
- **Arsitektur:** Feature-First Clean Architecture (`presentation` ➔ `domain` ➔ `data`)
- **HTTP Client & Storage:** `dio` 5.x, `flutter_secure_storage`
- **Testing:** `flutter_test` (Unit Test Domain, Provider Test, Widget Test)

---

## 3. Context Engineering & Prompt Inti

Untuk memastikan AI tidak menghasilkan kode halusinasi dan mematuhi arsitektur, digunakan **Prompt 5-Slot Framework**:

```text
[SLOT 1: PERSONA]
Senior Flutter Developer & Clean Architecture Specialist.

[SLOT 2: KONTEKS PROYEK]
Campus Notify (week6_campus_notify), Flutter SDK ^3.13.5, Riverpod 3.x, GoRouter, sound null-safety.

[SLOT 3: TUGAS SPESIFIK]
Membuat fitur pencarian judul pengumuman + empty state, mengisolasi filter ke domain use case murni, dan membuat unit/widget test.

[SLOT 4: BATASAN / CONSTRAINTS]
- Domain layer dilarang import Flutter/Dio/SQLite.
- Dilarang setState untuk state yang dikelola Riverpod.
- Setiap widget/fungsi berukuran maksimal 40 baris.
- Zero issues pada flutter analyze.

[SLOT 5: FORMAT OUTPUT]
File implementasi modular di presentation/widgets/, domain use case murni, dan unit/widget test terpisah.
```

*Log prompt mentah, output awal AI, dan siklus debug terdokumentasi di [`docs/ai-log.md`](docs/ai-log.md).*

---

## 4. Cara Menjalankan Aplikasi & Pengujian

### Prasyarat
- Flutter SDK telah terinstal (`flutter --version` >= 3.13.5)
- Perangkat / Emulator Android/iOS atau Desktop

### Langkah Instalasi
```powershell
# 1. Masuk ke direktori proyek
cd week6_campus_notify

# 2. Unduh dependensi
flutter pub get

# 3. Jalankan static analyzer
flutter analyze

# 4. Verifikasi format kode
dart format --set-exit-if-changed .

# 5. Jalankan pengujian test suite
flutter test test/search_filter_test.dart
flutter test
```

---

## 5. Hasil Pengujian & Bukti Mesin Hijau

### Analisis Statis (Zero Warning)
```
> flutter analyze
Analyzing week6_campus_notify...
No issues found! (ran in 15.7s)
```

### Verifikasi Format Kode
```
> dart format --set-exit-if-changed .
Formatted 40 files (0 changed) in 0.46 seconds.
```

### Hasil Test Suite Lengkap
```
> flutter test
00:07 +47: All tests passed!
```
*Seluruh 47 pengujian (termasuk unit test logika domain, provider test, dan widget test empty state) lolos 100%.*

---

## 6. Tabel Evaluasi Saran AI (Terima vs Tolak)

| Saran AI | Keputusan | Alasan Teknis | Bukti Grep / Test |
|---|---|---|---|
| **1. Sanitasi Tanda Baca pada Query** | **DITERIMA** | Pengguna sering mengetik dengan tanda baca otomatis (misal `"beasiswa?"`). Tanpa sanitasi, string matching `.contains()` gagal menemukan `"Pengumuman Beasiswa"`. | Test gagal membuktikan bug di `filter_announcements_test.dart` (`Expected: length 1, Actual: []`), diperbaiki dan lolos. |
| **2. Pindahkan Filter ke SQLite / Remote API Dio** | **DITOLAK** | Volume data pengumuman aktif berfrekuensi rendah. In-memory filter di Riverpod menghasilkan latensi 0 ms tanpa I/O lock SQLite atau overhead jaringan. Menghindari *over-engineering* (YAGNI). | Test in-memory filter selesai dalam < 2 ms (`00:02 +8: All tests passed!`). |
| **3. Klarifikasi Redundansi Use Case** | **DITERIMA** | Memperjelas batas antara `filter_announcements.dart` (in-memory presentation filter) dan `search_announcements.dart` (remote repository search). | Audit file domain use case dengan penegasan boundary yang jelas. |

---

## 7. Refleksi

1. **Halusinasi AI yang Ditemukan:**
   AI mengklaim bahwa in-memory filtering adalah blocker skalabilitas dan berpotensi *out of memory*. Faktanya, data pengumuman aktif hanya puluhan entri dan memakan memori < 10 KB dengan waktu eksekusi < 0.001 ms. Klaim AI terbukti sebagai halusinasi konteks generik.
2. **Prompt Paling Membantu:**
   Prompt 5-Slot dengan penegasan constraint arsitektur (domain bebas framework, state terikat ke Notifier, fungsi < 40 baris).
3. **Refactor yang Dilakukan:**
   Mendekomposisi widget monolitik `home_page.dart` (> 200 baris) menjadi 4 widget modular kecil (< 40 baris) di `presentation/widgets/` dan memindahkan aturan filter ke domain use case murni.
4. **Keputusan Paling Menantang:**
   Menolak saran pemindahan pencarian ke backend/database SQLite demi mempertahankan kesederhanaan, latensi 0 ms, dan menghindari over-engineering.
