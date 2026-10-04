# Week 5: Local Storage & Offline-First Notes

Aplikasi Flutter Offline Notes dengan local storage dan sinkronisasi antrean (offline-first).

---

## AI Verification Checklist

Temuan verifikasi terhadap rekomendasi AI coding assistant terkait pemilihan storage:

### 1. Apakah AI menempatkan daftar catatan di SharedPreferences?
- **Temuan:** Tidak. AI merekomendasikan SQLite (`sqflite`) untuk koleksi catatan dan SharedPreferences hanya untuk preferensi primitif (tema dan timestamp terakhir dibuka).
- **Justifikasi Penolakan SharedPreferences untuk Catatan:** Menyimpan koleksi catatan dalam format string JSON di SharedPreferences sangat rapuh untuk operasi CRUD, tidak mendukung indexing, tidak dapat melakukan query parsial (seperti filter `dirty = 1`), dan pembaruan 1 catatan mengharuskan serialisasi ulang seluruh koleksi.

### 2. Apakah skema AI mendukung antrean sync (dirty flag / updated_at) atau hanya CRUD polos?
- **Temuan:** Ya. Skema yang diajukan AI memuat kolom `dirty INTEGER NOT NULL DEFAULT 0` untuk menandai catatan yang belum tersinkron dan `updated_at TEXT NOT NULL` untuk resolusi konflik berbasis waktu (*last-write-wins*).
- **Mekanisme Sync:** Disertai implementasi fungsi `countDirty()` dan `markAllSynced()` untuk pemrosesan sinkronisasi batch.

### 3. Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?
- **Temuan:** Terverifikasi bukan asumsi tanpa dasar.
- **Fakta Teknis:** `sqflite` tidak memiliki listener stream bawaan; pembaruan UI dilakukan secara eksplisit melalui Riverpod (`ref.invalidate(notesProvider)`). Sebaliknya, Drift mendukung `watch()` berbasis stream reaktif. Karena kebutuhan aplikasi ini berfokus pada CRUD terarah, penggunaan SQLite + Riverpod invalidation sudah mencukupi tanpa perlu overhead stream bawaan.

### 4. Apakah estimasi boilerplate AI masuk akal setelah mencoba instalasinya?
- **Temuan:** Masuk akal dan akurat sesuai hasil implementasi langsung:
  - `shared_preferences`: Setup minimal (`flutter pub add shared_preferences`), hanya memerlukan 1 class pembungkus repository tanpa konfigurasi tambahan.
  - `sqflite` + `path`: Boilerplate terukur (file skema DB, model dengan mapping map, dan repository CRUD), tanpa memerlukan generator kode (`build_runner`).
  - `Drift`: Memerlukan dependensi ganda (`drift`, `drift_dev`, `build_runner`), penulisan definisi tabel, dan eksekusi kompilasi kode tambahan yang menambah kompleksitas setup.

### 5. Keputusan Final & Argumen Teknis
- **Preferensi Tema:** `SharedPreferences` (cocok untuk data key-value sederhana non-relasional).
- **CRUD Catatan & Cache Data:** `SQLite (sqflite)` (mendukung query efisien `ORDER BY updated_at DESC`, filter `dirty`, serta indexing tanpa ketergantungan code generation).

Dokumentasi lengkap mengenai prompt, analisis trade-off, dan skema perbandingan dapat dilihat di [`docs/ai_challenge.md`](file:///D:/Kuliah/Semester%205/Pemrograman%20Mobile/Week%201/week5_offline_notes/docs/ai_challenge.md).
