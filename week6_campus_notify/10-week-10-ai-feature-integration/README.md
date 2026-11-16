# 10 — AI Feature Integration (Chat, Multimodal, & Fallback Strategy)

Repositori pengerjaan **Mini Project / Industry Challenge Minggu 10**: Integrasi Fitur AI pada aplikasi **Campus Notify** (`week6_campus_notify`).

---

## 🚀 1. Deskripsi Fitur AI yang Diintegrasikan

Aplikasi dilengkapi dengan **Asisten AI Multimodal Kampus** terpadu berbasis Google Gemini:
1. **Chat Interface dengan Streaming SSE:** Percakapan akademik interaktif dengan streaming teks real-time (`▍`) dan animasi tiga titik memantul saat berpikir.
2. **OCR (Optical Character Recognition):** Ekstraksi teks otomatis dari citra Kartu Tanda Mahasiswa (KTM), kuitansi/bukti bayar UKT, dokumen KRS, maupun foto papan pengumuman kampus via `image_picker`.
3. **Speech-to-Text (STT):** Input suara cepat menggunakan mikrofon perangkat via package `record` yang otomatis ditranskripsikan menjadi teks prompt AI.
4. **Image Understanding:** Analisis visual objek, fasilitas gedung kampus, maupun dokumen akademik.
5. **Kontrol Biaya & Keandalan:**
   - **Local Cache (`AiResponseCache`):** Pertanyaan berulang dijawab dari memori lokal (0 API call, 0 biaya).
   - **Rate Limiter (`AiUsageTracker`):** Kuota harian dibatasi 20 request/hari/user untuk mencegah pembengkakan tagihan.
   - **Offline Mode & Fallback (`LocalCampusKnowledgeBase`):** Basis data akademik lokal terverifikasi (KRS, beasiswa, skripsi, UKT) saat jaringan terputus atau API down.

---

## 🛡️ 2. Tabel Risiko dan Mitigasi

| Risiko | Mitigasi | Implementasi Nyata |
|---|---|---|
| **Bocor data pengguna** | Jangan kirim data sensitif ke AI API | `AiSecurityGuard.sanitize()` menyensor NIK 16 digit (`[NIK_ANONIM_XXXX]`), no. HP (`[NO_TELP_ANONIM]`), email, dan alamat fisik sebelum data dikirim ke cloud. |
| **Biaya melonjak** | Batasi request per user/hari, gunakan cache lokal | `AiUsageTracker` (kuota 20 req/hari di `FlutterSecureStorage`) + `AiResponseCache` (simpan query yang dinormalisasi). |
| **API error / down** | Tampilkan pesan ramah, opsi coba lagi, mode offline | `AlertDialog` "Layanan AI Sibuk" dengan tombol *Coba Lagi*, *Mode Offline*, serta tombol retry per bubble chat. |
| **Respons tidak relevan** | Terapkan validasi dan fallback ke data lokal | `LocalCampusKnowledgeBase` yang mencocokkan kata kunci FAQ kampus secara instan tanpa internet. |

---

## ⚙️ 3. Prompt Engineering & AI Log

Proses generasi dan penyempurnaan kode AI didokumentasikan di file [`docs/ai-log.md`](docs/ai-log.md):
- **System Prompt:** Panduan context engineering berbasis `RULES.md` (persona Senior Flutter Developer, Clean Architecture, larangan membocorkan data pribadi).
- **User Prompt:** Rangkaian instruksi terstruktur untuk Chat Interface, Multimodal (OCR, STT, Visual), dan strategi penanganan error/biaya.
- **Output Awal AI & Siklus Refinement:** Rekam jejak kode mentah, perbaikan type signature `AppleOptions` pada `flutter_secure_storage: ^11.2.0`, dan perbaikan `DateTime` non-const.

---

## 🧪 4. Bukti Mesin Hijau (Green Pipeline)

### Analisis Statik (`flutter analyze`)
```powershell
> flutter analyze
Analyzing week6_campus_notify...
No issues found! (ran in 16.8s)
```
*Status: **0 errors, 0 warnings, 0 lints**.*

### Rangkaian Tes Otomatis (`flutter test`)
```powershell
> flutter test
00:00 +0: D:/test/ai/ai_cost_test.dart: AiResponseCache Unit Tests
00:00 +3: D:/test/ai/ai_security_test.dart: Sanitasi NIK, telepon, email, alamat
00:00 +10: D:/test/ai/ai_service_test.dart: ask, streaming, OCR, STT, Image Understanding
00:00 +19: D:/test/ai/local_campus_kb_test.dart: Pencocokan kata kunci FAQ & offline fallback
00:09 +73: D:/test/features/chat_screen_test.dart: Mode offline tanpa API call
00:10 +74: D:/test/features/chat_screen_test.dart: Error handling memicu fallback dialog
00:10 +75: D:/test/features/chat_screen_test.dart: Pertanyaan di-cache bertanda isCached
00:13 +86: All tests passed!
```
*Status: **86/86 tests passed (100% Green)**.*

---

## 💡 5. Refleksi

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
> **Jawaban:**  
> Saya mengintegrasikan **Campus AI Assistant** dengan dukungan **Multimodal Terpadu (Chat Interaktif, OCR Dokumen, dan Speech-to-Text)**.  
> **Alasan:** Mahasiswa memiliki preferensi dan situasi penggunaan yang beragam saat mengakses informasi akademik. Ketika berada di tempat tenang, mahasiswa dapat mengetik pertanyaan atau membaca ringkasan. Namun, ketika memegang berkas fisik seperti KTM atau kuitansi pembayaran UKT, fitur **OCR** memungkinkan mahasiswa memindai langsung tanpa perlu mengetik ulang NIM atau nomor registrasi yang panjang. Di sisi lain, fitur **Speech-to-Text** memberikan kemudahan input cepat saat sedang berjalan atau terburu-buru, sekaligus menjadi solusi aksesibilitas yang sangat berharga bagi mahasiswa dengan kebutuhan khusus.

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
> **Jawaban:**  
> Perlindungan privasi dilakukan melalui pendekatan **Client-Side Data Sanitization & Anonymization** menggunakan modul `AiSecurityGuard`. Sebelum payload dikirimkan ke endpoint Google Gemini melalui internet:
> 1. Teks diperiksa menggunakan pola regular expression untuk mendeteksi NIK (16 digit angka berturut-turut), nomor telepon Indonesia (`08xx`, `+62xx`), email, dan detail alamat fisik (nama jalan, RT/RW, nomor rumah).
> 2. Data sensitif tersebut dianonimkan (misal: NIK `3578012345670001` diubah menjadi `[NIK_ANONIM_0001]` dengan hanya mempertahankan 4 digit terakhir untuk identifikasi lokal).
> 3. Teks yang diekstrak dari gambar OCR (seperti foto KTM) juga melewati modul sanitasi ini.
> 4. Aplikasi memunculkan banner peringatan privasi transparan di layar obrolan agar pengguna menyadari bahwa data pribadinya disaring demi keamanan. Dengan demikian, penyedia AI pihak ketiga tidak pernah menerima informasi identitas asli mahasiswa.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
> **Jawaban:**  
> Saya menerapkan strategi **Fallback Bertingkat Tiga Lapis**:
> 1. **Lapis 1 - Local Response Cache (`AiResponseCache`):** Jika mahasiswa menanyakan pertanyaan yang sama atau serupa (dengan normalisasi karakter dan spasi), jawaban diambil langsung dari cache memori tanpa perlu koneksi ke server AI (0 milidetik latency dan 0 panggilan API).
> 2. **Lapis 2 - Friendly AlertDialog:** Jika server AI mengalami gangguan (500/503), kuota harian habis, atau internet mati, aplikasi tidak crash dan tidak menampilkan stack trace teknis. Sebaliknya, aplikasi memunculkan dialog ramah: *"Layanan AI Sibuk. Coba lagi nanti atau gunakan mode offline."* dengan tombol aksi langsung: **Coba Lagi** dan **Gunakan Mode Offline**.
> 3. **Lapis 3 - Basis Pengetahuan Lokal Kampus (`LocalCampusKnowledgeBase`):** Sistem menyediakan basis data offline berisi informasi terverifikasi seputar jadwal KRS, syarat beasiswa, prosedur sidang skripsi, pembayaran UKT, dan layanan Tata Usaha. Pengguna tetap mendapatkan jawaban akurat secara instan meski perangkat berada dalam mode pesawat (*airplane mode*).

### 4. Satu hal yang Anda pelajari tentang UX fitur AI di mobile?
> **Jawaban:**  
> Pelajaran UX terpenting adalah: **"Ekspektasi waktu tunggu pada fitur AI di perangkat bergerak sangat berbeda dengan API REST biasa, sehingga feedback visual progresif dan transparansi state adalah kunci utama kenyamanan pengguna."**  
> Pada aplikasi mobile, jeda waktu 2–5 detik tanpa respon visual akan membuat pengguna mengira aplikasi *hang* atau *freeze*. Menggunakan *streaming response* karakter demi karakter (`▍`) bersama dengan animasi *loading dots* berdenyut membuat waktu tunggu terasa jauh lebih singkat dan interaktif. Selain itu, pengguna mobile sangat menghargai kejelasan status: mengetahui sisa kuota harian (`18/20 Kuota`), mengetahui bahwa privasi mereka terjaga lewat badge keamanan, serta memiliki tombol kendali yang jelas (seperti saklar *Mode Offline* dan tombol *Coba Lagi*) saat koneksi seluler tidak stabil.

---

## 📁 6. Struktur Direktori

```text
10-week-10-ai-feature-integration/
├── lib/
│   ├── ai/
│   │   ├── ai_cost_controller.dart    # Cache respons & Rate Limiter harian
│   │   ├── ai_security_guard.dart     # Sanitasi NIK, telepon, email, alamat
│   │   ├── ai_service.dart            # Service Gemini API, SSE stream & multimodal
│   │   └── local_campus_kb.dart       # Basis pengetahuan offline kampus (fallback)
│   ├── features/
│   │   └── chat_screen.dart           # Antarmuka Chat, OCR, Mic STT, & dialog fallback
│   └── services/
│       └── audio_recorder_service.dart# Layanan perekaman mikrofon via package record
├── docs/
│   └── ai-log.md                      # Log prompt sistem, user prompt, & output AI
├── screenshots/
│   └── README.md                      # Dokumentasi bukti tangkapan layar 6 skenario
└── README.md                          # Laporan mini project, bukti mesin hijau, & refleksi
```
