# Jawaban Refleksi Codelab Minggu 5

### 1. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?
- **Penyebab:** SharedPreferences dirancang untuk pasangan key-value primitif kecil (seperti boolean, integer, string pendek). Data disimpan dalam satu file XML/plist yang dibaca seluruhnya ke dalam memori saat aplikasi dijalankan.
- **Dampak jika dilanggar:**
  - Jika daftar catatan disimpan sebagai satu string JSON besar, setiap operasi penambahan, perubahan, atau penghapusan 1 item mengharuskan deserialisasi dan serialisasi ulang seluruh list.
  - Tidak ada dukungan pengindeksan (*indexing*), *sorting* database, atau pencarian parsial berbasis query SQL (`WHERE`, `LIMIT`, `OFFSET`).
  - Penandaan antrean sinkronisasi (*dirty flag*) menjadi rapuh karena tidak bisa dilakukan pembaruan granular per baris.
  - Memori aplikasi terbebani dan berisiko mengalami *race condition* atau *data corruption* saat data membesar (1000+ catatan).

---

### 2. Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain (misalnya network-first untuk data harga real-time)?
- **Cache-First Cukup Saat:**
  - Data bersifat referensial, artikel, postingan berita, atau catatan lokal pengguna di mana ketersediaan data secara instan (*instant load*) lebih diutamakan daripada kebaruan detik itu juga (*eventual consistency*).
  - Background refresh dapat dijalankan tanpa mengganggu interaksi pengguna yang sedang membaca cache lokal.
- **Network-First Diperlukan Saat:**
  - Data bersifat transaksional yang nilainya sangat sensitif terhadap waktu, seperti harga saham, nilai tukar mata uang real-time, ketersediaan kursi tiket, atau saldo dompet digital. Menampilkan data basi (*stale data*) pada skenario ini dapat menyebabkan kerugian finansial atau kesalahan fatal dalam pengambilan keputusan pengguna.

---

### 3. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah (tabel outbox) menjadi perlu?
- **Mekanisme Tanpa Memblokir UI:**
  - Setiap operasi tulis lokal (tambah/edit/hapus) langsung disimpan ke SQLite dengan flag `dirty = 1`. UI menerima respons seketika dan diperbarui dari database lokal.
  - Proses sinkronisasi (`syncNotes`) dieksekusi secara asinkron (`async`/`await`) di latar belakang (misalnya via provider atau background worker). UI tetap interaktif dan hanya memantau state proses sinkronisasi melalui provider.
- **Kapan Tabel Outbox Terpisah Diperlukan?**
  - Ketika urutan operasi mutasi (*order of execution*) harus dijaga secara ketat (misalnya Create -> Update judul -> Delete catatan yang sama).
  - Ketika sistem membutuhkan pencatatan detail payload mutasi yang gagal kirim, jumlah percobaan ulang (*retry count*), *backoff delay*, atau status mutasi non-idempoten.

---

### 4. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?
- **Poin yang Ditolak/Disesuaikan:**
  - Jika AI merekomendasikan penggunaan Drift untuk proyek skala kecil ini dengan alasan "reaktivitas bawaan", rekomendasi tersebut ditolak/tidak digunakan.
  - **Alasan:** Drift memerlukan konfigurasi *code generation* (`build_runner`, `drift_dev`) yang memperbesar ukuran boilerplate dan memperlambat alur kompilasi/testing. Kombinasi `sqflite` dengan invalidasi reaktif Riverpod (`ref.invalidate()`) terbukti jauh lebih ringan, modular, dan mencukupi kebutuhan offline-first tanpa overhead tooling berlebih.
