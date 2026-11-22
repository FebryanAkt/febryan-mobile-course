# Panduan Screenshot Bukti Praktikum Minggu 11

Folder ini diperuntukkan sebagai lokasi penyimpanan file screenshot bukti pengerjaan praktikum Minggu 11 (Optimasi Performa). Anda dapat mengambil screenshot secara langsung dari laptop/PC Anda dan menyimpannya di folder ini dengan penamaan file berikut:

---

## Daftar File Screenshot yang Diperlukan:

### 1. `before-profile.png`
- **Apa yang diambil:** Tampilan **Flutter DevTools Tab Performance** saat aplikasi dijalankan dengan `flutter run --profile` **SEBELUM** optimasi.
- **Yang perlu terlihat:** 
  - Frame bar chart dengan bar berwarna **merah/kuning (jank frames > 16.6ms)** saat melakukan scroll cepat.
  - Flame Chart yang menunjukkan event `build` atau `layout` yang memakan waktu lama.
- **Lokasi file:** `screenshots/before-profile.png`

### 2. `after-profile.png`
- **Apa yang diambil:** Tampilan **Flutter DevTools Tab Performance** saat aplikasi dijalankan dengan `flutter run --profile` **SESUDAH** optimasi diterapkan.
- **Yang perlu terlihat:**
  - Frame bar chart yang didominasi oleh bar **hijau konsisten (< 16.6ms / 60 FPS)** saat scroll cepat dan navigasi.
  - Flame chart rapi tanpa bottleneck jank.
- **Lokasi file:** `screenshots/after-profile.png`

### 3. `memory-leak-check.png`
- **Apa yang diambil:** Tampilan **Flutter DevTools Tab Memory** saat melakukan analisis **Heap Snapshot**.
- **Yang perlu terlihat:**
  - Snapshot setelah navigasi Beranda ➔ Detail ➔ Beranda sebanyak 5 kali.
  - Filter class `ScrollController` atau `TextEditingController` menunjukkan jumlah instance stabil (1 instance, tidak ada leak bertambah).
- **Lokasi file:** `screenshots/memory-leak-check.png`

### 4. `flutter-analyze-test.png`
- **Apa yang diambil:** Tampilan Terminal / Command Prompt saat mengeksekusi pengujian:
  ```powershell
  flutter analyze
  flutter test
  ```
- **Yang perlu terlihat:**
  - `No issues found!` pada static analyzer.
  - `All tests passed!` pada test suite pengujian performa.
- **Lokasi file:** `screenshots/flutter-analyze-test.png`

---

> **Catatan:** Format referensi markdown di `README.md` dan `docs/performance-report.md` telah disiapkan secara otomatis mengarah ke file-file gambar di atas. Cukup letakkan screenshot Anda dengan nama file yang sesuai di folder ini!
