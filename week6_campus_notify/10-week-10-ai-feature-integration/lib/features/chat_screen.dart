import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../ai/ai_cost_controller.dart';
import '../ai/ai_security_guard.dart';
import '../ai/ai_service.dart';
import '../routes.dart';
import '../services/audio_recorder_service.dart';

// ============================================================================
// Model & State
// ============================================================================

enum MessageRole { user, ai, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;
  final List<String> sanitizedTypes;
  final bool isError;
  final bool isOffline;
  final bool isCached;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
    this.sanitizedTypes = const [],
    this.isError = false,
    this.isOffline = false,
    this.isCached = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageRole? role,
    DateTime? timestamp,
    bool? isStreaming,
    List<String>? sanitizedTypes,
    bool? isError,
    bool? isOffline,
    bool? isCached,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      sanitizedTypes: sanitizedTypes ?? this.sanitizedTypes,
      isError: isError ?? this.isError,
      isOffline: isOffline ?? this.isOffline,
      isCached: isCached ?? this.isCached,
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final bool isOfflineMode;
  final int remainingQuota;
  final String? errorMessage;
  final String? lastSanitizationNotice;
  final String? lastFailedPrompt;
  final bool triggerFallbackDialog;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.isOfflineMode = false,
    this.remainingQuota = 20,
    this.errorMessage,
    this.lastSanitizationNotice,
    this.lastFailedPrompt,
    this.triggerFallbackDialog = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    bool? isOfflineMode,
    int? remainingQuota,
    String? errorMessage,
    String? lastSanitizationNotice,
    String? lastFailedPrompt,
    bool? triggerFallbackDialog,
    bool clearNotice = false,
    bool clearError = false,
    bool clearFailedPrompt = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      remainingQuota: remainingQuota ?? this.remainingQuota,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSanitizationNotice: clearNotice
          ? null
          : (lastSanitizationNotice ?? this.lastSanitizationNotice),
      lastFailedPrompt: clearFailedPrompt
          ? null
          : (lastFailedPrompt ?? this.lastFailedPrompt),
      triggerFallbackDialog:
          triggerFallbackDialog ?? this.triggerFallbackDialog,
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class ChatNotifier extends Notifier<ChatState> {
  late final AiService _aiService;

  @override
  ChatState build() {
    _aiService = ref.watch(aiServiceProvider);

    // Muat sisa kuota awal
    Future.microtask(() => refreshQuota());

    return ChatState(
      messages: [
        ChatMessage(
          id: 'welcome-msg',
          text:
              'Halo! Saya Asisten AI Kampus. Anda dapat menanyakan info akademik, KRS, beasiswa, dan panduan kampus.\n\n'
              '✨ Fitur Cerdas & Keamanan:\n'
              '• 🔒 Privasi: NIK, nomor telepon & alamat otomatis disanitasi.\n'
              '• ⚡ Kontrol Biaya: Dilengkapi cache lokal & pembatas kuota harian.\n'
              '• 📱 Mode Offline & Fallback: Tetap berfungsi saat jaringan down.\n'
              '• 📷 OCR & 🎙️ Speech-to-Text: Pindai dokumen dan input suara.',
          role: MessageRole.ai,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> refreshQuota() async {
    try {
      final quota = await _aiService.usageTracker.getRemainingQuota();
      state = state.copyWith(remainingQuota: quota);
    } catch (_) {}
  }

  void toggleOfflineMode() {
    final nextMode = !state.isOfflineMode;
    state = state.copyWith(isOfflineMode: nextMode);
  }

  void dismissFallbackDialog() {
    state = state.copyWith(triggerFallbackDialog: false);
  }

  /// Mengirim pesan teks dengan mitigasi risiko privasi, biaya, dan error handling
  Future<void> sendMessage(String text, {bool forceOnline = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Audit Privasi: Deteksi dan sanitasi data sensitif sebelum dikirim ke AI API
    final sanitization = AiSecurityGuard.sanitize(trimmed);
    String? sanitizationNotice;
    if (sanitization.containsSensitiveData) {
      sanitizationNotice =
          '🛡️ Keamanan: Terdeteksi ${sanitization.detectedTypes.join(", ")}. Data telah disanitasi sebelum dikirim.';
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      sanitizedTypes: sanitization.detectedTypes,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      isStreaming: false,
      clearError: true,
      clearFailedPrompt: true,
      triggerFallbackDialog: false,
      lastSanitizationNotice: sanitizationNotice,
    );

    // 2. Mode Offline Aktif: Langsung gunakan basis pengetahuan lokal (0 API call & 0 biaya)
    if (state.isOfflineMode && !forceOnline) {
      final offlineAnswer = _aiService.getOfflineAnswer(trimmed);
      final aiMessage = ChatMessage(
        id: 'offline-${DateTime.now().millisecondsSinceEpoch}',
        text: offlineAnswer,
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        isOffline: true,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
      return;
    }

    // 3. Mitigasi Biaya: Periksa cache lokal
    final cached = _aiService.cache.get(trimmed);
    if (cached != null) {
      final cachedMessage = ChatMessage(
        id: 'cached-${DateTime.now().millisecondsSinceEpoch}',
        text: cached,
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        isCached: true,
      );

      state = state.copyWith(
        messages: [...state.messages, cachedMessage],
        isLoading: false,
      );
      return;
    }

    final aiMessageId = 'ai-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 4. Inisiasi streaming respons dari AI
      final stream = _aiService.askStream(trimmed);
      bool isFirstChunk = true;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);

        if (isFirstChunk) {
          isFirstChunk = false;
          final streamingAiMessage = ChatMessage(
            id: aiMessageId,
            text: buffer.toString(),
            role: MessageRole.ai,
            timestamp: DateTime.now(),
            isStreaming: true,
          );
          state = state.copyWith(
            messages: [...state.messages, streamingAiMessage],
            isLoading: false,
            isStreaming: true,
          );
        } else {
          final updatedMessages = state.messages.map((m) {
            if (m.id == aiMessageId) {
              return m.copyWith(text: buffer.toString(), isStreaming: true);
            }
            return m;
          }).toList();

          state = state.copyWith(messages: updatedMessages);
        }
      }

      final finalizedMessages = state.messages.map((m) {
        if (m.id == aiMessageId) {
          return m.copyWith(isStreaming: false);
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: finalizedMessages,
        isLoading: false,
        isStreaming: false,
      );

      await refreshQuota();
    } catch (e) {
      // 5. Error Handling Ramah & Pemicu Fallback
      String friendlyMessage;
      if (e is QuotaExceededException) {
        friendlyMessage = e.toString();
      } else {
        final raw = e.toString().replaceFirst('Exception: ', '');
        friendlyMessage =
            'Layanan AI sedang sibuk atau mengalami gangguan sementara ($raw). Coba lagi nanti atau gunakan mode offline.';
      }

      final errorChatMessage = ChatMessage(
        id: aiMessageId,
        text: '⚠️ $friendlyMessage',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        isError: true,
      );

      state = state.copyWith(
        messages: [...state.messages, errorChatMessage],
        isLoading: false,
        isStreaming: false,
        errorMessage: friendlyMessage,
        lastFailedPrompt: trimmed,
        triggerFallbackDialog: true,
      );
    }
  }

  /// Menjawab pertanyaan yang gagal menggunakan Basis Data Pengetahuan Lokal (Offline Fallback)
  void answerWithOfflineFallback([String? customPrompt]) {
    final promptToUse = customPrompt ?? state.lastFailedPrompt;
    if (promptToUse == null || promptToUse.trim().isEmpty) return;

    final offlineText = _aiService.getOfflineAnswer(promptToUse);

    // Hapus pesan error terakhir jika ada dan gantikan dengan jawaban offline
    final updatedMessages = state.messages
        .where((m) => !m.isError || m.text.contains('Layanan AI'))
        .toList();

    final fallbackMessage = ChatMessage(
      id: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
      text: offlineText,
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      isOffline: true,
    );

    state = state.copyWith(
      messages: [...updatedMessages, fallbackMessage],
      clearError: true,
      clearFailedPrompt: true,
      triggerFallbackDialog: false,
    );
  }

  /// Mencoba ulang (Retry) pengiriman pesan yang gagal
  Future<void> retryLastMessage() async {
    final prompt = state.lastFailedPrompt;
    if (prompt != null && prompt.isNotEmpty) {
      // Hapus pesan error sebelumnya
      final filtered = state.messages.where((m) => !m.isError).toList();
      state = state.copyWith(
        messages: filtered,
        clearError: true,
        triggerFallbackDialog: false,
      );
      await sendMessage(prompt, forceOnline: true);
    }
  }

  /// Ekstraksi teks dari gambar (OCR)
  Future<void> performOcr(dynamic imageFile) async {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📷 [OCR] Pindai Teks Dokumen/KTM',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    final aiMessageId = 'ocr-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final extracted = await _aiService.recognizeText(imageFile);
      final sanitization = AiSecurityGuard.sanitize(extracted);

      final aiMessage = ChatMessage(
        id: aiMessageId,
        text: '📄 **Hasil Ekstraksi OCR:**\n\n${sanitization.sanitizedText}',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        sanitizedTypes: sanitization.detectedTypes,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        lastSanitizationNotice: sanitization.containsSensitiveData
            ? '🛡️ Data ${sanitization.detectedTypes.join(", ")} pada dokumen telah disanitasi.'
            : null,
      );
      await refreshQuota();
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: aiMessageId,
            text: '⚠️ Gagal melakukan OCR: $errorMessage',
            role: MessageRole.ai,
            timestamp: DateTime.now(),
            isError: true,
          ),
        ],
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Memahami dan mendeskripsikan konten visual gambar (Image Understanding)
  Future<void> performImageUnderstanding(
    dynamic imageFile, {
    String? prompt,
  }) async {
    final displayPrompt =
        prompt ?? 'Deskripsikan isi gambar ini secara rinci dan informatif.';

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '🔍 [Image Understanding] $displayPrompt',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    final aiMessageId = 'img-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final analysis = await _aiService.understandImage(
        imageFile,
        prompt: displayPrompt,
      );

      final aiMessage = ChatMessage(
        id: aiMessageId,
        text: '🖼️ **Hasil Analisis Gambar:**\n\n$analysis',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
      await refreshQuota();
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: aiMessageId,
            text: '⚠️ Gagal menganalisis gambar: $errorMessage',
            role: MessageRole.ai,
            timestamp: DateTime.now(),
            isError: true,
          ),
        ],
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Mengonversi rekaman suara menjadi teks (Speech-to-Text) lalu mengirimkannya
  Future<void> performSpeechToText(dynamic audioFile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final transcribedText = await _aiService.speechToText(audioFile);
      state = state.copyWith(isLoading: false);
      if (transcribedText.trim().isNotEmpty) {
        await sendMessage(transcribedText);
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mentranskripsi rekaman audio: $errorMessage',
      );
    }
  }

  void clearChat() {
    state = ChatState(
      messages: [
        ChatMessage(
          id: 'welcome-msg-cleared',
          text:
              'Percakapan telah dibersihkan. Silakan tanyakan hal lain seputar perkuliahan.',
          role: MessageRole.ai,
          timestamp: DateTime.now(),
        ),
      ],
      isOfflineMode: state.isOfflineMode,
      remainingQuota: state.remainingQuota,
    );
  }

  void clearSanitizationNotice() {
    state = state.copyWith(clearNotice: true);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

// ============================================================================
// UI: ChatScreen
// ============================================================================

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isComposing = false;
  bool _isRecording = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _recorderService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() => _isComposing = false);

    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  /// Menampilkan AlertDialog saat Layanan AI Sibuk / Error (Sesuai Contoh Fallback)
  void _showFallbackDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Layanan AI Sibuk'),
          ],
        ),
        content: const Text('Coba lagi nanti atau gunakan mode offline.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(chatProvider.notifier).answerWithOfflineFallback();
            },
            child: const Text('Gunakan Mode Offline'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(chatProvider.notifier).retryLastMessage();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      final audioPath = await _recorderService.stopRecording();
      setState(() => _isRecording = false);

      if (audioPath != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎙️ Memproses suara dengan Speech-to-Text...'),
            duration: Duration(seconds: 2),
          ),
        );
        await ref.read(chatProvider.notifier).performSpeechToText(audioPath);
        _scrollToBottom();
      }
    } else {
      final started = await _recorderService.startRecording();
      if (started) {
        setState(() => _isRecording = true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon tidak diberikan atau tidak didukung.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    await _recorderService.cancelRecording();
    setState(() => _isRecording = false);
  }

  Future<void> _pickImage(ImageSource source, {required bool isOcr}) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        if (!mounted) return;
        if (isOcr) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📷 Menjalankan OCR ekstraksi teks...')),
          );
          await ref.read(chatProvider.notifier).performOcr(picked);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔍 Menganalisis konten gambar visual...')),
          );
          await ref.read(chatProvider.notifier).performImageUnderstanding(picked);
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog({required bool isOcr}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOcr ? 'Pindai Teks (OCR Dokumen / KTM)' : 'Analisis Gambar (Image Understanding)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.of(bottomSheetCtx).pop();
                    _pickImage(ImageSource.camera, isOcr: isOcr);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.of(bottomSheetCtx).pop();
                    _pickImage(ImageSource.gallery, isOcr: isOcr);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMultimodalActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fitur AI Multimodal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.document_scanner, color: Colors.white, size: 20),
                  ),
                  title: const Text('OCR: Pindai Dokumen / KTM'),
                  subtitle: const Text('Ekstraksi teks dari KTM, bukti pembayaran, dokumen'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showImageSourceDialog(isOcr: true);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.image_search, color: Colors.white, size: 20),
                  ),
                  title: const Text('Image Understanding: Analisis Gambar'),
                  subtitle: const Text('Identifikasi objek, fasilitas kampus, atau deskripsi visual'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showImageSourceDialog(isOcr: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showApiKeyDialog() async {
    final aiService = ref.read(aiServiceProvider);
    final currentKey = await aiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        bool obscure = true;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final masked = currentKey.length > 8
                ? '${currentKey.substring(0, 4)}...${currentKey.substring(currentKey.length - 4)}'
                : (currentKey.isEmpty ? '(Belum diatur)' : 'Sudah tersimpan');

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.key, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Google Gemini API Key'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kunci API disimpan secara aman di perangkat menggunakan FlutterSecureStorage.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Status saat ini: $masked',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Masukkan Gemini API Key',
                        hintText: 'AIzaSy...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() => obscure = !obscure);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dapatkan API Key gratis di Google AI Studio (aistudio.google.com).',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
              actions: [
                if (currentKey.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await aiService.deleteApiKey();
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API Key telah dihapus.')),
                      );
                    },
                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final key = controller.text.trim();
                    if (key.isNotEmpty) {
                      await aiService.saveApiKey(key);
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API Key berhasil disimpan dengan aman.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Buka fallback AlertDialog jika error terjadi dan diminta oleh state
    ref.listen(chatProvider, (previous, next) {
      if (next.triggerFallbackDialog &&
          previous?.triggerFallbackDialog != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showFallbackDialog(context);
            ref.read(chatProvider.notifier).dismissFallbackDialog();
          }
        });
      }
      if (previous?.messages.length != next.messages.length ||
          next.isStreaming) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.smart_toy_outlined, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(chatState.isOfflineMode ? 'AI (Offline)' : 'Campus AI Chat'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          // Indikator Kuota Harian (Mitigasi Biaya Melonjak)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chatState.remainingQuota <= 3
                    ? Colors.red.shade100
                    : Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    size: 14,
                    color: chatState.remainingQuota <= 3
                        ? Colors.red
                        : Colors.deepPurple,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${chatState.remainingQuota}/20',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: chatState.remainingQuota <= 3
                          ? Colors.red
                          : Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol Saklar Mode Offline (Mitigasi API Down)
          IconButton(
            icon: Icon(
              chatState.isOfflineMode ? Icons.wifi_off : Icons.wifi,
              color: chatState.isOfflineMode ? Colors.orange : Colors.green,
            ),
            tooltip: chatState.isOfflineMode
                ? 'Mode Offline Aktif (Basis Data Lokal)'
                : 'Mode Online Aktif (Tekan untuk Mode Offline)',
            onPressed: () {
              ref.read(chatProvider.notifier).toggleOfflineMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    chatState.isOfflineMode
                        ? 'Beralih ke Mode Online (Google Gemini API)'
                        : 'Beralih ke Mode Offline (Basis Data Kampus Lokal)',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Fitur AI Multimodal (OCR / Gambar)',
            onPressed: _showMultimodalActions,
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Pengaturan API Key',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Bersihkan Percakapan',
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Mode Offline / Keamanan
            if (chatState.isOfflineMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: Colors.orange.shade100,
                child: const Row(
                  children: [
                    Icon(Icons.offline_bolt, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode Offline Aktif: Menjawab langsung dari Basis Pengetahuan Lokal Kampus (Hemat kuota, tanpa API).',
                        style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              _SecurityHeaderBanner(
                lastNotice: chatState.lastSanitizationNotice,
                onDismissNotice: () =>
                    ref.read(chatProvider.notifier).clearSanitizationNotice(),
              ),

            // Daftar Pesan
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: chatState.messages.length +
                    (chatState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < chatState.messages.length) {
                    final message = chatState.messages[index];
                    return _MessageBubble(
                      message: message,
                      onRetry: () =>
                          ref.read(chatProvider.notifier).retryLastMessage(),
                      onFallbackOffline: () => ref
                          .read(chatProvider.notifier)
                          .answerWithOfflineFallback(),
                    );
                  }
                  return const _LoadingIndicatorBubble();
                },
              ),
            ),

            // Quick Prompt Suggestions (Chip pilihan cepat)
            if (chatState.messages.length <= 2 && !chatState.isLoading)
              _QuickSuggestions(
                onSelectPrompt: (prompt) {
                  if (prompt == '📷 Pindai KTM (OCR)') {
                    _showImageSourceDialog(isOcr: true);
                  } else if (prompt == '🔍 Analisis Gambar') {
                    _showImageSourceDialog(isOcr: false);
                  } else {
                    _textController.text = prompt;
                    setState(() => _isComposing = true);
                  }
                },
              ),

            // Input Bar dengan OCR & Mic STT
            _buildInputArea(chatState),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatState chatState) {
    final isBusy = chatState.isLoading || chatState.isStreaming;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '🔴 Sedang merekam suara... Tekan mic lagi untuk transkripsi.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: _cancelRecording,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.deepPurple),
                tooltip: 'Unggah Gambar (OCR / Analisis Visual)',
                onPressed: isBusy ? null : _showMultimodalActions,
              ),
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic_none,
                  color: _isRecording ? Colors.red : Colors.deepPurple,
                ),
                tooltip: _isRecording
                    ? 'Hentikan & Transkripsi (Speech-to-Text)'
                    : 'Rekam Suara (Speech-to-Text)',
                onPressed: isBusy && !_isRecording ? null : _toggleVoiceRecording,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  onChanged: (text) {
                    setState(() => _isComposing = text.trim().isNotEmpty);
                  },
                  decoration: InputDecoration(
                    hintText: chatState.isOfflineMode
                        ? 'Tanya basis data kampus offline...'
                        : 'Tanyakan sesuatu atau unggah berkas...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                icon: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                onPressed: (_isComposing && !isBusy) ? _handleSend : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UI Components
// ============================================================================

/// Banner privasi dan pemberitahuan sanitasi data sensitif
class _SecurityHeaderBanner extends StatelessWidget {
  final String? lastNotice;
  final VoidCallback onDismissNotice;

  const _SecurityHeaderBanner({
    required this.lastNotice,
    required this.onDismissNotice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Colors.deepPurple.withValues(alpha: 0.08),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: Colors.deepPurple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode Aman Aktif: NIK, nomor telepon & alamat otomatis disanitasi sebelum dikirim ke AI.',
                  style: TextStyle(fontSize: 11, color: Colors.deepPurple),
                ),
              ),
            ],
          ),
        ),
        if (lastNotice != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: Colors.amber.withValues(alpha: 0.2),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lastNotice!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onDismissNotice,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bubble pesan (User / AI)
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onFallbackOffline;

  const _MessageBubble({
    required this.message,
    this.onRetry,
    this.onFallbackOffline,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? Colors.red.withValues(alpha: 0.2)
                  : (message.isOffline
                      ? Colors.orange.withValues(alpha: 0.2)
                      : theme.colorScheme.primaryContainer),
              child: Icon(
                message.isError
                    ? Icons.error_outline
                    : (message.isOffline
                        ? Icons.offline_bolt_outlined
                        : Icons.smart_toy_rounded),
                size: 18,
                color: message.isError
                    ? Colors.red
                    : (message.isOffline
                        ? Colors.orange.shade800
                        : theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : (message.isError
                            ? Colors.red.shade50
                            : (message.isOffline
                                ? Colors.orange.shade50
                                : theme.colorScheme.surfaceContainerHighest)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: message.isError
                        ? Border.all(color: Colors.red.shade200)
                        : (message.isOffline
                            ? Border.all(color: Colors.orange.shade200)
                            : null),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message.text + (message.isStreaming ? ' ▍' : ''),
                        style: TextStyle(
                          color: isUser
                              ? theme.colorScheme.onPrimary
                              : (message.isError
                                  ? Colors.red.shade900
                                  : theme.colorScheme.onSurfaceVariant),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (message.sanitizedTypes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Data ${message.sanitizedTypes.join(", ")} disanitasi',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (message.isOffline) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.offline_bolt,
                                size: 12,
                                color: Colors.brown,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Basis Data Kampus Offline',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (message.isCached) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 12,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Diambil dari Cache Lokal (Hemat Kuota)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Tombol Aksi saat Error: Coba Lagi & Gunakan Mode Offline
                      if (message.isError) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Coba Lagi', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: onFallbackOffline,
                              icon: const Icon(Icons.offline_bolt, size: 14),
                              label: const Text('Jawab via Offline', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                    if (!isUser && !message.isStreaming && !message.isError) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14),
                        tooltip: 'Salin balasan',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: message.text),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teks disalin ke clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Indikator loading saat AI sedang menyiapkan balasan
class _LoadingIndicatorBubble extends StatefulWidget {
  const _LoadingIndicatorBubble();

  @override
  State<_LoadingIndicatorBubble> createState() =>
      _LoadingIndicatorBubbleState();
}

class _LoadingIndicatorBubbleState extends State<_LoadingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(0.2),
                const SizedBox(width: 4),
                _buildDot(0.4),
                const SizedBox(width: 8),
                Text(
                  'AI sedang memproses...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final val = (_animController.value - delay) % 1.0;
        final scale = 0.5 + 0.5 * (1 - (val - 0.5).abs() * 2);
        return Transform.scale(
          scale: scale.clamp(0.4, 1.0),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

/// Prompt saran cepat untuk pengguna
class _QuickSuggestions extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const _QuickSuggestions({required this.onSelectPrompt});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      '📅 Jadwal KRS semester genap',
      '📷 Pindai KTM (OCR)',
      '🔍 Analisis Gambar',
      '🎓 Syarat pengajuan beasiswa kampus',
      '🛡️ Cek beasiswa NIK 3578012345670001 telp 08123456789',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = suggestions[index];
          return ActionChip(
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => onSelectPrompt(prompt),
          );
        },
      ),
    );
  }
}
