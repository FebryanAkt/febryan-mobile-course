import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'ai_cost_controller.dart';
import 'ai_security_guard.dart';
import 'local_campus_kb.dart';

/// Service untuk berkomunikasi dengan Google Gemini Generative Language API.
/// Mengelola penyimpanan kunci API secara aman menggunakan [FlutterSecureStorage],
/// menyediakan pemrosesan teks, streaming SSE, kapabilitas Multimodal
/// (OCR, Speech-to-Text, Image Understanding), serta dilengkapi
/// kontrol biaya (Cache lokal & Rate limiter) dan fallback offline.
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

  AiResponseCache get cache => _cache;
  AiUsageTracker get usageTracker => _usageTracker;

  /// Mengirim pertanyaan ke Gemini AI API dan mengembalikan teks jawaban.
  ///
  /// Dilengkapi:
  /// 1. Cache Lokal: Pertanyaan yang sama diambil dari cache (0 API call & 0 biaya).
  /// 2. Rate Limiting: Membatasi kuota request harian pengguna untuk mencegah pembengkakan biaya.
  /// 3. Catatan Keamanan: Sanitasi data sensitif pengguna (NIK, No. Telp, Alamat).
  Future<String> ask(String question, {bool bypassCache = false}) async {
    // 1. Mitigasi Biaya: Periksa cache lokal
    if (!bypassCache) {
      final cachedResponse = _cache.get(question);
      if (cachedResponse != null) {
        return cachedResponse;
      }
    }

    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    // 2. Mitigasi Biaya: Periksa kuota harian pengguna
    final canRequest = await _usageTracker.canMakeRequest();
    if (!canRequest) {
      throw QuotaExceededException(
        dailyLimit: _usageTracker.dailyLimit,
        resetDate: 'besok',
      );
    }

    // 3. Catatan Keamanan: Anonimkan data sensitif pengguna
    final sanitizedQuestion = AiSecurityGuard.sanitize(question).sanitizedText;

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
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Tidak ada kandidat jawaban dari AI.');
      }
      final resultText =
          candidates[0]['content']['parts'][0]['text'] as String;

      // Simpan ke cache lokal & catat penggunaan kuota
      await _usageTracker.incrementUsage();
      _cache.put(question, resultText);

      return resultText;
    } else {
      final errorBody = response.body;
      throw Exception(
        'Gagal memanggil AI API: ${response.statusCode} - $errorBody',
      );
    }
  }

  /// Streaming respons dari Gemini AI menggunakan Server-Sent Events (SSE).
  /// Menghasilkan [Stream<String>] yang mengalirkan potongan teks jawaban secara real-time.
  Stream<String> askStream(String question, {bool bypassCache = false}) async* {
    // 1. Mitigasi Biaya: Jika ada di cache, alirkan langsung dari cache
    if (!bypassCache) {
      final cached = _cache.get(question);
      if (cached != null) {
        yield cached;
        return;
      }
    }

    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    // 2. Mitigasi Biaya: Periksa kuota harian
    final canRequest = await _usageTracker.canMakeRequest();
    if (!canRequest) {
      throw QuotaExceededException(
        dailyLimit: _usageTracker.dailyLimit,
        resetDate: 'besok',
      );
    }

    // 3. Catatan Keamanan: Anonimkan data sensitif pengguna
    final sanitizedQuestion = AiSecurityGuard.sanitize(question).sanitizedText;

    final baseStream =
        _apiUrl.replaceAll(':generateContent', ':streamGenerateContent');
    final streamUrl = '$baseStream?alt=sse&key=$apiKey';

    final request = http.Request('POST', Uri.parse(streamUrl))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': sanitizedQuestion}
            ]
          }
        ]
      });

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      // Fallback ke method ask() jika streaming SSE endpoint gagal
      final fallbackResponse = await ask(question);
      final words = fallbackResponse.split(' ');
      for (var i = 0; i < words.length; i++) {
        yield (i == 0 ? '' : ' ') + words[i];
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return;
    }

    final streamBuffer = StringBuffer();

    // Parse stream chunks dari Server-Sent Events (SSE) atau raw chunked JSON
    await for (final line in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      String jsonStr = line.trim();
      if (jsonStr.startsWith('data: ')) {
        jsonStr = jsonStr.substring(6).trim();
      }
      if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
      try {
        final data = jsonDecode(jsonStr);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) {
              streamBuffer.write(text);
              yield text;
            }
          }
        }
      } catch (_) {}
    }

    // Rekam kuota & simpan jawaban lengkap ke cache
    if (streamBuffer.isNotEmpty) {
      await _usageTracker.incrementUsage();
      _cache.put(question, streamBuffer.toString());
    }
  }

  /// Mendapatkan jawaban dari Basis Pengetahuan Kampus Lokal (Mode Offline / Fallback)
  String getOfflineAnswer(String question) {
    final result = LocalCampusKnowledgeBase.findAnswer(question);
    return result?.answer ?? LocalCampusKnowledgeBase.getGeneralOfflineFallback();
  }

  // ==========================================================================
  // Multimodal: OCR, Speech-to-Text, Image Understanding
  // ==========================================================================

  /// Melakukan OCR (Optical Character Recognition) untuk mengekstraksi teks
  /// dari berkas gambar dokumen, Kartu Tanda Mahasiswa (KTM), kwitansi/receipt,
  /// maupun papan pengumuman kampus.
  Future<String> recognizeText(dynamic imageFile) async {
    final bytes = await _resolveBytes(imageFile);
    final mimeType = _detectMimeType(imageFile, defaultType: 'image/jpeg');

    const ocrPrompt =
        'Lakukan OCR (Optical Character Recognition) pada gambar ini secara akurat. '
        'Ekstrak seluruh teks yang tertulis pada dokumen/KTM/receipt/papan pengumuman ini. '
        'Pertahankan susunan baris teks dan kembalikan hanya hasil teks tanpa komentar tambahan.';

    return await _callMultimodal(
      prompt: ocrPrompt,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// Mengonversi rekaman audio suara pengguna menjadi teks (Speech-to-Text)
  /// menggunakan Generative AI multimodal audio processing.
  Future<String> speechToText(dynamic audioFile) async {
    final bytes = await _resolveBytes(audioFile);
    final mimeType = _detectMimeType(audioFile, defaultType: 'audio/m4a');

    const sttPrompt =
        'Transkripsikan rekaman audio suara ini ke dalam teks secara akurat kata demi kata. '
        'Kembalikan hanya teks hasil transkripsi dalam bahasa yang diucapkan pengguna.';

    return await _callMultimodal(
      prompt: sttPrompt,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// Menganalisis dan memahami isi gambar secara visual (Image Understanding)
  /// untuk mengidentifikasi objek kampus, fasilitas, dan deskripsi visual.
  Future<String> understandImage(
    dynamic imageFile, {
    String prompt =
        'Deskripsikan isi gambar ini secara detail dan sebutkan informasi penting atau objek yang teridentifikasi.',
  }) async {
    final bytes = await _resolveBytes(imageFile);
    final mimeType = _detectMimeType(imageFile, defaultType: 'image/jpeg');

    return await _callMultimodal(
      prompt: prompt,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// Helper untuk memanggil Gemini Multimodal API dengan payload inline_data
  Future<String> _callMultimodal({
    required String prompt,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final canRequest = await _usageTracker.canMakeRequest();
    if (!canRequest) {
      throw QuotaExceededException(
        dailyLimit: _usageTracker.dailyLimit,
        resetDate: 'besok',
      );
    }

    final multimodalUrl = _apiUrl.contains('gemini-pro')
        ? _apiUrl.replaceAll('gemini-pro', 'gemini-1.5-flash')
        : _apiUrl;

    final base64Data = base64Encode(bytes);

    final response = await _client.post(
      Uri.parse('$multimodalUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Data,
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Tidak ada kandidat jawaban dari AI.');
      }
      await _usageTracker.incrementUsage();
      return candidates[0]['content']['parts'][0]['text'] as String;
    } else {
      final errorBody = response.body;
      throw Exception(
        'Gagal memanggil AI Multimodal API: ${response.statusCode} - $errorBody',
      );
    }
  }

  Future<Uint8List> _resolveBytes(dynamic file) async {
    if (file is Uint8List) return file;
    if (file is XFile) return await file.readAsBytes();
    if (file is io.File) return await file.readAsBytes();
    if (file is String) return await io.File(file).readAsBytes();
    throw ArgumentError(
      'Tipe berkas tidak didukung: ${file.runtimeType}. Gunakan File, XFile, Uint8List, atau String path.',
    );
  }

  String _detectMimeType(dynamic file, {required String defaultType}) {
    String? path;
    if (file is XFile) {
      path = file.path;
      if (file.mimeType != null && file.mimeType!.isNotEmpty) {
        return file.mimeType!;
      }
    } else if (file is io.File) {
      path = file.path;
    } else if (file is String) {
      path = file;
    }

    if (path != null) {
      final ext = path.toLowerCase().split('.').last;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'webp':
          return 'image/webp';
        case 'gif':
          return 'image/gif';
        case 'mp3':
          return 'audio/mp3';
        case 'm4a':
          return 'audio/m4a';
        case 'wav':
          return 'audio/wav';
        case 'aac':
          return 'audio/aac';
        case 'ogg':
          return 'audio/ogg';
      }
    }
    return defaultType;
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key.trim());
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: 'ai_api_key');
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: 'ai_api_key');
  }
}
