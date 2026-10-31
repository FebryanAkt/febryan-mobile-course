# Review Checklist – Kesiapan Tengah Semester

## 1. Struktur Feature-First (Hasil Grep Sterilitas Minggu 7)

Tiga grep membuktikan tidak ada import lintas-fitur maupun import ke folder legacy:

| # | Perintah Grep | Hasil |
|---|--------------|-------|
| 1 | `Select-String -Path lib\features\auth\**\*.dart -Pattern "import.*features/announcements"` | **0 temuan** — auth tidak mengimpor announcements |
| 2 | `Select-String -Path lib\features\announcements\**\*.dart -Pattern "import.*features/auth"` | **0 temuan** — announcements tidak mengimpor auth |
| 3 | `Select-String -Path lib\features\**\*.dart -Pattern "import.*package:week6_campus_notify/(pages\|providers\|services\|data)/"` | **0 temuan** — fitur tidak mengimpor folder legacy |

Struktur folder saat ini:

```
lib/features/
├── announcements/
│   ├── data/        (models, repositories)
│   ├── domain/      (entities, repositories, usecases)
│   └── presentation/ (providers)
└── auth/
    ├── data/        (models, repositories)
    ├── domain/      (entities, repositories, usecases)
    └── presentation/ (providers)
```

## 2. Analyze Bersih

```
> flutter analyze
Analyzing week6_campus_notify...
No issues found! (ran in 68.1s)
```

## 3. Test Hijau

```
> flutter test
00:01 +25: All tests passed!
```

25 test — mencakup domain auth (login use case), domain announcements (get announcements, get by id), core (format/route), dan auth+push (token refresh, logout, payload parsing).

## 4. PR Kecil + Commit Jelas

Contoh commit terakhir yang sudah mengikuti format konvensional:

| Commit | Pesan |
|--------|-------|
| `6817c78` | `ci: tambahkan workflow otomatis untuk analyze dan test` |
| `e5bdf2f` | `feat(notes): validasi judul kosong + test` |

### Tabel Perbaikan Pesan Commit (Simulasi)

| # | Commit Lama (Sebelum) | Commit Baru (Sesudah) | Alasan Perbaikan |
|---|----------------------|----------------------|------------------|
| 1 | `week6` | `chore(week6): inisialisasi struktur project week 6` | Terlalu singkat, tidak menjelaskan aksi. Tipe `chore` + scope memperjelas konteks. |
| 2 | `laporan praktikum week 6` | `docs(week6): tambah laporan praktikum minggu 6` | Tipe `docs` karena yang berubah adalah dokumentasi, bukan kode. |
| 3 | `Tugas, refleksi, dan referensi` | `docs(week6): tambah tugas, refleksi, dan daftar referensi` | Hanya kata benda tanpa konteks. Perlu tipe, scope, dan kata kerja. |

## 5. README + Screenshot + Cara Menjalankan

- **README.md** tersedia (332 baris), berisi:
  - Setup proyek & konfigurasi Firebase
  - Cara menjalankan (`flutter create`, `flutter pub add`, `flutter run`)
  - Cara menjalankan test (`flutter test`)
- **Screenshot** tersedia di `docs/`: `1.jpeg`, `2.jpeg`, `3.jpeg`, `4.jpeg`

## 6. Komentar Review Sudah Ditindaklanjuti

Semua temuan dari review Minggu 7 sudah diterapkan:

- ✅ Struktur feature-first steril (grep terbukti 0 pelanggaran)
- ✅ Tidak ada warning dari `flutter analyze`
- ✅ Seluruh test hijau (25/25)
- ✅ Commit terbaru sudah menggunakan format konvensional

---

> **Kesimpulan:** Yang dinilai bukan banyaknya fitur, melainkan fondasi yang bisa dipercaya untuk paruh kedua. Arsitektur bersih, test hijau, analyze bersih, dan histori commit rapi menunjukkan fondasi yang siap untuk dikembangkan lebih lanjut.
