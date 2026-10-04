# AI Challenge — Perbandingan Storage untuk Offline Notes

## Prompt yang Digunakan

```
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

---

## Output AI — Tabel Perbandingan

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|---|---|---|---|---|
| **Kompleksitas query** | Tidak ada query; hanya `get`/`set` per key | Query dasar per box (`getAt`, `values.where`); tidak ada SQL | SQL penuh (`JOIN`, `WHERE`, `ORDER BY`, `GROUP BY`, subquery) | SQL penuh + query builder Dart type-safe |
| **Kebutuhan relasi** | ❌ Tidak didukung | ❌ Tidak ada relasi native; harus manual | ✅ Foreign key, JOIN, index | ✅ Foreign key, JOIN, index + type-safe |
| **Reaktivitas (stream)** | ❌ Tidak ada stream | ✅ `box.watch()` per key/box | ❌ Tidak built-in; harus manual wrap | ✅ `watchAll()`, `watchSingle()` built-in |
| **Type-safety** | ❌ Dynamic; key string, tipe runtime | ⚠️ Adapter wajib ditulis per model; typo key baru ketahuan runtime | ❌ Map dynamic; kolom string; error runtime | ✅ Code-gen; kolom, tipe, dan query dicek saat compile |
| **Ukuran boilerplate** | Sangat kecil (~5 baris per pref) | Sedang (adapter + `@HiveType` annotation + build_runner) | Kecil–sedang (SQL string + `fromMap`/`toMap` manual) | Besar (table class + code-gen + build_runner + migrasi versioned) |
| **Kemudahan testing** | Mudah; `SharedPreferences.setMockInitialValues({})` | Mudah; `Hive.init(tmpDir)` + in-memory | Sedang; inject `openDb` callback atau in-memory DB | Sedang–sulit; in-memory DB + generated code harus ada |
| **Ukuran dependensi** | ~50 KB (platform channel) | ~200 KB (native binary per platform) | ~300 KB (SQLite binary, sudah ada di Android/iOS) | ~300 KB + build_runner + drift_dev |
| **Cocok untuk** | Pengaturan kecil (tema, bahasa, flag) | Cache objek sederhana tanpa relasi | Data terstruktur relasional, CRUD koleksi | Aplikasi besar, query kompleks, reaktif |

---

## Analisis Trade-off per Pilihan

### SharedPreferences
- **Kelebihan:** API paling sederhana. Tidak perlu skema, migrasi, atau code-gen. Instalasi cepat (`flutter pub add shared_preferences`). Cocok untuk 5–10 key primitif.
- **Kekurangan:** Hanya menyimpan `bool`, `int`, `double`, `String`, `List<String>`. Menyimpan koleksi catatan sebagai JSON string di sini membuat query parsial mustahil, update satu item harus serialize ulang seluruh list, dan sinkronisasi (dirty flag per item) tidak bisa dilakukan.
- **Trade-off:** Kesederhanaan vs keterbatasan tipe dan query.

### Hive
- **Kelebihan:** NoSQL embedded, cepat untuk baca sekuensial, `box.watch()` untuk reaktivitas per key. Tidak perlu SQL.
- **Kekurangan:** Tidak ada relasi antar-box. Query kompleks (filter + sort + pagination) harus dilakukan di Dart (O(n) scan seluruh box). Adapter harus ditulis atau di-generate per model — boilerplate tambahan. Migrasi skema manual dan rentan error.
- **Trade-off:** Kecepatan baca vs ketidakmampuan query relasional. Untuk 1000+ catatan dengan sorting `updated_at` dan filter `dirty`, Hive harus load semua ke memori dulu.

### sqflite (SQLite)
- **Kelebihan:** SQL penuh — index pada `updated_at` membuat sort O(log n), `WHERE dirty = 1` efisien dengan index. Foreign key dan JOIN tersedia. Tidak perlu code-gen. SQLite sudah bawaan Android/iOS, jadi tidak ada dependensi native tambahan.
- **Kekurangan:** Query berupa string (typo baru ketahuan runtime). Mapping `Map<String, dynamic>` ke model manual. Tidak ada stream built-in — harus invalidate provider secara manual setelah mutasi.
- **Trade-off:** Fleksibilitas query vs kurangnya type-safety dan reaktivitas otomatis.

### Drift
- **Kelebihan:** Semua keunggulan SQLite + type-safe query builder + `watch()` stream otomatis. Error query terdeteksi saat compile. Migrasi skema terstruktur.
- **Kekurangan:** Boilerplate besar — harus setup `build_runner`, `drift_dev`, menulis table class, dan menjalankan code-gen. Learning curve lebih tinggi. Untuk aplikasi notes sederhana, overhead-nya tidak sebanding.
- **Trade-off:** Type-safety + reaktivitas vs kompleksitas setup dan ukuran boilerplate.

---

## Rekomendasi Final

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| **Preferensi tema (dark mode, last opened)** | **SharedPreferences** | Hanya 2–3 key primitif (`bool`, `String`). API paling sederhana, tidak perlu skema atau migrasi. Overhead Hive/SQLite/Drift tidak justified untuk data sesederhana ini. |
| **CRUD catatan (1000+ item, dirty flag, sync)** | **sqflite (SQLite)** | Butuh query terstruktur (`ORDER BY updated_at DESC`, `WHERE dirty = 1`, `COUNT(*)`), index untuk performa, dan dirty flag per baris untuk antrean sync. SQLite menyediakan semua ini tanpa overhead code-gen. Drift overkill untuk skema sederhana ini; Hive tidak bisa query efisien pada 1000+ item. |

---

## Skema untuk 1000+ Catatan

### SQLite (sqflite) — yang dipakai

```sql
CREATE TABLE notes(
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty      INTEGER NOT NULL DEFAULT 0
);

-- Index untuk sorting dan filter sync
CREATE INDEX idx_notes_updated ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty   ON notes(dirty) WHERE dirty = 1;

CREATE TABLE cached_posts(
  id        INTEGER PRIMARY KEY,
  payload   TEXT NOT NULL,
  cached_at TEXT NOT NULL
);
```

**Kapasitas:** SQLite menangani jutaan baris tanpa masalah. Untuk 1000 catatan, query dengan index di atas membutuhkan < 1ms.

### Hive (alternatif — TIDAK dipilih)

```dart
@HiveType(typeId: 0)
class NoteHive extends HiveObject {
  @HiveField(0) late String title;
  @HiveField(1) late String body;
  @HiveField(2) late DateTime updatedAt;
  @HiveField(3) late bool dirty;
}
// Box<NoteHive> noteBox = await Hive.openBox('notes');
```

**Masalah untuk 1000+ item:** `noteBox.values.where((n) => n.dirty).toList()` melakukan full scan O(n). Tidak ada index. Sort harus dilakukan di Dart setelah load semua item ke memori.

### Drift (alternatif — TIDAK dipilih)

```dart
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
}
```

**Trade-off:** Type-safe dan reaktif, tapi memerlukan `build_runner`, `drift_dev`, dan `drift` — 3 dependensi tambahan + code-gen setiap kali skema berubah. Untuk 1 tabel sederhana, overhead tidak sebanding.

---

## AI Verification Checklist

### 1. Apakah AI menempatkan daftar catatan di SharedPreferences?
**TIDAK.** AI dengan benar merekomendasikan SQLite untuk koleksi catatan dan SharedPreferences hanya untuk preferensi primitif (tema, last opened). Jika AI menempatkan catatan di SharedPreferences, itu harus ditolak karena:
- Tidak bisa query parsial (filter dirty, sort by date)
- Update 1 catatan = serialize ulang seluruh list
- Dirty flag per item tidak bisa dilakukan
- Performa menurun drastis pada 1000+ item

### 2. Apakah skema AI mendukung antrean sync (dirty flag / updated_at)?
**YA.** Skema yang direkomendasikan memiliki:
- Kolom `dirty INTEGER NOT NULL DEFAULT 0` — menandai catatan yang belum di-sync
- Kolom `updated_at TEXT NOT NULL` — untuk last-write-wins conflict resolution
- Method `countDirty()` dan `markAllSynced()` di repository

### 3. Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?
**Dijawab jujur:** sqflite TIDAK memiliki stream built-in. Reaktivitas dicapai dengan `ref.invalidate(notesProvider)` setelah setiap mutasi. Ini adalah trade-off yang diterima — untuk aplikasi notes sederhana, invalidasi manual sudah cukup. Jika kebutuhan reaktivitas meningkat (misalnya multi-tab, background sync notification), Drift menjadi pilihan yang lebih baik.

### 4. Apakah estimasi boilerplate AI masuk akal?
**YA, sudah diverifikasi:**
- **SharedPreferences:** `flutter pub add shared_preferences` → 1 file `prefs.dart` (~25 baris). Sesuai estimasi "sangat kecil".
- **sqflite:** `flutter pub add sqflite path` → `db.dart` (~28 baris) + `note.dart` (~34 baris) + `note_repository.dart` (~51 baris). Sesuai estimasi "kecil–sedang".
- **Drift** (tidak dicoba, estimasi dari dokumentasi): memerlukan `drift`, `drift_dev`, `build_runner` + table class + generated `.g.dart` files + migrasi. Boilerplate memang jauh lebih besar.

### 5. Keputusan final
**SharedPreferences + sqflite (SQLite)** — sesuai rekomendasi AI dan sesuai kebutuhan codelab.

**Alasan:**
- SharedPreferences untuk 2 key primitif (dark mode, last opened) — overkill pakai database.
- sqflite untuk CRUD catatan karena: SQL query efisien, dirty flag per baris, index untuk sorting, tidak perlu code-gen. Drift terlalu berat untuk 1 tabel; Hive tidak bisa query efisien.
- Kombinasi ini adalah standar industri untuk aplikasi offline-first sederhana.
