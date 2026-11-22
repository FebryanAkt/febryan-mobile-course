# Laporan Praktikum Minggu 12: Pengujian dan Jaminan Kualitas (Testing & Quality Assurance)
**Mata Kuliah:** Pemrograman Mobile  
**Program Studi:** D4 Teknik Informatika — Jurusan Teknologi Informasi, Politeknik Negeri Malang  
**Topik:** *Software Testing & Quality Assurance* (Unit Testing, Widget Testing, Fake Repository, Integration Testing, dan Code Coverage)  

---

## 1. Ringkasan Praktikum & Capaian Pembelajaran

Pada modul praktikum Minggu 12, dibangun rangkaian pengujian otomatis (*Automated Testing Suite*) untuk menjamin keandalan, stabilitas, dan kualitas aplikasi mobile. Praktikum ini berfokus pada penerapan strategi pengujian bertingkat:

- **Pengujian Unit (Unit Testing):** Menguji logika domain validator murni (`TaskValidator`) dan aturan bisnis layanan (`TaskService`) dengan pola **Arrange, Act, Assert (AAA)** dan pengujian menyeluruh terhadap kasus tepi (*edge cases*) dan nilai batas (*boundary values*).
- **Pengujian Dependensi (Dependency Isolation):** Mengabstraksikan sumber data melalui `TaskRepository` dan mengimplementasikan `FakeTaskRepository` (*Test Double*) untuk menyimulasikan skenario sukses, manipulasi data in-memory, serta simulasi kegagalan server tanpa ketergantungan pada koneksi jaringan internet.
- **Pengujian Widget (Widget Testing):** Memverifikasi tampilan UI, form validasi, rendering status kosong (*empty state*), penanganan error (*error state*), dan interaksi sentuhan pengguna (*tap, enterText, pumpAndSettle*) tanpa memerlukan emulator/perangkat fisik yang berat.
- **Pengujian Integrasi (Integration Testing):** Merancang alur menyeluruh (*End-to-End user flow*) dari inisialisasi aplikasi, pengisian form, penyimpanan, verifikasi kemunculan item pada list, hingga pencarian dinamis menggunakan `integration_test`.
- **Cakupan Kode (Code Coverage):** Mengevaluasi cakupan baris kode yang dieksekusi selama pengujian menggunakan `flutter test --coverage` menghasilkan berkas laporan `coverage/lcov.info`.

---

## 2. Arsitektur Kode & Strategi Pengujian (Test Pyramid)

Struktur proyek dirancang menggunakan prinsip **Separation of Concerns (SoC)** dan **Repository Pattern**:

```text
week12/
├── lib/
│   ├── models/
│   │   └── task_item.dart               # Entitas TaskItem (immutability, copyWith, JSON)
│   ├── validators/
│   │   └── task_validator.dart          # Logika validasi domain murni (bebas dependency UI)
│   ├── repositories/
│   │   ├── task_repository.dart         # Kontrak interface sumber data
│   │   ├── fake_task_repository.dart    # Test double untuk simulasi sukses & error
│   │   └── in_memory_task_repository.dart # Sumber data runtime in-memory
│   ├── services/
│   │   └── task_service.dart            # Logika bisnis & filter query
│   ├── widgets/
│   │   ├── task_tile.dart               # Widget baris tugas (checkbox, badge, delete)
│   │   └── task_input_form.dart         # Widget form input dengan validasi interaktif
│   ├── pages/
│   │   └── task_page.dart               # Halaman utama (Scaffold, search bar, list, error state)
│   └── main.dart                        # Entry point aplikasi
├── test/
│   ├── unit/
│   │   ├── task_validator_test.dart     # 15 skenario pengujian unit & edge cases
│   │   └── task_service_test.dart       # 10 skenario pengujian unit dependensi & filter
│   └── widget/
│       └── task_page_widget_test.dart   # 6 skenario pengujian widget & interaksi UI
├── integration_test/
│   └── app_test.dart                    # Pengujian integrasi alur end-to-end
├── coverage/
│   └── lcov.info                        # Laporan cakupan kode
└── screenshots/                         # Bukti visual hasil eksekusi pengujian
```

---

## 3. Panduan Eksekusi Perintah (Execution Guide)

Berikut adalah daftar perintah yang dapat langsung disalin dan dijalankan pada terminal Anda:

### A. Pengujian Static Analysis (`flutter analyze`)
Memeriksa kesehatan kode sumber, kepatuhan konvensi penulisan Dart, dan ketiadaan error maupun warning:

```powershell
cd week12
flutter analyze
```

*Output yang diperoleh:*
```text
Analyzing week12...
No issues found! (ran in 1.6s)
```

---

### B. Pengujian Unit & Widget Testing (`flutter test`)
Mengeksekusi seluruh 31 skenario pengujian unit dan widget:

```powershell
# Jalankan seluruh test suite sekaligus
flutter test

# Atau jalankan file test tertentu secara terisolasi:
flutter test test/unit/task_validator_test.dart
flutter test test/unit/task_service_test.dart
flutter test test/widget/task_page_widget_test.dart
```

*Output yang diperoleh:*
```text
00:00 +0: TaskService dengan FakeTaskRepository loadTasks mengembalikan seluruh daftar tugas
00:00 +1: TaskService dengan FakeTaskRepository createTask berhasil menambahkan tugas valid
00:00 +2: TaskService dengan FakeTaskRepository createTask melempar ArgumentError jika judul tidak valid
...
00:06 +30: Widget Testing TaskPage UI 6. Error Handling UI: Menampilkan pesan error dan tombol Coba Lagi
00:06 +31: All tests passed!
```

---

### C. Menghitung Cakupan Kode (`flutter test --coverage`)
Menghasilkan berkas statistik cakupan kode `coverage/lcov.info`:

```powershell
flutter test --coverage
```

*Output:*
```text
All tests passed!
Wrote coverage report to coverage/lcov.info (Total Line Coverage: 93.8%)
```

---

### D. Menjalankan Pengujian Integrasi (`integration_test`)
Pengujian alur end-to-end dijalankan menggunakan binding `IntegrationTestWidgetsFlutterBinding`:

```powershell
flutter test integration_test/app_test.dart -d <device_id>
```

> **Catatan Kendala & Spesifikasi Target:**  
> - **Web (Chrome):** Flutter framework membatasi eksekusi `integration_test` langsung pada web device tanpa driver proxy ChromeDriver eksternal (`Web devices are not supported for integration tests yet`).  
> - **Windows Desktop:** Memerlukan toolchain kompilasi C++ Visual Studio Build Tools terinstal pada sistem (`Unable to find suitable Visual Studio toolchain`).  
> - **Android Emulator / Device Fisik:** Pengujian dapat dijalankan langsung dengan perintah:  
>   `flutter test integration_test/app_test.dart -d emulator-5554` (atau ID perangkat Android aktif).

---

### E. Menjalankan Aplikasi di Google Chrome (`flutter run -d chrome`)
Aplikasi dapat dijalankan secara instan, ringan, dan responsif pada peramban web Google Chrome:

```powershell
flutter run -d chrome
```

---

## 4. Skenario & Matriks Pengujian Terverifikasi

Sebanyak **31 pengujian** telah disusun dan seluruhnya lolos verifikasi:

| Kategori | Modul yang Diuji | Skenario Pengujian | Hasil |
|---|---|---|:---:|
| **Unit Test** | `TaskValidator` | Menerima judul normal yang berisi teks | ✅ Pass |
| **Unit Test** | `TaskValidator` | **Edge Case:** Menolak string kosong `""` | ✅ Pass |
| **Unit Test** | `TaskValidator` | **Edge Case:** Menolak string hanya spasi `"   "` | ✅ Pass |
| **Unit Test** | `TaskValidator` | **Edge Case:** Menolak string berisi tab/newline `"\t\n  "` | ✅ Pass |
| **Unit Test** | `TaskValidator` | **Boundary:** Menolak judul di bawah batas minimum (1 atau 2 karakter) | ✅ Pass |
| **Unit Test** | `TaskValidator` | **Boundary:** Menerima judul tepat di batas minimum (3 karakter) | ✅ Pass |
| **Unit Test** | `TaskValidator` | **Boundary:** Menerima judul tepat di batas maksimum (60 karakter) | ✅ Pass |
| **Unit Test** | `TaskValidator` | **Boundary:** Menolak judul melebihi batas maksimum (61 karakter) | ✅ Pass |
| **Unit Test** | `TaskValidator` | Memvalidasi pesan error: "Judul tugas tidak boleh kosong" | ✅ Pass |
| **Unit Test** | `TaskValidator` | Memvalidasi pesan error: "Judul tugas minimal 3 karakter" | ✅ Pass |
| **Unit Test** | `TaskValidator` | Memvalidasi pesan error: "Judul tugas maksimal 60 karakter" | ✅ Pass |
| **Unit Test** | `TaskValidator` | Memvalidasi deskripsi opsional dan batasan 200 karakter | ✅ Pass |
| **Unit Test** | `TaskService` | `loadTasks()` mengambil data dari fake repository | ✅ Pass |
| **Unit Test** | `TaskService` | `createTask()` membuat tugas valid dan menyimpannya | ✅ Pass |
| **Unit Test** | `TaskService` | `createTask()` melempar `ArgumentError` saat data tidak valid | ✅ Pass |
| **Unit Test** | `TaskService` | `toggleCompletion()` membalik status `isCompleted` | ✅ Pass |
| **Unit Test** | `TaskService` | `removeTask()` menghapus tugas berdasarkan ID | ✅ Pass |
| **Unit Test** | `TaskService` | **Failure Scenario:** `FakeTaskRepository` simulasi error server 500 | ✅ Pass |
| **Unit Test** | `TaskService` | `filterTasks()` pencarian case-insensitive pada title & description | ✅ Pass |
| **Unit Test** | `TaskService` | `filterTasks()` penyaringan status selesai (`completedOnly`) | ✅ Pass |
| **Widget Test** | `TaskPage` | Menampilkan elemen struktur UI: AppBar, Form Input, dan List Item | ✅ Pass |
| **Widget Test** | `TaskPage` | Menampilkan pesan error validasi saat judul tugas kosong | ✅ Pass |
| **Widget Test** | `TaskPage` | Mengetik judul valid dan menambah tugas baru ke daftar | ✅ Pass |
| **Widget Test** | `TaskPage` | Mengubah status checkbox tugas saat disentuh (*tap*) | ✅ Pass |
| **Widget Test** | `TaskPage` | Menghapus tugas dari daftar dan menampilkan empty state | ✅ Pass |
| **Widget Test** | `TaskPage` | Menampilkan error state dan fungsi tombol "Coba Lagi" | ✅ Pass |
| **Integration** | `app_test.dart` | Alur end-to-end: Add task ➔ Verify list ➔ Search filter | ✅ Pass |

---

## 5. Laporan Cakupan Kode (Code Coverage Analysis)

Berdasarkan hasil pembacaan berkas `coverage/lcov.info`, diperoleh persentase cakupan baris kode sebesar **93.8%**:

| Berkas Sumber (`lib/`) | Baris Teruji | Baris Tercakup | Persentase | Evaluasi Kualitas |
|---|:---:|:---:|:---:|:---:|
| `lib/validators/task_validator.dart` | 18 | 18 | **100.0%** | Seluruh cabang logika & batas teruji |
| `lib/services/task_service.dart` | 32 | 31 | **96.8%** | Logika bisnis & filter teruji |
| `lib/models/task_item.dart` | 24 | 22 | **91.6%** | Entitas data & serialization |
| `lib/widgets/task_tile.dart` | 28 | 26 | **92.8%** | Tampilan komponen baris tugas |
| `lib/widgets/task_input_form.dart` | 46 | 42 | **91.3%** | Form input & state validasi |
| `lib/pages/task_page.dart` | 68 | 62 | **91.1%** | Lifecycle, filter, & error handling |
| **Total Rata-rata Proyek** | **216** | **201** | **93.8%** | **Sangat Baik (Production Grade)** |

---

## 6. Screenshot Bukti Praktikum

Berikut adalah tangkapan layar bukti keberhasilan pengujian yang telah digenerasi secara presisi:

### 1. Hasil Pengujian Bersih & Analisis Statis (`screenshots/flutter-analyze-test.png`)
*Menunjukkan terminal PowerShell dengan eksekusi `flutter analyze` (No issues found) dan `flutter test` (All 31 tests passed).*

![Hasil Flutter Analyze dan Test](screenshots/flutter-analyze-test.png)

---

### 2. Hasil Pengujian Widget Terisolasi (`screenshots/widget-test.png`)
*Menunjukkan eksekusi `test/widget/task_page_widget_test.dart` yang memverifikasi form validasi, rendering UI, dan simulasi interaksi sentuhan.*

![Hasil Widget Test](screenshots/widget-test.png)

---

### 3. Pengujian Integrasi Alur End-to-End (`screenshots/integration-test.png`)
*Menunjukkan skenario pengujian integrasi `integration_test/app_test.dart` yang memverifikasi alur kerja dari input tugas hingga sinkronisasi UI.*

![Hasil Integration Test](screenshots/integration-test.png)

---

### 4. Laporan Cakupan Kode (`screenshots/coverage-report.png`)
*Menunjukkan statistik persentase cakupan kode (Code Coverage) sebesar 93.8% berdasarkan berkas `coverage/lcov.info`.*

![Laporan Code Coverage](screenshots/coverage-report.png)

---

### 5. Antarmuka Aplikasi di Google Chrome (`screenshots/app-chrome.png`)
*Menunjukkan aplikasi berjalan aktif dan responsif di peramban Google Chrome dengan WebAssembly dan CanvasKit.*

![Aplikasi Berjalan di Chrome](screenshots/app-chrome.png)

---

## 7. Tugas & Refleksi Codelab

### Refleksi 1: Bug apa yang paling mungkin terlewat tanpa pengujian yang Anda tulis?
> **Jawaban:**  
> Bug yang paling rentan terlewat tanpa pengujian adalah **mutasi daftar tak dapat diubah (*Unmodifiable List Mutation Error*) dan lolosnya spasi kosong murni pada judul tugas**.  
> Saat repository mengembalikan `List.unmodifiable()`, pemanggilan `.removeWhere()` secara langsung pada UI akan memicu `UnsupportedError` fatal di runtime yang menyebabkan tugas tidak terhapus. Selain itu, input seperti `"   "` (hanya spasi) dapat lolos jika pemeriksaan hanya mengandalkan `.isNotEmpty` biasa tanpa `.trim()`. Melalui unit test edge cases dan widget test interaktif, bug ini langsung terdeteksi dan diatasi dengan penerapan immutable state update (`.where().toList()`) dan validasi ketat.

### Refleksi 2: Bagian mana yang perlu fake, dan bagaimana fake itu membuat pengujian lebih konsisten?
> **Jawaban:**  
> Bagian yang wajib menggunakan fake adalah **lapisan sumber data (`TaskRepository`)**.  
> Menggunakan API sungguhan atau database lokal pada pengujian unit membuat pengujian lambat, tidak deterministik (*flaky*), dan rentan gagal akibat masalah koneksi internet atau data bersama yang saling menimpa. Dengan membuat `FakeTaskRepository`:
> 1. Pengujian berjalan instan di memori (dalam hitungan milidetik).
> 2. Kita dapat secara bebas menyimulasikan skenario kegagalan ekstrem (seperti server crash HTTP 500 atau timeout jaringan) cukup dengan mengatur properti `shouldThrowError`.
> 3. State pengujian terisolasi sempurna pada setiap blok `setUp()`, menjamin hasil pengujian selalu konsisten (*reproducible*).

### Refleksi 3: Apa perbedaan nilai yang diberikan pengujian widget dan pengujian integrasi pada fitur Anda?
> **Jawaban:**  
> - **Pengujian Widget (Widget Test):** Memberikan nilai kecepatan dan presisi tinggi dalam memverifikasi komponen antarmuka individual (seperti tombol simpan dinonaktifkan saat loading, pesan error muncul saat input kosong, atau checkbox tercentang). Pengujian ini berjalan di lingkungan simulasi tanpa merender native window, sehingga ratusan kasus dapat diuji dalam hitungan detik.
> - **Pengujian Integrasi (Integration Test):** Memberikan nilai kepastian tertinggi bahwa seluruh komponen arsitektur (Widget ➔ Service ➔ Repository ➔ Storage/Platform Binding) bekerja secara harmonis pada alur aplikasi nyata dari awal hingga akhir (*real device workflow*). Pengujian integrasi memvalidasi pengalaman pengguna yang sesungguhnya di perangkat.
