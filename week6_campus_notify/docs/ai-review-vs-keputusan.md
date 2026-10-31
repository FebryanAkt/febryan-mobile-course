# AI Review vs Keputusan Saya

## Konteks

Prompt yang diberikan ke AI:

> Review PR Flutter ini sebagai senior Flutter dev.
> Konteks: feature-first Clean Architecture (presentation → domain ← data),
> Riverpod, GoRouter, SQLite + Dio.
> Fokus: kebenaran, arsitektur, dan test. Abaikan style.
> Berikan 5 temuan teratas + level (blocker/saran) + alasan + usulan potongan kode perbaikan.

---

## 5 Temuan AI

### Temuan 1 — Ada dua `AuthRepository` yang saling duplikasi

- **Level:** Blocker
- **Alasan:** Terdapat dua class `AuthRepository` terpisah:
  - `lib/data/auth_repository.dart` — class konkret (dipakai oleh `lib/providers/auth_provider.dart` dan `lib/data/api_client.dart`)
  - `lib/features/auth/domain/repositories/auth_repository.dart` — abstract class (dipakai oleh `features/auth/domain/usecases/login_usecase.dart`)

  Keduanya punya method `login()` tapi dengan return type berbeda (`AuthSession` vs record `({UserSession?, Failure?})`). Ini berarti ada dua jalur login yang tidak terhubung — `AuthNotifier` di `lib/providers/` memanggil repository yang **bukan** bagian dari arsitektur Clean Architecture.

- **Usulan:** Hapus `lib/data/auth_repository.dart` dan ubah `AuthNotifier` agar menggunakan `LoginUseCase` dari domain layer.

### Temuan 2 — `announcementsProvider` membuang `Failure` typed lalu melempar `Exception` generik

- **Level:** Blocker
- **Alasan:** Di `announcement_providers.dart` baris 21:
  ```dart
  throw Exception(result.failure!.message);
  ```
  `Failure` yang sudah ter-typed (`LocalFailure`, `NetworkFailure`, dll.) dibuang dan diganti `Exception` generik. UI (`HomePage`) hanya menerima pesan string — tidak bisa membedakan apakah ini network error (perlu retry) atau local error.

- **Usulan:**
  ```dart
  final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
    final result = await ref.watch(getAnnouncementsProvider).call();
    if (result.failure != null) {
      throw result.failure!; // Pertahankan tipe Failure
    }
    return result.announcements;
  });
  ```

### Temuan 3 — `pendingDeepLink` adalah global mutable state yang rentan race condition

- **Level:** Saran
- **Alasan:** `pendingDeepLink` dideklarasikan sebagai variabel global top-level di `push_service.dart` baris 106. Ini bisa menyebabkan race condition jika `onDidReceiveNotificationResponse` callback dipanggil bersamaan dengan `handleTerminated()`.

- **Usulan:** Pindahkan ke class dengan synchronization, atau gunakan `Completer<String?>`.

### Temuan 4 — `getAnnouncementById` ada di repository tapi tidak punya use case dan tidak dipanggil siapa pun

- **Level:** Saran
- **Alasan:** Method `getAnnouncementById` didefinisikan di abstract `AnnouncementRepository` dan diimplementasikan di `AnnouncementRepositoryImpl`, tapi:
  - Tidak ada `GetAnnouncementById` use case di domain layer
  - Tidak ada provider yang memanggilnya
  - `AnnouncementPage` hanya menampilkan ID statis, tidak memuat data dari repository

  Ini dead code yang menambah surface area tanpa manfaat saat ini.

- **Usulan:** Buat use case `GetAnnouncementById` + provider, atau hapus sampai benar-benar dibutuhkan.

### Temuan 5 — Validasi email di `LoginUseCase` duplikat dengan `AuthRepositoryImpl` dan `LoginPage`

- **Level:** Saran
- **Alasan:** Validasi `email.contains('@')` dan `password.length < 6` dilakukan di tiga tempat:
  1. `LoginPage` (form validator)
  2. `LoginUseCase` (domain)
  3. `AuthRepositoryImpl` (data)

  Tiga titik validasi yang sama berarti perubahan aturan harus diubah di tiga tempat.

- **Usulan:** Cukup validasi di `LoginUseCase` (domain) sebagai sumber kebenaran. Form validator di UI boleh tetap ada untuk UX cepat. Hapus validasi di `AuthRepositoryImpl` karena data layer seharusnya hanya memanggil API.

---

## AI Verification Checklist

### ✅ Temuan 1 — BENAR (diterima)

**Bukti grep:**

```
> Get-ChildItem -Recurse -Include *.dart -Path lib | Select-String -Pattern "class AuthRepository"

lib\data\auth_repository.dart:7:           class AuthRepository {
lib\features\auth\domain\repositories\auth_repository.dart:4:  abstract class AuthRepository {
lib\features\auth\data\repositories\auth_repository_impl.dart:6: class AuthRepositoryImpl implements AuthRepository {
```

```
> Get-ChildItem -Recurse -Include *.dart -Path lib | Select-String -Pattern "import.*data/auth_repository"

lib\providers\auth_provider.dart:3:import '../data/auth_repository.dart';
```

**Terbukti:** Ada dua `AuthRepository`. `AuthNotifier` mengimpor versi konkret (`lib/data/`), bukan abstrak domain. Ini melanggar arsitektur — presentation layer (`AuthNotifier`) langsung bergantung pada implementasi konkret, bukan domain interface.

**Keputusan saya:** Diterima. Ini memang warisan dari Week 6 sebelum refactor Clean Architecture di Week 7. Idealnya `AuthNotifier` harus menggunakan `LoginUseCase`, tapi karena `lib/providers/auth_provider.dart` dan `lib/data/` adalah modul legacy yang belum dimigrasi penuh, saya catat sebagai tech debt untuk paruh kedua semester.

### ✅ Temuan 2 — BENAR (diterima)

**Bukti grep:**

```
> Select-String -Path lib\features\announcements\presentation\providers\announcement_providers.dart -Pattern "throw Exception"

announcement_providers.dart:21:    throw Exception(result.failure!.message);
```

**Terbukti:** `Failure` typed dibuang dan diganti `Exception` generik. Informasi tipe (`LocalFailure`, `NetworkFailure`, dsb.) hilang sebelum sampai ke UI.

**Keputusan saya:** Diterima. Perbaikan ringan dan tidak melanggar dependency rule — cukup ganti `throw Exception(...)` menjadi `throw result.failure!` agar tipe tetap terbawa. UI bisa melakukan pattern matching pada `Failure` untuk menampilkan pesan yang sesuai.

### ❌ Temuan 3 — BENAR tapi DITOLAK

**Bukti grep:**

```
> Get-ChildItem -Recurse -Include *.dart -Path lib | Select-String -Pattern "pendingDeepLink"

lib\messaging\push_service.dart:79:   pendingDeepLink = response.payload;
lib\messaging\push_service.dart:86:   pendingDeepLink = launchDetails?...payload;
lib\messaging\push_service.dart:106:  String? pendingDeepLink;
lib\messaging\push_service.dart:165:  final localRoute = pendingDeepLink;
lib\messaging\push_service.dart:166:  pendingDeepLink = null;
```

**Apakah benar ada?** Ya, `pendingDeepLink` memang global mutable.

**Alasan ditolak:** Dalam Flutter, semua kode Dart berjalan di satu isolate (main isolate) dan event loop single-threaded. Tidak ada true concurrency yang menyebabkan race condition pada variabel Dart biasa. `onDidReceiveNotificationResponse` dan `handleTerminated` keduanya berjalan di main isolate secara sekuensial melalui event loop. Mengubah ini menjadi `Completer` atau class wrapper justru over-engineering untuk kasus yang tidak bisa terjadi di Dart single-threaded. **AI salah menerapkan konsep race condition multi-threaded ke Dart.**

### ✅ Temuan 4 — BENAR (diterima sebagai catatan)

**Bukti grep:**

```
> Get-ChildItem -Recurse -Include *.dart -Path lib | Select-String -Pattern "getAnnouncementById"

lib\features\announcements\data\repositories\announcement_repository_impl.dart:51: ...getAnnouncementById(
lib\features\announcements\domain\repositories\announcement_repository.dart:7:    ...getAnnouncementById(
```

**Terbukti:** `getAnnouncementById` hanya ada di definisi repository (abstract + impl), tidak dipanggil oleh use case, provider, maupun UI manapun. Namun sudah ada test-nya di `announcement_domain_test.dart`.

**Keputusan saya:** Diterima sebagai catatan. Ini bukan dead code yang berbahaya — ini bagian dari kontrak repository yang sudah di-test dan direncanakan untuk dipakai saat `AnnouncementPage` nanti memuat data dari repository (saat ini masih menampilkan ID statis). Tidak perlu dihapus; cukup ditandai untuk diintegrasikan di paruh kedua.

### ✅ Temuan 5 — BENAR tapi bukan masalah sebenarnya

**Apakah benar ada?** Ya, validasi `email.contains('@')` ada di 3 tempat:
- `LoginPage` form validator (baris 96)
- `LoginUseCase` (baris 13)
- `AuthRepositoryImpl` (baris 14)

**Keputusan saya:** Diterima sebagian. Validasi di form (UI) wajar untuk UX — user langsung dapat feedback tanpa round-trip. Validasi di `LoginUseCase` (domain) benar sebagai business rule. Yang memang tidak perlu adalah validasi di `AuthRepositoryImpl` — karena data layer idealnya hanya memanggil API/backend, bukan memvalidasi ulang input. Tapi karena sekarang masih mock (belum ada backend asli), ini tidak berbahaya dan bisa dibersihkan saat integrasi API nyata.

---

## Ringkasan

| # | Temuan | Benar? | Keputusan | Alasan |
|---|--------|--------|-----------|--------|
| 1 | Dua `AuthRepository` duplikasi | ✅ Ya | **Diterima** — catat sebagai tech debt | Legacy Week 6 belum migrasi penuh |
| 2 | `throw Exception` buang tipe `Failure` | ✅ Ya | **Diterima** — perbaiki | Ganti ke `throw result.failure!` |
| 3 | `pendingDeepLink` global race condition | ✅ Ada, tapi salah | **Ditolak** | Dart single-threaded, race condition tidak mungkin terjadi |
| 4 | `getAnnouncementById` dead code | ✅ Ya | **Diterima sebagai catatan** | Sudah di-test, direncanakan untuk integrasi |
| 5 | Validasi tripel di 3 layer | ✅ Ya | **Diterima sebagian** | Bersihkan di `AuthRepositoryImpl` saat integrasi API nyata |

**Temuan terbukti benar dengan bukti: 4** (Temuan 1, 2, 4, 5)
**Temuan ditolak dengan alasan: 1** (Temuan 3)
