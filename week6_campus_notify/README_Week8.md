# Perbaiki satu commit buruk (simulasi)

## Tabel Sebelum/Sesudah Commit Message

| # | Commit Lama (Sebelum) | Commit Baru (Sesudah) | Alasan Perbaikan |
|---|----------------------|----------------------|------------------|
| 1 | `week6` | `chore(week6): inisialisasi struktur project week 6` | Pesan awal terlalu singkat, tidak menjelaskan *apa* yang dilakukan. Format konvensional `chore` menandakan ini bukan fitur/fix melainkan setup project, dan scope `week6` memperjelas konteks. |
| 2 | `laporan praktikum week 6` | `docs(week6): tambah laporan praktikum minggu 6` | Menggunakan tipe `docs` karena yang berubah adalah dokumentasi/laporan, bukan kode. Scope `week6` memperjelas minggu keberapa, dan kata kerja "tambah" menjelaskan aksi yang dilakukan. |
| 3 | `Tugas, refleksi, dan referensi` | `docs(week6): tambah tugas, refleksi, dan daftar referensi` | Pesan awal hanya daftar kata benda tanpa konteks. Dengan tipe `docs` dan scope `week6`, reviewer langsung tahu ini perubahan dokumentasi untuk minggu 6 serta aksi spesifik yang dilakukan. |
