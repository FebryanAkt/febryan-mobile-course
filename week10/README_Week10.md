# Laporan Praktikum Minggu 10: Chat Interface dengan AI, Multimodal Intelligence, & Robust Error Handling

---

## Ringkasan Praktikum

Pada praktikum Minggu 10, dibangun antarmuka percakapan cerdas (**AI Chat Interface**) yang diperluas dengan kemampuan **Multimodal AI** (Teks, Gambar, dan Audio) berbasis Google Gemini, serta dilengkapi mekanisme pertahanan menyeluruh terhadap **Privasi, Biaya, Error Handling, dan Fallback Data Lokal**.

Modul praktikum mencakup:
1. **Chat Interface dengan AI:**
   - Konfigurasi dependensi (`http`, `flutter_secure_storage`, `riverpod`/`flutter_riverpod`).
   - Pembangunan `AiService` untuk memanggil API Google Gemini (`generateContent` & streaming Server-Sent Events / SSE).
   - Pembuatan `ChatScreen` dengan respons *real-time streaming*, indikator animasi ketik (*loading dots*), dan dialog pengelolaan kunci API yang terenkripsi.
2. **Fitur Multimodal (OCR, Speech-to-Text, Image Understanding):**
   - **OCR (Optical Character Recognition):** Pengambilan gambar dari kamera atau galeri via `image_picker` untuk ekstraksi teks dokumen, Kartu Tanda Mahasiswa (KTM), kwitansi/receipt, dan papan pengumuman.
   - **Speech-to-Text (STT):** Perekaman suara pengguna via package `record` (`AudioRecorderService`) dan konversi otomatis menjadi teks via Generative AI untuk input cepat dan aksesibilitas.
   - **Image Understanding:** Analisis visual mendalam untuk mengenali fasilitas kampus, mendeskripsikan objek, dan membantu aksesibilitas visual.
3. **Privasi, Biaya, Error Handling, dan Fallback:**
   - **Privasi:** Perlindungan data sensitif pengguna (NIK 16 digit, nomor telepon, email, alamat fisik).
   - **Biaya:** Pengendalian pembengkakan biaya API melalui *Rate Limiting* (pembatas 20 request/hari/user) dan *Local Response Cache* (0 API call untuk pertanyaan berulang).
   - **Error Handling & Retry:** Pemetaan pesan kesalahan ramah pengguna, tombol *Coba Lagi*, serta *AlertDialog* fallback saat API sibuk.
   - **Fallback Data Lokal & Mode Offline:** Integrasi basis data pengetahuan kampus lokal (`LocalCampusKnowledgeBase`) yang siap melayani pertanyaan seputar KRS, beasiswa, skripsi, dan UKT secara 100% offline.

---

## Tabel Risiko dan Mitigasi

| Risiko | Mitigasi | Implementasi Kode |
|---|---|---|
| **Bocor data pengguna** | Jangan kirim data sensitif ke AI API | `AiSecurityGuard.sanitize()` (Deteksi & sensor NIK, no telp, email, alamat). |
| **Biaya melonjak** | Batasi request per user/hari, gunakan cache lokal | `AiUsageTracker` (kuota 20 req/hari) + `AiResponseCache` (simpan respons di memori). |
| **API error / down** | Tampilkan pesan ramah, opsi coba lagi, mode offline | `AlertDialog` "Layanan AI Sibuk", tombol *Coba Lagi* & saklar *Mode Offline*. |
| **Respons tidak relevan** | Terapkan validasi dan fallback ke data lokal | `LocalCampusKnowledgeBase` (pencocokan kata kunci FAQ kampus offline). |

---

## Langkah 1: Penambahan Dependensi (`pubspec.yaml`)

Dependensi dikonfigurasi pada file [`pubspec.yaml`](pubspec.yaml):

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  flutter_riverpod: ^3.4.3
  go_router: ^18.0.2
  dio: ^5.11.1
  flutter_secure_storage: ^11.2.0
  http: ^1.2.0
  firebase_core: ^4.15.0
  firebase_messaging: ^16.7.0
  flutter_local_notifications: ^22.3.1
  image_picker: ^1.2.4
  record: ^7.1.2
```

Eksekusi instalasi paket:
```powershell
flutter pub get
```
*Hasil: Got dependencies! (Exited code 0).*

---

## Langkah 2: Pembangunan AI Service Terpadu (`lib/ai/ai_service.dart`)

Layanan AI dibangun di [`lib/ai/ai_service.dart`](lib/ai/ai_service.dart) dengan antarmuka:
- `ask(question, {bypassCache})`: Pemanggilan teks standar dengan pemeriksaan cache dan kuota harian.
- `askStream(question, {bypassCache})`: Streaming potongan teks real-time melalui Server-Sent Events (SSE).
- `recognizeText(imageFile)`: Ekstraksi teks dari gambar dokumen/KTM (OCR).
- `speechToText(audioFile)`: Transkripsi audio rekaman suara pengguna menjadi teks (STT).
- `understandImage(imageFile, {prompt})`: Pemahaman konten visual gambar.
- `getOfflineAnswer(question)`: Mengambil jawaban terverifikasi dari basis data kampus lokal.
- `saveApiKey(key)`, `getApiKey()`, `deleteApiKey()`: Pengelolaan kunci API di secure storage.

### Cuplikan Logika `lib/ai/ai_service.dart`:

```dart
class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;
  final AiResponseCache _cache;
  final AiUsageTracker _usageTracker;

  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? apiUrl,
    AiResponseCache? cache,
    AiUsageTracker? usageTracker,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _apiUrl = apiUrl ??
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
        _cache = cache ?? AiResponseCache(),
        _usageTracker = usageTracker ??
            AiUsageTracker(storage: storage ?? const FlutterSecureStorage());

  Future<String> ask(String question, {bool bypassCache = false}) async {
    // 1. Mitigasi Biaya: Cek Cache Lokal
    if (!bypassCache) {
      final cachedResponse = _cache.get(question);
      if (cachedResponse != null) {
        return cachedResponse; // 0 API call, 0 biaya
      }
    }

    // 2. Mitigasi Biaya: Cek Batas Kuota Harian
    final canRequest = await _usageTracker.canMakeRequest();
    if (!canRequest) {
      throw QuotaExceededException(
        dailyLimit: _usageTracker.dailyLimit,
        resetDate: 'besok',
      );
    }

    // 3. Mitigasi Privasi: Sensor Data Sensitif
    final sanitizedQuestion = AiSecurityGuard.sanitize(question).sanitizedText;

    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': sanitizedQuestion}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final resultText = data['candidates'][0]['content']['parts'][0]['text'];

      // Rekam pemakaian kuota & simpan ke cache
      await _usageTracker.incrementUsage();
      _cache.put(question, resultText);

      return resultText;
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  // ... recognizeText, speechToText, understandImage, askStream
}
```

---

## Mitigasi Risiko 1: Perlindungan Privasi Data (`lib/ai/ai_security_guard.dart`)

> [!IMPORTANT]
> **Aturan Keamanan:** Jangan pernah mengirim NIK, nomor telepon, alamat, atau data sensitif pengguna ke AI API publik.

Modul [`AiSecurityGuard`](lib/ai/ai_security_guard.dart) bekerja sebelum payload meninggalkan perangkat:
- **NIK (16 Digit):** Dideteksi dengan pola `\b\d{16}\b` dan dianonimkan menjadi `[NIK_ANONIM_XXXX]`.
- **Nomor Telepon Indonesia:** Dideteksi dengan pola `(\+62|62|08)[0-9]{8,11}\b` dan dianonimkan menjadi `[NO_TELP_ANONIM]`.
- **Email:** Dianonimkan menjadi `[EMAIL_ANONIM]`.
- **Alamat Fisik:** Kata kunci jalan, nomor rumah, RT/RW dianonimkan menjadi `[ALAMAT_ANONIM]`.
- **Pemberitahuan Banner UI:** Banner oranye muncul di atas chat menginformasikan jenis data sensitif yang berhasil disanitasi.

---

## Mitigasi Risiko 2: Pengendalian Biaya API (`lib/ai/ai_cost_controller.dart`)

### 1. Pembatasan Kuota Request Harian (`AiUsageTracker`)
- Pengguna dibatasi maksimal **20 request AI per hari** (dapat dikonfigurasi).
- Riwayat pemakaian disimpan di `FlutterSecureStorage` dengan format tanggal `yyyy-MM-dd`.
- Kuota otomatis direset pada hari berikutnya.
- Jika kuota habis, sistem melempar `QuotaExceededException` dan mengarahkan pengguna ke **Mode Offline**.
- Indikator sisa kuota (misal: `18/20`) ditampilkan secara real-time pada AppBar.

### 2. Cache Respons Lokal (`AiResponseCache`)
- Pertanyaan yang sama (dengan normalisasi huruf kecil, spasi ganda, tanda baca akhir) disimpan dalam memori lokal.
- Ketika mahasiswa menanyakan hal yang sama (misal: *"Jadwal KRS kapan?"* lalu *"jadwal krs kapan"*), jawaban diambil seketika dari cache (0ms) tanpa memanggil Google Gemini API.
- Menghasilkan penghematan kuota dan pemangkasan biaya API hingga 100% untuk pertanyaan repetitif.

---

## Mitigasi Risiko 3 & 4: Error Handling, Retry, & Fallback Data Lokal

### 1. Contoh Fallback & AlertDialog Layanan AI Sibuk
Saat koneksi internet terputus, API key belum disetel, server Gemini 500/503, atau kuota habis, aplikasi menangkap error dan memunculkan dialog fallback sesuai spesifikasi praktikum:

```dart
try {
  final response = await aiService.ask(question);
} catch (e) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Layanan AI Sibuk'),
      content: const Text('Coba lagi nanti atau gunakan mode offline.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(chatProvider.notifier).answerWithOfflineFallback();
          },
          child: const Text('Gunakan Mode Offline'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(chatProvider.notifier).retryLastMessage();
          },
          child: const Text('Coba Lagi'),
        ),
      ],
    ),
  );
}
```

### 2. Basis Data Pengetahuan Lokal Kampus (`lib/ai/local_campus_kb.dart`)
Sistem menyediakan basis data akademik offline yang mencakup:
1. **Jadwal & Prosedur KRS:** Periode KRS, portal SIAKAD, persetujuan DPA, batas SKS.
2. **Beasiswa Kampus:** Syarat Beasiswa Prestasi (IPK 3.50), KIP Kuliah, loket pendaftaran Gedung Rektorat.
3. **Sidang Skripsi & TA:** Syarat 138 SKS, uji Turnitin max 20%, pendaftaran loket TU.
4. **Pembayaran UKT & Keuangan:** Nomor Virtual Account (VA), cicilan UKT, batas pembayaran.
5. **Fasilitas & Layanan:** Jam operasional Tata Usaha (TU), Perpustakaan Graha Literasi, Poliklinik Kampus, WiFi institusi.

### 3. Saklar Mode Offline Mandiri
- Pengguna dapat mengaktifkan **Mode Offline** kapan saja melalui icon wifi pada AppBar (`Icons.wifi_off`).
- Saat aktif, seluruh pertanyaan dijawab seketika dari basis data lokal (100% tanpa internet, 0 API call, dan 0 kuota).

---

## Layanan Rekaman Suara (`lib/services/audio_recorder_service.dart`)

Layanan perekaman mikrofon dibuat di [`lib/services/audio_recorder_service.dart`](lib/services/audio_recorder_service.dart):
- Menggunakan package `record` (`AudioRecorder`).
- Menyediakan fungsi `startRecording()`, `stopRecording()`, dan `cancelRecording()`.
- Menyimpan rekaman audio dalam format AAC-LC (`.m4a`) di direktori temporary untuk diproses oleh Gemini STT.

---

## Langkah 3: Antarmuka Chat & Multimodal (`lib/features/chat_screen.dart`)

Antarmuka percakapan [`lib/features/chat_screen.dart`](lib/features/chat_screen.dart) mengintegrasikan seluruh kapabilitas:
1. **Streaming Response:** Teks balasan AI muncul karakter demi karakter dengan kursor ketik `▍`.
2. **Indikator Loading:** Bubble animasi tiga titik berdenyut (`AI sedang memproses...`).
3. **Penyematan Berkas / OCR Dokumen:**
   - Tombol attach di input bar (`Icons.attach_file`).
   - Modal pilihan sumber: **Kamera** atau **Galeri**.
   - Menjalankan `final result = await aiService.recognizeText(imageFile);`.
4. **Input Suara Cepat (Speech-to-Text):**
   - Tombol mikrofon (`Icons.mic_none`).
   - Status bar merah: `🔴 Sedang merekam suara...`.
   - Menghentikan rekaman memicu `final text = await aiService.speechToText(audioFile);`.
5. **Image Understanding:**
   - Menjalankan `final desc = await aiService.understandImage(imageFile, prompt: ...);`.
6. **Badge & Status Pesan:**
   - Badge `📱 Basis Data Kampus Offline` untuk jawaban lokal.
   - Badge `⚡ Diambil dari Cache Lokal` untuk jawaban dari cache.
   - Tombol *Coba Lagi* dan *Jawab via Offline* pada bubble pesan yang mengalami kegagalan.

---

## Diagram Alur Lengkap Sistem (Arsitektur & Mitigasi)

```mermaid
flowchart TD
    User["Mahasiswa / Pengguna"]
    
    subgraph UI_Layer["ChatScreen & Input Area"]
        User -->|1. Ketik Pertanyaan| TextInput["Input Teks"]
        User -->|2. Rekam Suara (Mic)| Mic["AudioRecorder (record)"]
        User -->|3. Ambil Foto Dokumen| Cam["ImagePicker (Kamera/Galeri)"]
        User -->|4. Tombol Saklar| OfflineToggle["Mode Offline Switch"]
    end
    
    subgraph Notifier["ChatNotifier (Riverpod)"]
        TextInput --> Dispatcher{"Mode Offline Aktif?"}
        OfflineToggle -->|Ubah State| Dispatcher
        Dispatcher -->|YA| LocalKB["LocalCampusKnowledgeBase"]
        Dispatcher -->|TIDAK| CacheCheck{"Ada di Cache Lokal?"}
        
        CacheCheck -->|YA| CacheHit["Ambil dari AiResponseCache (0 API Call)"]
        CacheCheck -->|TIDAK| QuotaCheck{"Kuota Harian Tersedia?"}
        
        QuotaCheck -->|HABIS| QuotaExceeded["Throw QuotaExceededException"]
        QuotaCheck -->|ADA| SecurityGuard["AiSecurityGuard (Sensor NIK, Telp, Alamat)"]
    end
    
    subgraph Cloud_AI["Google Gemini Generative AI"]
        SecurityGuard -->|generateContent / streamGenerateContent| GeminiAPI["Gemini API (1.5 Flash / Pro)"]
        Mic -->|speechToText| GeminiAPI
        Cam -->|recognizeText / understandImage| GeminiAPI
    end
    
    GeminiAPI -->|Sukses: Stream Chunks / Text| ResponseHandler["Simpan ke Cache & Kurangi Kuota"]
    GeminiAPI -->|Gagal / Timeout / 500| ErrorHandler["Tangkap Error"]
    
    ErrorHandler --> FallbackDialog["Tampilkan AlertDialog: Layanan AI Sibuk"]
    FallbackDialog -->|Opsi 1: Coba Lagi| SecurityGuard
    FallbackDialog -->|Opsi 2: Mode Offline| LocalKB
    
    LocalKB --> ChatUI["Tampilkan di Chat Bubble (Badge Offline)"]
    CacheHit --> ChatUI
    ResponseHandler --> ChatUI
```

---

## Bukti Pengujian & Hasil Verifikasi (100% Green Pipeline)

### 1. Analisis Statis (`flutter analyze`)
```powershell
> flutter analyze
Analyzing week6_campus_notify...
No issues found! (ran in 18.8s)
```
*Hasil: **0 errors, 0 warnings, 0 lint issues**.*

### 2. Rangkaian Pengujian Otomatis (`flutter test`)
Pengujian mencakup:
- **`ai_security_test.dart`:** 7 tests (sanitasi NIK, telepon, email, alamat).
- **`ai_service_test.dart`:** 9 tests (API key, REST endpoint, streaming, OCR recognizeText, Speech-to-Text, Image Understanding).
- **`ai_cost_test.dart`:** 5 tests (cache hit, query normalization, rate limiting, quota decrement, quota reset).
- **`local_campus_kb_test.dart`:** 5 tests (pencarian kata kunci KRS, Beasiswa, Skripsi, UKT, dan fallback umum).
- **`chat_screen_test.dart`:** 12 tests (multimodal OCR/STT/Image, saklar mode offline tanpa API call, error handling & fallback dialog, cache hit UI, render antarmuka).
- Seluruh unit test lama (auth, FCM push, router, search filter) tetap lulus.

**Hasil Eksekusi:**
```powershell
> flutter test
00:00 +0: D:/test/ai/ai_cost_test.dart: AiResponseCache Unit Tests Menyimpan dan mengembalikan respons yang di-cache berdasarkan query yang dinormalisasi
00:00 +1: D:/test/ai/ai_cost_test.dart: AiUsageTracker Unit Tests (Rate Limiting) incrementUsage menambah jumlah pemakaian dan mengurangi sisa kuota
00:00 +2: D:/test/ai/ai_cost_test.dart: AiUsageTracker Unit Tests (Rate Limiting) resetUsage mengembalikan kuota ke nilai penuh
00:00 +3: D:/test/ai/ai_security_test.dart: Teks biasa tanpa data sensitif tidak diubah
00:00 +4: D:/test/ai/ai_security_test.dart: Menyaring dan menganonimkan NIK (16 digit angka)
00:00 +5: D:/test/ai/ai_security_test.dart: Menyaring dan menganonimkan nomor telepon Indonesia (+62/08)
00:00 +6: D:/test/ai/ai_security_test.dart: Menyaring dan menganonimkan alamat email pribadi
00:00 +7: D:/test/ai/ai_security_test.dart: Menyaring dan menganonimkan detail alamat fisik
00:00 +8: D:/test/ai/ai_security_test.dart: Menyaring kombinasi beberapa data sensitif sekaligus
00:00 +9: D:/test/ai/ai_security_test.dart: hasSensitiveData mendeteksi data sensitif secara akurat
00:00 +10: D:/test/ai/ai_service_test.dart: ask() melempar exception saat API key belum tersedia
00:00 +11: D:/test/ai/ai_service_test.dart: ask() berhasil memanggil Gemini API dan mengembalikan teks balasan
00:00 +12: D:/test/ai/ai_service_test.dart: ask() melempar exception saat API mengembalikan status error (bukan 200)
00:00 +13: D:/test/ai/ai_service_test.dart: ask() otomatis menyaring data NIK pengguna sebelum dikirim ke API
00:00 +14: D:/test/ai/ai_service_test.dart: saveApiKey, getApiKey, dan deleteApiKey mengelola storage dengan benar
00:00 +15: D:/test/ai/ai_service_test.dart: askStream() mengalirkan potongan teks balasan
00:00 +16: D:/test/ai/ai_service_test.dart: recognizeText() mengekstrak teks gambar melalui multimodal API (OCR)
00:00 +17: D:/test/ai/ai_service_test.dart: speechToText() mengonversi rekaman audio menjadi teks
00:00 +18: D:/test/ai/ai_service_test.dart: understandImage() menghasilkan deskripsi visual konten gambar
00:00 +19: D:/test/ai/local_campus_kb_test.dart: Mencocokkan kata kunci KRS dan mengembalikan jadwal KRS
00:00 +20: D:/test/ai/local_campus_kb_test.dart: Mencocokkan kata kunci Beasiswa dan mengembalikan info beasiswa
00:00 +21: D:/test/ai/local_campus_kb_test.dart: Mencocokkan kata kunci Skripsi dan mengembalikan syarat sidang
00:00 +22: D:/test/ai/local_campus_kb_test.dart: Mencocokkan kata kunci UKT dan pengajuan cicilan
00:00 +23: D:/test/ai/local_campus_kb_test.dart: Pertanyaan yang tidak cocok mengembalikan null dan fallback umum
... (seluruh pengujian autentikasi, token store, fcm push, dan filter pengumuman)
00:09 +73: D:/test/features/chat_screen_test.dart: Mode Offline Aktif langsung menjawab dari basis pengetahuan lokal tanpa memanggil API
00:10 +74: D:/test/features/chat_screen_test.dart: Error handling memicu fallback dialog dan answerWithOfflineFallback memberikan solusi lokal
00:10 +75: D:/test/features/chat_screen_test.dart: Pertanyaan yang di-cache mengembalikan respons lokal bertanda isCached
00:10 +77: D:/test/features/chat_screen_test.dart: Merender ChatScreen dengan komponen utama secara lengkap
00:13 +86: All tests passed!
```
*Total: **86 tests passed** (100% lulus tanpa kegagalan).*

---

## Panduan Penggunaan & Pengujian Mandiri

1. **Menguji Proteksi Privasi (Sanitasi NIK):**
   - Ketik: `"Tolong cek status beasiswa NIK 3578012345670001 dan telepon 08123456789"`
   - Perhatikan banner keamanan muncul di layar, dan data sensitif diubah menjadi `[NIK_ANONIM_0001]` dan `[NO_TELP_ANONIM]` sebelum dikirim ke API.
2. **Menguji Cache Lokal (Penghematan Biaya):**
   - Tanyakan: `"Jadwal KRS kapan?"`. Jawaban pertama berasal dari AI.
   - Tanyakan hal yang sama: `"jadwal krs kapan"`. Jawaban muncul seketika dengan badge `⚡ Diambil dari Cache Lokal (Hemat Kuota)`.
3. **Menguji Mode Offline (Mitigasi API Down):**
   - Tekan icon wifi di AppBar untuk beralih ke **Mode Offline**.
   - Tanyakan seputar beasiswa, KRS, atau skripsi. Jawaban langsung dijawab seketika dari basis pengetahuan lokal kampus tanpa memerlukan koneksi internet.
4. **Menguji Fallback saat Layanan Sibuk:**
   - Jika koneksi terputus atau API Key belum diisi, dialog **Layanan AI Sibuk** muncul dengan pilihan **Coba Lagi** atau **Gunakan Mode Offline**.

---

## Refleksi Praktikum

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

## Kesimpulan
Seluruh persyaratan praktikum meliputi **Chat Interface dengan AI**, **Multimodal (OCR, Speech-to-Text, Image Understanding)**, serta strategi mitigasi risiko **Privasi, Biaya, Error Handling, dan Fallback Data Lokal** telah selesai dibangun, teruji secara komprehensif (86/86 tes unit & widget lulus), dan terdokumentasi rapi.
