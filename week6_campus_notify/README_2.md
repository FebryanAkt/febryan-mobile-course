# Praktikum 1: Audit Layer Project Lama (Minggu 7 — Clean Architecture)

> **Proyek yang Diaudit:** `week6_campus_notify`  
> **Referensi Codelab:** [Polinema Mobile Codelab #07 - Clean Architecture (Langkah 2: Praktikum 1)](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html#2)

---

## 📌 Ringkasan Praktikum 1

Tujuan dari Praktikum 1 adalah melakukan audit menyeluruh terhadap arsitektur kode proyek Minggu 6 (`campus_notify`), mengidentifikasi pelanggaran prinsip **SOLID** dan aturan dependensi (**Separation of Concerns**), serta merancang struktur arsitektur target berbasis **Feature-First Clean Architecture** sebelum refactoring dilakukan pada praktikum berikutnya.

---

## 1. Pemetaan File ke Layer Saat Ini

Berikut adalah tabel audit pemetaan seluruh berkas proyek `campus_notify` ke layer arsitektur saat ini beserta analisis permasalahannya:

| File | Layer Saat Ini | Masalah / Temuan Audit |
| :--- | :--- | :--- |
| `lib/pages/home_page.dart` | `presentation` | ⚠️ **Pelanggaran:** Memanggil `FirebaseMessaging.instance.getToken()` langsung di dalam widget state. Memanggil method statis `FcmService.subscribeToTopic` / `unsubscribeFromTopic` langsung dari event handler tombol. Mengandung logika pemformatan/masking string token (`token.substring(...)`). Mendefinisikan entity/model tiruan `_NotifItem` dan mock data di dalam file presentation. |
| `lib/pages/login_page.dart` | `presentation` | ⚠️ **Pelanggaran:** Mengandung logika pemetaan error HTTP/API secara langsung (`mapApiError`) di dalam UI. Logika validasi bisnis login tercampur di form validator tanpa abstraksi *use case*. |
| `lib/pages/announcement_page.dart` | `presentation` | ⚠️ **Pelanggaran:** Menerima `id` mentah via path parameter dan langsung menampilkan string statis tanpa memanggil domain use case atau entitas pengumuman. |
| `lib/providers/auth_provider.dart` | `presentation` (State Management / DI) | ⚠️ **Pelanggaran:** Instansiasi kelas konkret langsung `AuthRepository()` tanpa abstraksi interface repository. Notifier memanggil implementasi repositori langsung tanpa perantara *use case*. |
| `lib/data/auth_repository.dart` | `data` (+ kontrak tercampur) | ⚠️ **Pelanggaran:** Interface (kontrak domain) dan implementasi konkret masih berada dalam satu kelas `AuthRepository`. Entity bisnis `AuthSession` bercampur di file layer data. |
| `lib/data/token_store.dart` | `data` | ⚠️ **Pelanggaran:** Kontrak `SessionTokenStore` diletakkan di layer data. Memiliki default instansiasi library platform `FlutterSecureStorage()` di constructor. |
| `lib/data/api_client.dart` | `data` | ℹ️ **Status:** Berfungsi sebagai network client wrapper, namun bergantung langsung pada kelas konkrit `AuthRepository` dan `SessionTokenStore`. |
| `lib/data/api_errors.dart` | `data` / `core` | ⚠️ **Pelanggaran:** Pemetaan error ditempatkan di folder `data`, padahal representasi `Failure` seharusnya berada di domain / core murni Dart. |
| `lib/messaging/push_service.dart` | `messaging` (Infrastruktur) | ⚠️ **Pelanggaran:** Mencampur konfigurasi native, presentasi banner lokal (`flutter_local_notifications`), dan penanganan payload navigasi. |
| `lib/services/fcm_service.dart` | `services` (Infrastruktur) | ⚠️ **Pelanggaran:** Semua fungsi bertipe statis (`static`), menyulitkan dependency injection dan unit test. Validasi aturan bisnis topik (`_validateTopic`) berada di service infrastruktur, bukan di domain. |
| `lib/routes.dart` | `core` / `presentation` | ⚠️ **Pelanggaran:** Menggabungkan konfigurasi rute navigasi dan fungsi parsing payload FCM (`routeFromMessage`). |
| `lib/main.dart` | `app` (Composition Root) | ℹ️ **Status:** Mengorkestrasi inisialisasi Firebase, provider Riverpod, dan GoRouter. Masih memanggil service statis `FcmService.initFcmToken` secara langsung. |

---

## 2. Hasil Audit Tiga Pelanggaran Klasik

Berdasarkan pencarian menggunakan perintah grep/pattern matching pada folder `lib/pages` dan `lib/providers`:

### 🔴 Pelanggaran 1: Widget yang Menyentuh Jaringan / Database / Service Eksternal Langsung
**Perintah Pencarian:**
```powershell
Select-String -Path "lib/pages/*.dart" -Pattern "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage|FirebaseMessaging\.instance"
```
**Temuan di Kode:**
- `lib/pages/home_page.dart:50`:
  ```dart
  final token = await FirebaseMessaging.instance.getToken();
  ```
- `lib/pages/home_page.dart:150`:
  ```dart
  await FirebaseMessaging.instance.getToken();
  ```
- `lib/pages/home_page.dart:66 & 68`:
  ```dart
  await FcmService.unsubscribeFromTopic('pengumuman-kampus');
  await FcmService.subscribeToTopic('pengumuman-kampus');
  ```
**Analisis:**
Widget UI secara langsung mengakses SDK Firebase dan method statis I/O eksternal. Hal ini melanggar *Separation of Concerns* dan *Dependency Inversion Principle (DIP)*. Widget seharusnya hanya berinteraksi dengan Notifier/ViewModel yang memanggil *Use Case*.

---

### 🟡 Pelanggaran 2: Logika Bisnis di dalam `build()` / Presentation
**Perintah Pencarian:**
```powershell
Select-String -Path "lib/pages/*.dart" -Pattern "DateFormat|jsonDecode|\.toIso8601String|substring"
```
**Temuan di Kode:**
- `lib/pages/home_page.dart:55`:
  ```dart
  _tokenDisplay = '...${token.substring(token.length - 6)}';
  ```
- `lib/pages/home_page.dart:22-41`:
  ```dart
  // Model dan daftar pengumuman tiruan didefinisikan langsung di dalam kelas widget state
  class _NotifItem { ... }
  final List<_NotifItem> _history = [ ... ];
  ```
**Analisis:**
Logika manipulasi data (masking string token) dan definisi entitas/daftar pengumuman berada di dalam file widget. Hal ini menyulitkan pengujian unit logika bisnis secara independen tanpa merender widget tree.

---

### 🔵 Pelanggaran 3: Instansiasi Manual (Dependency Injection Bocor)
**Perintah Pencarian:**
```powershell
Select-String -Path "lib/**/*.dart" -Pattern "Repository\(|Dio\(BaseOptions|FlutterSecureStorage\("
```
**Temuan di Kode:**
- `lib/providers/auth_provider.dart:7`:
  ```dart
  final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
  ```
- `lib/data/token_store.dart:12`:
  ```dart
  : _storage = storage ?? const FlutterSecureStorage();
  ```
- `lib/services/fcm_service.dart`:
  Semua method bertipe `static` tanpa adanya dependency injection interface yang dapat di-mock untuk testing.

**Analisis:**
Provider menginstansiasi implementasi konkret `AuthRepository` secara langsung alih-alih mengikat (*binding*) implementasi terhadap sebuah *abstract interface* repository.

---

## 3. Rancangan Struktur Target (Feature-First Clean Architecture)

Sesuai panduan Codelab Minggu 7, arsitektur target yang akan diterapkan pada refactoring fitur `announcements` dan `auth` adalah sebagai berikut:

```text
lib/
├── core/
│   ├── errors/
│   │   └── failures.dart                      # Kelas Failure domain murni Dart
│   └── network/
│       └── api_client.dart                    # Dio network client
│
├── features/
│   ├── announcements/
│   │   ├── domain/                            # Layer Domain (Murni Dart, Bebas Flutter)
│   │   │   ├── entities/
│   │   │   │   └── announcement.dart          # Entity murni Announcement
│   │   │   ├── repositories/
│   │   │   │   └── announcement_repository.dart # Abstract Interface kontrak repositori
│   │   │   └── usecases/
│   │   │       ├── get_announcements.dart     # Use case mengambil riwayat pengumuman
│   │   │       └── manage_topic.dart          # Use case subscribe/unsubscribe topik
│   │   │
│   │   ├── data/                              # Layer Data (Implementasi & Sumber Data Luar)
│   │   │   ├── models/
│   │   │   │   └── announcement_model.dart    # Model DTO pengumuman (fromJson/toJson)
│   │   │   ├── datasources/
│   │   │   │   └── announcement_remote_data_source.dart # Sumber data API / FCM
│   │   │   └── repositories/
│   │   │       └── announcement_repository_impl.dart    # Implementasi konkret repositori
│   │   │
│   │   └── presentation/                      # Layer Presentation (UI & State)
│   │       ├── providers/
│   │       │   └── announcement_providers.dart # Riverpod Notifier & DI binding
│   │       └── pages/
│   │           ├── home_page.dart             # UI Beranda bebas akses langsung ke FCM/Dio
│   │           └── announcement_page.dart     # UI Detail pengumuman
│   │
│   └── auth/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user_session.dart          # Entitas bisnis sesi autentikasi
│       │   ├── repositories/
│       │   │   └── auth_repository.dart       # Interface kontrak autentikasi
│       │   └── usecases/
│       │       └── login_usecase.dart         # Use case login bisnis
│       ├── data/
│       │   ├── models/
│       │   │   └── user_session_model.dart    # Model sesi JWT
│       │   └── repositories/
│       │       └── auth_repository_impl.dart  # Implementasi repositori auth & secure storage
│       └── presentation/
│           ├── providers/
│           │   └── auth_providers.dart        # Notifier auth & DI
│           └── pages/
│               └── login_page.dart            # UI Halaman login
│
├── routes.dart                                # Konfigurasi GoRouter & rute aplikasi
└── main.dart                                  # Entry point & Composition Root
```

---

## 4. Rangkuman Target Item Refactor untuk Praktikum Selanjutnya

Berdasarkan audit di atas, target refactor yang akan dilakukan pada praktikum berikutnya adalah:
1. **Membuat layer Domain (Praktikum 2):**
   - Mendefinisikan entity murni (`Announcement`) tanpa dependency eksternal.
   - Membuat kontrak abstract repository di layer domain.
   - Membuat *Use Case* untuk operasi bisnis (`GetAnnouncements`).
2. **Membuat layer Data (Praktikum 2):**
   - Mengimplementasikan repository interface di `data/repositories/`.
   - Mengonversi data eksternal ke domain entity menggunakan *Model*.
3. **Membersihkan layer Presentation (Praktikum 3):**
   - Menghubungkan widget hanya ke Riverpod Notifier yang memanggil Use Case.
   - Memastikan hasil audit grep di folder `lib/pages` dan `lib/widgets` menghasilkan **0 temuan pelanggaran**.

---

# Praktikum 2: Domain dan Data per Fitur (Minggu 7 — Clean Architecture)

> **Fitur yang Direfactor:** `announcements`  
> **Referensi Codelab:** [Polinema Mobile Codelab #07 - Clean Architecture (Langkah 3: Praktikum 2)](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html#3)

---

## 📌 Ringkasan Praktikum 2

Praktikum 2 berfokus pada implementasi dua lapisan terdalam dari Clean Architecture untuk fitur `announcements`:
1. **Layer Domain:** Merupakan lapisan paling dalam dan murni (*pure Dart*). Bebas dari impor Flutter, Dio, Firebase, atau SQLite. Berisi entitas bisnis murni (`Announcement`), failure hierarchy (`Failure`), kontrak abstraksi repositori (`AnnouncementRepository`), dan use case bisnis tunggal (`GetAnnouncements`).
2. **Layer Data:** Mengimplementasikan kontrak yang didefinisikan oleh domain. Berisi representasi DTO model data (`AnnouncementModel`) dengan fungsi mapping (`fromMap`, `toMap`, `toEntity`), serta implementasi konkret repositori (`AnnouncementRepositoryImpl`).

---

## 1. Entity Murni (Domain Layer)

Entity merepresentasikan objek bisnis murni tanpa logika mapping database/JSON dan tanpa dependensi framework UI Flutter.

📁 **Berkas:** `lib/features/announcements/domain/entities/announcement.dart`
```dart
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.time,
  });

  final String id;
  final String title;
  final String body;
  final String route;
  final String time;
}
```

---

## 2. Failure dan Kontrak Repository (Domain Layer)

### a. Hierarki Failure Murni Dart
📁 **Berkas:** `lib/core/failures.dart`
```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}
```

### b. Kontrak Interface Repository
Mendefinisikan *interface* murni yang dibutuhkan oleh domain. Menggunakan fitur **Dart Record** `({List<Announcement> announcements, Failure? failure})` untuk membedakan hasil sukses dan gagal secara tipe data tanpa membocorkan exception mentah ke presentation layer.

📁 **Berkas:** `lib/features/announcements/domain/repositories/announcement_repository.dart`
```dart
import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements();
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  );
}
```

---

## 3. Model dan Implementasi Repository (Data Layer)

### a. Model Data & Mapping
Model bertindak sebagai Data Transfer Object (DTO) yang bertanggung jawab memetakan format data eksternal (JSON/Map) ke entitas domain murni.

📁 **Berkas:** `lib/features/announcements/data/models/announcement_model.dart`
```dart
import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    required super.route,
    required super.time,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'route': route,
    'time': time,
  };

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      route: map['route']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
    );
  }

  Announcement toEntity() => Announcement(
    id: id,
    title: title,
    body: body,
    route: route,
    time: time,
  );
}
```

### b. Implementasi Repositori
Mengimplementasikan `AnnouncementRepository` yang didefinisikan oleh domain. Menangani eksepsi dan mengonversinya menjadi objek `Failure`.

📁 **Berkas:** `lib/features/announcements/data/repositories/announcement_repository_impl.dart`
```dart
import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({List<AnnouncementModel>? initialData})
    : _data = initialData ?? _defaultAnnouncements;

  final List<AnnouncementModel> _data;

  static const _defaultAnnouncements = [
    AnnouncementModel(
      id: '1',
      title: 'Jadwal UTS Dipercepat',
      body: 'UTS Pemrograman Mobile dimajukan ke 18 Oktober 2026.',
      route: '/pengumuman/1',
      time: '08:00',
    ),
    AnnouncementModel(
      id: '2',
      title: 'Pengumuman Beasiswa',
      body: 'Pendaftaran beasiswa prestasi dibuka hingga 30 Oktober 2026.',
      route: '/pengumuman/2',
      time: 'Kemarin',
    ),
    AnnouncementModel(
      id: '3',
      title: 'Libur Nasional',
      body: 'Kampus libur pada 28 Oktober 2026 (Hari Sumpah Pemuda).',
      route: '/pengumuman/3',
      time: '2 hari lalu',
    ),
  ];

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    try {
      final announcements = _data.map((m) => m.toEntity()).toList();
      return (announcements: announcements, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    try {
      final found = _data.where((m) => m.id == id).toList();
      if (found.isEmpty) {
        return (
          announcement: null,
          failure: const LocalFailure('Pengumuman tidak ditemukan'),
        );
      }
      return (announcement: found.first.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Gagal memuat detail pengumuman: $e'),
      );
    }
  }
}
```

---

## 4. Use Case: Operasi Bisnis Tunggal (Domain Layer)

Use case mewakili satu aksi bisnis spesifik dari pengguna. `GetAnnouncements` hanya bergantung pada abstraksi interface `AnnouncementRepository`.

📁 **Berkas:** `lib/features/announcements/domain/usecases/get_announcements.dart`
```dart
import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncements {
  const GetAnnouncements(this._repository);
  final AnnouncementRepository _repository;

  Future<({List<Announcement> announcements, Failure? failure})> call() {
    return _repository.fetchAnnouncements();
  }
}
```

---

## 5. Verifikasi Kepatuhan & Pengujian

### a. Sterilitas Domain Layer (Dependency Rule Check)
Sesuai aturan emas Clean Architecture, domain layer harus steril dari dependensi UI atau package pihak ketiga.
```powershell
Select-String -Path "lib/core/*.dart", "lib/features/**/domain/**/*.dart" -Pattern "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase"
```
**Hasil:** **0 Temuan (Lolos Sterilitas)** ✅

### b. Analisa Statis (Static Analysis)
```powershell
flutter analyze
```
**Hasil:**
```text
Analyzing week6_campus_notify...
No issues found!
```

### c. Pengujian Unit Otomatis (Unit Testing)
Dibuat pengujian unit di `test/features/announcements/announcement_domain_test.dart` untuk memverifikasi entitas, model serialization, repositori, dan use case:
```powershell
flutter test
```
**Hasil:**
```text
00:00 +0: loading test/auth_push_test.dart
00:00 +1: routeFromMessage parses announcement payloads safely
00:00 +2: Announcement Entity & Model Entity preserves properties
00:00 +3: Announcement Entity & Model Model converts toMap and fromMap correctly
00:00 +4: 401 refreshes once and retries the request with the new access token
00:00 +5: dead refresh token clears session and invokes logout callback
00:00 +6: AnnouncementRepositoryImpl & UseCase fetchAnnouncements returns non-empty list without failure
00:00 +7: AnnouncementRepositoryImpl & UseCase getAnnouncementById returns matching announcement
00:00 +8: AnnouncementRepositoryImpl & UseCase getAnnouncementById returns failure when id not found
00:00 +9: AnnouncementRepositoryImpl & UseCase GetAnnouncements usecase calls repository.fetchAnnouncements
00:00 +9: All tests passed!
```
Seluruh **9 skenario pengujian unit berhasil lolos 100% (PASS)** ✅.

---

# Praktikum 3: Presentation, DI, dan Verifikasi (Minggu 7 — Clean Architecture)

> **Fitur yang Direfactor:** `announcements`  
> **Referensi Codelab:** [Polinema Mobile Codelab #07 - Clean Architecture (Langkah 4: Praktikum 3)](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html#4)

---

## 📌 Ringkasan Praktikum 3

Praktikum 3 menyelesaikan tahapan refactoring Clean Architecture dengan:
1. **Dependency Injection (Wiring) dengan Riverpod:** Menghubungkan data layer (`AnnouncementRepositoryImpl`) dan domain layer (`GetAnnouncements`) ke presentation provider tanpa membuat widget bergantung langsung pada implementasi konkret.
2. **Refactoring UI Widget:** Memperbarui `HomePage` agar hanya membaca asynchronous state dari `announcementsProvider` menggunakan pola `AsyncValue.when()`. Model lokal tiruan `_NotifItem` dan hardcoded list `_history` berhasil dihapus sepenuhnya dari presentation layer.
3. **Verifikasi Tiga Aturan Dependensi (Dependency Rule Check):** Membuktikan bahwa presentation steril dari data mentah, domain steril dari library pihak ketiga, analisa statis bebas issue, dan seluruh unit test lulus 100%.

---

## 1. Dependency Injection dengan Riverpod

Berkas `announcement_providers.dart` menjadi satu-satunya tempat perakitan (*wiring*) dependensi antara Data, Domain, dan Presentation layer:

📁 **Berkas:** `lib/features/announcements/presentation/providers/announcement_providers.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';

// Data layer: repository disuntikkan (memudahkan mocking / replacement saat testing)
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

// Domain layer: use case menerima abstraksi interface, bukan implementasi konkret
final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

// Presentation layer: state asynchronous untuk dikonsumsi oleh UI widget
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.announcements;
});
```

---

## 2. Halaman Hanya Membaca State (UI Presentation)

Halaman `HomePage` dibersihkan dari model data lokal tiruan `_NotifItem` dan hardcoded list `_history`. Sekarang widget hanya mendengarkan state dari Riverpod melalui `announcementsProvider`:

📁 **Berkas:** `lib/pages/home_page.dart` (potongan kode implementasi):
```dart
@override
Widget build(BuildContext context) {
  final announcementsAsync = ref.watch(announcementsProvider);
  return Scaffold(
    ...
    // Riwayat Pengumuman
    Text(
      'Riwayat Pengumuman',
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    announcementsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Gagal memuat pengumuman: $err'),
        ),
      ),
      data: (announcements) => Column(
        children: announcements
            .map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    item.time,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                  onTap: () => context.go(item.route),
                ),
              ),
            )
            .toList(),
      ),
    ),
    ...
  );
}
```

> **Catatan:** Tampilan antarmuka (*UI*) tetap 100% identik dengan hasil implementasi Minggu 6 (judul, waktu, avatar icon, dan route `/pengumuman/1`), namun arsitektur di baliknya kini telah murni mengalir dari Data $\rightarrow$ Domain $\rightarrow$ Presentation.

---

## 3. Tiga Verifikasi Wajib Dependency Rule

Sesuai kriteria penyelesaian Praktikum 3 codelab, tiga pemeriksaan berikut wajib dipenuhi:

### ✅ Pemeriksaan 1: Presentation Steril dari Data Mentah (Target: 0 Temuan)
Memastikan tidak ada instansiasi klien HTTP mentah, SQLite database, secure storage, shared preferences, maupun parsing JSON manual di dalam presentation layer:
```powershell
Select-String -Path "lib/pages/*.dart", "lib/features/**/presentation/**/*.dart" -Pattern "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode"
```
**Hasil Eksekusi:** **0 Temuan (Lolos 100%)** ✅

---

### ✅ Pemeriksaan 2: Domain Steril dari Framework & Package Luar (Target: 0 Temuan)
Memastikan seluruh kode pada `domain` dan `core` merupakan *pure Dart* tanpa impor Flutter, Dio, SQLite, atau Firebase:
```powershell
Select-String -Path "lib/core/*.dart", "lib/features/**/domain/**/*.dart" -Pattern "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase"
```
**Hasil Eksekusi:** **0 Temuan (Lolos 100%)** ✅

---

### ✅ Pemeriksaan 3: Static Analysis & Unit Testing Bebas Masalah
1. **Analisa Statis:**
   ```powershell
   flutter analyze
   ```
   **Hasil:**
   ```text
   Analyzing week6_campus_notify...
   No issues found!
   ```

2. **Pengujian Unit Otomatis:**
   ```powershell
   flutter test
   ```
   **Hasil:**
   ```text
   00:00 +0: loading test/auth_push_test.dart
   00:00 +1: routeFromMessage parses announcement payloads safely
   00:00 +2: Announcement Entity & Model Entity preserves properties
   00:00 +3: Announcement Entity & Model Model converts toMap and fromMap correctly
   00:00 +4: 401 refreshes once and retries the request with the new access token
   00:00 +5: dead refresh token clears session and invokes logout callback
   00:00 +6: AnnouncementRepositoryImpl & UseCase fetchAnnouncements returns non-empty list without failure
   00:00 +7: AnnouncementRepositoryImpl & UseCase getAnnouncementById returns matching announcement
   00:00 +8: AnnouncementRepositoryImpl & UseCase getAnnouncementById returns failure when id not found
   00:00 +9: AnnouncementRepositoryImpl & UseCase GetAnnouncements usecase calls repository.fetchAnnouncements
   00:00 +10: GetAnnouncements Use Case (Pure Domain Test) GetAnnouncements meneruskan daftar pengumuman dari repository palsu
   00:00 +11: GetAnnouncements Use Case (Pure Domain Test) GetAnnouncements meneruskan failure tanpa melempar exception mentah
   00:00 +11: All tests passed!
   ```
   **11/11 Unit Tests Berhasil Lolos (PASS)** ✅.

---

## 🎯 Definisi Selesai (Definition of Done)

Refactoring Clean Architecture pada fitur `announcements` dinyatakan **SELESAI**:
- ✅ Tiga pemeriksaan sterilitas menghasilkan **0 temuan** pelanggaran.
- ✅ `flutter analyze` bersih tanpa warning atau lint error.
- ✅ Seluruh pengujian unit berjalan sukses dan hijau (11/11 tests pass).
- ✅ Tampilan dan fungsionalitas aplikasi berjalan identik seperti sebelum refactoring tanpa degradasi performa atau regresi fitur.

---

# AI Challenge (Minggu 7 — Clean Architecture)

> **Konteks:** Evaluasi Reorganisasi Clean Architecture, Penilaian Over-Engineering, dan Verifikasi Checklist  
> **Referensi Codelab:** [Polinema Mobile Codelab #07 - Clean Architecture (Langkah 5: AI Challenge)](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html#5)

---

## 1. Prompt Asli AI Challenge

Berikut adalah prompt tantangan yang diajukan:

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

## 2. Output & Draf Usulan Awal AI

### a. Usulan Struktur Folder oleh AI
AI menyarankan pembagian sub-fitur lengkap untuk `auth` dan `announcements` dengan setiap layer memiliki `entities`, `repositories`, `usecases`, `models`, `datasources`, `providers`, dan `pages`. AI juga membuat 6 use case terpisah untuk setiap aksi individual (misal `LoginUseCase`, `LogoutUseCase`, `GetAnnouncementsUseCase`, `GetAnnouncementDetailUseCase`, `SubscribeTopicUseCase`, `UnsubscribeTopicUseCase`).

### b. Usulan Dependency Injection oleh AI
AI menyarankan penggunaan Riverpod untuk menyuntikkan repository ke dalam use case, dan use case ke dalam notifier/provider.

---

## 3. AI Verification Checklist & Hasil Audit

| No | Checklist Verifikasi Codelab | Status | Hasil Evaluasi & Tindakan |
| :---: | :--- | :---: | :--- |
| 1 | **Apakah interface repository tinggal di `domain` dan implementasi di `data`?** | **LULUS** ✅ | Terpisah tegas: abstract class `AnnouncementRepository` di `domain/repositories/` dan `AnnouncementRepositoryImpl` di `data/repositories/`. |
| 2 | **Apakah `domain` bebas import Flutter / Dio / SQLite / Firebase?** | **LULUS** ✅ | Terbukti 100% steril lewat grep: `0 temuan` import framework UI/platform pada `lib/core` dan `lib/features/*/domain`. Draf AI yang menyarankan anotasi `@immutable` dari Flutter ditolak demi menjaga kemurnian Dart. |
| 3 | **Apakah AI membuat use case untuk tiap CRUD satu-baris? (Over-Engineering Check)** | **DISELEKSI** 🛑 | Draf AI membuat use case terpisah untuk setiap pemanggilan satu baris. Ini diidentifikasi sebagai **over-engineering**. Keputusan: Hanya buat use case untuk alur utama yang memiliki aturan bisnis (`GetAnnouncements`). Aksi trivial satu-baris dapat langsung menghubungkan repository ke notifier. |
| 4 | **Apakah entity bebas mapping (`toMap`/`fromMap`/`toJson` hanya di model)?** | **LULUS** ✅ | Entity `Announcement` murni berisi properti objek domain. Seluruh serialisasi JSON/Map ditempatkan eksklusif pada `AnnouncementModel` di layer data. |
| 5 | **Apakah wiring DI terpusat di provider dan widget tidak `new Repository()` sendiri?** | **LULUS** ✅ | Terpusat di `announcement_providers.dart`. Widget `HomePage` hanya membaca state via `ref.watch(announcementsProvider)`. |

---

## 4. Tabel Usulan AI vs Keputusan Final Developer

| Komponen / Topik | Usulan Awal AI | Keputusan Final Developer | Alasan Teknis & Trade-Off |
| :--- | :--- | :--- | :--- |
| **Granularitas Use Case** | Membuat use case untuk setiap aksi kecil (misal `LogoutUseCase`, `ToggleTopicUseCase`). | Hanya membuat use case yang merepresentasikan logika bisnis inti (`GetAnnouncements`). | **Menghindari Boilerplate Explosion:** Membuat kelas use case untuk operasi satu baris yang hanya meneruskan parameter ke repository tanpa transformasi adalah pemborosan kode (*accidental complexity*). |
| **Penyimpanan Format Data & Error Handling** | Menyarankan library pihak ketiga `dartz` / `fpdart` untuk tipe data `Either<Failure, T>`. | Menggunakan fitur bawaan bahasa **Dart Record** `({T data, Failure? failure})`. | **Zero Dependency Overhead:** Dart Record (tersedia sejak Dart 3) memberikan keamanan tipe data (*type-safety*) yang identik tanpa menambah ukuran build (*APK bloat*) atau dependensi eksternal. |
| **Kemurnian Domain Layer** | Menyarankan import `package:flutter/foundation.dart` untuk `@immutable`. | Menggunakan constructor `const` murni Dart tanpa import package luar. | **Sterilitas Domain:** Memastikan layer domain 100% independen dari Flutter SDK sehingga dapat dijalankan dan diuji di lingkungan Dart murni secara instan. |
| **Struktur Halaman UI** | Memindahkan seluruh file `lib/pages/` dan merombak file rute GoRouter. | Menjaga stabilitas rute di `lib/pages/` dan mengintegrasikan provider Clean Architecture ke dalam widget. | **Mencegah Regresi Fitur:** Menjaga agar deep linking FCM push notification dari Minggu 6 tetap berfungsi stabil tanpa risiko *breaking changes* pada navigasi. |

---

## 5. Kapan Use Case Benar-Benar Dibutuhkan?

1. **Use Case Wajib Dibuat Kapan:**
   - Ketika ada **validasi atau logika bisnis** sebelum/sesudah interaksi data (contoh: validasi format data, kalkulasi, pemfilteran).
   - Ketika ada **orkestrasi multi-repository** (contoh: mengambil pengumuman dari server lalu menyimpan log riwayat ke analitik lokal).
   - Ketika ada **aturan offline-first / caching** (contoh: cek database lokal terlebih dahulu, jika kosong baru request ke API jaringan).

2. **Kapan Repository Langsung ke Notifier Sudah Cukup:**
   - Untuk operasi CRUD sederhana satu baris (misal membaca detail berdasarkan ID tunggal atau menghapus item) di mana data langsung diteruskan apa adanya tanpa logika bisnis tambahan.
   - Pada proyek kecil hingga menengah, pendekatan ini menghemat waktu pemeliharaan tanpa mengorbankan kemampuan pengujian (*testability*).



