# AI Log — Minggu 10: Integrasi Fitur AI (Chat, Multimodal, & Robust Fallback)

---

## 1. System Prompt (Context Engineering)

Berdasarkan arsitektur pada [`RULES.md`](../RULES.md), berikut adalah **Prompt Sistem** yang digunakan untuk memandu AI coding assistant:

```text
[PERSONA]
Kamu adalah Senior Flutter Developer dan AI Integration Specialist yang ahli dalam
Clean Architecture, Riverpod state management, dan pemrosesan Generative AI.

[KONTEKS PROYEK]
- Proyek: Campus Notify (week6_campus_notify) — Aplikasi notifikasi kampus Flutter.
- Framework: Flutter SDK ^3.13.5 (Sound Null Safety).
- State Management: flutter_riverpod (Riverpod 3.x).
- HTTP Client: http ^1.2.0 & dio ^5.11.1.
- Penyimpanan Kunci: flutter_secure_storage.
- Routing: go_router ^18.0.2.
- UI: Material Design 3 (Seed Color: Colors.deepPurple).

[ATURAN WAJIB & CONSTRAINTS]
1. Domain TIDAK boleh import dari layer Data atau Presentation.
2. Gunakan ConsumerWidget / ConsumerStatefulWidget dengan Riverpod NotifierProvider.
3. DILARANG menggunakan setState() untuk state yang dibagikan antar komponen.
4. KEAMANAN DATA MUTLAK: Jangan pernah mengirim NIK (16 digit), nomor telepon, email,
   atau alamat fisik pengguna ke AI API publik. Wajib lakukan sanitasi client-side.
5. KONTROL BIAYA & KEANDALAN:
   - Terapkan rate limiter (maksimal 20 request/hari/user).
   - Terapkan cache respons lokal untuk pertanyaan repetitif.
   - Sediakan mekanisme fallback ke basis pengetahuan lokal kampus saat API error/down.
6. Kode wajib 100% bebas issue pada `flutter analyze` dan memiliki unit/widget test lengkap.
```

---

## 2. User Prompts

### Prompt 1: Chat Interface dengan AI
```text
Ikuti aturan di RULES.md.
Kerjakan Praktikum: Chat Interface dengan AI
Langkah 1: Tambahkan dependensi (http, flutter_secure_storage, riverpod).
Langkah 2: Buat AI Service lib/ai/ai_service.dart untuk memanggil Gemini API generateContent
dan menyimpan apiKey di FlutterSecureStorage.
Langkah 3: Buat Chat Screen lib/features/chat_screen.dart dengan streaming response dan indikator loading.
Catatan keamanan: Jangan pernah mengirim NIK, nomor telepon, alamat, atau data sensitif pengguna ke AI API.
```

### Prompt 2: Multimodal (OCR, Speech-to-Text, Image Understanding)
```text
Kerjakan ini: OCR, Speech-to-Text, dan Image Understanding.
- OCR: Ambil gambar dari kamera/galeri via image_picker, ekstrak teks dokumen/KTM/receipt.
- Speech-to-Text: Rekam suara pengguna menggunakan package record, konversi ke teks via AI API.
- Image Understanding: Unggah gambar dan minta deskripsi visual ke AI.
Wajib sediakan method:
  final result = await aiService.recognizeText(imageFile);
  final text = await aiService.speechToText(audioFile);
  final desc = await aiService.understandImage(imageFile, prompt: ...);
```

### Prompt 3: Privasi, Biaya, Error Handling, dan Fallback
```text
Kerjakan mitigasi risiko berikut:
- Bocor data pengguna: Jangan kirim data sensitif ke AI API.
- Biaya melonjak: Batasi request per user/hari (rate limiter), gunakan cache lokal.
- API error / down: Tampilkan pesan ramah, opsi coba lagi, mode offline.
- Respons tidak relevan: Terapkan validasi dan fallback ke data lokal kampus.
Sediakan dialog fallback:
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Layanan AI Sibuk'),
      content: const Text('Coba lagi nanti atau gunakan mode offline.'),
    ),
  );
```

---

## 3. Output Awal AI & Siklus Refinement

### Tahap 1: Ekstraksi Output Awal `AiService` & `AiSecurityGuard`
AI menghasilkan method `ask()` dasar dan modul `AiSecurityGuard` dengan regex:
- NIK: `\b\d{16}\b` ➔ `[NIK_ANONIM_XXXX]`
- Telepon: `(\+62|62|08)[0-9]{8,11}\b` ➔ `[NO_TELP_ANONIM]`
- Email: `\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b` ➔ `[EMAIL_ANONIM]`
- Alamat: Keyword jalan, perumahan, gang, RT/RW ➔ `[ALAMAT_ANONIM]`

### Tahap 2: Implementasi Streaming & Multimodal (SSE & InlineData)
- Menambahkan SSE parsing: streaming respons kata per kata melalui Server-Sent Events (`streamGenerateContent?alt=sse`).
- Mengimplementasikan `_callMultimodal` dengan payload `inline_data` base64 untuk citra JPEG/PNG dan audio AAC/M4A.

### Tahap 3: Debugging & Perbaikan Teknis Otomatis
Selama proses integrasi, ditemukan beberapa kendala statis yang langsung diperbaiki:
1. **DateTime Non-Const:**
   - *Masalah:* `const ChatState(messages: [ChatMessage(timestamp: DateTime.now())])` gagal karena `DateTime` bukan const constructor di Dart.
   - *Solusi:* Mengubah inisialisasi state awal menjadi non-const di method `build()` Riverpod Notifier.
2. **FlutterSecureStorage v11 Signature:**
   - *Masalah:* Mock storage awal menggunakan `IOSOptions`, sedangkan `flutter_secure_storage: ^11.2.0` menggunakan `AppleOptions`.
   - *Solusi:* Menyesuaikan parameter mock override menjadi `AppleOptions? iOptions, AppleOptions? mOptions`.
3. **Uint8List Import:**
   - *Masalah:* Pustaka `dart:typed_data` belum diimpor pada berkas pengujian.
   - *Solusi:* Ditambahkan `import 'dart:typed_data';`.

### Tahap 4: Implementasi Kontrol Biaya & Basis Pengetahuan Lokal
- `AiResponseCache`: Menyimpan riwayat query yang dinormalisasi untuk menghindari duplicate request (0 API calls).
- `AiUsageTracker`: Melacak kuota harian (20 request/hari) yang disimpan di `FlutterSecureStorage`.
- `LocalCampusKnowledgeBase`: Menyimpan pengetahuan offline akademik kampus (KRS, Beasiswa, Skripsi, UKT, dan TU) sebagai fallback andal saat layanan eksternal down.

---

## 4. Hasil Verifikasi Akhir
- **`flutter analyze`:** `No issues found! (ran in 16.8s)`.
- **`flutter test`:** Seluruh **86 unit dan widget test lulus (100% Green)**.
