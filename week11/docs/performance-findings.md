# Laporan Temuan Profiling Baseline (Performance Findings)
**Mata Kuliah:** Pemrograman Mobile  
**Modul:** Minggu 11 — Optimasi Performa (*Performance Optimization*)  
**Aplikasi Objek Profiling:** *Campus Notify* (`week6_campus_notify`)  
**Lingkungan Uji:** Mode Profile (`flutter run --profile`), Flutter SDK 3.47.6 (Dart 3.13.5), Flutter DevTools 2.60.0  

---

## 1. Ringkasan Eksekutif & Skenario Baseline

Sebelum menerapkan optimasi pada Minggu 11, dilakukan *baseline profiling* komprehensif pada aplikasi *Campus Notify*. Profiling dijalankan menggunakan **Flutter DevTools** pada mode `--profile` (bukan mode debug untuk menghindari overhead interpreter dan assertions).

### Skenario Pengujian Standar (Standard Load Scenario):
1. **Langkah 1:** Buka aplikasi hingga halaman Beranda (*Cold Startup*).
2. **Langkah 2:** Lakukan scrolling cepat (*fling scroll*) dari atas ke bawah daftar pengumuman berulang kali (10 siklus).
3. **Langkah 3:** Masukkan teks kata kunci pada Search Bar karakter demi karakter (*typing simulation*).
4. **Langkah 4:** Navigasi bolak-balik antara Beranda ➔ Detail Pengumuman sebanyak 5 kali.
5. **Langkah 5:** Melakukan pull-to-refresh secara simultan.

---

## 2. Metrik Kinerja Baseline (Sebelum Optimasi)

| Indikator Performa | Nilai Baseline (Before) | Ambang Batas Ideal | Status Kinerja |
|---|---|---|---|
| **Rata-rata UI Thread Time** | **23.4 ms** (Melebihi budget) | < 16.67 ms (60 FPS) | 🔴 **JANK TINGGI** |
| **Rata-rata Raster Thread Time** | **19.8 ms** (Spike hingga 38 ms) | < 16.67 ms (60 FPS) | 🔴 **BOTTLENECK GPU** |
| **Persentase Frame Drop (Jank)** | **34.2%** (Merah & Kuning) | < 2% | 🔴 **KRITIS** |
| **Alokasi Heap Memory (Dart + External)**| **142.5 MB** | < 70 MB | 🟠 **BOROS MEMORI** |
| **Frekuensi Garbage Collection (GC)** | **14 GC Events / 30 detik** | < 3 events / 30 detik | 🔴 **GC CHURN** |
| **Redundant HTTP Request Rate** | **100% request berulang tanpa cache** | 0% (Stale-While-Revalidate)| 🔴 **TIDAK EFISIEN** |

---

## 3. Identifikasi Masalah Utama (Bottlenecks)

Berdasarkan rekaman Flame Chart, Timeline Events, dan Heap Snapshot pada Flutter DevTools, diidentifikasi **5 masalah performa utama**:

### Masalah 1: Widget Rebuild Berlebih pada Seluruh Hirarki Daftar Pengumuman
- **Gejala pada DevTools:** Flame chart menunjukkan event `build` raksasa pada `AnnouncementList` dan setiap anak `AnnouncementCard` setiap kali satu huruf diketik pada kolom pencarian.
- **Penyebab Akar (Root Cause):**
  1. Pada `AnnouncementList`, listener `final currentQuery = ref.watch(searchQueryProvider)` diletakkan di tingkat atas widget. Setiap kali query berubah 1 huruf, seluruh widget tree di bawahnya di-rebuild secara paksa.
  2. Komponen `AnnouncementCard` tidak memanfaatkan konstruktor `const` untuk elemen statisnya (`CircleAvatar`, `Icon`, teks pembungkus).
  3. Menggunakan anonymous closure `() => context.go(...)` secara inline di dalam loop per item.
- **Dampak Kinerja:** Waktu eksekusi UI Thread melonjak hingga 26 ms pada setiap keystroke, menyebabkan freeze UI mikro (*stutter*).

### Masalah 2: Eager List Rendering Menggunakan `Column` (Bukan Lazy `ListView.builder`)
- **Gejala pada DevTools:** Event `layout` dan `paint` memakan waktu sangat lama (18 ms) saat inisialisasi awal dan saat scrolling.
- **Penyebab Akar (Root Cause):**
  - Pada `AnnouncementList`:
    ```dart
    // KODE SEBELUMNYA:
    return Column(
      children: items.map((item) => AnnouncementCard(item: item)).toList(),
    );
    ```
    Seluruh item pengumuman di-instansiasi dan di-layout sekaligus ke dalam memori, meskipun hanya 3-4 item yang tampak di layar (*viewport*).
- **Dampak Kinerja:** Beban layout O(N) linier terhadap total data. Tidak ada daur ulang elemen (*element recycling*), memboroskan alokasi memori heap Dart.

### Masalah 3: Raster Thread Bottleneck Akibat Decode Gambar Tanpa Pembatasan Resolusi
- **Gejala pada DevTools:** Raster Thread Flame Chart didominasi oleh event `image decode` dan `Rasterize` berwarna merah pekat berdurasi 32–45 ms.
- **Penyebab Akar (Root Cause):**
  - Gambar thumbnail diunduh dan didecode pada resolusi aslinya (misalnya 1920x1080 atau 1200x800) ke dalam buffer GPU native, padahal widget penampil hanya berukuran 56x56 pixel di layar ponsel.
  - Tidak digunakannya properti `cacheWidth` / `cacheHeight` pada image provider.
- **Dampak Kinerja:** Memori *external native texture* membengkak drastis (mencapai 68 MB hanya untuk buffer tekstur gambar), dan GPU mengalami stall saat mendekompresi bitmap.

### Masalah 4: Permintaan Jaringan Berulang (Zero Caching & Tanpa Mekanisme Retry)
- **Gejala pada DevTools:** Tab Network mencatat HTTP GET request identik berulang kali setiap kali halaman Beranda dibuka atau saat berpindah rute (12 request identik dalam 1 menit).
- **Penyebab Akar (Root Cause):**
  - `announcementRepositoryProvider` memanggil backend secara naif setiap kali provider di-watch ulang tanpa memeriksa apakah data sebelumnya masih valid (*fresh*).
  - Tidak ada layer *HTTP Interceptor* untuk menangani caching berbatas waktu (TTL), mode offline, maupun toleransi error transien (*exponential backoff*).
- **Dampak Kinerja:** Menghabiskan kuota data seluler, mempercepat habisnya daya baterai radio modem, dan menampilkan layar kosong (*loading spinner*) berulang kali bagi pengguna.

### Masalah 5: Akumulasi Memori (Memory Leak Potensial) pada Siklus Navigasi
- **Gejala pada DevTools:** Tab Memory Heap Snapshot menunjukkan jumlah instance `TextEditingController`, listener closure, dan `ScrollController` terus bertambah saat simulasi navigasi Beranda ➔ Detail ➔ Beranda diulang 5 kali berturut-turut.
- **Penyebab Akar (Root Cause):**
  - Listener stream dan controller tidak di-unlisten atau di-`dispose()` dengan disiplin pada beberapa lifecycle widget yang diubah secara tidak lengkap pada iterasi sebelumnya.
- **Dampak Kinerja:** Heap memory tidak pernah kembali ke baseline awal setelah navigasi, memicu peningkatan frekuensi Garbage Collection (*stop-the-world GC pauses*) yang menginterupsi animasi rendering 60 FPS.

---

## 4. Rencana Solusi Optimasi Terarah

| Target Area | Teknik Optimasi yang Direncanakan |
|---|---|
| **CPU / Rebuild** | Terapkan `const` constructor, pecah sub-widget modular, gunakan Riverpod `select`, dan tear-off method callback. |
| **GPU / Paint** | Isolasi card dengan `RepaintBoundary` untuk memangkas canvas repaint saat scrolling. |
| **List & Viewport** | Refactor ke `ListView.builder` lazy loading + implementasi infinite scrolling pagination per batch (4 item). |
| **Texture & Memori** | Terapkan `OptimizedNetworkImage` dengan constraint `cacheWidth: 112` dan `cacheHeight: 112` (2x DPI 56x56). |
| **Network & Cache** | Buat `PerformanceCacheInterceptor` (Stale-While-Revalidate) & `PerformanceRetryInterceptor` (Exponential Backoff). |
| **Memory Lifecycle** | Disiplin `dispose()` controller dan pembersihan listener saat widget unmount. |
