# Bukti Pengujian Mode Pesawat (Offline-First)

Folder ini digunakan untuk menyimpan screenshot hasil observasi pengujian mode pesawat (offline-first):

1. **`01_offline_add_notes.png`**
   - Kondisi: Mode pesawat aktif (Wi-Fi & Data mati).
   - Observasi: Aplikasi tetap dapat dibuka, menampilkan daftar catatan dari SQLite, dan dapat menambahkan catatan baru.
   - Indikator: Badge catatan kotor (dirty flag) menampilkan jumlah catatan yang belum tersinkronisasi (`dirty == true`), dan ikon cloud off muncul pada tiap item.

2. **`02_before_sync.png`**
   - Kondisi: Koneksi internet diaktifkan kembali.
   - Observasi: Catatan masih berstatus belum tersinkronisasi (badge dirty > 0) sampai tombol Sync ditekan.

3. **`03_after_sync.png`**
   - Kondisi: Tombol Sync (`syncNotes`) ditekan.
   - Observasi: Simulasi upload selesai, fungsi `markAllSynced()` dijalankan, badge berubah menjadi ikon `cloud_done` (dirty = 0), dan indikator badge pada catatan terhapus.
