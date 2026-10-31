# AI Challenge — Minggu 7: Clean Architecture

> **Proyek:** `week6_campus_notify`  
> **Topik:** Reorganisasi Feature-First Clean Architecture, Evaluasi Over-Engineering, dan Wiring DI Riverpod  
> **Model AI:** Claude Sonnet / Gemini 3.8 Flash  

---

## 1. Prompt Asli AI Challenge

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

## 2. Draf Usulan Awal AI

### a. Struktur Folder yang Diusulkan AI:
```text
lib/
├── core/
│   ├── errors/failures.dart
│   └── network/api_client.dart
├── features/
│   ├── auth/
│   │   ├── domain/ (entities, repositories, usecases: login, logout, refresh, check_auth)
│   │   ├── data/ (models, repositories, datasources)
│   │   └── presentation/ (providers, pages)
│   └── announcements/
│       ├── domain/ (entities, repositories, usecases: get_all, get_by_id, filter, refresh)
│       ├── data/ (models, repositories, datasources)
│       └── presentation/ (providers, pages, widgets)
└── main.dart
```

### b. Pemetaan File yang Diusulkan AI:
- `lib/data/auth_repository.dart` $\rightarrow$ Dipecah menjadi `domain/repositories/auth_repository.dart` dan `data/repositories/auth_repository_impl.dart`.
- `lib/pages/home_page.dart` $\rightarrow$ Pindah ke `features/announcements/presentation/pages/home_page.dart`.
- `lib/pages/login_page.dart` $\rightarrow$ Pindah ke `features/auth/presentation/pages/login_page.dart`.
- Dibuat 6 kelas Use Case individual terpisah untuk setiap aksi CRUD kecil.

---

## 3. AI Verification Checklist & Temuan Kritis

| No | Kriteria Verifikasi | Status | Temuan & Evaluasi Developer |
| :---: | :--- | :---: | :--- |
| 1 | Interface di `domain`, Implementasi di `data` | **LOLOS** ✅ | AI berhasil memisahkan abstract contract di domain dan implementasi konkrit di data. |
| 2 | Domain steril dari Flutter, Dio, Firebase, SQLite | **PERLU PERBAIKAN** ⚠️ | AI sempat mengusulkan import `package:flutter/foundation.dart` di file entity untuk anotasi `@immutable`. **Ditolak & diperbaiki:** Menggunakan constructor `const` murni Dart tanpa import package Flutter apapun agar domain benar-benar murni. |
| 3 | Use Case untuk tiap CRUD 1-baris | **OVER-ENGINEERING** 🛑 | AI membuat Use Case untuk setiap panggilan satu baris (misal `LogoutUseCase`, `GetAnnouncementByIdUseCase`). **Ditolak & disederhanakan:** CRUD satu baris yang hanya meneruskan parameter ke repository tanpa transformasi atau multi-repository adalah over-engineering untuk tim kecil. Cukup panggil repository via notifier, kecuali operasi bisnis penting seperti `GetAnnouncements`. |
| 4 | Entity bebas dari serialization mapping | **LOLOS** ✅ | AI memisahkan `toMap/fromMap/toEntity` ke dalam kelas `Model` di layer data. Entity di domain murni hanya atribut. |
| 5 | Wiring DI terpusat di Riverpod Provider | **LOLOS** ✅ | AI mengusulkan provider terpusat tanpa membuat widget menginstansiasi repositori secara manual. |

---

## 4. Tabel Perbandingan: Usulan AI vs Keputusan Final Developer

| Aspek Arsitektur | Usulan Awal AI | Keputusan Final Developer | Alasan Teknis & Trade-Off |
| :--- | :--- | :--- | :--- |
| **Granularitas Use Case** | Membuat use case untuk setiap aksi (mis. `GetAnnouncementById`, `ToggleTopic`, `RefreshAnnouncement`) | Hanya membuat use case yang memiliki nilai bisnis (`GetAnnouncements`) | Menghindari *boilerplate explosion* (kelas wrapper 5 baris). Pada aplikasi kecil/menengah, CRUD 1-baris langsung dari repository ke Notifier jauh lebih cepat dirawat tanpa mengurangi testability. |
| **Dependensi Entity** | Menggunakan `@immutable` dari `package:flutter/foundation.dart` | Menggunakan `const` constructor murni Dart | Menjaga sterilitas domain layer 100% dari framework UI. Domain harus dapat dijalankan pada lingkungan Dart VM murni (CLI / server / pure unit test). |
| **Return Type Repository** | Mengusulkan package eksternal `dartz` / `fpdart` (`Either<Failure, T>`) | Menggunakan fitur bawaan **Dart Record** `({T data, Failure? failure})` | Menghindari penambahan dependensi pihak ketiga (*third-party bloat*). Dart Record didukung secara native oleh bahasa Dart 3.x dan memberikan type-safety yang setara. |
| **Migrasi Halaman Eksisting** | Memindahkan seluruh file `lib/pages/` dan memecah rute GoRouter ke sub-folder fitur | Mempertahankan letak halaman `home_page.dart` dan `login_page.dart` pada komposisi rute utama, tetapi menghubungkan datanya ke `announcementsProvider` | Menghindari *breaking changes* pada navigasi GoRouter dan deep linking FCM push notification yang sudah stabil di Minggu 6. |

---

## 5. Kapan Use Case Benar-Benar Dibutuhkan?

1. **Use Case WAJIB Digunakan:**
   - Ketika ada **logika bisnis/validasi** sebelum atau sesudah data diambil (mis. validasi email, kalkulasi diskon, sorting custom, pemfilteran status).
   - Ketika ada **orkestrasi lintas repositori** (mis. mengambil data pengumuman dari `AnnouncementRepository` lalu mencatat riwayat baca ke `AnalyticsRepository` dan `CacheRepository`).
   - Ketika proses melibatkan **sinkronisasi offline-online** (mis. simpan ke local SQLite dulu, lalu kirim ke remote Dio di latar belakang).

2. **Use Case TIDAK Perlu (Over-Engineering):**
   - Operasi read/get sederhana satu baris yang hanya mem-forward data dari repository ke UI (`repo.fetchById(id)`).
   - Operasi delete atau toggle sederhana tanpa validasi tambahan.
   - Menggunakan use case untuk hal tersebut hanya menambah berkas dummy tanpa memberikan manfaat nyata bagi tim pengembang (*accidental complexity*).
