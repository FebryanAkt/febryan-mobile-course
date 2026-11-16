# Screenshot Evidence — Week 10 AI Feature Integration

Dokumentasi skenario pengujian visual antarmuka AI dan kapabilitas Multimodal pada aplikasi **Campus Notify**:

1. **`01_chat_streaming_interface.png`**:
   - Tampilan percakapan interaktif dengan Google Gemini.
   - Respons teks *real-time* yang muncul karakter per karakter disertai kursor ketik `▍`.
   - Indikator sisa kuota harian pada AppBar (`18/20 Kuota`).

2. **`02_privacy_sanitization_banner.png`**:
   - Deteksi otomatis data sensitif ketika mahasiswa memasukkan NIK atau nomor telepon.
   - Tampilan banner oranye: `🛡️ Keamanan: Terdeteksi NIK, Nomor Telepon. Data telah disanitasi sebelum dikirim.`
   - Teks yang dikirimkan ke AI API terbukti disensor menjadi `[NIK_ANONIM_0001]` dan `[NO_TELP_ANONIM]`.

3. **`03_ocr_document_extraction.png`**:
   - Pengambilan citra dokumen atau Kartu Tanda Mahasiswa (KTM) dari Kamera/Galeri via `image_picker`.
   - Hasil ekstraksi teks OCR terstruktur rapi pada bubble pesan AI.

4. **`04_speech_to_text_recording.png`**:
   - Status bar merah `🔴 Sedang merekam suara...` saat pengguna berbicara melalui mikrofon.
   - Hasil transkripsi otomatis dikirimkan ke model AI untuk dijawab seketika.

5. **`05_offline_mode_and_fallback_dialog.png`**:
   - Dialog peringatan `Layanan AI Sibuk` saat API mengalami error/timeout atau kuota harian habis.
   - Tampilan respons alternatif yang diambil langsung dari **Basis Data Kampus Offline** (`LocalCampusKnowledgeBase`) dengan badge `📱 Basis Data Kampus Offline`.

6. **`06_local_cache_hit.png`**:
   - Jawaban atas pertanyaan yang sama muncul dalam 0 milidetik dengan badge `⚡ Diambil dari Cache Lokal (Hemat Kuota)`.

> [!NOTE]
> Seluruh skenario di atas diverifikasi 100% oleh rangkaian pengujian otomatis pada `test/features/chat_screen_test.dart` dan `test/ai/`.
