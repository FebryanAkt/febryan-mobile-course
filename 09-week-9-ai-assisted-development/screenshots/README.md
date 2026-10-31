# Screenshot Evidence — Week 9 AI-Assisted Development

Dokumentasi tangkapan layar untuk verifikasi 3 skenario pencarian pengumuman:

1. **`search-empty-query.png`**:
   - Tampilan default ketika query pencarian kosong (`""`).
   - Menampilkan seluruh 3 pengumuman kampus aktif.

2. **`search-matching-query.png`**:
   - Tampilan saat pengguna mengetik query cocok (`"beasiswa"`).
   - Menampilkan 1 hasil pengumuman yang sesuai (*"Pengumuman Beasiswa"*).

3. **`search-unmatched-empty-state.png`**:
   - Tampilan saat query pencarian tidak cocok dengan judul mana pun (`"xyz-tak-ada"`).
   - Menampilkan komponen `AnnouncementEmptyState` berupa icon `Icons.search_off` dan pesan `"Tidak ditemukan pengumuman untuk 'xyz-tak-ada'"`.

Catatan: Di lingkungan pengujian otomatis (CI/headless), ketiga skenario ini juga diverifikasi 100% menggunakan widget test di `test/search_filter_test.dart`.
